import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/cart_items.dart';
import 'checkout_page.dart'; // To navigate on confirm

// Define colors
const Color kWhite = Color(0xFFFFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kDarkGrey = Color(0xFF232323); // Button color, Active Processing BG
const Color kInactiveText = Color(0xFF232323);
const Color kScaffoldBackground = Color(0xFFF5F5F5);
const Color kDividerColor = Color(0xFFF0F0F0);
const Color kInactiveBorderColor = Color(0xFFE0E0E0);
const Color kSuccessColor = Colors.green; // Delivered BG
const Color kFailureColor = Colors.red;   // Unsuccessful BG
const Color kDetailsColor = Colors.blue; // Details Active BG

class OrderProcessingPage extends StatelessWidget {
  // Parameters
  final List<CartItem> cartItems;
  final String orderId; // May be empty in 'Details' mode
  final String userId;
  final double deliveryCharges;
  final double subtotal;
  final double totalAmount;
  final String? viewMode; // 'Details' or 'Processing' (or null defaults to Processing)

  // Status Constants
  static const String statusDetails = 'Details';
  static const String statusProcessing = 'Processing';
  static const String statusDelivered = 'Delivered';
  static const String statusUnsuccessful = 'Unsuccessful';

  const OrderProcessingPage({
    super.key,
    required this.cartItems,
    required this.orderId,
    required this.userId,
    required this.deliveryCharges,
    required this.subtotal,
    required this.totalAmount,
    this.viewMode, // Optional view mode parameter
  });

  // --- HELPER: Status Tab ---
  Widget _buildStatusTab({ /* ... (Keep same helper code) ... */
     required String title, required bool isActive, required TextStyle activeTextStyle, required TextStyle inactiveTextStyle, required Color activeBackground, Color inactiveBackground = kWhite, required double minWidth, required double height, required double borderRadius, Color? inactiveBorderColor,
   }) { return Container( constraints: BoxConstraints( minWidth: minWidth, minHeight: height, maxHeight: height,), padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration( color: isActive ? activeBackground : inactiveBackground, borderRadius: BorderRadius.circular(borderRadius), border: !isActive ? Border.all(color: inactiveBorderColor ?? kInactiveBorderColor, width: 1) : null, boxShadow: isActive ? [ BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)) ] : [],), child: Center( child: Text( title, textAlign: TextAlign.center, style: isActive ? activeTextStyle : inactiveTextStyle,),),); }

  // --- HELPER: Summary Row ---
  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14}) { /* ... (Keep same helper code) ... */
       return Padding( padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row( mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text( label, style: TextStyle( fontSize: fontSize, color: Colors.grey.shade700, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, fontFamily: 'Poppins',),), Text( value, style: TextStyle( fontSize: isBold ? fontSize + 1 : fontSize, fontWeight: isBold ? FontWeight.w600 : FontWeight.w500, color: isBold ? kBlack : Colors.black87, fontFamily: 'Poppins',),),],),);
   }

  // --- HELPER: Styled Button ---
  Widget buildStyledButton({ /* ... (Keep same helper code) ... */
     required BuildContext context, required String text, required VoidCallback onPressed, required TextStyle textStyle, required double minWidth, required double height, required double borderRadius, required Color backgroundColor, bool isEnabled = true,
   }) { return ElevatedButton( onPressed: isEnabled ? onPressed : null, style: ElevatedButton.styleFrom( backgroundColor: backgroundColor, foregroundColor: textStyle.color ?? kWhite, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(borderRadius),), minimumSize: Size(minWidth, height), padding: EdgeInsets.zero, elevation: 2, disabledBackgroundColor: Colors.grey[400]?.withOpacity(0.5), disabledForegroundColor: Colors.grey[200],), child: Text( text, textAlign: TextAlign.center, style: textStyle,),); }

   // --- Logic for Confirm Button (navigates to Checkout) ---
   void _confirmOrderAndGoToCheckout(BuildContext context) { /* ... (Keep same logic from previous response) ... */
       final user = FirebaseAuth.instance.currentUser; if (user == null || cartItems.isEmpty) { print("Error: User not logged in or no items."); return; }
       const uuid = Uuid(); final newOrderId = uuid.v4();
       final confirmedSubtotal = cartItems.fold<double>(0.0, (sum, item) => sum + (item.discountedPrice ?? item.price) * item.quantity);
       const confirmedDelivery = 350.0;
       Navigator.push( context, MaterialPageRoute( builder: (context) => CheckoutPage( cartItems: cartItems, orderId: newOrderId, userId: user.uid, deliveryCharges: confirmedDelivery, subtotal: confirmedSubtotal,),),);
   }

  @override
  Widget build(BuildContext context) {
    // Determine current display status based on viewMode
    final String currentDisplayStatus = (viewMode == statusDetails) ? statusDetails : statusProcessing;
    // Define TextStyles for Tabs
    const activeStyle = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, height: 1.0, letterSpacing: 0, color: kWhite);
    const inactiveStyle = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, height: 1.0, letterSpacing: 0, color: kInactiveText);
    const inactiveUnsuccessfulStyle = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14, height: 1.0, letterSpacing: 0, color: kInactiveText);

    // Show success dialog only if entering 'Processing' mode from checkout
    if (viewMode == statusProcessing) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) { showDialog( context: context, barrierDismissible: false, builder: (context) => AlertDialog( shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), title: const Row(children: [ Icon(Icons.check_circle_outline, color: Colors.green, size: 28), SizedBox(width: 10), Text('Success!'), ]), content: const Text('Order placed successfully!'), actions: [ TextButton( onPressed: () => Navigator.pop(context), child: const Text('OK'), ),],),); }
       });
    }

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: Text(currentDisplayStatus == statusDetails ? 'Confirm Your Item' : 'Order Status'),
        automaticallyImplyLeading: currentDisplayStatus == statusDetails,
        leading: currentDisplayStatus == statusDetails ? IconButton( icon: const Icon(Icons.arrow_back, color: kBlack), onPressed: () => Navigator.pop(context),) : null,
        centerTitle: true, backgroundColor: kScaffoldBackground, elevation: 0,
        titleTextStyle: const TextStyle( fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: kBlack,),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // --- Status Tabs Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                child: SingleChildScrollView( scrollDirection: Axis.horizontal,
                  child: Row( mainAxisAlignment: MainAxisAlignment.start, children: [
                       _buildStatusTab( title: statusDetails, isActive: currentDisplayStatus == statusDetails, activeTextStyle: activeStyle.copyWith(color: kWhite), inactiveTextStyle: inactiveStyle, activeBackground: kDetailsColor, inactiveBackground: kWhite, minWidth: 100, height: 40, borderRadius: 30,),
                       const SizedBox(width: 10),
                       _buildStatusTab( title: statusProcessing, isActive: currentDisplayStatus == statusProcessing, activeTextStyle: activeStyle, inactiveTextStyle: inactiveStyle, activeBackground: kDarkGrey, inactiveBackground: kWhite, minWidth: 124, height: 40, borderRadius: 30,),
                       const SizedBox(width: 10),
                       _buildStatusTab( title: statusDelivered, isActive: currentDisplayStatus == statusDelivered, activeTextStyle: activeStyle, inactiveTextStyle: inactiveStyle, activeBackground: kSuccessColor, inactiveBackground: kWhite, minWidth: 119, height: 40, borderRadius: 30,),
                       const SizedBox(width: 10),
                       _buildStatusTab( title: statusUnsuccessful, isActive: currentDisplayStatus == statusUnsuccessful, activeTextStyle: activeStyle.copyWith(fontWeight: FontWeight.w400), inactiveTextStyle: inactiveUnsuccessfulStyle, activeBackground: kFailureColor, inactiveBackground: kWhite, minWidth: 124, height: 40, borderRadius: 30,),
                    ],),),),
              const SizedBox(height: 10),

              // --- Items Ordered/Details Section ---
              // *** RESTORED Padding content ***
              const Padding(
                 padding: EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
                 child: Text("Item Details:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
              // *** RESTORED ListView.separated content ***
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final displayPrice = item.discountedPrice ?? item.price;
                  final itemTotal = displayPrice * item.quantity;
                  // Use Padding and Row to display item details
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network( // Assuming network image for simplicity
                            item.imageUrl, width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 40)),
                            loadingBuilder: (c, ch, p) => p == null ? ch : Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text( item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'), maxLines: 2, overflow: TextOverflow.ellipsis,),
                              const SizedBox(height: 4),
                              Text( 'Quantity: ${item.quantity}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontFamily: 'Poppins'),),
                              const SizedBox(height: 8),
                              Text( 'Rs ${itemTotal.toStringAsFixed(2)}', style: const TextStyle( fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins'),),
                              if (item.discountedPrice != null)
                                Padding( padding: const EdgeInsets.only(top: 2.0),
                                  child: Text( 'Rs ${(item.price * item.quantity).toStringAsFixed(2)}', style: TextStyle( fontSize: 12, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough, fontFamily: 'Poppins'),),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16, color: kInactiveBorderColor),
              ),
              const Divider(thickness: 6, color: kDividerColor),

              // --- Order Summary Section ---
              // *** RESTORED Padding content ***
              Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text("Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                     const SizedBox(height: 12),
                     // Show Order ID only if it's not empty (i.e., not in initial 'Details' mode)
                     if (orderId.isNotEmpty) _buildSummaryRow('Order ID', orderId),
                     _buildSummaryRow('Items Subtotal', 'Rs ${subtotal.toStringAsFixed(2)}'),
                     _buildSummaryRow('Delivery Charges', 'Rs ${deliveryCharges.toStringAsFixed(2)}'),
                     const Divider(height: 15),
                     _buildSummaryRow( 'Total Amount', 'Rs ${totalAmount.toStringAsFixed(2)}', isBold: true, fontSize: 16,),
                 ],
               ),
              ),
            ],
          ),
        ),
      ),
      // --- Bottom Navigation Bar (Conditional) ---
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        // *** RESTORED Padding content and conditional logic ***
        child: (currentDisplayStatus == statusDetails)
            // Show Cancel/Confirm in 'Details' mode
            ? Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  buildStyledButton( context: context, text: 'Cancel Order', onPressed: () => Navigator.pop(context), textStyle: const TextStyle( fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, height: 1.0, letterSpacing: -0.02 * 16, color: kWhite,), minWidth: 161, height: 46, borderRadius: 30, backgroundColor: kDarkGrey,),
                  buildStyledButton( context: context, text: 'Confirm Order', onPressed: () => _confirmOrderAndGoToCheckout(context), textStyle: const TextStyle( fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, height: 1.0, letterSpacing: -0.02 * 16, color: kWhite,), minWidth: 161, height: 46, borderRadius: 30, backgroundColor: kDarkGrey,),
                ],)
            // Show Continue Shopping/Reorder in other modes
            : Column( mainAxisSize: MainAxisSize.min, children: [
                  ElevatedButton( onPressed: () { Navigator.of(context).popUntil((route) => route.isFirst); }, style: ElevatedButton.styleFrom( backgroundColor: kBlack, foregroundColor: kWhite, shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30),), padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50),), child: const Text( 'Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),),),
                  // Example Reorder button - uncomment and adjust logic based on actual fetched status
                  // if (actualOrderStatus == statusDelivered || actualOrderStatus == statusUnsuccessful)
                  //   Padding( padding: const EdgeInsets.only(top: 10.0), child: buildStyledButton( context: context, text: 'Reorder', onPressed: () { /* Reorder Logic */}, textStyle: const TextStyle( fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16, height: 1.0, letterSpacing: -0.02 * 16, color: kWhite,), minWidth: 161, height: 46, borderRadius: 30, backgroundColor: kDarkGrey,),),
                ],),
      ),
    );
  }
}
