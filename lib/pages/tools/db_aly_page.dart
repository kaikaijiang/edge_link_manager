import 'package:flutter/material.dart';

class DbAlyPage extends StatelessWidget {
  const DbAlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DB Aly'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'DB Aly Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
