import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edge_link_manager/models/settings_provider.dart';
import 'package:edge_link_manager/services/ssh_service.dart';

class SshPage extends StatefulWidget {
  const SshPage({super.key});

  @override
  State<SshPage> createState() => _SshPageState();
}

class _SshPageState extends State<SshPage> {
  final TextEditingController _commandController = TextEditingController();
  final SshService _sshService = SshService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isConnected = false;
  List<String> _output = [];
  bool _isConnecting = false;
  bool _isInteractiveMode = false;
  
  @override
  void initState() {
    super.initState();
    // Connect automatically when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }
  
  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    _disconnect();
    super.dispose();
  }
  
  void _autoConnect() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settingsProvider.hostHistory.isNotEmpty) {
      final host = settingsProvider.hostHistory.first;
      final username = settingsProvider.sshUsername;
      final password = settingsProvider.sshPassword;
      final port = settingsProvider.sshPort;
      
      _connectToSsh(host, port, username, password);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          if (!_isConnected && !_isConnecting) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SSH Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (settingsProvider.hostHistory.isNotEmpty) ...[
                      const Text('Recent Connections:'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: settingsProvider.hostHistory.length,
                          itemBuilder: (context, index) {
                            final host = settingsProvider.hostHistory[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  _connectToSsh(
                                    host,
                                    settingsProvider.sshPort,
                                    settingsProvider.sshUsername,
                                    settingsProvider.sshPassword,
                                  );
                                },
                                child: Text(host),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    const Text(
                      'Connect to a new SSH server using the settings configured in the Settings page.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: () {
                        if (settingsProvider.hostHistory.isNotEmpty) {
                          _autoConnect();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a host in the Settings page first'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.terminal),
                      label: const Text('Connect to SSH Server'),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_isConnecting) ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to SSH server...'),
                ],
              ),
            ),
          ] else if (_isConnected) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                // Use a single SelectableText widget inside a SingleChildScrollView
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SelectableText(
                    // Join all output lines with newlines
                    _output.join('\n'),
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      height: 1.2, // Adjust line height for better readability
                    ),
                    // Enable text selection
                    enableInteractiveSelection: true,
                    // Make sure the text can be selected across multiple lines
                    maxLines: null,
                    // Ensure the text wraps properly
                    textAlign: TextAlign.left,
                    // Preserve whitespace to maintain formatting
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isInteractiveMode) ...[
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Interactive mode active: ${_sshService.isInteractiveSessionActive ? "Running" : "Inactive"}. Type "exit" to return to normal mode.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _sshService.stopInteractiveSession();
                        setState(() {
                          _isInteractiveMode = false;
                          _output.add('Exited interactive mode');
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Exit Interactive Mode',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    decoration: InputDecoration(
                      hintText: _isInteractiveMode ? 'Enter input for interactive command' : 'Enter command',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(_isInteractiveMode ? Icons.terminal : Icons.code),
                      prefixIconColor: _isInteractiveMode ? Colors.orange : null,
                      fillColor: _isInteractiveMode ? Colors.amber.shade50 : null,
                      filled: _isInteractiveMode,
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                    onSubmitted: (_) => _executeCommand(),
                    autofocus: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _executeCommand,
                  icon: Icon(_isInteractiveMode ? Icons.keyboard_return : Icons.send),
                  tooltip: _isInteractiveMode ? 'Send Input' : 'Send Command',
                  color: _isInteractiveMode ? Colors.orange : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _disconnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close),
              label: const Text('Disconnect'),
            ),
          ],
        ],
      ),
    );
  }
  
  Future<void> _connectToSsh(String host, int port, String username, String password) async {
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host')),
      );
      return;
    }
    
    setState(() {
      _isConnecting = true;
      _output = [];
    });
    
    // Save to history
    Provider.of<SettingsProvider>(context, listen: false).addHostToHistory(host);
    
    // Connect to the SSH server using the SSH service
    final success = await _sshService.connect(
      host: host,
      port: port,
      username: username,
      password: password,
    );
    
    setState(() {
      _isConnecting = false;
      _isConnected = success;
      
      if (success) {
        _output = [
          'Connected to $host as $username',
          'Welcome to SSH terminal',
          'Type commands below',
        ];
      } else {
        _output = [
          'Failed to connect to $host',
          'Please check your connection settings and try again',
        ];
        
        // Show a snackbar with the error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed')),
        );
      }
    });
  }
  
  // Handle interactive session output
  void _handleInteractiveOutput(String output) {
    setState(() {
      _output.add(output);
      _scrollToBottom();
    });
  }
  
  // Helper method to scroll to the bottom of the terminal output
  void _scrollToBottom() {
    // Use a post-frame callback to ensure the scroll happens after the UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;
    
    // If we're in interactive mode, send the input to the interactive session
    if (_isInteractiveMode) {
      setState(() {
        _output.add('> $command');
      });
      
      // Send the input to the interactive session
      _sshService.sendInput(command + '\n');
      
      _commandController.clear();
      return;
    }
    
    setState(() {
      _output.add('\$ $command');
    });
    
    // Check if this is a special command to exit interactive mode
    if (command.toLowerCase() == 'exit' && _sshService.isInteractiveSessionActive) {
      _sshService.stopInteractiveSession();
      setState(() {
        _isInteractiveMode = false;
        _output.add('Exited interactive mode');
      });
      _commandController.clear();
      return;
    }
    
    // Execute the command on the SSH server
    final result = await _sshService.executeCommand(
      command,
      _isInteractiveCommand(command) ? _handleInteractiveOutput : null,
    );
    
    setState(() {
      if (result != null) {
        // Check if we started an interactive session
        if (_sshService.isInteractiveSessionActive && !_isInteractiveMode) {
          _isInteractiveMode = true;
          _output.add('Entered interactive mode. Type "exit" to exit.');
        } else if (result.isEmpty) {
          // Command executed successfully but produced no output
          _output.add('Command executed successfully');
        } else {
          // Split the result by newlines and add each line to the output
          final lines = result.split('\n');
          // Include all lines, even empty ones, to preserve formatting
          _output.addAll(lines);
        }
      } else {
        // This case happens when there's a connection issue
        _output.add('Error executing command - connection may be lost');
      }
    });
    
    _commandController.clear();
    
    // Scroll to the bottom of the output
    _scrollToBottom();
  }
  
  // Check if a command is interactive (requires PTY)
  bool _isInteractiveCommand(String command) {
    // Extract the base command (without arguments)
    final baseCommand = command.split(' ').first.trim();
    
    // List of known interactive commands
    const interactiveCommands = [
      'top', 'htop', 'vi', 'vim', 'nano', 'less', 'more',
      'tail', 'watch', 'screen', 'tmux', 'emacs', 'pico',
      'joe', 'jed', 'mc', 'lynx', 'links', 'elinks'
    ];
    
    return interactiveCommands.contains(baseCommand);
  }
  
  Future<void> _disconnect() async {
    if (_isConnected) {
      await _sshService.disconnect();
      
      // Only call setState if the widget is still mounted
      if (mounted) {
        setState(() {
          _isConnected = false;
          _output.clear();
        });
      } else {
        // If not mounted, just update the variables without setState
        _isConnected = false;
        _output.clear();
      }
    }
  }
}
