// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // *** ADDED IMPORT ***

// Screen Imports (ensure paths are correct for your project)
import 'package:heavenly_homes/screens/pages/account.dart'; // *** Ensure this file exists at this path ***
import 'package:heavenly_homes/screens/authenticates/login.dart';
import 'package:heavenly_homes/screens/pages/best_bids.dart';
import 'package:heavenly_homes/screens/pages/cart.dart';
import 'package:heavenly_homes/screens/pages/category_selection.dart';
import 'package:heavenly_homes/screens/pages/chat_page.dart';
import 'package:heavenly_homes/screens/pages/contact_designer_page.dart';
import 'package:heavenly_homes/screens/pages/home.dart';
import 'package:heavenly_homes/screens/pages/order_details.dart';
import 'package:heavenly_homes/screens/splashes/get_started_screen.dart';
import 'package:heavenly_homes/screens/splashes/intro.dart';
import 'package:heavenly_homes/screens/splashes/splash_screen.dart';

// Model Imports (ensure paths are correct)
import 'package:heavenly_homes/model/decoration_items.dart';
import 'package:heavenly_homes/model/designer.dart';

// --- Your Firebase Options ---
// IMPORTANT: Replace placeholders with your actual Firebase config values.
// Consider using Firebase CLI or environment variables for security.
const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyANrw-mS5r1_0OQJF1FqP0mQki-1NiOjyc", // Replace if necessary
    appId: "1:194849413888:android:ad3b35a1e1a6de67dd31e5", // Replace if necessary
    messagingSenderId: "194849413888", // Replace if necessary
    projectId: "homesapp-797a9", // Replace if necessary
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: firebaseOptions, // Use the options defined above
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
        primarySwatch: Colors.blue, // Base color scheme
        fontFamily: 'Poppins', // Default font
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark, // Use a dark theme base
        scaffoldBackgroundColor: Colors.grey[900], // Dark background
        appBarTheme: AppBarTheme(
           backgroundColor: const Color(0xFF232323), // Consistent AppBar color
           elevation: 0,
           iconTheme: const IconThemeData(color: Colors.white),
           // *** Corrected: Use GoogleFonts here ***
           titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
         // *** Corrected: Use GoogleFonts here ***
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
           bodyColor: Colors.white, // Default text color
           displayColor: Colors.white,
        ),
        // Add other theme customizations if needed
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
        '/cart': (context) => const CartPage(),
        // *** Route for Account Page (ensure AccountPage class exists) ***
        '/account': (context) => const AccountPage(),

        // --- Routes that require arguments (Keep your existing logic) ---
        '/order_detail': (context) {
          // Ensure arguments are handled correctly
          final arguments = ModalRoute.of(context)?.settings.arguments;
          DecorationItem item;
          String orderId = '';
          String userId = '';

          if (arguments is Map<String, dynamic>) {
             item = arguments['item'] as DecorationItem? ?? _getDefaultDecorationItem(); // Use helper for default
             orderId = arguments['orderId'] as String? ?? '';
             userId = arguments['userId'] as String? ?? '';
          } else {
             // Handle cases where arguments might not be a map or are null
             item = _getDefaultDecorationItem(); // Fallback to default
             print("Warning: No or invalid arguments passed to /order_detail route.");
          }

          return OrderDetailPage(
              item: item,
              orderId: orderId,
              userId: userId,
            );
        },

        '/chat': (context) {
          // Ensure arguments are handled correctly
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Designer) {
             return ChatPage(designer: arguments);
          } else {
             print("Error: Incorrect arguments passed to /chat route.");
             // Provide a fallback or error screen
             return Scaffold(appBar: AppBar(title: const Text("Error")), body: const Center(child: Text("Could not load chat.")));
          }
        },
      },
      // Optional: Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const UndefinedRouteScreen());
      },
    );
  }

   // Helper function to provide default item for OrderDetailPage route if needed
   static DecorationItem _getDefaultDecorationItem() {
     // Provide sensible defaults
     return DecorationItem(
       id: 'default_id', name: 'Unknown Item', description: 'No details available', imageUrl: '', price: 0.0,
       rating: 0.0, reviewCount: 0, availableQty: 0, category: 'Unknown',
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