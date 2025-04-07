import 'package:flutter/material.dart';
import '../../services/auth_services.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login Page',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: Image.asset(
                'assets/logos/google-image.jpg',
                width: 24,
                height: 24,
              ),
              label: const Text('Sign in with Google'),
            ),

          ],
        ),
      ),
    );
  }
}