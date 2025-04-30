import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../model/designer.dart';
import 'designer_detail_page.dart';


class ContactDesignerPage extends StatefulWidget {
  const ContactDesignerPage({super.key});

  @override
  State<ContactDesignerPage> createState() => _ContactDesignerPageState();
}

class _ContactDesignerPageState extends State<ContactDesignerPage> {
  String _searchQuery = ''; // For searching designers in the first tab
  String? _selectedCategory; // For category selection in the second tab
  String _projectSearchQuery = ''; // For searching projects in the second tab
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0; // 0: Contact a Designer, 1: I Will Select My Designs

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch all designers and their projects from Firestore
  Stream<List<Designer>> _fetchDesigners() {
    return FirebaseFirestore.instance
        .collection('designers')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        Designer.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Get all unique categories from all designers' projects
  Stream<List<String>> _getAllCategories() {
    return _fetchDesigners().map((designers) {
      final categories = designers
          .expand((designer) => designer.projects.map((project) => project.category))
          .toSet()
          .toList();
      categories.sort();
      return categories;
    });
  }

  // Get all projects for the selected category, filtered by search query
  Stream<List<MapEntry<Designer, Project>>> _getFilteredProjects() {
    return _fetchDesigners().map((designers) {
      if (_selectedCategory == null) return [];

      final allProjects = designers
          .asMap()
          .entries
          .expand((designerEntry) {
        final designer = designerEntry.value;
        return designer.projects.asMap().entries.map((projectEntry) {
          return MapEntry(designer, projectEntry.value);
        });
      })
          .where((entry) => entry.value.category == _selectedCategory)
          .toList();

      if (_projectSearchQuery.isEmpty) return allProjects;

      return allProjects.where((entry) {
        final project = entry.value;
        return project.title.toLowerCase().contains(_projectSearchQuery.toLowerCase()) ||
            project.description.toLowerCase().contains(_projectSearchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryWhite,
      appBar: AppBar(
        title: const Text('Contact Designer'),
        backgroundColor: AppConstants.primaryBlack,
        foregroundColor: AppConstants.primaryWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTab(context, 'By name Designer', 0),
                _buildTab(context, 'By Designs', 1),
              ],
            ),
          ),
          // Search Bar (only for "Contact a Designer" tab)
          if (_selectedTabIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search Designers',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  fillColor: AppConstants.primaryWhite,
                ),
              ),
            ),
          // Tab Content
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildContactDesignerTab()
                : _buildSelectDesignsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, int index) {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
            if (index == 0) {
              // Reset category selection and search when switching to "Contact a Designer" tab
              _selectedCategory = null;
              _projectSearchQuery = '';
              _searchController.clear();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? AppConstants.primaryBlack
                : AppConstants.primaryWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConstants.primaryBlack),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues (alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTabIndex == index
                  ? AppConstants.primaryGold
                  : AppConstants.primaryBlack,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactDesignerTab() {
    return StreamBuilder<List<Designer>>(
      stream: _fetchDesigners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading designers'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No designers available'));
        }

        final designers = snapshot.data!;
        final filteredDesigners = _searchQuery.isEmpty
            ? designers
            : designers
            .where((designer) =>
            designer.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (filteredDesigners.isEmpty) {
          return const Center(child: Text('No designers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: filteredDesigners.length,
          itemBuilder: (context, index) {
            final designer = filteredDesigners[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Profile Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        designer.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 50),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Designer Details
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DesignerDetailPage(designer: designer),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              designer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < designer.rating.floor()
                                          ? Icons.star
                                          : (index < designer.rating
                                          ? Icons.star_half
                                          : Icons.star_border),
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${designer.reviewCount} Reviews)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              designer.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.yellow,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                designer.availability,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Send Message Button
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: () {
                        // Navigate to ChatPage
                        Navigator.pushNamed(context, '/chat', arguments: designer);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectDesignsTab() {
    if (_selectedCategory == null) {
      // Show category selection grid
      return StreamBuilder<List<String>>(
        stream: _getAllCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading categories'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories available'));
          }

          final categories = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 3 / 2,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppConstants.primaryWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues (alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Placeholder for category image
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppConstants.primaryGold.withValues (alpha: 0.3),
                              AppConstants.primaryBlack.withValues (alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryBlack,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      // Show projects for the selected category with a search bar
      return Column(
        children: [
          // Back button and category title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppConstants.primaryBlack,
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _projectSearchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _selectedCategory!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues (alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects (e.g., Industrial, Home)',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppConstants.primaryBlack,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppConstants.primaryWhite,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _projectSearchQuery = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Project list
          Expanded(
            child: StreamBuilder<List<MapEntry<Designer, Project>>>(
              stream: _getFilteredProjects(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading projects'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No projects match your search.'));
                }

                final projects = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final entry = projects[index];
                    final designer = entry.key;
                    final project = entry.value;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DesignerDetailPage(designer: designer),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues (alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                              child: Image.asset(
                                project.imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      project.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryBlack,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'By ${designer.name}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }
}