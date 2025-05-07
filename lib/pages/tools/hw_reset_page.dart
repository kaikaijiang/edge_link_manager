import 'package:flutter/material.dart';

class HwResetPage extends StatelessWidget {
  const HwResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HW Reset'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'HW Reset Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
