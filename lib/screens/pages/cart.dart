import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../model/cart_Items.dart';


class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // Fetch cart items for the current user
  Future<void> _fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user.uid)
        .get();

    final items = snapshot.docs
        .map((doc) => CartItem.fromFirestore(doc.data(), doc.id))
        .toList();

    // Calculate total price
    double total = 0.0;
    for (var item in items) {
      total += item.price * item.quantity;
    }

    setState(() {
      _cartItems = items;
      _totalPrice = total;
    });
  }

  // Update quantity of a cart item
  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity < 1) {
      // Remove item if quantity is 0
      await _removeItem(cartItem);
      return;
    }

    // Check available quantity in decoration_items
    final itemDoc = await FirebaseFirestore.instance
        .collection('decoration_items')
        .doc(cartItem.decorationItemId)
        .get();
    final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0;

    if (newQuantity > availableQty) {
      // Show alert if requested quantity exceeds available stock
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insufficient Stock'),
            content: Text('Only $availableQty items are available.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Update quantity in Firestore
    await FirebaseFirestore.instance
        .collection('cart')
        .doc(cartItem.id)
        .update({'quantity': newQuantity});

    // Refresh cart
    await _fetchCartItems();
  }

  // Remove item from cart
  Future<void> _removeItem(CartItem cartItem) async {
    await FirebaseFirestore.instance
        .collection('cart')
        .doc(cartItem.id)
        .delete();

    // Refresh cart
    await _fetchCartItems();
  }

  // Proceed to checkout (placeholder)
  void _proceedToCheckout() {
    // Implement checkout functionality (future enhancement)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proceeding to checkout... (Not implemented yet)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final cartItem = _cartItems[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: cartItem.imageUrl.startsWith('http')
                              ? Image.network(
                            cartItem.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40),
                          )
                              : Image.asset(
                            cartItem.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cartItem.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs ${cartItem.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      _updateQuantity(cartItem, cartItem.quantity - 1);
                                    },
                                  ),
                                  Text(
                                    '${cartItem.quantity}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      _updateQuantity(cartItem, cartItem.quantity + 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Remove Button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeItem(cartItem);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Total Price and Checkout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs ${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cartItems.isEmpty ? null : _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}