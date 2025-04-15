import 'package:flutter/material.dart';

class CategorySelectionPage extends StatelessWidget {
  const CategorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['Bathroom', 'Kitchen', 'Living Area', 'Bedroom'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Category'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(categories[index]),
              onTap: () {
                // Navigate to a page for the selected category (implement later)
              },
            ),
          );
        },
      ),
    );
  }
}