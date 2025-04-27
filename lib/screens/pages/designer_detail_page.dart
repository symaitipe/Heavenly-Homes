import 'package:flutter/material.dart';
import '../../model/designer.dart';
import 'project_detail_page.dart';
import '../../constants/app_constants.dart'; // Import AppConstants

class DesignerDetailPage extends StatefulWidget {
  final Designer designer;

  const DesignerDetailPage({super.key, required this.designer});

  @override
  State<DesignerDetailPage> createState() => _DesignerDetailPageState();
}

class _DesignerDetailPageState extends State<DesignerDetailPage> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  // Get unique categories from the designer's projects
  List<String> get _projectCategories {
    final categories = widget.designer.projects
        .map((project) => project.category)
        .toSet()
        .toList();
    categories.sort(); // Sort categories alphabetically
    return categories;
  }

  // Filter projects based on search query and selected category
  List<Project> get _filteredProjects {
    return widget.designer.projects.where((project) {
      final matchesSearch = _searchQuery.isEmpty ||
          project.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || project.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Show category selection dialog
  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppConstants.primaryWhite,
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select a Category',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      // Option to show all projects
                      ListTile(
                        title: const Text(
                          'All Categories',
                          style: TextStyle(fontSize: 16),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                          });
                          Navigator.pop(context);
                        },
                        tileColor: _selectedCategory == null
                            ? AppConstants.lightGold // Light gold background
                            : null,
                      ),
                      // List of categories
                      ..._projectCategories.map((category) {
                        return ListTile(
                          title: Text(
                            category,
                            style: const TextStyle(fontSize: 16),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                            Navigator.pop(context);
                          },
                          tileColor: _selectedCategory == category
                              ? AppConstants.lightGold // Light gold background
                              : null,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: AppConstants.primaryBlack,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryWhite,
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar with Profile Image and Name
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.primaryBlack,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.designer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.designer.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryGold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.designer.availability,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.primaryBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTab(context, 'About', 0),
                  _buildTab(context, 'Projects', 1),
                ],
              ),
            ),
          ),
          // Tab Content
          _selectedTabIndex == 0 ? _buildAboutTab() : _buildProjectsTab(),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: _selectedTabIndex == index
              ? AppConstants.primaryBlack
              : AppConstants.primaryWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppConstants.primaryBlack),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedTabIndex == index
                ? AppConstants.primaryGold
                : AppConstants.primaryBlack,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildAboutTab() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Section
            Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.about,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Service We Provided
            Text(
              'Service We Provided',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.services,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Phone Numbers
            Text(
              'Phone',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.designer.phoneNumbers.map((phone) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                phone,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            )),
            const SizedBox(height: 16),
            // Email
            Text(
              'Email',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.email,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Location
            Text(
              'Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.location,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProjectsTab() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous Projects Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Previous Projects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryBlack,
                  ),
                ),
                GestureDetector(
                  onTap: _showCategoryDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGold,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryWhite,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search projects (e.g., modern, luxury)',
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
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Project List
            if (_filteredProjects.isEmpty)
              const Center(
                child: Text(
                  'No projects match your search.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              ..._filteredProjects.asMap().entries.map((entry) {
                final index = widget.designer.projects.indexOf(entry.value);
                final project = entry.value;
                final projectId = '${widget.designer.id}_$index';
                return GestureDetector(
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
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppConstants.primaryWhite,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                                    'Category: ${project.category}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}