class CartItem {
  final String id;
  final String userId;
  final String decorationItemId;
  final String name;
  final String imageUrl;
  final double price;
  final double? discountedPrice;
  final int quantity;

  CartItem({
    required this.id,
    required this.userId,
    required this.decorationItemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.discountedPrice,
    required this.quantity,
  });

  factory CartItem.fromFirestore(Map<String, dynamic> data, [String? id]) {
    return CartItem(
      id: id ?? data['id'] ?? '',
      userId: data['userId'] ?? '',
      decorationItemId: data['decorationItemId'] ?? '',
      name: data['name'] ?? 'Unknown Item',
      imageUrl: data['imageUrl'] ?? 'assets/images/default_item.png',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'decorationItemId': decorationItemId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
    };
  }
}