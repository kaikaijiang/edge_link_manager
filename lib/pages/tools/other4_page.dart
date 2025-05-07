import 'package:flutter/material.dart';

class Other4Page extends StatelessWidget {
  const Other4Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other 4'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Other 4 Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
