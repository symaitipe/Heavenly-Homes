import 'package:flutter/material.dart';
import '../../model/designer.dart';
import 'project_detail_page.dart';
import '../../constants/app_constants.dart';

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

  List<String> get _projectCategories {
    final categories =
        widget.designer.projects
            .map((project) => project.category)
            .toSet()
            .toList();
    categories.sort();
    return categories;
  }

  List<Project> get _filteredProjects {
    return widget.designer.projects.where((project) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          project.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          project.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppConstants.primaryBlack,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),

            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                widget.designer.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.designer.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            Container(color: Colors.grey[300]),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryGold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.designer.availability,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Horizontal Tab Bar
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTabButton('About', 0),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                        ),
                        _buildTabButton('Projects', 1),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                        ),
                        _buildTabButton('Packages', 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _selectedTabIndex == 0
              ? _buildAboutTab()
              : _selectedTabIndex == 1
              ? _buildProjectsTab()
              : _buildPackagesTab(),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor:
            _selectedTabIndex == index
                ? AppConstants.primaryBlack
                : Colors.transparent,
        side: BorderSide(
          color:
              _selectedTabIndex == index
                  ? AppConstants.primaryBlack
                  : Colors.grey,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: () => setState(() => _selectedTabIndex = index),
      child: Text(
        label,
        style: TextStyle(
          color:
              _selectedTabIndex == index
                  ? AppConstants.primaryWhite
                  : AppConstants.primaryBlack,
        ),
      ),
    );
  }

  SliverList _buildAboutTab() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('About', widget.designer.about),
              const SizedBox(height: 24),
              _buildSection('Service We Provided', widget.designer.services),
              const SizedBox(height: 24),
              _buildContactSection(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 8),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Show More',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.designer.phoneNumbers.map(
          (phone) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(phone, style: const TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Email Address',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(widget.designer.email, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(widget.designer.location, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  SliverList _buildProjectsTab() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search projects...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged:
                          (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (value) {
                      setState(() {
                        _selectedCategory = value == 'All' ? null : value;
                      });
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'All',
                            child: Text('All Categories'),
                          ),
                          ..._projectCategories.map(
                            (category) => PopupMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_filteredProjects.isEmpty)
                const Center(
                  child: Text(
                    'No projects found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._filteredProjects.map(
                  (project) => _buildProjectCard(project),
                ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProjectDetailPage(
                      project: project,
                      projectId:
                          '${widget.designer.id}_${widget.designer.projects.indexOf(project)}',
                    ),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  project.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildPackagesTab() {
    return SliverList(
      delegate: SliverChildListDelegate([
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Packages will be displayed here',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ]),
    );
  }
}
