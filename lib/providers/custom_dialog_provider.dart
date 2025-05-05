
import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String buttonText;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.buttonText = 'OK',
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor ?? Theme.of(context).dialogTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (icon != null)
            Icon(icon, color: textColor),
          if (icon != null)
            const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        content,
        style: TextStyle(color: textColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            buttonText,
            style: TextStyle(
              color: textColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

