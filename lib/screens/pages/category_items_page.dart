import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/decoration_items.dart';
import 'item_details.dart';

class CategoryItemsPage extends StatefulWidget {
  final String categoryName;

  const CategoryItemsPage({super.key, required this.categoryName});

  @override
  State<CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<CategoryItemsPage> {
  List<DecorationItem> _items = [];
  RangeValues _priceRange = const RangeValues(0.0, 0.0); // Will be set dynamically
  double _minPrice = 0.0; // Will be updated dynamically
  double _maxPrice = 0.0; // Will be updated dynamically
  RangeValues _currentPriceRange = const RangeValues(0.0, 0.0); // Tracks user selection
  bool _isInitialLoad = true; // Track if this is the first load
  bool _isFilterApplied = false; // Track if the user has applied a custom price filter

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchItems(applyPriceFilter: false); // Initial fetch without price filter

    // Listen to changes in the search input
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _fetchItems(applyPriceFilter: _isFilterApplied); // Re-fetch items with the new search query
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch items for the selected category from Firestore
  Future<void> _fetchItems({bool applyPriceFilter = false}) async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('decoration_items')
          .where('category', isEqualTo: widget.categoryName);

      // Apply price filter only if the user has applied a custom filter
      if (applyPriceFilter && _isFilterApplied) {
        query = query
            .where('price', isGreaterThanOrEqualTo: _currentPriceRange.start)
            .where('price', isLessThanOrEqualTo: _currentPriceRange.end);
      }

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          var items = snapshot.docs
              .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
              .toList();

          // Apply search filter in-memory
          if (_searchQuery.isNotEmpty) {
            items = items.where((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          _items = items;

          // Calculate min and max prices only on the initial load
          if (_isInitialLoad && _items.isNotEmpty) {
            final prices = _items.map((item) => item.price).toList();
            _minPrice = prices.reduce((a, b) => a < b ? a : b);
            _maxPrice = prices.reduce((a, b) => a > b ? a : b);
            _priceRange = RangeValues(_minPrice, _maxPrice);
            _currentPriceRange = RangeValues(_minPrice, _maxPrice);
            _isInitialLoad = false;
          }
        });
      }
    } catch (e) {
      // Fallback: Fetch all items and filter in-memory if the index is missing
      //print('Firestore query failed: $e. Falling back to in-memory filtering.');
      final snapshot = await FirebaseFirestore.instance
          .collection('decoration_items')
          .where('category', isEqualTo: widget.categoryName)
          .get();

      if (mounted) {
        setState(() {
          var items = snapshot.docs
              .map((doc) => DecorationItem.fromFirestore(doc.data(), doc.id))
              .toList();

          // Apply price filter in-memory if the user has applied a custom filter
          if (applyPriceFilter && _isFilterApplied) {
            items = items.where((item) =>
            item.price >= _currentPriceRange.start &&
                item.price <= _currentPriceRange.end).toList();
          }

          // Apply search filter in-memory
          if (_searchQuery.isNotEmpty) {
            items = items.where((item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          _items = items;

          // Calculate min and max prices only on the initial load
          if (_isInitialLoad && _items.isNotEmpty) {
            final prices = _items.map((item) => item.price).toList();
            _minPrice = prices.reduce((a, b) => a < b ? a : b);
            _maxPrice = prices.reduce((a, b) => a > b ? a : b);
            _priceRange = RangeValues(_minPrice, _maxPrice);
            _currentPriceRange = RangeValues(_minPrice, _maxPrice);
            _isInitialLoad = false;
          }
        });
      }
    }
  }

  // Add item to cart
  Future<void> _addToCart(DecorationItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final itemDoc = await FirebaseFirestore.instance
        .collection('decoration_items')
        .doc(item.id)
        .get();
    final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0;

    if (availableQty <= 0) {
      if (mounted) {
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

    final cartQuery = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: user.uid)
        .where('decorationItemId', isEqualTo: item.id)
        .get();

    if (cartQuery.docs.isNotEmpty) {
      final cartItem = cartQuery.docs.first;
      final currentQuantity = (cartItem.data()['quantity'] as num?)?.toInt() ?? 1;
      if (currentQuantity >= availableQty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Maximum Quantity Reached'),
              content: const Text('You have reached the maximum available quantity for this item.'),
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
      await FirebaseFirestore.instance
          .collection('cart')
          .doc(cartItem.id)
          .update({'quantity': currentQuantity + 1});
    } else {
      await FirebaseFirestore.instance.collection('cart').add({
        'userId': user.uid,
        'decorationItemId': item.id,
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'quantity': 1,
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} added to cart!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Show price filter modal
  void _showPriceFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _currentPriceRange = RangeValues(_minPrice, _maxPrice);
                          });
                          setState(() {
                            _priceRange = RangeValues(_minPrice, _maxPrice);
                            _isFilterApplied = false; // Reset the filter
                          });
                          _fetchItems(applyPriceFilter: false);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'RESET',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Price',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: _currentPriceRange,
                    min: _minPrice,
                    max: _maxPrice,
                    divisions: 100,
                    labels: RangeLabels(
                      'Rs ${_currentPriceRange.start.toStringAsFixed(2)}',
                      'Rs ${_currentPriceRange.end.toStringAsFixed(2)}',
                    ),
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _currentPriceRange = values;
                      });
                    },
                    onChangeEnd: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                        _currentPriceRange = values;
                        _isFilterApplied = true; // Mark that a custom filter is applied
                      });
                      _fetchItems(applyPriceFilter: true);
                    },
                    activeColor: Colors.orange,
                    inactiveColor: Colors.grey.shade300,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs ${_currentPriceRange.start.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        'Rs ${_currentPriceRange.end.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Here',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // _searchQuery will be updated via the controller's listener
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          // Price Filter and Item Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: _showPriceFilterModal,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('PRICE FILTER'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                Text(
                  '${_items.length} ITEMS AVAILABLE',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Items List
          Expanded(
            child: _items.isEmpty && !_isInitialLoad
                ? const Center(child: Text('No items match your search or filters.'))
                : _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _items.length + 1, // +1 for the "Show All" button
              itemBuilder: (context, index) {
                if (index == _items.length) {
                  return Center(
                    child: TextButton(
                      onPressed: () {
                        // Implement show all functionality (future enhancement)
                      },
                      child: const Text(
                        'Show All',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  );
                }

                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailPage(item: item),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl.startsWith('http')
                                  ? Image.network(
                                item.imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                              )
                                  : Image.asset(
                                item.imageUrl,
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
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex < item.rating.floor()
                                                ? Icons.star
                                                : (starIndex < item.rating
                                                ? Icons.star_half
                                                : Icons.star_border),
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.reviewCount} reviews',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rs ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _addToCart(item);
                                        },
                                        icon: const Icon(Icons.shopping_cart, size: 18),
                                        label: const Text('Add to Cart'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          side: const BorderSide(color: Colors.black),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItemDetailPage(item: item),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        child: const Text('Buy Now'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}