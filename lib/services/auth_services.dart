import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../model/user_model.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Email/Password Sign-In
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return UserModel.fromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  // Email/Password Sign-Up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        return UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      return UserModel.fromFirebase(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('An unexpected error occurred');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      throw AuthException('Error signing out');
    }
  }

  // Helper: Convert Firebase error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-ups are disabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}

// Custom exception class for auth errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}