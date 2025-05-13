// lib/model/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final Timestamp createdAt;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final List<CartItem> items;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.createdAt,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.items,
  });

  static Future<OrderModel> fromFirestore(DocumentSnapshot doc) async {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return OrderModel(
        orderId: doc.id,
        userId: '',
        createdAt: Timestamp.now(),
        totalAmount: 0.0,
        deliveryAddress: 'N/A',
        paymentMethod: 'N/A',
        items: [],
      );
    }

    // Fetch items from subcollection
    List<CartItem> orderItems = [];
    try {
      QuerySnapshot itemsSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(doc.id)
              .collection('items')
              .get();

      orderItems =
          itemsSnapshot.docs.map((itemDoc) {
            Map<String, dynamic> itemData =
                itemDoc.data() as Map<String, dynamic>;
            return CartItem(
              id: itemData['id'] ?? '',
              name: itemData['name'] ?? 'Unknown Item',
              imageUrl:
                  itemData['imageUrl'] ?? 'assets/images/default_item.png',
              price: (itemData['price'] as num?)?.toDouble() ?? 0.0,
              quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
            );
          }).toList();
    } catch (e) {
      print("Error fetching items: $e");
    }

    return OrderModel(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: data['deliveryAddress'] ?? 'Not provided',
      paymentMethod: data['paymentMethod'] ?? 'Not specified',
      items: orderItems,
    );
  }
}

class CartItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });
}
