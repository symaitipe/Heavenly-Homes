import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../../model/cart_items.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  Set<String> _selectedItemIds = {};
  Map<String, List<CartItem>> _itemsByCategory = {};
  double _subtotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // Fetch cart items and their categories
  Future<void> _fetchCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user.uid)
        .get();

    final items = <CartItem>[];
    final itemsByCategory = <String, List<CartItem>>{};
    final selectedIds = <String>{};

    for (var doc in snapshot.docs) {
      final cartData = doc.data();
      // Fetch additional item details from decoration_items
      final itemDoc = await FirebaseFirestore.instance
          .collection('decoration_items')
          .doc(cartData['decorationItemId'] as String)
          .get();
      final itemData = itemDoc.data();
      if (itemData == null) continue;

      final category = (itemData['category'] as String?) ?? 'Other';
      final isDiscounted = itemData['isDiscounted'] as bool? ?? false;
      final discountedPrice = isDiscounted
          ? (itemData['discountedPrice'] as num?)?.toDouble()
          : null;

      final cartItem = CartItem(
        id: doc.id,
        userId: cartData['userId'] as String,
        decorationItemId: cartData['decorationItemId'] as String,
        name: cartData['name'] as String,
        imageUrl: cartData['imageUrl'] as String,
        price: (cartData['price'] as num).toDouble(),
        discountedPrice: discountedPrice,
        quantity: (cartData['quantity'] as num).toInt(),
      );

      items.add(cartItem);
      itemsByCategory.putIfAbsent(category, () => []).add(cartItem);
      selectedIds.add(cartItem.id); // Select all items by default
    }

    // Calculate subtotal for selected items using discounted price if available
    double subtotal = 0.0;
    for (var item in items) {
      if (selectedIds.contains(item.id)) {
        final price = item.discountedPrice ?? item.price;
        subtotal += price * item.quantity;
      }
    }

    if (mounted) {
      setState(() {
        _cartItems = items;
        _itemsByCategory = itemsByCategory;
        _selectedItemIds = selectedIds;
        _subtotal = subtotal;
      });
    }
  }

  // Update quantity of a cart item
  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity < 1) {
      // Remove item if quantity is 0
      await _removeItem(cartItem);
      return;
    }

    // Store mounted state before async operation
    final isMounted = mounted;

    // Check available quantity in decoration_items
    final itemDoc = await FirebaseFirestore.instance
        .collection('decoration_items')
        .doc(cartItem.decorationItemId)
        .get();
    final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0;

    if (newQuantity > availableQty) {
      // Show alert if requested quantity exceeds available stock
      if (isMounted) {
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

  // Toggle item selection
  void _toggleItemSelection(CartItem cartItem) {
    setState(() {
      if (_selectedItemIds.contains(cartItem.id)) {
        _selectedItemIds.remove(cartItem.id);
        final price = cartItem.discountedPrice ?? cartItem.price;
        _subtotal -= price * cartItem.quantity;
      } else {
        _selectedItemIds.add(cartItem.id);
        final price = cartItem.discountedPrice ?? cartItem.price;
        _subtotal += price * cartItem.quantity;
      }
    });
  }

  // Proceed to checkout with selected items
  Future<void> _proceedToCheckout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    if (_selectedItemIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one item to checkout.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Store mounted state before async operations
    final isMounted = mounted;

    // Validate stock for selected items
    final selectedItems = _cartItems.where((item) => _selectedItemIds.contains(item.id)).toList();
    for (var cartItem in selectedItems) {
      final itemDoc = await FirebaseFirestore.instance
          .collection('decoration_items')
          .doc(cartItem.decorationItemId)
          .get();
      final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0;
      if (cartItem.quantity > availableQty) {
        if (isMounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Stock'),
              content: Text('Only $availableQty items available for ${cartItem.name}.'),
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
    }

    // Generate a unique orderId
    const uuid = Uuid();
    final orderId = uuid.v4();

    // Calculate delivery charges and subtotal using discounted price
    const deliveryCharges = 35000.0; // Consistent with OrderDetailPage
    final subtotal = selectedItems.fold<double>(
      0.0,
          (double sum, item) => sum + ((item.discountedPrice ?? item.price) * item.quantity),
    ) + deliveryCharges;

    // Navigate to CheckoutPage with selected items
    if (isMounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutPage(
            cartItems: selectedItems,
            orderId: orderId,
            userId: user.uid,
            deliveryCharges: deliveryCharges,
            subtotal: subtotal,
          ),
        ),
      );
    }
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
              itemCount: _itemsByCategory.length,
              itemBuilder: (context, index) {
                final category = _itemsByCategory.keys.elementAt(index);
                final items = _itemsByCategory[category]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((cartItem) {
                      final displayPrice = cartItem.discountedPrice ?? cartItem.price;
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
                              // Checkbox
                              Checkbox(
                                value: _selectedItemIds.contains(cartItem.id),
                                onChanged: (bool? value) {
                                  _toggleItemSelection(cartItem);
                                },
                              ),
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
                                    if (cartItem.discountedPrice != null)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Rs ${cartItem.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          Text(
                                            'Rs ${cartItem.discountedPrice!.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
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
                    }),
                  ],
                );
              },
            ),
          ),
          // Subtotal and Checkout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sub Total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rs ${_subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedItemIds.isEmpty ? null : _proceedToCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Checkout'),
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