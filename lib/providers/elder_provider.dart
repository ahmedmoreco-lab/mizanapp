import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ElderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> checkIn(String elderUid, {bool isEmergency = false}) async {
    _setLoading(true);
    try {
      await _firestoreService.recordCheckin(elderUid, isEmergency: isEmergency);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> linkContact(String elderUid, String contactEmail) async {
    _setLoading(true);
    try {
      await _firestoreService.linkContact(elderUid, contactEmail);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeContact(String elderUid, String contactId) async {
    _setLoading(true);
    try {
      await _firestoreService.removeContact(elderUid, contactId);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
