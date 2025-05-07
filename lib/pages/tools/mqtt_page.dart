import 'package:flutter/material.dart';

class MqttPage extends StatelessWidget {
  const MqttPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'MQTT Tool',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
