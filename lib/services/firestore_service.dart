import 'package:cloud_firestore/cloud_firestore.dart';
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

    // 2. Link to Elder
    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'trustedContactId': contactId,
    });
  }

  Future<void> updateInactivityThreshold(String elderUid, int hours) async {
    await _db.collection(AppConstants.usersCollection).doc(elderUid).update({
      'inactivityThresholdHours': hours,
    });
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

  // --- Contact Features ---

  Stream<List<UserModel>> streamLinkedElders(String contactUid) {
    return _db
        .collection(AppConstants.usersCollection)
        .where('trustedContactId', isEqualTo: contactUid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList());
  }
}
