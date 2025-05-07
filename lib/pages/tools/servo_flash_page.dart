import 'package:flutter/material.dart';

class ServoFlashPage extends StatelessWidget {
  const ServoFlashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servo Flash'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Servo Flash Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
