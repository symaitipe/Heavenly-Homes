import 'package:heavenly_homes/constants/service_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> createPaymentIntent(String amount, String currency) async {
  const String secretKey = ServiceConstants.secretKey;
  final url = Uri.parse('https://api.stripe.com/v1/payment_intents');

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amount,
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create PaymentIntent: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error creating PaymentIntent: $e');
  }
}