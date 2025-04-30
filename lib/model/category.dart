class Category {
  final String name;
  final String imageUrl;

  Category({
    required this.name,
    required this.imageUrl,
  });

  factory Category.fromFirestore(Map<String, dynamic> data) {
    return Category(
      name: data['category'] ?? 'Unknown Category',
      imageUrl: data['categoryImage'] ?? 'assets/decoration_items/categories/default_category.jpg',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': name,
      'categoryImage': imageUrl,
    };
  }
}