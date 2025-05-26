import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _products = [];
  int _currentTabIndex = 0;

  // Form controllers for adding products
  final _addProductFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isDiscounted = false;
  final _discountPriceController = TextEditingController();

  // Form controllers for updating products
  final _updateProductFormKey = GlobalKey<FormState>();
  final _updateQuantityController = TextEditingController();
  final _updateDiscountPriceController = TextEditingController();
  bool _updateIsDiscounted = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final ordersQuery = await _firestore.collection('orders').get();
      final productsQuery = await _firestore.collection('decoration_items').get();

      setState(() {
        _orders = ordersQuery.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        _products = productsQuery.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<void> _addProduct() async {
    if (!_addProductFormKey.currentState!.validate()) return;

    try {
      await _firestore.collection('decoration_items').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'available_qty': int.parse(_quantityController.text),
        'imageUrl': _imageUrlController.text,
        'isDiscounted': _isDiscounted,
        'discountPrice': _isDiscounted ? double.parse(_discountPriceController.text) : null,
        'rating': 0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear form
      _addProductFormKey.currentState!.reset();
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _quantityController.clear();
      _imageUrlController.clear();
      _discountPriceController.clear();
      _isDiscounted = false;

      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e')),
      );
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ?? false;

      if (confirmDelete) {
        await _firestore.collection('decoration_items').doc(productId).delete();

        setState(() {
          _products.removeWhere((item) => item['id'] == productId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e')),
      );
      await _fetchData();
    }
  }

  Future<void> _updateProduct(String productId, Map<String, dynamic> currentProduct) async {
    // Initialize controllers with current values
    _updateQuantityController.text = currentProduct['available_qty'].toString();
    _updateIsDiscounted = currentProduct['isDiscounted'] ?? false;
    _updateDiscountPriceController.text =
        currentProduct['discountPrice']?.toString() ?? '';

    bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Product: ${currentProduct['name']}'),
        content: Form(
          key: _updateProductFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _updateQuantityController,
                  decoration: const InputDecoration(
                    labelText: 'Available Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _updateIsDiscounted,
                      onChanged: (value) {
                        setState(() {
                          _updateIsDiscounted = value!;
                        });
                      },
                    ),
                    const Text('Is Discounted'),
                  ],
                ),
                if (_updateIsDiscounted) ...[
                  TextFormField(
                    controller: _updateDiscountPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Discount Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                    value!.isEmpty ? 'Required' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_updateProductFormKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) return;

    try {
      await _firestore.collection('decoration_items').doc(productId).update({
        'available_qty': int.parse(_updateQuantityController.text),
        'isDiscounted': _updateIsDiscounted,
        'discountPrice': _updateIsDiscounted
            ? double.parse(_updateDiscountPriceController.text)
            : null,
      });

      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating product: $e')),
      );
    }
  }

  Future<void> _updateOrderStatus(String orderId) async {
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('Processing'),
            _buildStatusOption('Shipped'),
            _buildStatusOption('Delivered'),
            _buildStatusOption('Cancelled'),
          ],
        ),
      ),
    );

    if (newStatus != null) {
      try {
        await _firestore.collection('orders').doc(orderId).update({
          'status': newStatus,
        });
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $newStatus')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Widget _buildStatusOption(String status) {
    return ListTile(
      title: Text(status),
      onTap: () => Navigator.pop(context, status),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd MMM yyyy \'at\' hh:mm a').format(timestamp.toDate());
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2).format(amount);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          centerTitle: true,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                      (route) => false,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchData,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Orders'),
              Tab(text: 'Products'),
            ],
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
              });
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            // Orders Tab
            _orders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  key: ValueKey('order-${order['id']}'),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order['orderId']?.substring(0, 8) ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                order['status'] ?? 'Unknown',
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: _getStatusColor(order['status']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'User ID: ${order['userId']?.substring(0, 8)}...',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Address: ${order['address'] ?? 'Not specified'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Placed on: ${_formatTimestamp(order['createdAt'] as Timestamp)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items: ${order['itemCount'] ?? 0}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Subtotal: ${_formatCurrency((order['subtotal'] ?? 0).toDouble())}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery: ${_formatCurrency((order['deliveryCharges'] ?? 0).toDouble())}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Total: ${_formatCurrency((order['totalAmount'] ?? 0).toDouble())}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Payment: ${order['paymentMethod'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text(
                            'Update Status',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Products Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add New Product Form
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _addProductFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Product',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Product Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _categoryController,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Available Quantity',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Image URL or Asset Path (e.g., assets/images/product1.jpg)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isDiscounted,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDiscounted = value!;
                                    });
                                  },
                                ),
                                const Text('Is Discounted'),
                              ],
                            ),
                            if (_isDiscounted) ...[
                              TextFormField(
                                controller: _discountPriceController,
                                decoration: const InputDecoration(
                                  labelText: 'Discount Price',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                value!.isEmpty ? 'Required' : null,
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _addProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Add Product',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Existing Products List
                  ..._products.map((product) => Card(
                    key: ValueKey('product-${product['id']}'),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Rs. ${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Category: ${product['category'] ?? 'Uncategorized'}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available: ${product['available_qty'] ?? 0}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          if (product['imageUrl'] != null &&
                              product['imageUrl'].toString().isNotEmpty)
                            product['imageUrl'].toString().startsWith('http')
                                ? Image.network(
                              product['imageUrl'].toString(),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            )
                                : Image.asset(
                              product['imageUrl'].toString(),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            product['description'] ?? 'No description available',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(
                                ' ${product['rating']?.toStringAsFixed(1) ?? '0.0'} (${product['reviewCount'] ?? 0} reviews)',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              if (product['isDiscounted'] == true)
                                Text(
                                  'Discount: Rs. ${product['discountPrice']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _updateProduct(product['id'], product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(product['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose product controllers
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    _discountPriceController.dispose();
    _updateQuantityController.dispose();
    _updateDiscountPriceController.dispose();

    super.dispose();
  }
}