import 'package:flutter/material.dart';
import 'custom_dialog_provider.dart';

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => CustomDialog(
      title: 'Error',
      content: message,
      backgroundColor: Colors.red[900],
      textColor: Colors.white,
      icon: Icons.error_outline,
    ),
  );
}

void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => CustomDialog(
      title: 'Success',
      content: message,
      backgroundColor: Colors.green[800],
      textColor: Colors.white,
      icon: Icons.check_circle_outline,
    ),
  );
}