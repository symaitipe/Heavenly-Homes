import 'package:flutter/material.dart';

import '../../model/user_model.dart';
import '../../services/auth_services.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the UserModel from route arguments
    final UserModel userModel = ModalRoute.of(context)!.settings.arguments as UserModel;
    final AuthServices authServices = AuthServices();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authServices.signOut();
              Navigator.pushReplacementNamed(context, '/login');
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