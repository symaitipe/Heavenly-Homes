import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  String? email;
  String? firstName;
  String? lastName;
  String? phoneNumber;
  String? address;
  String? photoUrl;

  UserModel({
    required this.uid,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.address,
    this.photoUrl,
  });

  // Factory constructor from Firebase User
  factory UserModel.fromFirebase(User user) {
    String? potentialFirstName;
    String? potentialLastName;
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final nameParts = user.displayName!.split(' ');
      potentialFirstName = nameParts.first;
      if (nameParts.length > 1) {
        potentialLastName = nameParts.sublist(1).join(' ');
      }
    }

    return UserModel(
      uid: user.uid,
      email: user.email,
      firstName: potentialFirstName,
      lastName: potentialLastName,
      phoneNumber: user.phoneNumber,
      address: null,
      photoUrl: user.photoURL,
    );
  }

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      print("Warning: Firestore document data is null for doc ID: ${doc.id}");
      return UserModel(uid: doc.id);
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      address: data['address'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  // Method to convert UserModel to a Map for saving to Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'address': address,
      'photoUrl': photoUrl,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Add this method to save the user to Firestore
  Future<void> saveToFirestore() async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      
      await userDocRef.set(toJson(), SetOptions(merge: true));
      print("User data saved to Firestore for UID: $uid");
    } catch (e) {
      print("Error saving user details to Firestore for UID $uid: $e");
      throw e; // Rethrow to handle in the UI
    }
  }

  // Update first and last name from a full name string
  void updateFromDisplayName(String fullName) {
    if (fullName.isEmpty) return;
    
    final nameParts = fullName.split(' ');
    firstName = nameParts.first;
    if (nameParts.length > 1) {
      lastName = nameParts.sublist(1).join(' ');
    } else {
      lastName = '';
    }
  }

  // Static helper method to fetch complete user details
  static Future<UserModel> fetchUserDetails(User firebaseUser) async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid);
      DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        print("Firestore document found for UID: ${firebaseUser.uid}. Creating UserModel from Firestore.");
        return UserModel.fromFirestore(userDoc);
      } else {
        print("Firestore document NOT found for UID: ${firebaseUser.uid}. Creating UserModel from Firebase Auth basic info.");
        return UserModel.fromFirebase(firebaseUser);
      }
    } catch (e) {
      print("Error fetching user details from Firestore for UID ${firebaseUser.uid}: $e");
      return UserModel.fromFirebase(firebaseUser);
    }
  }

  // Getter for a convenient display name
  String get displayName {
    if (firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName != null && firstName!.isNotEmpty) {
      return firstName!;
    } else if (lastName != null && lastName!.isNotEmpty) {
      return lastName!;
    } else if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return 'User';
  }
}