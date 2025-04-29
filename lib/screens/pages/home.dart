import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/decoration_items.dart';
import '../../model/interior_design.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'item_details.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<InteriorDesign> _selectedDesigns = [];
  List<DecorationItem> _selectedItems = [];
  int _currentBannerIndex = 0;
  late PageController _bannerController;

  @override
  void initState() {
    super.initState();
    _fetchAndSelectItems();
    _bannerController = PageController();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_bannerController.hasClients) {
        if (_currentBannerIndex < 1) {
          _currentBannerIndex++;
        } else {
          _currentBannerIndex = 0;
        }
        _bannerController.animateToPage(
          _currentBannerIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
        _startBannerTimer();
      }
    });
  }

  // Fetch and select unique items
  Future<void> _fetchAndSelectItems() async {
    // Fetch interior designs
    final designSnapshot =
    await FirebaseFirestore.instance.collection('interior_designs').get();
    final allDesigns =
    designSnapshot.docs
        .map((doc) => InteriorDesign.fromFirestore(doc.data()))
        .toList();
    allDesigns.shuffle();
    setState(() {
      _selectedDesigns = allDesigns.take(3).toList();
    });

    // Fetch decoration items
    final itemSnapshot =
    await FirebaseFirestore.instance.collection('decoration_items').get();
    final allItems =
    itemSnapshot.docs
        .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
        .toList();
    allItems.shuffle();
    setState(() {
      _selectedItems = allItems.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the UserModel from route arguments or Firebase
    UserModel? userModel;
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments != null && arguments is UserModel) {
      userModel = arguments;
    } else {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      userModel = UserModel.fromFirebase(firebaseUser);
    }

    final AuthServices authServices = AuthServices();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the back button
        toolbarHeight: 0, // Hide the app bar
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Top Rectangle with Logo, Search, Cart Icon, and Logout Icon --------------------
            Container(
              width: double.infinity,
              height: 158,
              margin: const EdgeInsets.only(left: 0),
              decoration: const BoxDecoration(
                color: Color(0xFF232323),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Stack(
                children: [
                  // App Logo
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        image: const DecorationImage(
                          image: AssetImage('assets/logos/app-logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Search Bar
                  Positioned(
                    top: 81,
                    left: 19,
                    right: 19,
                    child: SizedBox(
                      height: 49,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Here',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Cart Icon with Badge
                  Positioned(
                    top: 15,
                    right: 60,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('cart')
                          .where(
                        'userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
                      )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final itemCount = snapshot.data!.docs.length;
                        return Stack(
                          children: [
                            IconButton(
                              icon: Image.asset(
                                'assets/homescreen/cart_icon.png',
                                width: 24,
                                height: 24,
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/cart');
                              },
                            ),
                            if (itemCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$itemCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  // Logout Icon
                  Positioned(
                    top: 15,
                    right: 15,
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await authServices.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ------------------ Swinging Banner Images --------------------
            SizedBox(
              height: 150,
              child: PageView(
                controller: _bannerController,
                children: [
                  Image.asset(
                    'assets/homescreen/Main card1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Image.asset(
                    'assets/homescreen/Main card2.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            //---------------------- Category Section -----------------------
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 19),
              child: Text(
                'All your category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Category Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryOption('assets/homescreen/Group 71.png', 'Meet My Designer', '/contact_designer'),
                _buildCategoryOption('assets/homescreen/Group 72.png', 'Decorate My Dream House', '/category_selection'),
                _buildCategoryOption('assets/homescreen/Group 73.png', 'Best Bids', '/best_bids'),
              ],
            ),

            //------------------- Featured Interior Designs Section -----------------------
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Interior Design',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to a page showing all designs (implement later)
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            _selectedDesigns.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedDesigns.length,
                itemBuilder: (context, index) {
                  final design = _selectedDesigns[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.asset(
                                  design.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                8,
                                4,
                                8,
                                2,
                              ),
                              child: Text(
                                design.type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                design.budget,
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2,
                              ),
                              child: Text(
                                'By ${design.designer}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            //------------------------------------ Decoration Items Section -----------------------------
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Featured Decoration Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/category_selection');
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            _selectedItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: _selectedItems.length,
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailPage(item: item),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child:
                            item.imageUrl.startsWith('http')
                                ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                size: 50,
                              ),
                            )
                                : Image.asset(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2,
                          ),
                          child: Text(
                            'Rs ${item.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String imagePath, String title, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Image.asset(
            imagePath,
            width: 80,
            height: 80,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}