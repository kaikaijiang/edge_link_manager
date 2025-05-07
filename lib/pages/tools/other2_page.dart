import 'package:flutter/material.dart';

class Other2Page extends StatelessWidget {
  const Other2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Other 2 Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
