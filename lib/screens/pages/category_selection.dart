import 'package:flutter/material.dart';
import '../../model/category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_items_page.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch unique categories and their images from decoration_items
  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('decoration_items').get();
    // Use a map to store unique categories with their corresponding categoryImage
    final Map<String, String> categoryImages = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final categoryName = data['category'] as String? ?? 'Uncategorized';
      final categoryImage = data['categoryImage'] as String? ?? 'assets/images/default_category.jpg';
      // Only add the category if we haven't seen it before
      categoryImages.putIfAbsent(categoryName, () => categoryImage);
    }

    setState(() {
      _categories = categoryImages.entries
          .map((entry) => Category(name: entry.key, imageUrl: entry.value))
          .toList();
      // Sort categories alphabetically for consistent display
      _categories.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decorate My Dream House'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return GestureDetector(
            onTap: () {
              // Navigate to CategoryItemsPage with the selected category
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryItemsPage(categoryName: category.name),
                ),
              );
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.asset(
                        category.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}