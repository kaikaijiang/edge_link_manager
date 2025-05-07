import 'package:flutter/material.dart';

class Other1Page extends StatelessWidget {
  const Other1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other 1'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Other 1 Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
