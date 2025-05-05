import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Email/Password Sign-Up
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber, // New parameter
    required String address,    // New parameter
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          phoneNumber: phoneNumber.trim(), // Use passed phone number
          address: address.trim(),       // Use passed address
          photoUrl: user.photoURL,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toJson());

        print("User created in Auth and details saved to Firestore.");
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign up: ${e.code} - ${e.message}");
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      print("Unexpected error during sign up: $e");
      throw AuthException('An unexpected error occurred during sign up.');
    }
  }

  // Email/Password Sign-In
  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = userCredential.user;

      if (user != null) {
        print("Fetching user details from Firestore for UID: ${user.uid}");
        return await UserModel.fetchUserDetails(user);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during sign in: ${e.code} - ${e.message}");
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      print("Unexpected error during sign in: $e");
      throw AuthException('An unexpected error occurred during sign in.');
    }
  }

  // Google Sign-In
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign In cancelled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDocSnapshot = await userDocRef.get();

        if (!userDocSnapshot.exists) {
          print("New Google user detected. Creating Firestore entry for UID: ${user.uid}");
          UserModel newUser = UserModel.fromFirebase(user);
          await userDocRef.set(newUser.toJson());
          return newUser;
        } else {
          print("Existing Google user found. Fetching details from Firestore for UID: ${user.uid}");
          return await UserModel.fetchUserDetails(user);
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException during Google sign in: ${e.code} - ${e.message}");
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      print("Unexpected error during Google sign in: $e");
      throw AuthException('An error occurred during Google Sign-In.');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      print("User signed out successfully.");
    } catch (e) {
      print("Error during sign out: $e");
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
        return 'Email/password sign-up is currently disabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'The sign-in credential is not valid.';
      default:
        print("Unhandled FirebaseAuthException code: $code");
        return 'An authentication error occurred. Please try again.';
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
