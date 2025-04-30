import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:heavenly_homes/screens/authenticates/login.dart';
import 'package:heavenly_homes/screens/pages/best_bids.dart';
import 'package:heavenly_homes/screens/pages/cart.dart'; // Corrected CartPage import if needed
import 'package:heavenly_homes/screens/pages/category_selection.dart';
import 'package:heavenly_homes/screens/pages/chat_page.dart';
// import 'package:heavenly_homes/screens/pages/checkout_page.dart'; // No longer needed for routes map
import 'package:heavenly_homes/screens/pages/contact_designer_page.dart';
import 'package:heavenly_homes/screens/pages/home.dart';
import 'package:heavenly_homes/screens/pages/order_details.dart';
// import 'package:heavenly_homes/screens/pages/order_processing_page.dart'; // No longer needed for routes map
import 'package:heavenly_homes/screens/splashes/get_started_screen.dart';
import 'package:heavenly_homes/screens/splashes/intro.dart';
import 'package:heavenly_homes/screens/splashes/splash_screen.dart';

import 'model/decoration_items.dart'; // Assuming paths are correct
import 'model/designer.dart';         // Assuming paths are correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Consider using Firebase CLI for configuration or environment variables
  // instead of hardcoding keys directly in the source code.
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyANrw-mS5r1_0OQJF1FqP0mQki-1NiOjyc", // IMPORTANT: Keep keys secure
      appId: "1:194849413888:android:ad3b35a1e1a6de67dd31e5",
      messagingSenderId: "194849413888",
      projectId: "homesapp-797a9",
    ),
  );
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
        primarySwatch: Colors.blue, // Consider defining a more specific theme
        fontFamily: 'Poppins', // Example: Set default font if used widely
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash', // Start with the splash screen
      routes: {
        // --- Static Routes ---
        '/splash': (context) => const SplashScreen(),
        '/get_started': (context) => const GetStartedScreen(),
        '/intro': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/contact_designer': (context) => const ContactDesignerPage(),
        '/category_selection': (context) => const CategorySelectionPage(),
        '/best_bids': (context) => const BestBidsPage(),
        '/cart': (context) => const CartPage(), // Keep if navigating by name is intended

        // --- Routes that often require arguments (Handle with care) ---
        '/order_detail': (context) {
          // It's generally better to navigate to detail pages using
          // Navigator.push with arguments rather than defining them here
          // with dummy data or complex ModalRoute logic if possible.
          // This example assumes arguments might be passed, otherwise it uses defaults.
          final arguments = ModalRoute.of(context)?.settings.arguments;
          DecorationItem item;
          String orderId = '';
          String userId = '';

          if (arguments is Map<String, dynamic>) {
             item = arguments['item'] as DecorationItem? ?? _getDefaultDecorationItem();
             orderId = arguments['orderId'] as String? ?? '';
             userId = arguments['userId'] as String? ?? '';
          } else {
             item = _getDefaultDecorationItem();
          }

          return OrderDetailPage(
              item: item,
              orderId: orderId,
              userId: userId,
            );
        },

        '/chat': (context) {
          // Ensure arguments are always passed correctly when navigating to '/chat'
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Designer) {
             return ChatPage(designer: arguments);
          } else {
             // Handle error: navigate back or show an error page
             print("Error: Incorrect arguments passed to /chat route.");
             // Example: Return a simple error view or navigate back
             return Scaffold(appBar: AppBar(), body: const Center(child: Text("Error loading chat.")));
             // Or Navigator.pop(context); return const SizedBox.shrink(); // Avoid building invalid page
          }
        },

        // --- REMOVED Routes ---
        // '/checkout': Route removed because it requires dynamic data passed via Navigator.push()
        // '/order_processing': Route removed because it requires dynamic data passed via Navigator.pushReplacement()

      },
      // Optional: Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const UndefinedRouteScreen()); // Create a screen for undefined routes
      },
    );
  }

   // Helper function to provide default item for OrderDetailPage route if needed
   static DecorationItem _getDefaultDecorationItem() {
     return DecorationItem(
       id: '', name: 'Unknown Item', description: '', imageUrl: '', price: 0.0,
       rating: 0.0, reviewCount: 0, availableQty: 0, category: '',
       isDiscounted: false, subImages: [],
     );
   }
}

// Example screen for undefined routes
class UndefinedRouteScreen extends StatelessWidget {
  const UndefinedRouteScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('The requested page could not be found.')),
    );
  }
}