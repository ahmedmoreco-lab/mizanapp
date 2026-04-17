import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = true;

  // Keep a reference to the inner subscription so we can cancel it
  StreamSubscription<UserModel?>? _userModelSubscription;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      // Cancel any previous inner stream subscription before creating a new one
      await _userModelSubscription?.cancel();
      _userModelSubscription = null;

      if (user != null) {
        _userModel = await _firestoreService.getUser(user.uid);

        // Save FCM token to Firestore so contacts can receive push alerts
        await _firestoreService.saveFcmToken(user.uid);

        // Listen to realtime changes (e.g. when contact links, threshold updates)
        _userModelSubscription = _firestoreService.streamUser(user.uid).listen((updatedUser) {
          _userModel = updatedUser;
          notifyListeners();
        });
      } else {
        _userModel = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      await _authService.login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup(String email, String password, String role, String name, {bool startPremium = false}) async {
    try {
      await _authService.signup(email, password, role, name, startPremium: startPremium);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _userModelSubscription?.cancel();
      _userModelSubscription = null;
      await _authService.signOut();
    } finally {
      // Done.
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> updateDisplayName(String name) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    await _firestoreService.updateUserName(uid, name);
    // Optimistically update local model so UI reflects instantly
    _userModel = _userModel?.copyWith(name: name);
    notifyListeners();
  }

  Future<void> deleteAccount(String currentPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Re-authenticate before deletion (Firebase requirement)
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Delete Firestore document first, then the auth user
    await _firestoreService.deleteUserData(user.uid);
    await user.delete();

    // Stream cancellation + cleanup
    await _userModelSubscription?.cancel();
    _userModelSubscription = null;
    _userModel = null;
    _firebaseUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> upgradeToPremium() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    _setLoading(true);
    try {
      await _firestoreService.upgradeUserToPremium(uid);
      // userModel will intuitively update via the stream listener in _init().
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _userModelSubscription?.cancel();
    super.dispose();
  }
}

