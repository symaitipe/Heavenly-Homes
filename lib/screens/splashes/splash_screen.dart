import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Navigate to the next page when the screen is tapped
          Navigator.pushReplacementNamed(context, '/get_started');
        },
        child: Container(
          width: 430,
          height: 932,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF000000), // Black
                const Color(0xFF1E1E1E), // Dark Gray
                const Color(0xFF232323), // Slightly lighter gray
              ],
              stops: [0.0, 0.4986, 0.9808], // Corresponding to the percentages in the gradient
              transform: GradientRotation(343.6 * 3.141592653589793 / 180), // Convert degrees to radians
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              // Centered logo
              Center(
                child: Image.asset(
                  'assets/logos/app-logo.png',
                  width: 150,
                  height: 150,
                ),
              ),
              // "Powered by" text at the bottom
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Powered by Heavenly Studio',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
