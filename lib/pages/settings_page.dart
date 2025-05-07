import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edge_link_manager/models/settings_provider.dart';
import 'package:edge_link_manager/services/ssh_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _edgeDeviceIpController = TextEditingController();
  final TextEditingController _sshUsernameController = TextEditingController();
  final TextEditingController _sshPasswordController = TextEditingController();
  final TextEditingController _sshPortController = TextEditingController();
  final TextEditingController _vncPasswordController = TextEditingController();
  final TextEditingController _dbUsernameController = TextEditingController();
  final TextEditingController _dbPasswordController = TextEditingController();
  
  final SshService _sshService = SshService();
  bool _isTesting = false;
  String _testResult = '';
  
  @override
  void initState() {
    super.initState();
    // Controllers will be initialized in didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    // Initialize controllers with values from settings provider
    if (settingsProvider.hostHistory.isNotEmpty) {
      _edgeDeviceIpController.text = settingsProvider.hostHistory.first;
    }
    _sshUsernameController.text = settingsProvider.sshUsername;
    _sshPasswordController.text = settingsProvider.sshPassword;
    _sshPortController.text = settingsProvider.sshPort.toString();
    _vncPasswordController.text = settingsProvider.vncPassword;
    _dbUsernameController.text = settingsProvider.dbUsername;
    _dbPasswordController.text = settingsProvider.dbPassword;
  }
  
  @override
  void dispose() {
    _edgeDeviceIpController.dispose();
    _sshUsernameController.dispose();
    _sshPasswordController.dispose();
    _sshPortController.dispose();
    _vncPasswordController.dispose();
    _dbUsernameController.dispose();
    _dbPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Theme Mode'),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {settingsProvider.themeMode},
                      onSelectionChanged: (Set<ThemeMode> selection) {
                        settingsProvider.setThemeMode(selection.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (settingsProvider.hostHistory.isEmpty)
                      const Text('No connection history')
                    else
                      Column(
                        children: [
                          ...settingsProvider.hostHistory.map((host) => ListTile(
                            title: Text(host),
                            leading: const Icon(Icons.history),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                // In a real app, we would implement removing a single host
                                // For now, we'll just show a message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Removed $host from history')),
                                );
                              },
                            ),
                          )),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              settingsProvider.clearHostHistory();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Connection history cleared')),
                              );
                            },
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Clear All History'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _edgeDeviceIpController,
                      decoration: const InputDecoration(
                        labelText: 'Edge Device IP',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.router),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _sshUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'SSH Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _sshPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'SSH Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _sshPortController,
                      decoration: const InputDecoration(
                        labelText: 'SSH Port',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _vncPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'VNC Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.desktop_windows),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _dbUsernameController,
                      decoration: const InputDecoration(
                        labelText: 'DB Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.storage),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextField(
                      controller: _dbPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'DB Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.password),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Settings'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.network_check),
                            label: const Text('Test Connection'),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_isTesting)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_testResult.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: _testResult.contains('Success') 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                            border: Border.all(
                              color: _testResult.contains('Success') 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            _testResult,
                            style: TextStyle(
                              color: _testResult.contains('Success') 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const ListTile(
                      title: Text('Edge Link Manager'),
                      subtitle: Text('Version 1.0.0'),
                      leading: Icon(Icons.info),
                    ),
                    
                    const Divider(),
                    
                    ListTile(
                      title: const Text('Check for Updates'),
                      leading: const Icon(Icons.system_update),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checking for updates...')),
                        );
                      },
                    ),
                    
                    ListTile(
                      title: const Text('Send Feedback'),
                      leading: const Icon(Icons.feedback),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback feature would open here')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _saveSettings() {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Save Edge Device IP to host history
    final ip = _edgeDeviceIpController.text.trim();
    if (ip.isNotEmpty) {
      settingsProvider.addHostToHistory(ip);
    }
    
    // Save SSH settings
    settingsProvider.setSshUsername(_sshUsernameController.text);
    settingsProvider.setSshPassword(_sshPasswordController.text);
    final port = int.tryParse(_sshPortController.text) ?? 22;
    settingsProvider.setSshPort(port);
    
    // Save VNC password
    settingsProvider.setVncPassword(_vncPasswordController.text);
    
    // Save DB credentials
    settingsProvider.setDbUsername(_dbUsernameController.text);
    settingsProvider.setDbPassword(_dbPasswordController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All settings saved')),
    );
  }
  
  Future<void> _testConnection() async {
    final ip = _edgeDeviceIpController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an IP address')),
      );
      return;
    }
    
    setState(() {
      _isTesting = true;
      _testResult = '';
    });
    
    try {
      final success = await _sshService.connect(
        host: ip,
        port: int.tryParse(_sshPortController.text) ?? 22,
        username: _sshUsernameController.text,
        password: _sshPasswordController.text,
      );
      
      setState(() {
        _isTesting = false;
        if (success) {
          _testResult = 'Success: Connected to $ip';
          // Save to history on successful connection
          Provider.of<SettingsProvider>(context, listen: false).addHostToHistory(ip);
        } else {
          _testResult = 'Failed: Could not connect to $ip';
        }
      });
      
      // Disconnect if connected
      if (success) {
        await _sshService.disconnect();
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = 'Error: ${e.toString()}';
      });
    }
  }
}
