import 'package:flutter/material.dart';

class Other3Page extends StatelessWidget {
  const Other3Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other 3'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Other 3 Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
