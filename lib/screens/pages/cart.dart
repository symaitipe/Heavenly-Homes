import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../model/cart_items.dart'; // Ensure this path is correct
import 'checkout_page.dart'; // Ensure this path is correct

// Define colors based on your request
const Color kDarkGrey = Color(0xFF232323); // Button background
const Color kMidGreyText = Color(0xFF797979); // Sub total label color
const Color kPanelBackground = Color(0xFF333333); // Bottom panel background
const Color kWhite = Colors.white; // Text color
const Color kBlack = Colors.black; // Body text color

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  Set<String> _selectedItemIds = {};
  Map<String, List<CartItem>> _itemsByCategory = {};
  double _subtotal = 0.0; // This subtotal is for display in the cart bottom bar

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // --- Data Fetching and Logic Functions (Keep As Provided) ---
  Future<void> _fetchCartItems() async {
     // ... (Keep your existing _fetchCartItems logic) ...
      final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
         WidgetsBinding.instance.addPostFrameCallback((_) {
             if (mounted) Navigator.pushReplacementNamed(context, '/login');
         });
      }
      return;
    }
    try {
        final snapshot = await FirebaseFirestore.instance .collection('cart') .where('userId', isEqualTo: user.uid).get();
        final items = <CartItem>[]; final itemsByCategory = <String, List<CartItem>>{}; final selectedIds = <String>{};
        final itemDetailFutures = snapshot.docs.map((doc) async {
          final cartData = doc.data(); final itemDocSnapshot = await FirebaseFirestore.instance .collection('decoration_items') .doc(cartData['decorationItemId'] as String) .get();
          return {'cartDoc': doc, 'itemDocSnapshot': itemDocSnapshot}; }).toList();
        final results = await Future.wait(itemDetailFutures);
        for (var result in results) {
          final doc = result['cartDoc'] as QueryDocumentSnapshot<Map<String, dynamic>>; final itemDoc = result['itemDocSnapshot'] as DocumentSnapshot<Map<String, dynamic>>;
          final cartData = doc.data(); final itemData = itemDoc.data();
          if (itemData == null) { print("Warning: Item details not found for cart item ${doc.id}, item ID ${cartData['decorationItemId']}"); continue; }
          final category = (itemData['category'] as String?) ?? 'Other'; final isDiscounted = itemData['isDiscounted'] as bool? ?? false; final discountedPrice = isDiscounted ? (itemData['discountedPrice'] as num?)?.toDouble() : null;
          final String cartName = cartData['name'] as String? ?? itemData['name'] as String? ?? 'Unknown Item'; final String cartImageUrl = cartData['imageUrl'] as String? ?? itemData['image_url'] as String? ?? 'assets/placeholder.png';
          final double cartPrice = (cartData['price'] as num?)?.toDouble() ?? (itemData['price'] as num?)?.toDouble() ?? 0.0; final int cartQuantity = (cartData['quantity'] as num?)?.toInt() ?? 1;
          final cartItem = CartItem( id: doc.id, userId: cartData['userId'] as String, decorationItemId: cartData['decorationItemId'] as String, name: cartName, imageUrl: cartImageUrl, price: cartPrice, discountedPrice: discountedPrice, quantity: cartQuantity, );
          items.add(cartItem); itemsByCategory.putIfAbsent(category, () => []).add(cartItem); selectedIds.add(cartItem.id);
        }
        double currentSubtotal = 0.0;
        for (var item in items) { if (selectedIds.contains(item.id)) { final price = item.discountedPrice ?? item.price; currentSubtotal += price * item.quantity; } }
        if (mounted) { setState(() { _cartItems = items; _itemsByCategory = itemsByCategory; _selectedItemIds = selectedIds; _subtotal = currentSubtotal; }); }
      } catch (e) { print("Error fetching cart items: $e"); if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error loading cart: ${e.toString()}'))); } }
  }
  Future<void> _updateQuantity(CartItem cartItem, int newQuantity) async {
      // ... (Keep your existing _updateQuantity logic) ...
       if (newQuantity < 1) { await _removeItem(cartItem); return; }
    final bool isMounted = mounted;
    try {
      final itemDoc = await FirebaseFirestore.instance .collection('decoration_items') .doc(cartItem.decorationItemId) .get();
      final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0;
      if (newQuantity > availableQty) {
        if (isMounted) { showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Insufficient Stock'), content: Text('Only $availableQty items are available for ${cartItem.name}.'), actions: [ TextButton( onPressed: () => Navigator.pop(context), child: const Text('OK'),), ],),); } return;
      }
      await FirebaseFirestore.instance .collection('cart') .doc(cartItem.id) .update({'quantity': newQuantity});
      await _fetchCartItems();
    } catch (e) { print("Error updating quantity: $e"); if (isMounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error updating quantity: ${e.toString()}'))); } }
  }
  Future<void> _removeItem(CartItem cartItem) async {
      // ... (Keep your existing _removeItem logic) ...
       final bool isMounted = mounted; try { await FirebaseFirestore.instance .collection('cart') .doc(cartItem.id) .delete(); await _fetchCartItems(); } catch (e) { print("Error removing item: $e"); if (isMounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error removing item: ${e.toString()}'))); } }
  }
  void _toggleItemSelection(CartItem cartItem) {
      // ... (Keep your existing _toggleItemSelection logic) ...
       setState(() { final price = cartItem.discountedPrice ?? cartItem.price; if (_selectedItemIds.contains(cartItem.id)) { _selectedItemIds.remove(cartItem.id); _subtotal -= price * cartItem.quantity; } else { _selectedItemIds.add(cartItem.id); _subtotal += price * cartItem.quantity; } if (_subtotal < 0) _subtotal = 0.0; });
  }
  Future<void> _proceedToCheckout() async {
      // ... (Keep your existing _proceedToCheckout logic - it correctly calculates itemsSubtotal) ...
     final user = FirebaseAuth.instance.currentUser; if (user == null) { if (mounted) Navigator.pushReplacementNamed(context, '/login'); return; }
    if (_selectedItemIds.isEmpty) { if (mounted) { ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Please select at least one item to checkout.'), duration: Duration(seconds: 2), backgroundColor: Colors.orange, ), ); } return; }
    final bool isMounted = mounted; final selectedItems = _cartItems.where((item) => _selectedItemIds.contains(item.id)).toList();
     showDialog( context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()), );
    bool stockAvailable = true; String unavailableItemName = ''; int availableQtyForUnavailableItem = 0;
    try {
       for (var cartItem in selectedItems) { final itemDoc = await FirebaseFirestore.instance .collection('decoration_items') .doc(cartItem.decorationItemId) .get(); final availableQty = (itemDoc.data()?['available_qty'] as num?)?.toInt() ?? 0; if (cartItem.quantity > availableQty) { stockAvailable = false; unavailableItemName = cartItem.name; availableQtyForUnavailableItem = availableQty; break; } }
        if (isMounted) Navigator.pop(context);
        if (!stockAvailable) { if (isMounted) { showDialog( context: context, builder: (context) => AlertDialog( title: const Text('Insufficient Stock'), content: Text('Only $availableQtyForUnavailableItem items available for $unavailableItemName. Please adjust your cart quantity.'), actions: [ TextButton( onPressed: () => Navigator.pop(context), child: const Text('OK'),),],),); } return; }
        const uuid = Uuid(); final orderId = uuid.v4(); const deliveryCharges = 350.0;
        final double itemsSubtotal = selectedItems.fold<double>( 0.0, (sum, item) => sum + ((item.discountedPrice ?? item.price) * item.quantity), );
        if (isMounted) { Navigator.push( context, MaterialPageRoute( builder: (context) => CheckoutPage( cartItems: selectedItems, orderId: orderId, userId: user.uid, deliveryCharges: deliveryCharges, subtotal: itemsSubtotal, ),),); }
     } catch (e) { if (isMounted) Navigator.pop(context); print("Error checking stock or proceeding to checkout: $e"); if (isMounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error during checkout: ${e.toString()}'))); } }
  }
  // --- End Logic Functions ---

  @override
  Widget build(BuildContext context) {
    bool allSelected = _cartItems.isNotEmpty && _selectedItemIds.length == _cartItems.length;

    return Scaffold(
       backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0, centerTitle: true,
        leading: IconButton( icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () { Navigator.pop(context); },),
        title: const Text( 'My Cart', style: TextStyle( fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 20, color: Colors.black,),),
         actions: [ if (_cartItems.isNotEmpty) TextButton( onPressed: () { setState(() { if (allSelected) { _selectedItemIds.clear(); _subtotal = 0.0; } else { _subtotal = 0.0; for (var item in _cartItems) { _selectedItemIds.add(item.id); final price = item.discountedPrice ?? item.price; _subtotal += price * item.quantity;} if (_subtotal < 0) _subtotal = 0.0; } }); },
                child: Text( allSelected ? 'Deselect All' : 'Select All', style: const TextStyle(color: kDarkGrey, fontFamily: 'Poppins'),),)],
      ),
      body: _cartItems.isEmpty
          ? const Center( /* ... (empty cart widget remains the same) ... */
             child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey), SizedBox(height: 16), Text( 'Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey), ), ],)
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder( // --- Cart Item List (Keep As Provided) ---
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                     itemCount: _cartItems.length,
                     itemBuilder: (context, index) {
                         final cartItem = _cartItems[index];
                         final bool isSelected = _selectedItemIds.contains(cartItem.id);
                          return Card( // ... (Keep your existing Card widget structure for items) ...
                            elevation: 1.5, margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(12),),
                            child: InkWell( onTap: () => _toggleItemSelection(cartItem), borderRadius: BorderRadius.circular(12),
                                child: Padding( padding: const EdgeInsets.all(10.0),
                                child: Row( crossAxisAlignment: CrossAxisAlignment.center, children: [
                                    Checkbox( value: isSelected, onChanged: (bool? value) { _toggleItemSelection(cartItem); }, activeColor: kDarkGrey, visualDensity: VisualDensity.compact,), const SizedBox(width: 5),
                                    ClipRRect( borderRadius: BorderRadius.circular(8), child: cartItem.imageUrl.startsWith('http') ? Image.network( cartItem.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)), loadingBuilder: (context, child, progress) => progress == null ? child : Container(width: 70, height: 70, color: Colors.grey[200], child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))) : Image.asset( cartItem.imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 30, color: Colors.grey)),),), const SizedBox(width: 12),
                                    Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                          Text( cartItem.name, style: const TextStyle( fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: kBlack,), maxLines: 2, overflow: TextOverflow.ellipsis,), const SizedBox(height: 5),
                                          if (cartItem.discountedPrice != null) Row( crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [ Text( 'Rs ${cartItem.discountedPrice!.toStringAsFixed(2)}', style: const TextStyle( fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: kDarkGrey,),), const SizedBox(width: 8), Text( 'Rs ${cartItem.price.toStringAsFixed(2)}', style: const TextStyle( fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough, fontFamily: 'Poppins',),),]) else Text( 'Rs ${cartItem.price.toStringAsFixed(2)}', style: const TextStyle( fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: kDarkGrey,),), const SizedBox(height: 8),
                                          Row( children: [ _buildQuantityButton(Icons.remove, () { _updateQuantity(cartItem, cartItem.quantity - 1); }), Padding( padding: const EdgeInsets.symmetric(horizontal: 10), child: Text( '${cartItem.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),),), _buildQuantityButton(Icons.add, () { _updateQuantity(cartItem, cartItem.quantity + 1); }),],),],),),
                                     IconButton( icon: const Icon(Icons.delete_outline, color: Colors.redAccent), iconSize: 22, padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: 'Remove item', onPressed: () { showDialog( context: context, builder: (BuildContext ctx) { return AlertDialog( title: const Text('Remove Item?'), content: Text('Remove ${cartItem.name} from your cart?'), actions: [ TextButton( child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop(),), TextButton( child: const Text('Remove', style: TextStyle(color: Colors.red)), onPressed: () { Navigator.of(ctx).pop(); _removeItem(cartItem); },),],);},);},),],),),),);
                    },
                  ),
                ),

                // --- NEW BOTTOM CHECKOUT PANEL ---
                Container(
                  // height: 136; // Height determined by content and padding
                  // width: 430; // Use full width
                  padding: const EdgeInsets.fromLTRB(29, 20, 20, 20), // left: 29px, others adjusted
                  decoration: const BoxDecoration(
                    color: kPanelBackground, // background: #333333;
                    // border-top-left-radius: 50px; border-top-right-radius: 50px;
                    borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                    // No shadow specified, can add if needed
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between left (total) and right (button)
                    crossAxisAlignment: CrossAxisAlignment.center, // Center items vertically
                    children: [
                      // --- Left Side: Subtotal Label and Amount ---
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min, // Take minimum vertical space
                        children: [
                          // Sub total text: width: 63; height: 21; top: 800px; left: 29px; font-family: Poppins; font-weight: 400; font-size: 14px; line-height: 100%; letter-spacing: -2%; font colour : #797979;
                          const Text(
                            'Sub total:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 1.0, // line-height: 100%
                              letterSpacing: -0.02 * 14, // letter-spacing: -2%
                              color: kMidGreyText, // font colour: #797979;
                            ),
                          ),
                          const SizedBox(height: 5), // Spacing between label and amount

                          // Amount numbers: width: 121; height: 27; top: 817px; left: 29px; font-family: Poppins; font-weight: 600; font-size: 18px; line-height: 100%; letter-spacing: 2%; fontcolour: #FFFFFF;
                          Text(
                            'Rs ${_subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              height: 1.0, // line-height: 100%
                              letterSpacing: 0.02 * 18, // letter-spacing: 2%
                              color: kWhite, // fontcolour: #FFFFFF;
                            ),
                          ),
                        ],
                      ),

                      // --- Right Side: Checkout Button ---
                      // Rectangle width: 161; height: 46; top: 798px; left: 241px; border-radius: 30px; background: #232323;
                      ElevatedButton(
                        onPressed: _selectedItemIds.isEmpty ? null : _proceedToCheckout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkGrey, // background: #232323;
                          foregroundColor: kWhite, // affects text color
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)), // border-radius: 30px;
                          minimumSize: const Size(161, 46), // width: 161; height: 46;
                          padding: EdgeInsets.zero, // Use minimumSize to control padding
                          elevation: 2, // Optional shadow
                          disabledBackgroundColor: Colors.grey.shade600, // Visual cue when disabled
                        ),
                        // Checkout text: width: 77; height: 24; top: 809px; left: 273px; font-family: Poppins; font-weight: 600; font-size: 16px; line-height: 100%; letter-spacing: -2%; fontcolour: #FFFFFF;
                        child: const Text(
                           'Checkout', // Just the text
                           textAlign: TextAlign.center,
                           style: TextStyle(
                             fontFamily: 'Poppins',
                             fontWeight: FontWeight.w600, // Weight 600 specified
                             fontSize: 16,
                             height: 1.0, // line-height: 100%
                             letterSpacing: -0.02 * 16, // letter-spacing: -2%
                             color: kWhite, // fontcolour: #FFFFFF;
                           ),
                         ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

 // Helper widget for quantity buttons (Keep As Provided)
 Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell( onTap: onPressed, borderRadius: BorderRadius.circular(15), child: Container( padding: const EdgeInsets.all(4), decoration: BoxDecoration( shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1),), child: Icon(icon, size: 18, color: kDarkGrey),),);
 }
}
