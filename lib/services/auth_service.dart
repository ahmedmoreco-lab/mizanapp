import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return await _firestoreService.getUser(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Firebase Auth SDK v5+ may return INVALID_LOGIN_CREDENTIALS instead
      // of the older user-not-found / wrong-password codes.
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email. Please check and try again.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        // Firebase SDK v9+ merges these into one opaque code
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
          throw Exception('Invalid email or password. Please check your credentials and try again.');
        case 'invalid-email':
          throw Exception('The email address is badly formatted.');
        case 'user-disabled':
          throw Exception('This account has been disabled. Please contact support.');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please wait a moment and try again.');
        case 'network-request-failed':
          throw Exception('No internet connection. Please check your network and try again.');
        default:
          throw Exception(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<UserModel?> signup(String email, String password, String role, String name, {bool startPremium = false}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          role: role,
          name: name,
          isPremium: startPremium,
        );

        await _firestoreService.createUser(userModel);
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Signup failed');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
