// lib/screens/pages/designer_details_page.dart
import 'package:flutter/material.dart';

class DesignerDetailsPage extends StatelessWidget {
  const DesignerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Designer Details'),
      ),
      body: const Center(
        child: Text('Designer Details Page'),
      ),
    );
  }
}