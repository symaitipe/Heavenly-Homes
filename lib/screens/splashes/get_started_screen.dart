import 'package:flutter/material.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/logos/Splash screen main photo.png',
              fit: BoxFit.cover,
            ),
          ),
          // App logo
          Positioned(
            top: size.height * 0.1, // around 10% from top
            left: (size.width / 2) - 42.5, // center horizontally (85/2 = 42.5)
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                image: DecorationImage(
                  image: AssetImage('assets/logos/app-logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Welcome Text
          Positioned(
            top: size.height * 0.45,
            left: (size.width - 220) / 2, // center horizontally
            child: SizedBox(
              width: 220,
              height: 62,
              child: Text(
                'Welcome',
                style: TextStyle(
                  fontFamily: 'PoiretOne',
                  fontWeight: FontWeight.w400,
                  fontSize: 48,
                  height: 1.0,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Makes your dream come true Text
          Positioned(
            top: size.height * 0.55,
            left: (size.width - 268) / 2,
            child: SizedBox(
              width: 268,
              height: 30,
              child: Text(
                'Makes your dream come true ...',
                style: TextStyle(
                  fontFamily: 'PoorStory',
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  height: 1.0,
                  color: Color(0xFF9E8324),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Get Started Button
          Positioned(
            bottom: size.height * 0.08, // 8% from bottom
            left: (size.width - 182) / 2,
            child: SizedBox(
              width: 182,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/intro');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // customize if needed
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
