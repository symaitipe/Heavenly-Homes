import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  double _opacity = 1.0;

  // Method to check if user is logged in and navigate
  void _handleSkip(BuildContext context) async {
    setState(() {
      _opacity = 0.0; // Fade out
    });

    await Future.delayed(const Duration(milliseconds: 300)); // Wait for fade animation

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut, // Smooth transition
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF000000),
                Color(0xFF1E1E1E),
                Color(0xFF232323),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Flexible spacing at the top
                const SizedBox(height: 16),
                
                // App Logo
                Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    image: const DecorationImage(
                      image: AssetImage('assets/logos/app-logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Flexible spacing
                const Spacer(flex: 1),
                
                // 3D Photo
                Image.asset(
                  'assets/logos/3D photo.png',
                  width: 278,
                  height: 273,
                  fit: BoxFit.contain,
                  colorBlendMode: BlendMode.lighten,
                ),
                
                // Spacing after image
                const SizedBox(height: 24),
                
                // "Design your dream house" Text - Ensuring it's below the photo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Design your dream house',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Spacing between title and paragraph
                const SizedBox(height: 16),
                
                // Paragraph Text - Ensuring it's below the title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Every human has their own ambitions and dreams for the future. One of my biggest dreams is to have a beautiful house that I can call my own. It will be a place where I can find peace, comfort, and happiness that reflects my personality and fulfills all my desires.',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 12,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Flexible spacing before skip button
                const Spacer(flex: 1),
                
                // Skip Button - Always at the bottom
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 24),
                    child: TextButton(
                      onPressed: () => _handleSkip(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            height: 1.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}