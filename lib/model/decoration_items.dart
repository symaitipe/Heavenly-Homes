// lib/models/decoration_item.dart
class DecorationItem {
  final String name;
  final double price;
  final String imageUrl;
  final bool isDiscounted;
  final String category;

  DecorationItem({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isDiscounted,
    required this.category,
  });

  factory DecorationItem.fromFirestore(Map<String, dynamic> data) {
    return DecorationItem(
      name: data['name'] ?? 'Unknown',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      isDiscounted: data['isDiscounted'] ?? false,
      category: data['category'] ?? 'Unknown',
    );
  }
}