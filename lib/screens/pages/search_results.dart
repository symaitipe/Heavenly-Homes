import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_homes/screens/pages/project_detail_page.dart';
import '../../model/decoration_items.dart';
import '../../model/designer.dart';
import 'item_details.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSearchResults();
  }

  Future<void> _fetchSearchResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> results = [];
      final queryWords = widget.query.toLowerCase().split(' ');

      // Fetch projects from designers
      final designerSnapshot =
      await FirebaseFirestore.instance.collection('designers').get();
      for (var doc in designerSnapshot.docs) {
        final data = doc.data();
        final designerId = doc.id;
        final designerName = data['name'] is String ? data['name'] as String : 'Unknown Designer';
        final designerNameLower = designerName.toLowerCase();
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

          final titleLower = project.title.toLowerCase();
          final categoryLower = project.category.toLowerCase();
          bool matchesDesigner = queryWords.any((word) => designerNameLower.contains(word));
          bool matches = queryWords.any((word) =>
          titleLower.contains(word) ||
              designerNameLower.contains(word) ||
              categoryLower.contains(word));

          if (matches) {
            results.add({
              'type': 'project',
              'project': project,
              'designerId': designerId,
              'designerName': designerName,
              'projectIndex': index,
              'matchesDesigner': matchesDesigner,
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
          results.add({
            'type': 'item',
            'item': item,
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      //print('Error fetching search results: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results for "${widget.query}"'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? const Center(child: Text('No results found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          if (result['type'] == 'project') {
            final project = result['project'] as Project;
            final String designerId = result['designerId'] as String;
            final String designerName = result['designerName'] as String;
            final int projectIndex = result['projectIndex'] as int;
            final bool matchesDesigner = result['matchesDesigner'] as bool;
            final String projectId = '${designerId}_$projectIndex';

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
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: Image.asset(
                        project.imageUrl.isNotEmpty
                            ? project.imageUrl
                            : 'assets/placeholder.jpg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                          Icons.broken_image,
                          size: 50,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${project.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              matchesDesigner
                                  ? 'Designer: $designerName (matched)'
                                  : 'By $designerName',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            final item = result['item'] as DecorationItem;
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
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                      child: item.imageUrl.startsWith('http')
                          ? Image.network(
                        item.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                          Icons.broken_image,
                          size: 50,
                        ),
                      )
                          : Image.asset(
                        item.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                          Icons.broken_image,
                          size: 50,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs ${item.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Category: ${item.category}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}