import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckInService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get uid => _auth.currentUser!.uid;

  /// Save check-in
  Future<void> recordCheckIn() async {
    final time = Timestamp.now();

    await _firestore
        .collection('users')
        .doc(uid)
        .set({'lastCheckIn': time}, SetOptions(merge: true));
  }

  /// Get last check-in
  Future<Timestamp?> getLastCheckIn() async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) return null;

    return doc.data()?['lastCheckIn'];
  }

  /// Inactivity logic
  bool isInactive(Timestamp lastCheckIn, {int hours = 24}) {
    final last = lastCheckIn.toDate();
    final now = DateTime.now();

    return now.difference(last).inHours >= hours;
  }
}