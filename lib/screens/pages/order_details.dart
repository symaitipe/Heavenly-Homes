import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/cart_Items.dart';
import '../../model/decoration_items.dart';
import 'checkout_page.dart';

class OrderDetailPage extends StatefulWidget {
  final DecorationItem item;
  final String orderId;
  final String userId;

  const OrderDetailPage({
    super.key,
    required this.item,
    required this.orderId,
    required this.userId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  int _checkoutQty = 1;
  int _availableQty = 0;

  @override
  void initState() {
    super.initState();
    _fetchAvailableQuantity();
  }

  // Fetch the available quantity from Firestore
  Future<void> _fetchAvailableQuantity() async {
    final doc = await FirebaseFirestore.instance
        .collection('decoration_items')
        .doc(widget.item.id)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (mounted) {
        setState(() {
          _availableQty = (data?['available_qty'] as num?)?.toInt() ?? 0;
        });
      }
    }
  }

  // Update the checkout quantity
  void _updateQuantity(int change) {
    setState(() {
      int newQty = _checkoutQty + change;
      if (newQty <= 0) {
        // Prevent quantity from going below 1
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invalid Quantity'),
            content: const Text('Quantity must be at least 1.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      if (newQty > _availableQty) {
        // Prevent exceeding available quantity
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quantity Exceeded'),
            content: Text('Only $_availableQty items are available.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      _checkoutQty = newQty;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double deliveryCharges = 35000.0;
    final double itemTotal = widget.item.price * _checkoutQty;
    final double subtotal = itemTotal + deliveryCharges;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildTab(context, 'Details', isActive: true),
                  _buildTab(context, 'Processing', isActive: false),
                  _buildTab(context, 'Delivered', isActive: false),
                ],
              ),
            ),
            // Item Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.item.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Quantity: ',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => _updateQuantity(-1),
                            ),
                            Text(
                              '$_checkoutQty',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => _updateQuantity(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs ${itemTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Order Summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Order ID', widget.orderId),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Item ID', widget.item.id),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Delivery Charges', 'Rs ${deliveryCharges.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Sub total', 'Rs ${subtotal.toStringAsFixed(2)}', isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cancel order, return to ItemDetailPage
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel Order'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Create a CartItem from the DecorationItem and checkout quantity
                  final cartItem = CartItem(
                    id: widget.item.id,
                    userId: widget.userId,
                    decorationItemId: widget.item.id,
                    name: widget.item.name,
                    imageUrl: widget.item.imageUrl,
                    price: widget.item.price,
                    quantity: _checkoutQty,
                  );

                  // Navigate to CheckoutPage with a list containing this single CartItem
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        cartItems: [cartItem], // Pass as a list
                        orderId: widget.orderId,
                        userId: widget.userId,
                        deliveryCharges: deliveryCharges,
                        subtotal: subtotal,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}