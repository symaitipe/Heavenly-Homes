import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/decoration_items.dart';
import 'item_details.dart';

class CategoryItemsPage extends StatefulWidget {
  final String categoryName;

  const CategoryItemsPage({super.key, required this.categoryName});

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  List<DecorationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  // Fetch items for the selected category from Firestore
  Future<void> _fetchItems() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('decoration_items')
        .where('category', isEqualTo: widget.categoryName)
        .get();
    setState(() {
      _items = snapshot.docs
          .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar (Placeholder)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Here',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              enabled: false, // Placeholder for now
            ),
          ),
          // Price Filter and Item Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Implement price filter functionality (future enhancement)
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('PRICE FILTER'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Text(
                  '${_items.length} ITEMS AVAILABLE',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _items.length + 1, // +1 for the "Show All" button
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  // Show All button
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        // Implement show all functionality (future enhancement)
                      },
                      child: const Text(
                        'Show All',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  );
                }

                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.imageUrl.startsWith('http')
                                ? Image.network(
                              item.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                            )
                                : Image.asset(
                              item.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Item Details and Buttons
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < item.rating.floor()
                                              ? Icons.star
                                              : (starIndex < item.rating
                                              ? Icons.star_half
                                              : Icons.star_border),
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.reviewCount} reviews',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rs ${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Buttons Row
                                Row(
                                  children: [
                                    // Add to Cart Button
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        // Navigate to ItemDetailPage (for now, same as Buy Now)
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ItemDetailPage(item: item),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.shopping_cart, size: 18),
                                      label: const Text('Add to Cart'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.black,
                                        side: const BorderSide(color: Colors.black),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Buy Now Button
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navigate to ItemDetailPage
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ItemDetailPage(item: item),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                      child: const Text('Buy Now'),
                                    ),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }
}