import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to retrieve the UserModel from route arguments
    UserModel? userModel;
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments != null && arguments is UserModel) {
      userModel = arguments;
    } else {
      // If no arguments are provided, get current user from firebase
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        // If no user is logged in, redirect to LoginPage
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      userModel = UserModel.fromFirebase(firebaseUser);
    }

    final AuthServices authServices = AuthServices();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authServices.signOut();
              if(context.mounted){
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${userModel.displayName ?? 'User'}!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            if (userModel.photoUrl != null)
              CircleAvatar(
                backgroundImage: NetworkImage(userModel.photoUrl!),
                radius: 40,
              ),
            const SizedBox(height: 10),
            Text(
              'Email: ${userModel.email ?? 'Not provided'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}