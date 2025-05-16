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
  String _searchQuery = '';
  String? _selectedCategory;
  String _projectSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Designer>> _fetchDesigners() {
    return FirebaseFirestore.instance
        .collection('designers')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Designer.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<List<String>> _getAllCategories() {
    return _fetchDesigners().map((designers) {
      final categories =
          designers
              .expand(
                (designer) =>
                    designer.projects.map((project) => project.category),
              )
              .toSet()
              .toList();
      categories.sort();
      return categories;
    });
  }

  Stream<List<MapEntry<Designer, Project>>> _getFilteredProjects() {
    return _fetchDesigners().map((designers) {
      if (_selectedCategory == null) return [];

      return designers
          .expand(
            (designer) =>
                designer.projects.map((project) => MapEntry(designer, project)),
          )
          .where((entry) => entry.value.category == _selectedCategory)
          .where(
            (entry) =>
                _projectSearchQuery.isEmpty ||
                entry.value.title.toLowerCase().contains(
                  _projectSearchQuery.toLowerCase(),
                ) ||
                entry.value.description.toLowerCase().contains(
                  _projectSearchQuery.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryWhite,
      appBar: AppBar(
        title: const Text('Meet Your Interior Designer'),
        backgroundColor: AppConstants.primaryBlack,
        foregroundColor: AppConstants.primaryWhite,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(child: _buildTab('I Need Interior Designer', 0)),
                const SizedBox(width: 8),
                Expanded(child: _buildTab('I Will Select My Design', 1)),
              ],
            ),
          ),
          // Search Bar (only for "Contact a Designer" tab)
          if (_selectedTabIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search Designers',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          // Tab Content
          Expanded(
            child:
                _selectedTabIndex == 0
                    ? _buildDesignersList()
                    : _buildSelectDesignsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return InkWell(
      onTap:
          () => setState(() {
            _selectedTabIndex = index;
            if (index == 0) {
              _selectedCategory = null;
              _projectSearchQuery = '';
              _searchController.clear();
            }
          }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              _selectedTabIndex == index
                  ? AppConstants.primaryBlack
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color:
                  _selectedTabIndex == index
                      ? AppConstants.primaryWhite
                      : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignersList() {
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

        final designers =
            _searchQuery.isEmpty
                ? snapshot.data!
                : snapshot.data!
                    .where(
                      (d) => d.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

        if (designers.isEmpty) {
          return const Center(child: Text('No designers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: designers.length,
          itemBuilder: (context, index) {
            final designer = designers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: InkWell(
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DesignerDetailPage(designer: designer),
                      ),
                    ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Profile Image
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: AssetImage(designer.imageUrl),
                          ),
                          const SizedBox(width: 16),
                          // Designer Info
                          Expanded(
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
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < designer.rating.floor()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${designer.reviewCount} Reviews)',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        designer.address,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 250, 191, 28),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              designer.availability,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.message, color: Colors.blue),
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: designer,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final category = snapshot.data![index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Center(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedCategory = null),
                ),
                Text(
                  _selectedCategory!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                    ),
                    onChanged:
                        (value) => setState(() => _projectSearchQuery = value),
                  ),
                ),
              ],
            ),
          ),
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
                  return const Center(child: Text('No projects found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final entry = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        DesignerDetailPage(designer: entry.key),
                              ),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  entry.value.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(Icons.image, size: 80),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.value.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'by ${entry.key.name}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
