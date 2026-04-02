import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class ContactProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // The view will mostly rely on StreamBuilders that call the service directly,
  // but we can put any complex Contact logic here if needed.
  // Currently, we just expose the streams from FirestoreService
  // to keep the UI reactive.

  Stream<List<UserModel>> streamLinkedElders(String contactUid) {
    return _firestoreService.streamLinkedElders(contactUid);
  }
}
