import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edge_link_manager/models/settings_provider.dart';
import 'package:edge_link_manager/services/ssh_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class DiagnosePage extends StatefulWidget {
  const DiagnosePage({super.key});

  @override
  State<DiagnosePage> createState() => _DiagnosePageState();
}

class _DiagnosePageState extends State<DiagnosePage> {
  final TextEditingController _logController = TextEditingController();
  bool _isRunning = false;
  final SshService _sshService = SshService();
  bool _isConnected = false;
  bool _isAnalyzing = false;
  String _aiDiagnosisResult = '';
  
  @override
  void initState() {
    super.initState();
    _initSshConnection();
  }
  
  @override
  void dispose() {
    _logController.dispose();
    _sshService.disconnect();
    super.dispose();
  }
  
  Future<void> _initSshConnection() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final host = settingsProvider.hostHistory.isNotEmpty 
        ? settingsProvider.hostHistory.first 
        : 'localhost';
    
    setState(() {
      _isRunning = true;
    });
    
    final connected = await _sshService.connect(
      host: host,
      port: settingsProvider.sshPort,
      username: settingsProvider.sshUsername,
      password: settingsProvider.sshPassword,
    );
    
    setState(() {
      _isRunning = false;
      _isConnected = connected;
      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to SSH server')),
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          // SSH Log text area
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SSH Command Output',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _logController,
                      maxLines: null,
                      expands: true,
                      readOnly: true,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(8),
                        border: InputBorder.none,
                        hintText: 'SSH command output will appear here...',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Log action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.terminal),
                  onPressed: _isRunning || !_isConnected ? null : _readLog,
                  label: const Text('Read Log'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _logController.text.isEmpty ? null : _saveLog,
                  label: const Text('Save Log'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.psychology),
                  onPressed: _isAnalyzing || _logController.text.isEmpty ? null : _aiDiagnose,
                  label: const Text('AI Diagnose'),
                ),
              ),
            ],
          ),
          
          // AI Diagnosis result
          if (_aiDiagnosisResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withAlpha(76)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'AI Diagnosis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_aiDiagnosisResult),
                ],
              ),
            ),
          ],
          
          // Loading indicator
          if (_isRunning || _isAnalyzing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Read Log button functionality
  Future<void> _readLog() async {
    if (!_isConnected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to SSH server')),
      );
      return;
    }
    
    if (!mounted) return;
    setState(() {
      _isRunning = true;
      _logController.clear();
    });
    
    // List of commands to run
    final commands = [
      'uname -a',
      'ifconfig || ip addr',
      'netstat -tuln || ss -tuln',
      'cat /var/log/syslog | grep -i network | tail -n 20 || journalctl -u NetworkManager --no-pager | tail -n 20',
      'ping -c 4 8.8.8.8',
      'traceroute 8.8.8.8 || tracepath 8.8.8.8',
    ];
    
    String logOutput = '';
    
    for (final command in commands) {
      final result = await _sshService.executeCommand(command);
      if (result != null) {
        logOutput += '=== Command: $command ===\n$result\n\n';
      } else {
        logOutput += '=== Command: $command ===\nFailed to execute command\n\n';
      }
    }
    
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _logController.text = logOutput;
    });
  }
  
  // Save Log button functionality
  Future<void> _saveLog() async {
    if (_logController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No log data to save')),
      );
      return;
    }
    
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Network Diagnostic Log',
        fileName: 'log.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );
      
      if (result != null) {
        final file = File(result);
        await file.writeAsString(_logController.text);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Log saved to ${file.path}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving log: $e')),
      );
    }
  }
  
  // AI Diagnose button functionality
  Future<void> _aiDiagnose() async {
    if (_logController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No log data to analyze')),
      );
      return;
    }
    
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _aiDiagnosisResult = '';
    });
    
    try {
      // Simulate API call to Gemini Flash 2.0
      // In a real implementation, this would be an actual API call
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulated AI response
      final logText = _logController.text;
      String aiResponse = '';
      
      if (logText.contains('Network is unreachable') || logText.contains('100% packet loss')) {
        aiResponse = '''
Network Diagnosis:
- Network connectivity issue detected
- Possible causes:
  1. Network interface is down
  2. IP configuration is incorrect
  3. Router/gateway is unreachable
  
Recommended actions:
1. Check physical network connections
2. Verify IP configuration (DHCP or static)
3. Restart network service with: sudo systemctl restart NetworkManager
4. Check router/gateway status''';
      } else if (logText.contains('Permission denied')) {
        aiResponse = '''
Network Diagnosis:
- Permission issues detected
- Possible causes:
  1. Insufficient privileges for network operations
  2. Firewall blocking connections
  
Recommended actions:
1. Run network commands with sudo
2. Check firewall settings with: sudo iptables -L
3. Temporarily disable firewall for testing: sudo ufw disable''';
      } else {
        aiResponse = '''
Network Diagnosis:
- Network appears to be functioning normally
- Observed metrics:
  1. Ping latency is within normal range
  2. All expected services are running
  3. No packet loss detected
  
Recommendations:
1. If experiencing issues, check application-specific configurations
2. Monitor network performance during peak usage times
3. Consider running a more comprehensive network analysis''';
      }
      
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _aiDiagnosisResult = aiResponse;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _aiDiagnosisResult = 'Error analyzing log: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing log: $e')),
      );
    }
  }
}
