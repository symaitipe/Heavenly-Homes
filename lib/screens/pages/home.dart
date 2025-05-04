// lib/screens/pages/home.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// Adjust import paths if necessary
import 'package:heavenly_homes/screens/pages/project_detail_page.dart';
import '../../model/decoration_items.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import 'package:heavenly_homes/screens/pages/item_details.dart';
import 'package:heavenly_homes/screens/pages/search_results.dart';
import '../../model/designer.dart'; // Assuming Project model is here

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _selectedProjectsData = [];
  List<DecorationItem> _selectedItems = [];
  bool _isLoadingContent = true;

  int _currentBannerIndex = 0;
  late PageController _bannerController;
  Timer? _bannerTimer;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  final FocusNode _searchFocusNode = FocusNode();

  UserModel? _currentUserModel;
  bool _isLoadingUser = true;

  final AuthServices _authServices = AuthServices();

  // Color constants
  final Color headerColor = const Color(0xFF232323);
  final Color iconColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _isLoadingUser = true;
    _isLoadingContent = true;
    _fetchUserDataAndContent();
    _bannerController = PageController();
    _startBannerTimer();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  Future<void> _fetchUserDataAndContent() async {
    await _fetchUserData();
    if (_currentUserModel != null && mounted) {
      await _fetchFeaturedContent();
    }
  }

  Future<void> _fetchUserData() async {
    if (!mounted) return;
    setState(() => _isLoadingUser = true);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      if (mounted) {
        _bannerTimer?.cancel();
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    _currentUserModel = await UserModel.fetchUserDetails(firebaseUser);
    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _fetchFeaturedContent() async {
    if (!mounted) return;
    setState(() => _isLoadingContent = true);
    try {
      // Fetch Projects
      final designerSnapshot = await FirebaseFirestore.instance.collection('designers').get();
      List<Map<String, dynamic>> allProjects = [];
       for (var doc in designerSnapshot.docs) {
           final data = doc.data();
           final designerId = doc.id;
           final designerName = data['name'] as String? ?? 'Unknown Designer';
           final projectsData = data['projects'] as List<dynamic>? ?? [];
           for (int index = 0; index < projectsData.length; index++) {
              try {
               final projectData = projectsData[index] as Map<String, dynamic>;
                String imageUrl = (projectData['imageUrl'] is List && (projectData['imageUrl'] as List).isNotEmpty)
                    ? (projectData['imageUrl'] as List).first as String? ?? 'assets/placeholder.jpg'
                    : projectData['imageUrl'] as String? ?? 'assets/placeholder.jpg';
                Project project = Project(
                  title: projectData['title'] as String? ?? 'Untitled Project', imageUrl: imageUrl,
                  category: projectData['category'] as String? ?? 'Uncategorized', description: projectData['description'] as String? ?? 'No description',
                  client: projectData['client'] as String? ?? 'Unknown Client', year: (projectData['year'] as num?)?.toInt() ?? 0,
                  location: projectData['location'] as String? ?? 'No location', price: (projectData['price'] as num?)?.toDouble() ?? 0.0,
                  reviews: [], comments: [],
                );
                allProjects.add({
                  'project': project, 'designerId': designerId, 'designerName': designerName,
                  'projectId': '${designerId}_project_$index', // Construct ID
                });
              } catch (e) { print("Error parsing project $index for $designerId: $e"); }
            }
        }
      allProjects.shuffle();

      // Fetch Items
      final itemSnapshot = await FirebaseFirestore.instance.collection('decoration_items').get();
      final allItems = itemSnapshot.docs.map((doc) {
          try { return DecorationItem.fromFirestore(doc.data(), doc.id); } catch (e) { print("Error parsing item ${doc.id}: $e"); return null; }
      }).whereType<DecorationItem>().toList();
      allItems.shuffle();

      if (mounted) {
        setState(() {
          _selectedProjectsData = allProjects.take(5).toList();
          _selectedItems = allItems.take(6).toList();
          _isLoadingContent = false;
        });
      }
    } catch (e) {
      print('Error fetching content: $e');
      if (mounted) {
        setState(() => _isLoadingContent = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load content.")));
      }
    }
  }

  void _onSearchChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _updateSuggestions();
    } else if (_searchController.text.isEmpty) {
      if(mounted) setState(() { _suggestions = []; _showSuggestions = false; });
    }
  }

  void _onSearchFocusChange() {
    if (!mounted) return;
    setState(() => _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty);
    if (_showSuggestions) _updateSuggestions();
  }

  Future<void> _updateSuggestions() async {
     final query = _searchController.text.trim().toLowerCase();
     if (query.isEmpty || !_searchFocusNode.hasFocus || !mounted) {
       if (mounted) setState(() => _showSuggestions = false);
       return;
     }
     setState(() => _showSuggestions = true);

     try {
       List<Map<String, dynamic>> suggestions = [];
       final queryWords = query.split(' ').where((s) => s.isNotEmpty).toList();
        if (queryWords.isEmpty) {
          if (mounted) setState(() => _showSuggestions = false);
          return;
       }

       // --- Fetch Item Suggestions (Example) ---
       final itemSnapshot = await FirebaseFirestore.instance.collection('decoration_items').limit(20).get();
       final allItems = itemSnapshot.docs.map((doc) { try { return DecorationItem.fromFirestore(doc.data(), doc.id); } catch (e) { return null; } }).whereType<DecorationItem>();
       for (var item in allItems) {
          final nameLower = item.name.toLowerCase(); final categoryLower = item.category.toLowerCase();
          bool matches = queryWords.any((word) => nameLower.contains(word) || categoryLower.contains(word));
          if (matches) suggestions.add({'type': 'item', 'item': item});
          if (suggestions.length >= 5) break;
       }
       // Add project/designer suggestion logic here...

       if (mounted) {
          setState(() { _suggestions = suggestions; _showSuggestions = _searchFocusNode.hasFocus && _suggestions.isNotEmpty; });
       }
     } catch (e) {
       print('Error fetching suggestions: $e');
       if (mounted) setState(() { _suggestions = []; _showSuggestions = false; });
     }
   }

  void _submitSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
       _searchFocusNode.unfocus();
       setState(() { _showSuggestions = false; });
       Navigator.push(context, MaterialPageRoute( builder: (context) => SearchResultsPage(query: trimmedQuery)));
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_bannerController.hasClients || _bannerController.page == null) { timer.cancel(); return; }
      int currentPage = _bannerController.page!.round(); int nextPage = currentPage + 1; const int bannerCount = 2;
      if (nextPage >= bannerCount) nextPage = 0;
      _bannerController.animateToPage(nextPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: Colors.blue)));
    }
    if (_currentUserModel == null) {
      return Scaffold(
           appBar: AppBar(title: const Text("Error"), centerTitle: true, backgroundColor: headerColor),
           backgroundColor: Colors.white,
           body: Center(
               child: Padding(
                 padding: const EdgeInsets.all(20.0),
                 child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                     const Icon(Icons.error_outline, color: Colors.red, size: 40), const SizedBox(height: 16),
                     Text("Failed to load user data. Please restart or log in.", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.black54)),
                     const SizedBox(height: 20), ElevatedButton( onPressed: () async { await _authServices.signOut(); _bannerTimer?.cancel(); if(mounted) Navigator.pushReplacementNamed(context, '/login'); },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text("Go to Login", style: GoogleFonts.poppins(color: Colors.white)), )
                   ],
                 ),
               ),
            )
       );
    }

    // --- Main UI Build ---
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () { if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus(); },
        child: Stack(
          children: [
            // --- Scrollable Content ---
            RefreshIndicator(
              onRefresh: _fetchFeaturedContent, color: Colors.blue, backgroundColor: Colors.white,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(padding: EdgeInsets.only(top: 158 + MediaQuery.of(context).padding.top)),
                  SliverToBoxAdapter(child: _buildBannerSection()),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 25, left: 19, right: 19, bottom: 10),
                    sliver: _buildSectionTitle('All your category'),
                  ),
                  SliverToBoxAdapter(child: _buildCategorySection()),
                  const SliverPadding(padding: EdgeInsets.only(top: 20)),
                  _buildSectionHeader('Featured Interior Design', '/contact_designer'),
                  _buildFeaturedProjectsList(), // Returns a Sliver
                  const SliverPadding(padding: EdgeInsets.only(top: 20)),
                  _buildSectionHeader('Featured Decoration Items', '/category_selection'),
                  _buildFeaturedItemsGrid(), // Returns a Sliver
                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            ),
            // --- Fixed Header ---
            _buildHeaderOriginalStructure(),
            // --- Suggestions Dropdown ---
            if (_showSuggestions && _suggestions.isNotEmpty) _buildSuggestionsOverlay(),
          ],
        ),
      ),
    );
  }

  // --- Header Widget (Original Structure + Account Icon) ---
  Widget _buildHeaderOriginalStructure() {
    return Container(
      width: double.infinity, height: 158,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration( 
        color: headerColor,
        borderRadius: const BorderRadius.only( bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Stack( children: [
          Positioned( top: 15, left: 15,
            child: Container( width: 55, height: 55,
              decoration: BoxDecoration( borderRadius: BorderRadius.circular(100),
                image: const DecorationImage( image: AssetImage('assets/logos/app-logo.png'), fit: BoxFit.cover))),
          ),
          Positioned( top: 81, left: 19, right: 19,
            child: SizedBox( height: 49,
              child: TextField( controller: _searchController, focusNode: _searchFocusNode, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
                 decoration: InputDecoration( hintText: 'Search designers, items...', hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                   prefixIcon: const Icon(Icons.search, color: Colors.grey),
                   suffixIcon: _searchController.text.isNotEmpty ? IconButton( icon: const Icon(Icons.clear, color: Colors.grey, size: 20), tooltip: 'Clear',
                           onPressed: () => _searchController.clear()) : null,
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                   filled: true, fillColor: Colors.grey[100], contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15)),
                 onSubmitted: _submitSearch))),
          Positioned( top: 15, right: 60, // Cart Icon Position
            child: StreamBuilder<QuerySnapshot>( stream: _currentUserModel?.uid == null ? null : FirebaseFirestore.instance.collection('cart')
                      .where('userId', isEqualTo: _currentUserModel!.uid).snapshots(),
              builder: (context, snapshot) { int itemCount = 0; if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) itemCount = snapshot.data!.docs.length;
                return IconButton( icon: Badge( label: Text('$itemCount'), isLabelVisible: itemCount > 0, backgroundColor: Colors.red,
                    child: Image.asset('assets/homescreen/cart_icon.png', width: 24, height: 24, color: iconColor)),
                  tooltip: 'Cart', onPressed: () => Navigator.pushNamed(context, '/cart'));
              })),
          Positioned( top: 15, right: 100, // Account Icon Position (Adjust as needed)
             child: IconButton( icon: Icon(Icons.account_circle_outlined, color: iconColor, size: 28),
               tooltip: 'My Account', onPressed: () => Navigator.pushNamed(context, '/account'))),
          Positioned( top: 15, right: 15, // Logout Icon Position
            child: IconButton( icon: Icon(Icons.logout, color: iconColor), tooltip: 'Sign Out',
              onPressed: () async { await _authServices.signOut(); _bannerTimer?.cancel(); if (mounted) Navigator.pushReplacementNamed(context, '/login'); })),
        ]));
  }

  // --- Suggestions Overlay Widget ---
  Widget _buildSuggestionsOverlay() {
     final double topPosition = 158; // Below the header
     return Positioned( top: topPosition, left: 19, right: 19,
       child: Material( elevation: 6, borderRadius: BorderRadius.circular(15), clipBehavior: Clip.antiAlias,
         child: Container( constraints: const BoxConstraints(maxHeight: 250), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15)),
           child: ListView.separated( shrinkWrap: true, padding: EdgeInsets.zero, itemCount: _suggestions.length,
             itemBuilder: (context, index) {
               final suggestion = _suggestions[index]; Widget? listTile;
               // Item Suggestion
               if (suggestion['type'] == 'item') {
                 final item = suggestion['item'] as DecorationItem;
                 listTile = ListTile(
                    leading: ClipRRect( borderRadius: BorderRadius.circular(4),
                      child: (item.imageUrl.startsWith('http')
                          ? Image.network(item.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.hide_image_outlined, size: 20))
                          : Image.asset(item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/placeholder.jpg', width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.hide_image_outlined, size: 20))),
                    ),
                    title: Text(item.name, style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Item - ${item.category}', style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    dense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    onTap: () { _searchFocusNode.unfocus(); setState(() { _showSuggestions = false; }); Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailPage(item: item))); }
                 );
               }
               // Add Project/Designer suggestion types here...
               return listTile ?? const SizedBox.shrink();
             },
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, indent: 15, endIndent: 15),
           ),
         ),
       ),
     );
  }

  // --- Banner Section Widget ---
  Widget _buildBannerSection() {
     return SizedBox( height: 150, child: PageView( controller: _bannerController, children: [
           _buildBannerImage('assets/homescreen/Main card1.png'),
           _buildBannerImage('assets/homescreen/Main card2.png'),
         ]));
  }
   Widget _buildBannerImage(String imagePath) {
     return Padding( padding: const EdgeInsets.symmetric(horizontal: 0), child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.error_outline, color: Colors.grey)))));
   }

   // --- Category Section Widgets ---
   SliverToBoxAdapter _buildSectionTitle(String title) {
      return SliverToBoxAdapter(
          child: Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87))
      );
   }
   Widget _buildCategorySection() {
      return Padding( padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.start, children: [
           _buildCategoryOption('assets/homescreen/Group 71.png', 'Meet My\nDesigner', '/contact_designer'),
           _buildCategoryOption('assets/homescreen/Group 72.png', 'Decorate My\nDream House', '/category_selection'),
           _buildCategoryOption('assets/homescreen/Group 73.png', 'Best\nBids', '/best_bids'),
         ]));
   }
   Widget _buildCategoryOption(String imagePath, String title, String route) {
      return Expanded( child: InkWell( onTap: () => Navigator.pushNamed(context, route), borderRadius: BorderRadius.circular(10), child: Padding( padding: const EdgeInsets.symmetric(vertical: 8.0),
           child: Column( mainAxisSize: MainAxisSize.min, children: [
               Image.asset(imagePath, width: 65, height: 65, errorBuilder: (c,e,s)=> const SizedBox(width: 65, height: 65, child: Icon(Icons.category, color: Colors.grey))),
               const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87, height: 1.1), maxLines: 2),
             ]))));
   }

  // --- Section Header Widget ---
  SliverToBoxAdapter _buildSectionHeader(String title, String viewAllRoute) {
     return SliverToBoxAdapter( child: Padding( padding: const EdgeInsets.only(left: 19, right: 10, top: 10, bottom: 5), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
             Text( title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)),
             TextButton( onPressed: () => Navigator.pushNamed(context, viewAllRoute), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), alignment: Alignment.centerRight),
               child: Text('View All', style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 13))) ])));
  }

  // --- Featured Projects List Widget ---
  SliverToBoxAdapter _buildFeaturedProjectsList() {
     if (_isLoadingContent) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator(color: Colors.blue))));
     if (_selectedProjectsData.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No featured designs.", style: TextStyle(color: Colors.grey)))));

     return SliverToBoxAdapter( child: SizedBox( height: 210,
           child: ListView.builder(
             scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 15, right: 5), itemCount: _selectedProjectsData.length,
             itemBuilder: (context, index) {
                 final projectData = _selectedProjectsData[index]; final project = projectData['project'] as Project;
                 final String designerName = projectData['designerName'] as String; final String projectId = projectData['projectId'] as String? ?? '';
                 if (projectId.isEmpty) return const SizedBox.shrink();
                 return Padding( padding: const EdgeInsets.only(right: 10.0), child: GestureDetector( onTap: () { Navigator.push(context, MaterialPageRoute( builder: (context) => ProjectDetailPage(project: project, projectId: projectId))); },
                     child: SizedBox( width: 130, child: Card( color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3, clipBehavior: Clip.antiAlias,
                         child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                             Expanded( child: Image.asset( project.imageUrl.isNotEmpty ? project.imageUrl : 'assets/placeholder.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (ctx, err, st) => Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40))))),
                             Padding( padding: const EdgeInsets.fromLTRB(8, 6, 8, 2), child: Text(project.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                             Padding( padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('By $designerName', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                             Padding( padding: const EdgeInsets.fromLTRB(8, 2, 8, 6), child: Text('LKR ${project.price > 0 ? project.price.toStringAsFixed(0) : 'N/A'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                           ]) // End Column children
                       ) // End Card
                     ) // End SizedBox
                   ) // End GestureDetector
                 ); // End Padding
             }, // End itemBuilder
           ), // End ListView.builder
       )); // End SizedBox & SliverToBoxAdapter
  }

  // --- Featured Items Grid Widget ---
  Widget _buildFeaturedItemsGrid() {
     if (_isLoadingContent && _selectedProjectsData.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
     if (_selectedItems.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20.0), child: Text("No featured items.", style: TextStyle(color: Colors.grey)))));

     return SliverPadding( padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.75),
            delegate: SliverChildBuilderDelegate(
               (context, index) {
                 final item = _selectedItems[index];
                 return GestureDetector( onTap: () { Navigator.push(context, MaterialPageRoute( builder: (context) => ItemDetailPage(item: item))); },
                   child: Card( color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3, clipBehavior: Clip.antiAlias,
                     child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                       Expanded( child: (item.imageUrl.startsWith('http')
                               ? Image.network( item.imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (ctx, err, st) => Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 30))), loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) return child; return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, strokeWidth: 2, color: Colors.blue)); })
                               : Image.asset( item.imageUrl.isNotEmpty ? item.imageUrl : 'assets/placeholder.jpg', fit: BoxFit.cover, width: double.infinity, errorBuilder: (ctx, err, st) => Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 30)))))),
                       Padding( padding: const EdgeInsets.fromLTRB(8, 6, 8, 2), child: Text(item.name, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                       Padding( padding: const EdgeInsets.fromLTRB(8, 0, 8, 6), child: Text('Rs ${item.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                     ])));
               },
               childCount: _selectedItems.length,
            )));
  }
}