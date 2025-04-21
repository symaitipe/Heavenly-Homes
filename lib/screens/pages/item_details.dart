import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../model/cart_Items.dart';
import '../../model/decoration_items.dart';
import 'order_details.dart';

class ItemDetailPage extends StatefulWidget {
  final DecorationItem item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  String _selectedImageUrl = '';

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = widget.item.imageUrl;
  }

  // Check available quantity before proceeding to Buy Now or Add to Cart
  Future<int> _checkAvailableQuantity() async {
    final doc = await FirebaseFirestore.instance
        .collection('decoration_items')
        .doc(widget.item.id)
        .get();
    if (doc.exists) {
      final data = doc.data();
      return (data?['available_qty'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // Add item to cart
  Future<void> _addToCart() async {
    // Check if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Check available quantity
    final availableQty = await _checkAvailableQuantity();
    if (availableQty <= 0) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Out of Stock'),
            content: const Text('Sorry, this item is currently out of stock.'),
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

    // Check if the item is already in the cart
    final cartSnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user.uid)
        .where('decorationItemId', isEqualTo: widget.item.id)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    if (cartSnapshot.docs.isNotEmpty) {
      // Item exists in cart; increment quantity
      final cartDoc = cartSnapshot.docs.first;
      final currentQty = (cartDoc.data()['quantity'] as num?)?.toInt() ?? 1;
      final newQty = currentQty + 1;

      if (newQty > availableQty) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Quantity Exceeded'),
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

      // Update quantity in cart
      batch.update(cartDoc.reference, {'quantity': newQty});
    } else {
      // Item not in cart; add new entry with quantity 1
      final cartItem = CartItem(
        id: '', // Will be set by Firestore
        userId: user.uid,
        decorationItemId: widget.item.id,
        name: widget.item.name,
        imageUrl: widget.item.imageUrl,
        price: widget.item.price,
        discountedPrice: widget.item.isDiscounted ? widget.item.discountedPrice : null, // Use discounted price if available
        quantity: 1,
      );

      final cartDocRef = FirebaseFirestore.instance.collection('cart').doc();
      batch.set(cartDocRef, cartItem.toFirestore());
    }

    // Commit the batch
    await batch.commit();

    // Show confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.item.name} added to cart!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality (future enhancement)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_selectedImageUrl), // Changed to NetworkImage for consistency with BestBidsPage
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border),
                    color: Colors.white,
                    onPressed: () {
                      // Implement favorite functionality (future enhancement)
                    },
                  ),
                ),
              ),
            ),
            // Sub-Images
            widget.item.subImages.isNotEmpty
                ? SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: widget.item.subImages.length,
                itemBuilder: (context, index) {
                  final subImageUrl = widget.item.subImages[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageUrl = subImageUrl;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network( // Changed to Image.network for consistency
                          subImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
                : const SizedBox(height: 8),
            // Item Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.item.rating.floor()
                                ? Icons.star
                                : (index < widget.item.rating ? Icons.star_half : Icons.star_border),
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.item.reviewCount} reviews',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Price Display (Show discounted price if available)
                  if (widget.item.isDiscounted && widget.item.discountedPrice != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs ${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'Rs ${widget.item.discountedPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Rs ${widget.item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add To Cart'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Get the current user ID
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    // If user is not logged in, redirect to login
                    Navigator.pushReplacementNamed(context, '/login');
                    return;
                  }

                  // Check available quantity
                  int availableQty = await _checkAvailableQuantity();
                  if (availableQty <= 0) {
                    // Show alert if out of stock
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Out of Stock'),
                          content: const Text('Sorry, this item is currently out of stock.'),
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

                  // Generate a unique order ID (using timestamp for simplicity)
                  final orderId = DateTime.now().millisecondsSinceEpoch.toString();

                  // Navigate to OrderDetailPage, passing the discounted price if available
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(
                          item: widget.item,
                          orderId: orderId,
                          userId: user.uid,
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
                child: const Text('Buy Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}