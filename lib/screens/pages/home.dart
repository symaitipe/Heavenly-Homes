import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/decoration_items.dart';
import '../../model/interior_design.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<InteriorDesign> _selectedDesigns = [];
  List<DecorationItem> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchAndSelectItems();
  }

  // Fetch and select unique items
  Future<void> _fetchAndSelectItems() async {
    // Fetch interior designs
    final designSnapshot = await FirebaseFirestore.instance.collection('interior_designs').get();
    final allDesigns = designSnapshot.docs
        .map((doc) => InteriorDesign.fromFirestore(doc.data()))
        .toList();
    allDesigns.shuffle();
    setState(() {
      _selectedDesigns = allDesigns.take(3).toList();
    });

    // Fetch decoration items
    final itemSnapshot = await FirebaseFirestore.instance.collection('decoration_items').get();
    final allItems = itemSnapshot.docs
        .map((doc) => DecorationItem.fromFirestore(doc.data()))
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
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      userModel = UserModel.fromFirebase(firebaseUser);
    }

    final AuthServices authServices = AuthServices();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heavenly Homes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authServices.signOut();
              if(context.mounted){
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------ Search Bar (Placeholder) --------------------
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Here',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                enabled: false, // Placeholder for now
              ),
            ),
            //---------------------- Premium Designs Section -----------------------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'PREMIUM DESIGNS FOR YOUR HOME',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionCard(
                  context,
                  'Meet My Designer',
                  Icons.person,
                  '/designer_details',
                ),
                _buildOptionCard(
                  context,
                  'Decorate My Dream House',
                  Icons.home,
                  '/category_selection',
                ),
                _buildOptionCard(
                  context,
                  'Best Bids',
                  Icons.local_offer,
                  '/best_bids',
                  hasDiscount: true,
                ),
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
                      // ****** Navigate to a page showing all designs (implement later)
                    },
                    child: const Text('View All'),
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
                      child: SizedBox(
                        width: 110,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.asset(
                                design.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                design.type,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                design.budget,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'By ${design.designer}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      // ****** Navigate to a page showing all designs (implement later)
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            _selectedItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16,0,16,16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7,
              ),
              itemCount: _selectedItems.length,
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.asset(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          item.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '₹${item.price}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context,
      String title,
      IconData icon,
      String route, {
        bool hasDiscount = false,
      }) {
    return Card(
      color: Colors.black,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 30),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    color: Colors.red,
                    child: const Text(
                      'Best\nPrice',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
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