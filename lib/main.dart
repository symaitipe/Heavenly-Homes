import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:heavenly_homes/screens/authenticates/login.dart';
import 'package:heavenly_homes/screens/pages/best_bids.dart';
import 'package:heavenly_homes/screens/pages/cart.dart';
import 'package:heavenly_homes/screens/pages/category_selection.dart';
import 'package:heavenly_homes/screens/pages/designer_details.dart';
import 'package:heavenly_homes/screens/pages/home.dart';
import 'package:heavenly_homes/screens/splashes/get_started_screen.dart';
import 'package:heavenly_homes/screens/splashes/intro.dart';
import 'package:heavenly_homes/screens/splashes/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heavenly Homes',
      debugShowCheckedModeBanner: false,


      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),



      initialRoute: '/splash', // Set the initial route
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/get_started': (context) => const GetStartedPage(),
        '/intro': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/designer_details': (context) => const DesignerDetailsPage(),
        '/category_selection': (context) => const CategorySelectionPage(),
        '/best_bids': (context) => const BestBidsPage(),
        '/cart': (context) => const CartPage(),
      },
    );
  }
}