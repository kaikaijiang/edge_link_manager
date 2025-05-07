import 'package:flutter/material.dart';
import 'package:edge_link_manager/pages/tools/hw_reset_page.dart';
import 'package:edge_link_manager/pages/tools/servo_flash_page.dart';
import 'package:edge_link_manager/pages/tools/db_aly_page.dart';
import 'package:edge_link_manager/pages/tools/mqtt_page.dart';
import 'package:edge_link_manager/pages/tools/other1_page.dart';
import 'package:edge_link_manager/pages/tools/other2_page.dart';
import 'package:edge_link_manager/pages/tools/other3_page.dart';
import 'package:edge_link_manager/pages/tools/other4_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildToolCard(
                  context,
                  'HW Reset',
                  Icons.restart_alt,
                  Colors.red,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HwResetPage()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'Servo Flash',
                  Icons.flash_on,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ServoFlashPage()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'DB Aly',
                  Icons.storage,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DbAlyPage()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'MQTT',
                  Icons.message,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MqttPage()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'Other 1',
                  Icons.build,
                  Colors.purple,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Other1Page()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'Other 2',
                  Icons.settings,
                  Colors.teal,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Other2Page()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'Other 3',
                  Icons.handyman,
                  Colors.amber,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Other3Page()),
                  ),
                ),
                _buildToolCard(
                  context,
                  'Other 4',
                  Icons.construction,
                  Colors.indigo,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Other4Page()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
