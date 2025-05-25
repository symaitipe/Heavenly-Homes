
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:heavenly_homes/constants/service_constants.dart';
import 'package:heavenly_homes/screens/authenticates/login.dart';
import 'package:heavenly_homes/screens/authenticates/adminlogin.dart';
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
import 'package:heavenly_homes/screens/pages/account.dart';
import 'package:heavenly_homes/screens/pages/admin_dashboard.dart';

import 'model/decoration_items.dart';
import 'model/designer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyANrw-mS5r1_0OQJF1FqP0mQki-1NiOjyc",
      appId: "1:194849413888:android:ad3b35a1e1a6de67dd31e5",
      messagingSenderId: "194849413888",
      projectId: "homesapp-797a9",
    ),
  );

// Initialize Stripe only for mobile platforms
  if (!kIsWeb) {
    Stripe.publishableKey = ServiceConstants.publishableKey;
    await Stripe.instance.applySettings();
  }

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
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/get_started': (context) => const GetStartedScreen(),
        '/intro': (context) => const IntroPage(),
        '/login': (context) => const LoginPage(),
        '/adminlogin': (context) => const AdminLoginPage(),
        '/home': (context) => const HomePage(),
        '/contact_designer': (context) => const ContactDesignerPage(),
        '/category_selection': (context) => const CategorySelectionPage(),
        '/best_bids': (context) => const BestBidsPage(),
        '/cart': (context) => const CartPage(),
        '/account': (context) => AccountPage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/order_detail': (context) {
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
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Designer) {
            return ChatPage(designer: arguments);
          }
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text("Error loading chat."))
          );
        },
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (_) => const UndefinedRouteScreen());
      },
    );
  }

  static DecorationItem _getDefaultDecorationItem() {
    return DecorationItem(
      id: '',
      name: 'Unknown Item',
      description: '',
      imageUrl: '',
      price: 0.0,
      rating: 0.0,
      reviewCount: 0,
      availableQty: 0,
      category: '',
      isDiscounted: false,
      subImages: [],
    );
  }
}

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