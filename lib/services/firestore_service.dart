import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../models/checkin_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---

  Future<void> createUser(UserModel user) async {
    await _db.collection(AppConstants.usersCollection).doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
  }

  // --- Elder Features ---

  Future<void> linkContact(String elderUid, String contactEmail) async {
    // 1. Find contact by email
    final querySnapshot = await _db
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: contactEmail)
        .where('role', isEqualTo: AppConstants.roleContact)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('This email is wrong or it belongs to another Elder. Please ensure the email is registered as a Trusted Contact.');
    }

    final contactDoc = querySnapshot.docs.first;
    final contactId = contactDoc.id;

    // 2. Fetch current Elder data to enforce limits
    final elderDoc = await _db.collection(AppConstants.usersCollection).doc(elderUid).get();
    final elderUser = UserModel.fromDocument(elderDoc);

    if (!elderUser.isPremium && elderUser.trustedContacts.length >= 3) {
      throw Exception('Free plan allows up to 3 Trusted Contacts. Please upgrade to Premium for up to 5 contacts and smart escalation.');
    }
    
    if (elderUser.isPremium && elderUser.trustedContacts.length >= 5) {
      throw Exception('Premium plan allows up to 5 Trusted Contacts.');
    }

    if (elderUser.trustedContacts.contains(contactId)) {
      throw Exception('This contact is already linked.');
    }

    // 3. Link to Elder (add to list, and update legacy field for backward compat)
    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'trustedContactId': contactId, 
      'trustedContacts': FieldValue.arrayUnion([contactId]),
      // Automatically add to end of escalation order
      'escalationOrder': FieldValue.arrayUnion([contactId]),
    });
  }

  Future<void> removeContact(String elderUid, String contactId) async {
    final elderDoc = await _db.collection(AppConstants.usersCollection).doc(elderUid).get();
    final elderUser = UserModel.fromDocument(elderDoc);
    
    // Determine new fallback legacy ID (if any)
    final updatedContacts = List<String>.from(elderUser.trustedContacts)..remove(contactId);
    final fallbackLegacyId = updatedContacts.isNotEmpty ? updatedContacts.first : null;

    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'trustedContactId': fallbackLegacyId,
      'trustedContacts': FieldValue.arrayRemove([contactId]),
      'escalationOrder': FieldValue.arrayRemove([contactId]),
    });
  }

  Future<void> upgradeUserToPremium(String uid) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'isPremium': true,
    });
  }

  Future<void> updateInactivityThreshold(String elderUid, int hours) async {
    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'inactivityThresholdHours': hours,
    });
  }

  /// Saves the device's FCM push token to Firestore so Cloud Functions
  /// can send push notifications to this specific device.
  Future<void> saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection(AppConstants.usersCollection).doc(uid).update({
          'fcmToken': token,
        });
      }
    } catch (_) {
      // Silently ignore — FCM may not be supported on all platforms (e.g. web without VAPID)
    }
  }

  Future<void> recordCheckin(String elderUid, {bool isEmergency = false}) async {
    final checkin = CheckinModel(
      id: '', // Firestore auto-generates this if we use add()
      userId: elderUid,
      timestamp: DateTime.now(),
      isEmergency: isEmergency,
    );

    // Save checkin in a subcollection under the specific user 
    // to avoid needing a global composite index (where + orderBy)
    await _db
        .collection(AppConstants.usersCollection)
        .doc(elderUid)
        .collection(AppConstants.checkinsCollection)
        .add(checkin.toMap());
        
    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'lastCheckIn': Timestamp.now(),
      'currentEscalationLevel': 0, // Reset escalation level when they check in
    });
  }

  Stream<CheckinModel?> streamLastCheckin(String elderUid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(elderUid)
        .collection(AppConstants.checkinsCollection)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return CheckinModel.fromDocument(snapshot.docs.first);
      }
      return null;
    });
  }

  Stream<List<CheckinModel>> streamWeeklyCheckins(String elderUid) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _db
        .collection(AppConstants.usersCollection)
        .doc(elderUid)
        .collection(AppConstants.checkinsCollection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CheckinModel.fromDocument(doc)).toList());
  }

  // --- Contact Features ---

  Stream<List<UserModel>> streamLinkedElders(String contactUid) {
    return _db
        .collection(AppConstants.usersCollection)
        // Use arrayContains for the new list, or Filter.or if we needed legacy support. 
        // We ensure trustedContacts is populated from now on.
        .where('trustedContacts', arrayContains: contactUid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }

  // --- Account Management ---

  Future<List<UserModel>> getContactsByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    // Firestore whereIn supports max 10 elements, perfect for Premium Limit (5)
    final querySnapshot = await _db
        .collection(AppConstants.usersCollection)
        .where(FieldPath.documentId, whereIn: userIds)
        .get();
        
    return querySnapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }

  Future<void> updateUserName(String uid, String name) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'name': name,
    });
  }

  Future<void> saveCustomCheckInTimes(String uid, List<String> times) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'customCheckInTimes': times,
    });
  }

  /// Deletes the user's Firestore document and all their checkins subcollection.
  /// Note: subcollection documents must be deleted individually — Firestore
  /// does NOT auto-delete subcollections when a parent document is deleted.
  Future<void> deleteUserData(String uid) async {
    // Delete all checkins in the subcollection first
    final checkins = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.checkinsCollection)
        .get();
    for (final doc in checkins.docs) {
      await doc.reference.delete();
    }
    // Then delete the user document itself
    await _db.collection(AppConstants.usersCollection).doc(uid).delete();
  }
}
