import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../model/cart_items.dart';
import '../../model/order.dart';

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
      backgroundColor: AppConstants.grey50,
      appBar: AppBar(
        title: const Text('Order History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryBlack,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppConstants.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppConstants.primaryBlack,
          ),
          onPressed: () => Navigator.pop(context),
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
            return _buildErrorState(snapshot.error.toString());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder<List<OrderModel>>(
            future: Future.wait(snapshot.data!.docs.map((doc) async {
              try {
                return await OrderModel.fromFirestore(doc);
              } catch (e) {
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
                return _buildErrorState(orderSnapshot.error.toString());
              }
              if (!orderSnapshot.hasData || orderSnapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final orders = orderSnapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order, context);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppConstants.completedBg;
      case 'shipped':
        return AppConstants.shippedBg;
      case 'processing':
        return AppConstants.processingBg;
      case 'cancelled':
        return AppConstants.cancelledBg;
      case 'pending':
      default:
        return AppConstants.pendingBg;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppConstants.completedText;
      case 'shipped':
        return AppConstants.shippedText;
      case 'processing':
        return AppConstants.processingText;
      case 'cancelled':
        return AppConstants.cancelledText;
      case 'pending':
      default:
        return AppConstants.pendingText;
    }
  }

  Widget _buildOrderCard(OrderModel order, BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt.toDate());
    final firstItemImage = order.items.isNotEmpty ? order.items.first.imageUrl : 'assets/images/default_item.png';
    final firstItemName = order.items.isNotEmpty ? order.items.first.name : 'No Items';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppConstants.grey200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Optional: Add navigation to order details page
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderId.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryBlack,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusTextColor(order.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.grey600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: firstItemImage.startsWith('http')
                        ? Image.network(
                      firstItemImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 60,
                        height: 60,
                        color: AppConstants.grey200,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: AppConstants.grey600,
                        ),
                      ),
                    )
                        : Image.asset(
                      firstItemImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.items.length > 1
                              ? '${order.items.length} items'
                              : firstItemName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppConstants.primaryBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs ${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                      color: AppConstants.primaryBlack,
                    ),
                    onPressed: () {
                      _showOrderDetailsBottomSheet(context, order);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsBottomSheet(BuildContext context, OrderModel order) {
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt.toDate());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppConstants.primaryWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryBlack,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Order ID', order.orderId),
              _buildDetailRow('Date', formattedDate),
              _buildDetailRow('Total', 'Rs ${order.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Payment Method', order.paymentMethod),
              _buildDetailRow('Delivery Address', order.deliveryAddress),
              const SizedBox(height: 16),
              const Divider(color: AppConstants.grey200),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryBlack,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => _buildOrderItem(item)).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppConstants.primaryWhite),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.grey600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.startsWith('http')
                ? Image.network(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50,
                height: 50,
                color: AppConstants.grey200,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 20,
                  color: AppConstants.grey600,
                ),
              ),
            )
                : Image.asset(
              item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
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
                    color: AppConstants.primaryBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rs ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.primaryBlack,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Qty: ${item.quantity}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppConstants.errorRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.contains('failed-precondition')
                  ? 'Please try again later or contact support.'
                  : 'An error occurred while loading your order history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.grey600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => setState(() {}),
            child: const Text(
              'Retry',
              style: TextStyle(color: AppConstants.primaryWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_order.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          const Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryBlack,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You haven\'t placed any orders yet. Start shopping to see your order history here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.grey600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlack,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            child: const Text(
              'Start Shopping',
              style: TextStyle(color: AppConstants.primaryWhite),
            ),
          ),
        ],
      ),
    );
  }
}