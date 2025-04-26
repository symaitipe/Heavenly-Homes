import 'package:flutter/material.dart';
import '../../model/designer.dart';
import 'project_detail_page.dart';

class DesignerDetailPage extends StatefulWidget {
  final Designer designer;

  const DesignerDetailPage({super.key, required this.designer});

  @override
  State<DesignerDetailPage> createState() => _DesignerDetailPageState();
}

class _DesignerDetailPageState extends State<DesignerDetailPage> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar with Profile Image and Name
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
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
                    const Icon(Icons.person, size: 50),
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
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.designer.availability,
                            style: const TextStyle(fontSize: 12, color: Colors.black),
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
                  _buildTab(context, 'Packages', 2),
                ],
              ),
            ),
          ),
          // Tab Content
          _selectedTabIndex == 0
              ? _buildAboutTab()
              : _selectedTabIndex == 1
              ? _buildProjectsTab()
              : _buildPackagesTab(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedTabIndex == index ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedTabIndex == index ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
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
            const Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.about,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Service We Provided
            const Text(
              'Service We Provided',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.services,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Phone Numbers
            const Text(
              'Phone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            const Text(
              'Email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.designer.email,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            // Location
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                const Text(
                  'Previous Projects',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to a page showing all projects (future implementation)
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 14, color: Colors.yellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Banner (Placeholder for "How to Make Your Home")
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: const Center(
                child: Text(
                  'How to Make Your Home (Banner Placeholder)',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Project List
            ...widget.designer.projects.asMap().entries.map((entry) {
              final index = entry.key;
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
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: ${project.category}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  SliverToBoxAdapter _buildPackagesTab() {
    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Packages (Coming Soon)',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}