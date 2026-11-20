import 'package:firebase_auth/firebase_auth.dart';

/// Error with a friendly message to show the user
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<User> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  Future<User> logIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  Future<void> logOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e.code));
    }
  }

  /// The login token sent to the Node.js backend with each request
  Future<String?> getToken() async {
    return _auth.currentUser?.getIdToken();
  }

  String _friendlyMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}