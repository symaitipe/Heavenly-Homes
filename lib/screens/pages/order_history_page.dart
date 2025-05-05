import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../model/cart_items.dart'; // Assuming you might reuse CartItem structure for order items

// Define a simple model for an order entry
class Order {
  final String orderId;
  final String userId;
  final Timestamp orderDate;
  final double totalAmount;
  final String deliveryAddress; // Assuming this is saved with the order
  final String paymentMethod; // Assuming this is saved with the order
  final List<CartItem> items; // Assuming the list of items is saved

  Order({
    required this.orderId,
    required this.userId,
    required this.orderDate,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.items,
  });

  // Factory constructor to create an Order from a Firestore DocumentSnapshot
  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      // Handle error or return a default/invalid order
      print("Error: Order document data is null for doc ID: ${doc.id}");
      return Order(
        orderId: doc.id,
        userId: '',
        orderDate: Timestamp.now(), // Default date
        totalAmount: 0.0,
        deliveryAddress: 'N/A',
        paymentMethod: 'N/A',
        items: [],
      );
    }

    // Assuming 'items' is saved as a List of Maps in Firestore
    List<dynamic> itemsData = data['items'] as List<dynamic>? ?? [];
    List<CartItem> orderItems = itemsData.map((itemData) {
      // Convert each item map back to a CartItem.
      // Note: The 'id' here isn't the cart item ID, but maybe just a temp ID or index
      // We can use the decorationItemId or a generated ID if needed,
      // but for display, the details within the map are key.
      // Using 'fromFirestore' with null ID or adjusting based on saved structure.
      return CartItem(
        id: itemData['decorationItemId'] ?? '', // Use item ID or generated
        userId: data['userId'] ?? '', // User ID from order
        decorationItemId: itemData['decorationItemId'] ?? '',
        name: itemData['name'] ?? 'Unknown Item',
        imageUrl: itemData['imageUrl'] ?? 'assets/images/default_item.png',
        price: (itemData['price'] as num?)?.toDouble() ?? 0.0,
        discountedPrice: (itemData['discountedPrice'] as num?)?.toDouble(),
        quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
      );
    }).toList();


    return Order(
      orderId: doc.id,
      userId: data['userId'] as String? ?? '',
      orderDate: data['orderDate'] as Timestamp? ?? Timestamp.now(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: data['deliveryAddress'] as String? ?? 'Not provided',
      paymentMethod: data['paymentMethod'] as String? ?? 'Not specified',
      items: orderItems,
    );
  }
}


class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      // Redirect to login if user is not logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Set background color to light grey/white
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color(0xFFF5F5F5), // Changed app bar background
        foregroundColor: Colors.black, // Changed app bar text/icon color
        elevation: 0, // Optional: remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query the 'orders' collection filtered by the current user's ID
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('orderDate', descending: true) // Show most recent orders first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching order history: ${snapshot.error}");
            return Center(child: Text('Error loading order history: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          // Map the documents to Order objects
          final orders = snapshot.data!.docs.map((doc) {
            return Order.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              // Format the date for display
              final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(order.orderDate.toDate());
              final firstItemImage = order.items.isNotEmpty ? order.items.first.imageUrl : 'assets/images/default_item.png';
              final firstItemName = order.items.isNotEmpty ? order.items.first.name : 'No Items';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID: ${order.orderId.substring(0, 8)}...', // Display truncated ID
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                           Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                             child: firstItemImage.startsWith('http')
                                  ? Image.network(
                                      firstItemImage,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                       loadingBuilder: (c, ch, p) => p == null ? ch : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                                    )
                                  : Image.asset(
                                      firstItemImage,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                   order.items.length > 1 ? '${order.items.length} items' : firstItemName,
                                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                ),
                                if (order.items.length > 1) // Show first item if multiple
                                   Text('e.g., $firstItemName', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),

                                const SizedBox(height: 4),
                                Text(
                                  'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Add more details here if needed, e.g., status, address summary
                       const SizedBox(height: 8),
                       Text('Delivery Address: ${order.deliveryAddress}', style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                       Text('Payment Method: ${order.paymentMethod}', style: const TextStyle(fontSize: 12, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),

                       // Optional: Add a button to view full order details
                       // Align(
                       //    alignment: Alignment.bottomRight,
                       //    child: TextButton(
                       //       onPressed: () {
                       //          // Navigate to a detailed order view page
                       //          // Navigator.push(context, MaterialPageRoute(builder: (context) => OrderDetailsPage(order: order)));
                       //       },
                       //       child: const Text('View Details'),
                       //    ),
                       // ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}