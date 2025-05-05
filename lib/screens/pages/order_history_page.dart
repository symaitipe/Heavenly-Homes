import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../model/order.dart'; // Import the OrderModel

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching order history: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load order history.',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString().contains('failed-precondition')
                        ? 'Please ensure the required Firestore index is created.'
                        : snapshot.error.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return FutureBuilder<List<OrderModel>>(
            future: Future.wait(snapshot.data!.docs.map((doc) async {
              try {
                return await OrderModel.fromFirestore(doc);
              } catch (e) {
                print("Error parsing order document ${doc.id}: $e");
                return OrderModel(
                  orderId: doc.id,
                  userId: _currentUserId!,
                  createdAt: Timestamp.now(),
                  totalAmount: 0.0,
                  deliveryAddress: 'N/A',
                  paymentMethod: 'N/A',
                  items: [],
                );
              }
            }).toList()),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (orderSnapshot.hasError) {
                print("Error loading orders: ${orderSnapshot.error}");
                return const Center(child: Text('Error loading orders.'));
              }
              if (!orderSnapshot.hasData || orderSnapshot.data!.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }

              final orders = orderSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt.toDate());
                  final firstItemImage = order.items.isNotEmpty ? order.items.first.imageUrl : 'assets/images/default_item.png';
                  final firstItemName = order.items.isNotEmpty ? order.items.first.name : 'No Items';

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID: ${order.orderId.substring(0, 8)}...',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
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
                                loadingBuilder: (c, ch, p) => p == null
                                    ? ch
                                    : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
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
                                  if (order.items.length > 1)
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: Rs ${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        // Additional order details (address, payment method)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Address: ${order.deliveryAddress}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Payment Method: ${order.paymentMethod}',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              const Divider(),
                              const Text(
                                'Items:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // List of items
                              order.items.isEmpty
                                  ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No items found.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              )
                                  : Column(
                                children: order.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: item.imageUrl.startsWith('http')
                                              ? Image.network(
                                            item.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(
                                              Icons.broken_image,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                            loadingBuilder: (c, ch, p) => p == null
                                                ? ch
                                                : Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey.shade200,
                                              child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2)),
                                            ),
                                          )
                                              : Image.asset(
                                            item.imageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(
                                              Icons.broken_image,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Quantity: ${item.quantity}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                              Text(
                                                'Price: Rs ${item.price.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}