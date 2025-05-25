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
  List<Map<String, dynamic>> _decorationItems = [];
  List<Map<String, dynamic>> _designers = [];
  int _currentTabIndex = 0;

  // Form controllers for decoration items
  final _addItemFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryImageController = TextEditingController();
  bool _isDiscounted = false;
  List<String> _subImages = [];
  final _subImageController = TextEditingController();

  // Form controllers for designers
  final _addDesignerFormKey = GlobalKey<FormState>();
  final _designerNameController = TextEditingController();
  final _designerAboutController = TextEditingController();
  final _designerAddressController = TextEditingController();
  final _designerEmailController = TextEditingController();
  final _designerImageUrlController = TextEditingController();
  final _designerLocationController = TextEditingController();
  final _designerServicesController = TextEditingController();
  final _designerPhoneController = TextEditingController();
  List<String> _designerPhones = [];
  bool _designerIsAvailable = true;
  final _designerProjectTitleController = TextEditingController();
  final _designerProjectCategoryController = TextEditingController();
  final _designerProjectClientController = TextEditingController();
  final _designerProjectDescriptionController = TextEditingController();
  final _designerProjectLocationController = TextEditingController();
  final _designerProjectPriceController = TextEditingController();
  final _designerProjectYearController = TextEditingController();
  final _designerProjectRatingController = TextEditingController();
  final _designerProjectReviewCountController = TextEditingController();
  final _designerProjectImageUrlController = TextEditingController();
  List<String> _designerProjectImages = [];
  List<Map<String, dynamic>> _designerProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final ordersQuery = await _firestore.collection('orders').get();
      final itemsQuery = await _firestore.collection('decoration_items').get();
      final designersQuery = await _firestore.collection('designers').get();

      setState(() {
        _orders = ordersQuery.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();

        _decorationItems = itemsQuery.docs.map((doc) {
          final data = doc.data();
          final subImages = data['subImages'] is List
              ? List<String>.from(data['subImages'] ?? [])
              : (data['subImages'] != null
              ? [data['subImages'].toString()]
              : []);

          return {
            'id': doc.id,
            ...data,
            'subImages': subImages,
          };
        }).toList();

        _designers = designersQuery.docs.map((doc) {
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

  Future<void> _deleteItem(String itemId) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
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
        await _firestore.collection('decoration_items').doc(itemId).delete();

        setState(() {
          _decorationItems.removeWhere((item) => item['id'] == itemId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item: $e')),
      );
      await _fetchData();
    }
  }

  Future<void> _addDecorationItem() async {
    if (!_addItemFormKey.currentState!.validate()) return;

    try {
      await _firestore.collection('decoration_items').add({
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'available_qty': int.parse(_quantityController.text),
        'imageUrl': _imageUrlController.text,
        'categoryImage': _categoryImageController.text,
        'isDiscounted': _isDiscounted,
        'subImages': _subImages,
        'rating': 0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _addItemFormKey.currentState!.reset();
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _categoryController.clear();
      _quantityController.clear();
      _imageUrlController.clear();
      _categoryImageController.clear();
      _subImages.clear();
      _subImageController.clear();
      _isDiscounted = false;

      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    }
  }

  void _addSubImage() {
    if (_subImageController.text.isNotEmpty) {
      setState(() {
        _subImages.add(_subImageController.text);
        _subImageController.clear();
      });
    }
  }

  void _removeSubImage(int index) {
    setState(() {
      _subImages.removeAt(index);
    });
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

  Future<void> _deleteDesigner(String designerId) async {
    try {
      bool confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this designer?'),
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
        await _firestore.collection('designers').doc(designerId).delete();
        setState(() {
          _designers.removeWhere((designer) => designer['id'] == designerId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Designer deleted successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete designer: $e')),
      );
      await _fetchData();
    }
  }

  void _addDesignerPhone() {
    if (_designerPhoneController.text.isNotEmpty) {
      setState(() {
        _designerPhones.add(_designerPhoneController.text);
        _designerPhoneController.clear();
      });
    }
  }

  void _removeDesignerPhone(int index) {
    setState(() {
      _designerPhones.removeAt(index);
    });
  }

  void _addDesignerProjectImage() {
    if (_designerProjectImageUrlController.text.isNotEmpty) {
      setState(() {
        _designerProjectImages.add(_designerProjectImageUrlController.text);
        _designerProjectImageUrlController.clear();
      });
    }
  }

  void _removeDesignerProjectImage(int index) {
    setState(() {
      _designerProjectImages.removeAt(index);
    });
  }

  void _addDesignerProject() {
    if (_designerProjectTitleController.text.isNotEmpty &&
        _designerProjectCategoryController.text.isNotEmpty) {
      setState(() {
        _designerProjects.add({
          'title': _designerProjectTitleController.text,
          'category': _designerProjectCategoryController.text,
          'client': _designerProjectClientController.text,
          'description': _designerProjectDescriptionController.text,
          'location': _designerProjectLocationController.text,
          'price': double.tryParse(_designerProjectPriceController.text) ?? 0,
          'year': int.tryParse(_designerProjectYearController.text) ?? 2023,
          'rating': int.tryParse(_designerProjectRatingController.text) ?? 0,
          'reviewCount': int.tryParse(_designerProjectReviewCountController.text) ?? 0,
          'imageUrl': List.from(_designerProjectImages),
        });

        // Clear project fields
        _designerProjectTitleController.clear();
        _designerProjectCategoryController.clear();
        _designerProjectClientController.clear();
        _designerProjectDescriptionController.clear();
        _designerProjectLocationController.clear();
        _designerProjectPriceController.clear();
        _designerProjectYearController.clear();
        _designerProjectRatingController.clear();
        _designerProjectReviewCountController.clear();
        _designerProjectImages.clear();
        _designerProjectImageUrlController.clear();
      });
    }
  }

  void _removeDesignerProject(int index) {
    setState(() {
      _designerProjects.removeAt(index);
    });
  }

  Future<void> _addDesigner() async {
    if (!_addDesignerFormKey.currentState!.validate()) return;

    try {
      await _firestore.collection('designers').add({
        'name': _designerNameController.text,
        'about': _designerAboutController.text,
        'address': _designerAddressController.text,
        'email': _designerEmailController.text,
        'imageUrl': _designerImageUrlController.text,
        'isAvailable': _designerIsAvailable,
        'location': _designerLocationController.text,
        'phoneNumbers': _designerPhones,
        'projects': _designerProjects,
        'services': _designerServicesController.text,
        'rating': 0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear all fields
      _addDesignerFormKey.currentState!.reset();
      _designerNameController.clear();
      _designerAboutController.clear();
      _designerAddressController.clear();
      _designerEmailController.clear();
      _designerImageUrlController.clear();
      _designerLocationController.clear();
      _designerServicesController.clear();
      _designerPhoneController.clear();
      _designerPhones.clear();
      _designerProjects.clear();
      _designerProjectImages.clear();
      _designerIsAvailable = true;

      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Designer added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding designer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
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
              Tab(text: 'Decoration Items'),
              Tab(text: 'Designers'),
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

            // Decoration Items Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add New Item Form
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _addItemFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Decoration Item',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Item Name',
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
                                labelText: 'Main Image URL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _categoryImageController,
                              decoration: const InputDecoration(
                                labelText: 'Category Image URL',
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
                            const SizedBox(height: 12),
                            const Text(
                              'Sub Images',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _subImageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Sub Image URL',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addSubImage,
                                ),
                              ],
                            ),
                            if (_subImages.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _subImages
                                    .asMap()
                                    .entries
                                    .map((entry) => Chip(
                                  label: Text('Image ${entry.key + 1}'),
                                  onDeleted: () =>
                                      _removeSubImage(entry.key),
                                ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _addDecorationItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Add Item',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Existing Items List
                  ..._decorationItems.map((item) => Card(
                    key: ValueKey('item-${item['id']}'),
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
                                item['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  'Rs. ${item['price']?.toStringAsFixed(2) ?? '0.00'}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Category: ${item['category'] ?? 'Uncategorized'}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Available: ${item['available_qty'] ?? 0}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          if (item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty)
                            Image.network(
                              item['imageUrl'].toString(),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            item['description'] ?? 'No description available',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (item['subImages'] != null && (item['subImages'] as List).isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: (item['subImages'] as List).length,
                                itemBuilder: (context, index) {
                                  final subImage = (item['subImages'] as List)[index]?.toString() ?? '';
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: subImage.isNotEmpty
                                        ? Image.network(
                                      subImage,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 100,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                        : Container(
                                      width: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(
                                ' ${item['rating']?.toStringAsFixed(1) ?? '0.0'} (${item['reviewCount'] ?? 0} reviews)',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const Spacer(),
                              if (item['isDiscounted'] == true)
                                const Text(
                                  'DISCOUNTED',
                                  style: TextStyle(
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
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(item['id']),
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

            // Designers Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Add New Designer Form
                  Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _addDesignerFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Designer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _designerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Designer Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerAboutController,
                              decoration: const InputDecoration(
                                labelText: 'About Designer',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerImageUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Image URL',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerServicesController,
                              decoration: const InputDecoration(
                                labelText: 'Services',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _designerIsAvailable,
                                  onChanged: (value) {
                                    setState(() {
                                      _designerIsAvailable = value!;
                                    });
                                  },
                                ),
                                const Text('Is Available'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Phone Numbers',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _designerPhoneController,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone Number',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addDesignerPhone,
                                ),
                              ],
                            ),
                            if (_designerPhones.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _designerPhones
                                    .asMap()
                                    .entries
                                    .map((entry) => Chip(
                                  label: Text(entry.value),
                                  onDeleted: () =>
                                      _removeDesignerPhone(entry.key),
                                ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const Text(
                              'Projects',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectTitleController,
                              decoration: const InputDecoration(
                                labelText: 'Project Title',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectCategoryController,
                              decoration: const InputDecoration(
                                labelText: 'Project Category',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectClientController,
                              decoration: const InputDecoration(
                                labelText: 'Client Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectDescriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Project Description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Project Location',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Project Price',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectYearController,
                              decoration: const InputDecoration(
                                labelText: 'Project Year',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectRatingController,
                              decoration: const InputDecoration(
                                labelText: 'Rating (1-5)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _designerProjectReviewCountController,
                              decoration: const InputDecoration(
                                labelText: 'Review Count',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Project Images',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _designerProjectImageUrlController,
                                    decoration: const InputDecoration(
                                      labelText: 'Image URL',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addDesignerProjectImage,
                                ),
                              ],
                            ),
                            if (_designerProjectImages.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: _designerProjectImages
                                    .asMap()
                                    .entries
                                    .map((entry) => Chip(
                                  label: Text('Image ${entry.key + 1}'),
                                  onDeleted: () =>
                                      _removeDesignerProjectImage(entry.key),
                                ))
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _addDesignerProject,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const Text(
                                'Add Project',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            if (_designerProjects.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Added Projects:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ..._designerProjects
                                  .asMap()
                                  .entries
                                  .map((entry) => ListTile(
                                title: Text(entry.value['title']),
                                subtitle: Text(
                                    '${entry.value['category']} - ${entry.value['year']}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _removeDesignerProject(entry.key),
                                ),
                              ))
                                  .toList(),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _addDesigner,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                'Add Designer',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Existing Designers List
                  ..._designers.map((designer) => Card(
                    key: ValueKey('designer-${designer['id']}'),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                designer['name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  designer['isAvailable'] == true
                                      ? 'Available'
                                      : 'Not Available',
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                                backgroundColor:
                                designer['isAvailable'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (designer['imageUrl'] != null &&
                              designer['imageUrl'].toString().isNotEmpty)
                            Image.network(
                              designer['imageUrl'].toString(),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            designer['about'] ?? 'No description',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Contact Information:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Address: ${designer['address'] ?? 'Not specified'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Location: ${designer['location'] ?? 'Not specified'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Email: ${designer['email'] ?? 'Not specified'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          if (designer['phoneNumbers'] != null &&
                              (designer['phoneNumbers'] as List)
                                  .isNotEmpty)
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone Numbers:',
                                  style: TextStyle(fontSize: 14),
                                ),
                                ...(designer['phoneNumbers'] as List)
                                    .map((phone) => Text(
                                  '• $phone',
                                  style: const TextStyle(
                                      fontSize: 14),
                                ))
                                    .toList(),
                              ],
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Services:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            designer['services'] ?? 'Not specified',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          if (designer['projects'] != null &&
                              (designer['projects'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Projects:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                ...(designer['projects'] as List)
                                    .map((project) => Padding(
                                  padding:
                                  const EdgeInsets.only(
                                      top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        project['title'] ??
                                            'No Title',
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${project['category']} • ${project['year']} • ${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2).format(project['price'] ?? 0)}',
                                        style:
                                        const TextStyle(
                                            fontSize: 14),
                                      ),
                                      Text(
                                        'Client: ${project['client'] ?? 'Not specified'}',
                                        style:
                                        const TextStyle(
                                            fontSize: 14),
                                      ),
                                      Text(
                                        project[
                                        'description'] ??
                                            'No description',
                                        style:
                                        const TextStyle(
                                            fontSize: 14),
                                      ),
                                      if (project['imageUrl'] !=
                                          null &&
                                          (project['imageUrl']
                                          as List)
                                              .isNotEmpty)
                                        SizedBox(
                                          height: 100,
                                          child:
                                          ListView.builder(
                                            scrollDirection:
                                            Axis.horizontal,
                                            itemCount: (project[
                                            'imageUrl']
                                            as List)
                                                .length,
                                            itemBuilder:
                                                (context,
                                                index) {
                                              final image = (project['imageUrl']
                                              as List)[
                                              index]
                                                  ?.toString();
                                              return Padding(
                                                padding:
                                                const EdgeInsets
                                                    .only(
                                                    right:
                                                    8),
                                                child: image !=
                                                    null
                                                    ? Image
                                                    .network(
                                                  image,
                                                  height:
                                                  100,
                                                  width:
                                                  100,
                                                  fit: BoxFit
                                                      .cover,
                                                  errorBuilder: (context,
                                                      error,
                                                      stackTrace) =>
                                                      Container(
                                                        width:
                                                        100,
                                                        color:
                                                        Colors.grey[200],
                                                        child:
                                                        const Icon(Icons.broken_image),
                                                      ),
                                                )
                                                    : Container(
                                                  width:
                                                  100,
                                                  color:
                                                  Colors.grey[200],
                                                  child:
                                                  const Icon(Icons.broken_image),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                ))
                                    .toList(),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              Text(
                                ' ${designer['rating']?.toStringAsFixed(1) ?? '0.0'} (${designer['reviewCount'] ?? 0} reviews)',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteDesigner(designer['id']),
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
    // Dispose decoration item controllers
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _imageUrlController.dispose();
    _categoryImageController.dispose();
    _subImageController.dispose();

    // Dispose designer controllers
    _designerNameController.dispose();
    _designerAboutController.dispose();
    _designerAddressController.dispose();
    _designerEmailController.dispose();
    _designerImageUrlController.dispose();
    _designerLocationController.dispose();
    _designerServicesController.dispose();
    _designerPhoneController.dispose();
    _designerProjectTitleController.dispose();
    _designerProjectCategoryController.dispose();
    _designerProjectClientController.dispose();
    _designerProjectDescriptionController.dispose();
    _designerProjectLocationController.dispose();
    _designerProjectPriceController.dispose();
    _designerProjectYearController.dispose();
    _designerProjectRatingController.dispose();
    _designerProjectReviewCountController.dispose();
    _designerProjectImageUrlController.dispose();

    super.dispose();
  }
}