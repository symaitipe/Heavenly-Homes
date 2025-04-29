import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_homes/screens/pages/project_detail_page.dart';
import '../../model/decoration_items.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'item_details.dart';
import 'search_results.dart';
import '../../model/designer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _selectedProjectsData = [];
  List<DecorationItem> _selectedItems = [];
  int _currentBannerIndex = 0;
  late PageController _bannerController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _fetchAndSelectItems();
    _bannerController = PageController();
    _startBannerTimer();
    _searchController.addListener(_updateSuggestions);
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _searchController.removeListener(_updateSuggestions);
    _searchController.dispose();
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

  Future<void> _fetchAndSelectItems() async {
    try {
      final designerSnapshot =
      await FirebaseFirestore.instance.collection('designers').get();
      List<Map<String, dynamic>> allProjects = [];

      for (var doc in designerSnapshot.docs) {
        final data = doc.data();
        final designerId = doc.id;
        final designerName = data['name'] is String ? data['name'] as String : 'Unknown Designer';
        final projectsData = data['projects'] as List<dynamic>? ?? [];

        for (int index = 0; index < projectsData.length; index++) {
          final projectData = projectsData[index] as Map<String, dynamic>;
          String imageUrl = '';
          final imageUrlData = projectData['imageUrl'];
          if (imageUrlData is String) {
            imageUrl = imageUrlData;
          } else if (imageUrlData is List && imageUrlData.isNotEmpty) {
            imageUrl = imageUrlData.first as String;
          }

          final project = Project(
            title: projectData['title'] is String ? projectData['title'] as String : 'Untitled Project',
            imageUrl: imageUrl,
            category: projectData['category'] is String ? projectData['category'] as String : 'Uncategorized',
            description: projectData['description'] is String ? projectData['description'] as String : 'No description available',
            client: projectData['client'] is String ? projectData['client'] as String : 'Unknown Client',
            year: (projectData['year'] as num?)?.toInt() ?? 0,
            location: projectData['location'] is String ? projectData['location'] as String : 'No location provided',
            price: (projectData['price'] as num?)?.toDouble() ?? 0.0,
            reviews: [],
            comments: [],
          );

          allProjects.add({
            'project': project,
            'designerId': designerId,
            'designerName': designerName,
            'projectIndex': index,
          });
        }
      }

      allProjects.shuffle();
      setState(() {
        _selectedProjectsData = allProjects.take(3).toList();
      });

      final itemSnapshot =
      await FirebaseFirestore.instance.collection('decoration_items').get();
      final allItems = itemSnapshot.docs
          .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
          .toList();
      allItems.shuffle();
      setState(() {
        _selectedItems = allItems.take(3).toList();
      });
    } catch (e) {
      //print('Error fetching data: $e');
      setState(() {
        _selectedProjectsData = [];
        _selectedItems = [];
      });
    }
  }

  Future<void> _updateSuggestions() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
    });

    try {
      List<Map<String, dynamic>> suggestions = [];
      final queryWords = query.toLowerCase().split(' ');

      // Fetch projects from designers
      final designerSnapshot =
      await FirebaseFirestore.instance.collection('designers').get();
      for (var doc in designerSnapshot.docs) {
        final data = doc.data();
        final designerId = doc.id;
        final designerName = data['name'] is String ? data['name'] as String : 'Unknown Designer';
        //print('Designer Name: $designerName');
        final designerNameLower = designerName.toLowerCase();
        final projectsData = data['projects'] as List<dynamic>? ?? [];

        // Check if designer name matches directly
        bool designerMatches = queryWords.any((word) => designerNameLower.contains(word));
        if (designerMatches) {
          suggestions.add({
            'type': 'designer',
            'designerName': designerName,
            'designerId': designerId,
          });
        }

        // Check projects
        for (int index = 0; index < projectsData.length; index++) {
          final projectData = projectsData[index] as Map<String, dynamic>;
          String imageUrl = '';
          final imageUrlData = projectData['imageUrl'];
          if (imageUrlData is String) {
            imageUrl = imageUrlData;
          } else if (imageUrlData is List && imageUrlData.isNotEmpty) {
            imageUrl = imageUrlData.first as String;
          }

          final project = Project(
            title: projectData['title'] is String ? projectData['title'] as String : 'Untitled Project',
            imageUrl: imageUrl,
            category: projectData['category'] is String ? projectData['category'] as String : 'Uncategorized',
            description: projectData['description'] is String ? projectData['description'] as String : 'No description available',
            client: projectData['client'] is String ? projectData['client'] as String : 'Unknown Client',
            year: (projectData['year'] as num?)?.toInt() ?? 0,
            location: projectData['location'] is String ? projectData['location'] as String : 'No location provided',
            price: (projectData['price'] as num?)?.toDouble() ?? 0.0,
            reviews: [],
            comments: [],
          );

          final titleLower = project.title.toLowerCase();
          final categoryLower = project.category.toLowerCase();
          bool projectMatches = queryWords.any((word) =>
          titleLower.contains(word) ||
              designerNameLower.contains(word) ||
              categoryLower.contains(word));

          if (projectMatches) {
            suggestions.add({
              'type': 'project',
              'project': project,
              'designerId': designerId,
              'designerName': designerName,
              'projectIndex': index,
            });
          }
        }
      }

      // Fetch decoration items
      final itemSnapshot =
      await FirebaseFirestore.instance.collection('decoration_items').get();
      final allItems = itemSnapshot.docs
          .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
          .toList();

      for (var item in allItems) {
        final nameLower = item.name.toLowerCase();
        final categoryLower = item.category.toLowerCase();
        bool matches = queryWords.any((word) =>
        nameLower.contains(word) || categoryLower.contains(word));

        if (matches) {
          suggestions.add({
            'type': 'item',
            'item': item,
          });
        }
      }

      // Limit suggestions to 5 for performance
      setState(() {
        _suggestions = suggestions.take(5).toList();
      });
    } catch (e) {
      //print('Error fetching suggestions: $e');
      setState(() {
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      Positioned(
                        top: 81,
                        left: 19,
                        right: 19,
                        child: SizedBox(
                          height: 49,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search designer name, item name, or design name',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _showSuggestions = false;
                                  });
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onTap: () {
                              if (_searchController.text.isNotEmpty) {
                                setState(() {
                                  _showSuggestions = true;
                                });
                              }
                            },
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                setState(() {
                                  _showSuggestions = false;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchResultsPage(query: value.trim()),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
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
                          Navigator.pushNamed(context, '/contact_designer');
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                _selectedProjectsData.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedProjectsData.length,
                    itemBuilder: (context, index) {
                      final projectData = _selectedProjectsData[index];
                      final project = projectData['project'] as Project;
                      final String designerId = projectData['designerId'] as String;
                      final String designerName = projectData['designerName'] as String;
                      final int projectIndex = projectData['projectIndex'] as int;
                      final String projectId = '${designerId}_$projectIndex';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailPage(
                                  project: project,
                                  projectId: projectId,
                                ),
                              ),
                            );
                          },
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
                                        project.imageUrl.isNotEmpty
                                            ? project.imageUrl
                                            : 'assets/placeholder.jpg',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (context, error, stackTrace) =>
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
                                      project.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'LKR ${project.price.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 2),
                                    child: Text(
                                      'By $designerName',
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
                                child: item.imageUrl.startsWith('http')
                                    ? Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                  ),
                                )
                                    : Image.asset(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
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
          // Suggestions Dropdown
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 130,
              left: 19,
              right: 19,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      if (suggestion['type'] == 'designer') {
                        final designerName = suggestion['designerName'] as String;
                        return ListTile(
                          title: Text(designerName),
                          subtitle: const Text('Designer'),
                          onTap: () {
                            setState(() {
                              _showSuggestions = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultsPage(query: designerName),
                              ),
                            );
                          },
                        );
                      } else if (suggestion['type'] == 'project') {
                        final project = suggestion['project'] as Project;
                        final designerName = suggestion['designerName'] as String;
                        return ListTile(
                          title: Text(project.title),
                          subtitle: Text('Design by $designerName'),
                          onTap: () {
                            final designerId = suggestion['designerId'] as String;
                            final projectIndex = suggestion['projectIndex'] as int;
                            final projectId = '${designerId}_$projectIndex';
                            setState(() {
                              _showSuggestions = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailPage(
                                  project: project,
                                  projectId: projectId,
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        final item = suggestion['item'] as DecorationItem;
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text('Item - ${item.category}'),
                          onTap: () {
                            setState(() {
                              _showSuggestions = false;
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailPage(item: item),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
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