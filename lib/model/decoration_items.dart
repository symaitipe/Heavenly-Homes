class DecorationItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? discountedPrice;
  final bool isDiscounted;
  final List<String> subImages;
  final double rating;
  final int reviewCount;
  final String description;
  final int availableQty;
  final String category;

  DecorationItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discountedPrice,
    required this.isDiscounted,
    required this.subImages,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.availableQty,
    required this.category,
  });

  // Calculate the discount percentage (returns 0 if no discount)
  double get discountPercentage {
    if (discountedPrice == null || discountedPrice! >= price || price == 0) {
      return 0.0;
    }
    return ((price - discountedPrice!) / price) * 100;
  }

  factory DecorationItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return DecorationItem(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? 'Unknown Item',
      imageUrl: data['imageUrl'] ?? 'assets/images/default_item.png',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble(),
      isDiscounted: data['isDiscounted'] ?? false,
      subImages: List<String>.from(data['subImages'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? 'No description available',
      availableQty: (data['available_qty'] as num?)?.toInt() ?? 0,
      category: data['category'] ?? 'Uncategorized',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'discountedPrice': discountedPrice,
      'isDiscounted': isDiscounted,
      'subImages': subImages,
      'rating': rating,
      'reviewCount': reviewCount,
      'description': description,
      'available_qty': availableQty,
      'category': category,
    };
  }
}