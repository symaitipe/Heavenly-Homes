class DecorationItem {
  final String id; // Added to uniquely identify the item
  final String name;
  final double price;
  final String imageUrl;
  final bool isDiscounted;
  final String category;
  final List<String> subImages; // List of sub-image URLs
  final double rating; // Rating value (e.g., 4.5)
  final int reviewCount; // Number of reviews
  final String description;

  DecorationItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.isDiscounted,
    required this.category,
    required this.subImages,
    required this.rating,
    required this.reviewCount,
    required this.description,
  });

  factory DecorationItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return DecorationItem(
      id: id ?? data['id'] ?? '', // Use the document ID if provided
      name: data['name'] ?? 'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      isDiscounted: data['isDiscounted'] ?? false,
      category: data['category'] ?? 'Unknown',
      subImages: List<String>.from(data['subImages'] ?? []), // Default to empty list
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0, // Default to 0.0
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0, // Default to 0
      description: data['description'] ?? 'No description available.',
    );
  }
}