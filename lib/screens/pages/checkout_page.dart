import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../model/cart_items.dart';
import 'order_processing_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final String orderId;
  final String userId;
  final double deliveryCharges;
  final double subtotal;

  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.orderId,
    required this.userId,
    required this.deliveryCharges,
    required this.subtotal,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'Cash on Delivery';
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = "";
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // Save the order to Firestore and update available quantities
  Future<void> _saveOrderAndUpdateQuantity() async {
    final batch = FirebaseFirestore.instance.batch();

    // Save the main order document
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
    batch.set(orderRef, {
      'orderId': widget.orderId,
      'userId': widget.userId,
      'deliveryCharges': widget.deliveryCharges,
      'subtotal': widget.subtotal,
      'status': 'Processing',
      'address': _addressController.text,
      'paymentMethod': _selectedPaymentMethod,
      'createdAt': Timestamp.now(),
    });

    // Save each item in a sub collection
    for (var item in widget.cartItems) {
      final itemRef = orderRef.collection('items').doc(item.decorationItemId);
      batch.set(itemRef, {
        'itemId': item.decorationItemId,
        'itemName': item.name,
        'itemPrice': item.price,
        'quantity': item.quantity,
      });

      // Update available quantity
      final itemDocRef = FirebaseFirestore.instance.collection('decoration_items').doc(item.decorationItemId);
      batch.update(itemDocRef, {
        'available_qty': FieldValue.increment(-item.quantity),
      });

      // Delete cart item
      final cartDocRef = FirebaseFirestore.instance.collection('cart').doc(item.id);
      batch.delete(cartDocRef);
    }

    // Commit the batch
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address
              const Text(
                'Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Enter your delivery address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPaymentOption('Cash on Delivery', Icons.money),
              const SizedBox(height: 8),
              _buildPaymentOption('Card Details', Icons.credit_card),
              const SizedBox(height: 16),
              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // List all items
                    ...widget.cartItems.map((item) {
                      return Column(
                        children: [
                          _buildSummaryRow(
                            '${item.name} (${item.quantity} x Rs ${item.price.toStringAsFixed(2)})',
                            'Rs ${(item.price * item.quantity).toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                    _buildSummaryRow('Delivery Charge', 'Rs ${widget.deliveryCharges.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Promotion', 'Not Available', valueColor: Colors.grey),
                    const SizedBox(height: 8),
                    const Divider(),
                    _buildSummaryRow(
                      'Total',
                      'Rs ${widget.subtotal.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () async {
            if (_addressController.text.isEmpty) {
              // Show alert if address is empty
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Address Required'),
                  content: const Text('Please enter a delivery address.'),
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

            // Save the order and update quantities
            await _saveOrderAndUpdateQuantity();

            // Navigate to OrderProcessingPage
            if (context.mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderProcessingPage(
                    cartItems: widget.cartItems,
                    orderId: widget.orderId,
                    userId: widget.userId,
                    deliveryCharges: widget.deliveryCharges,
                    subtotal: widget.subtotal,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Pay Now'),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == title ? Colors.black : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            if (_selectedPaymentMethod == title)
              const Icon(Icons.check_circle, color: Colors.black)
            else
              const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}