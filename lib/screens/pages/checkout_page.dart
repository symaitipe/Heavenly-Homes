import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:heavenly_homes/services/stripe_services.dart';
import '../../model/cart_items.dart';
import 'order_processing_page.dart';

// Define colors
const Color kWhite = Color(0xFFFFFFFF);
const Color kBlack = Color(0xFF000000);
const Color kDarkGrey = Color(0xFF232323);
const Color kLightTextGrey = Color(0xFF7B7B7B);
const Color kScaffoldBackground = Color(0xFFF5F5F5);
const Color kInputBorderColor = Color(0xFFE0E0E0);
const Color kErrorColor = Colors.redAccent;

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // --- Handle Stripe Payment ---
  Future<void> _handleStripePayment(double totalAmount) async {
    try {
      // For LKR, Stripe expects the amount in cents (multiply by 100)
      final amountInCents = (totalAmount * 100).toInt().toString();

      // Create Payment Intent using the function from stripe_services.dart
      final paymentIntentData = await createPaymentIntent(amountInCents, 'LKR');

      // Initialize the Payment Sheet (Google Pay enabled for Android)
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'Heavenly Homes',
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'LK',
            currencyCode: 'LKR',
            testEnv: true, // Set to false in production
          ),
        ),
      );

      // Present the Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // If payment is successful, save the order
      await _saveOrderAndNavigate(totalAmount);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: $e'),
            backgroundColor: kErrorColor,
          ),
        );
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  // --- Firestore Logic ---
  Future<void> _saveOrderAndNavigate(double totalAmount) async {
    final batch = FirebaseFirestore.instance.batch();
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);

    batch.set(orderRef, {
      'orderId': widget.orderId,
      'userId': widget.userId,
      'deliveryCharges': widget.deliveryCharges,
      'subtotal': widget.subtotal,
      'totalAmount': totalAmount,
      'status': 'Processing',
      'address': _addressController.text.trim(),
      'paymentMethod': _selectedPaymentMethod,
      'createdAt': Timestamp.now(),
      'itemCount': widget.cartItems.fold<int>(0, (sum, item) => sum + item.quantity),
    });

    for (var item in widget.cartItems) {
      final itemRef = orderRef.collection('items').doc(item.decorationItemId);
      batch.set(itemRef, {
        'itemId': item.decorationItemId,
        'itemName': item.name,
        'itemPrice': item.price,
        'discountedPrice': item.discountedPrice,
        'pricePaidPerItem': item.discountedPrice ?? item.price,
        'quantity': item.quantity,
        'imageUrl': item.imageUrl,
      });
      final itemDocRef = FirebaseFirestore.instance.collection('decoration_items').doc(item.decorationItemId);
      batch.update(itemDocRef, {'available_qty': FieldValue.increment(-item.quantity)});
      if (item.id.isNotEmpty && !item.id.startsWith('details_') && !item.id.startsWith('buynow_') && !item.id.startsWith('process_')) {
        final cartDocRef = FirebaseFirestore.instance.collection('cart').doc(item.id);
        batch.delete(cartDocRef);
      }
    }
    await batch.commit();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderProcessingPage(
            cartItems: widget.cartItems,
            orderId: widget.orderId,
            userId: widget.userId,
            deliveryCharges: widget.deliveryCharges,
            subtotal: widget.subtotal,
            totalAmount: totalAmount,
            viewMode: 'Processing',
          ),
        ),
      );
    }
  }

  // --- Address Validation Dialog ---
  void _showAddressRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Address Required'),
        content: const Text('Please enter a valid delivery address.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Pay Now Action ---
  Future<void> _payNowAction() async {
    if (_isPlacingOrder) return;
    if (!_formKey.currentState!.validate()) {
      _showAddressRequiredDialog();
      return;
    }
    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final double totalAmount = widget.subtotal + widget.deliveryCharges;

      if (_selectedPaymentMethod == 'Card Details') {
        // Handle Stripe Payment
        await _handleStripePayment(totalAmount);
      } else {
        // Handle Cash on Delivery
        await _saveOrderAndNavigate(totalAmount);
      }
    } catch (e) {
      //print("Error placing order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: kErrorColor,
          ),
        );
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  // --- Helper: Payment Option (UI Styled) ---
  Widget _buildPaymentOption(String title, IconData icon, {TextStyle? textStyle, bool isEnabled = true}) {
    bool isSelected = _selectedPaymentMethod == title;
    Color effectiveColor = isEnabled ? kDarkGrey : Colors.grey;
    Color selectionColor = isEnabled ? kBlack : Colors.grey;
    return GestureDetector(
      onTap: isEnabled
          ? () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      }
          : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isSelected ? selectionColor : kInputBorderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 24, color: effectiveColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: textStyle ??
                            const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: selectionColor, size: 22)
              else
                Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER: Summary Row (UI Styled) ---
  Widget _buildSummaryRow(String label, String value, {bool isBold = false, TextStyle? textStyle, Color? valueColor}) {
    final effectiveTextStyle = textStyle ??
        TextStyle(
          fontSize: 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: valueColor ?? kBlack,
          fontFamily: 'Poppins',
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: effectiveTextStyle,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: effectiveTextStyle.copyWith(),
          ),
        ),
      ],
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final double displayTotalAmount = widget.subtotal + widget.deliveryCharges;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        backgroundColor: kScaffoldBackground,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kBlack),
          onPressed: () {
            if (!_isPlacingOrder) Navigator.pop(context);
          },
        ),
        title: const Text(
          'Checkout',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 24,
            height: 1.0,
            letterSpacing: 0,
            color: kBlack,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Address Section ---
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          height: 1.0,
                          letterSpacing: -0.02 * 16,
                          color: kBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          hintText: 'Enter your delivery address',
                          hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey[400]),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                          isDense: true,
                        ),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, color: kBlack),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a delivery address';
                          }
                          if (value.trim().length < 10) {
                            return 'Address seems too short';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // --- Payment Method Section ---
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildPaymentOption(
                  'Cash on Delivery',
                  Icons.money_outlined,
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.0,
                    letterSpacing: -0.02 * 16,
                    color: kDarkGrey,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPaymentOption(
                  'Card Details',
                  Icons.credit_card_outlined,
                  isEnabled: true,
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 1.0,
                    letterSpacing: -0.02 * 16,
                    color: kDarkGrey,
                  ),
                ),
                const SizedBox(height: 24),
                // --- Order Summary Section ---
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kInputBorderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ...widget.cartItems.map((item) {
                        final itemTotal = (item.discountedPrice ?? item.price) * item.quantity;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildSummaryRow(
                            '${item.name} (x${item.quantity})',
                            'Rs ${itemTotal.toStringAsFixed(2)}', // Show with 2 decimal places
                            textStyle: const TextStyle(
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              height: 1.0,
                              letterSpacing: 0,
                              color: kLightTextGrey,
                            ),
                          ),
                        );
                      }),
                      _buildSummaryRow(
                        'Delivery Charge',
                        'Rs ${widget.deliveryCharges.toStringAsFixed(2)}', // Show with 2 decimal places
                        textStyle: const TextStyle(
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          height: 1.0,
                          letterSpacing: 0,
                          color: kLightTextGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Promotion',
                        'Not Available',
                        textStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          height: 1.0,
                          letterSpacing: 0,
                          color: kLightTextGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: kInputBorderColor),
                      _buildSummaryRow(
                        'Total',
                        'Rs ${displayTotalAmount.toStringAsFixed(2)}',
                        isBold: true,
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.0,
                          letterSpacing: -0.02 * 16,
                          color: kBlack,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: (screenWidth - 305) / 2, vertical: 20.0),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _payNowAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: kDarkGrey,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            minimumSize: const Size(305, 46),
            padding: EdgeInsets.zero,
            elevation: 2,
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: _isPlacingOrder
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(kWhite),
            ),
          )
              : const Text(
            'Pay Now',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 1.0,
              letterSpacing: 0,
              color: kWhite,
            ),
          ),
        ),
      ),
    );
  }
}