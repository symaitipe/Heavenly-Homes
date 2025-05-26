import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/cart_items.dart';

class OrderModel {
  final String orderId;
  final String userId;
  final Timestamp createdAt;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final List<CartItem> items;
  final String status;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.createdAt,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.items,
    required this.status,
  });

  static Future<OrderModel> fromFirestore(DocumentSnapshot doc) async {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    print("Firestore data for order ${doc.id}: $data");

    if (data == null) {
      print("Error: Order document data is null for doc ID: ${doc.id}");
      return OrderModel(
        orderId: doc.id,
        userId: '',
        createdAt: Timestamp.now(),
        totalAmount: 0.0,
        deliveryAddress: 'N/A',
        paymentMethod: 'N/A',
        items: [],
        status: 'pending',
      );
    }

    // Handle 'createdAt' field (it's a Timestamp)
    Timestamp createdAt = data['createdAt'] as Timestamp? ?? Timestamp.now();

    // Fetch items from the 'items' sub collection
    List<CartItem> orderItems = [];
    try {
      QuerySnapshot itemsSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(doc.id)
          .collection('items')
          .get();

      orderItems = itemsSnapshot.docs.map((itemDoc) {
        Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
        return CartItem(
          id: itemData['decorationItemId'] ?? '',
          userId: data['userId'] ?? '',
          decorationItemId: itemData['decorationItemId'] ?? '',
          name: itemData['itemName'] ?? 'Unknown Item',
          imageUrl: itemData['imageUrl'] ?? 'assets/images/default_item.png',
          price: (itemData['itemPrice'] as num?)?.toDouble() ?? 0.0,
          discountedPrice: (itemData['discountedPrice'] as num?)?.toDouble(),
          quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
    } catch (e) {
      print("Error fetching items subcollection for order ${doc.id}: $e");
    }

    return OrderModel(
      orderId: doc.id,
      userId: data['userId'] as String? ?? '',
      createdAt: createdAt,
      totalAmount: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: data['address'] as String? ?? 'Not provided',
      paymentMethod: data['paymentMethod'] as String? ?? 'Not specified',
      items: orderItems,
      status: data['status'] as String? ?? 'pending', // Explicitly map status
    );
  }
}