import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  // Method to check if user is logged in and navigate accordingly
  void _handleSkip(BuildContext context) {
    // Check if a user is already logged in
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is already logged in, navigate to HomePage
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User is not logged in, navigate to LoginPage
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.greenAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Intro Page!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _handleSkip(context), // Call the method to handle navigation
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}