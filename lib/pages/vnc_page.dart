import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edge_link_manager/models/settings_provider.dart';
import 'package:edge_link_manager/services/ssh_service.dart';
import 'package:edge_link_manager/services/vnc_service.dart';
import 'package:flutter_rfb/flutter_rfb.dart';

class VncPage extends StatefulWidget {
  const VncPage({super.key});

  @override
  State<VncPage> createState() => _VncPageState();
}

class _VncPageState extends State<VncPage> {
  // VNC connection state
  bool _isVncConnected = false;
  final VncService _vncService = VncService();
  String? _vncHost;
  String? _vncPassword;
  int _vncPort = 5900;
  
  // SSH service for MQTT commands
  final SshService _sshService = SshService();
  bool _isSshConnected = false;
  
  // MQTT state
  final TextEditingController _mqttTopicController = TextEditingController();
  final TextEditingController _mqttValueController = TextEditingController();
  final List<String> _mqttTopics = ['None', 'CMT/GUI/I/PageIndex/Num/RAW', 'CMT/GUI/I/UpdateTagGlobalPara/Num/RAW', 'CMT/GUI/I/UpdateTagRecipePara/Num/RAW', 'CMT/General/O/MachineStatus/Num/RAW',
                                    'CMT/General/I/ManuelMode/Num/RAW', 'CMT/General/I/MachineSpeed/Num/PEC', 'CMT/General/I/TriangleBase/Num/mm', 'CMT/General/I/TriangleHeight/Num/mm', 'CMT/General/I/TriangleTip/Num/mm',
                                    'CMT/Calibrator/I/DelayRockerInfeedReleased/Num/s', 'CMT/Calibrator/I/DelayRockerInfeedPressed/Num/s', 'CMT/Calibrator/I/DelayRockerOutfeedReleased/Num/s','CMT/Calibrator/I/DelayRockerOutfeedPressed/Num/s',
                                    'CMT/Calibrator/O/ActGap/Num/mm'];
  String _selectedTopic = 'None';
  List<String> _mqttMessages = [];
  bool _isSubscribed = false;
  
  // Variables to track click feedback animation
  bool _showClickFeedback = false;
  int _clickX = 0;
  int _clickY = 0;
  
  // Position offset correction values
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  
  // Variables to track mouse movement and throttle events
  int _lastMouseX = -1;
  int _lastMouseY = -1;
  DateTime _lastMouseMoveTime = DateTime.now();
  
  @override
  void dispose() {
    _mqttTopicController.dispose();
    _mqttValueController.dispose();
    _vncService.disconnect();
    _sshService.disconnect();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel - VNC viewer
        Expanded(
          flex: 3,
          child: Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'VNC Viewer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                  ),
                  const SizedBox(height: 16),
                  
                  if (!_isVncConnected) ...[
                    const Expanded(
                      child: Center(
                        child: Text(
                          'VNC viewer will be displayed here after connection',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                          maxLines: 2, // Allow up to 2 lines before truncating
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _connectVnc,
                      icon: const Icon(Icons.connect_without_contact),
                      label: const Text(
                        'Connect to VNC',
                        overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SizedBox(
                              width: 1280,
                              height: 800,
                              child: _buildVncViewer(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _disconnectVnc,
                            icon: const Icon(Icons.close),
                            label: const Text(
                              'Disconnect',
                              overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        
        // Right panel - MQTT
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Top half - MQTT publisher
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'MQTT Publisher',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                        ),
                        const SizedBox(height: 16),
                        
                        // Topic dropdown
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Topic',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          isExpanded: true, // Make the dropdown take up all available space
                          value: _selectedTopic,
                          items: _mqttTopics.map((String topic) {
                            return DropdownMenuItem<String>(
                              value: topic,
                              child: Text(
                                topic,
                                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedTopic = newValue;
                                _mqttTopicController.text = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // Topic text field
                        TextField(
                          controller: _mqttTopicController,
                          decoration: const InputDecoration(
                            labelText: 'Topic',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            // Ensure the label doesn't overflow
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                          // Allow text to scroll if it's too long
                          scrollPhysics: const ClampingScrollPhysics(),
                        ),
                        const SizedBox(height: 12),
                        
                        // Value text field
                        TextField(
                          controller: _mqttValueController,
                          decoration: const InputDecoration(
                            labelText: 'Value',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            // Ensure the label doesn't overflow
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                          ),
                          // Allow text to scroll if it's too long
                          scrollPhysics: const ClampingScrollPhysics(),
                        ),
                        const SizedBox(height: 12),
                        
                        // Send button
                        ElevatedButton.icon(
                          onPressed: _publishMqttMessage,
                          icon: const Icon(Icons.send),
                          label: const Text(
                            'Send',
                            overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom half - MQTT subscriber
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Use Expanded widgets in the Row to prevent overflow
                        Row(
                          children: [
                            // Title with Expanded to take available space
                            const Expanded(
                              child: Text(
                                'MQTT Messages',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Toggle button for subscription
                            ElevatedButton.icon(
                              onPressed: _toggleMqttSubscription,
                              icon: Icon(_isSubscribed ? Icons.stop : Icons.play_arrow),
                              label: Text(
                                _isSubscribed ? 'Stop' : 'Start',
                                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSubscribed ? Colors.red : Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: _isSubscribed 
                              ? ListView.builder(
                                  itemCount: _mqttMessages.length,
                                  reverse: true,
                                  itemBuilder: (context, index) {
                                    final reversedIndex = _mqttMessages.length - 1 - index;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Text(
                                        _mqttMessages[reversedIndex],
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                        maxLines: 2, // Allow up to 2 lines before truncating
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'Click Start to subscribe to MQTT messages',
                                    style: TextStyle(color: Colors.white70),
                                    textAlign: TextAlign.center, // Center align text
                                    overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
                                    maxLines: 2, // Allow up to 2 lines before truncating
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Build the VNC viewer widget
  Widget _buildVncViewer() {
    // Use the RemoteFrameBufferWidget directly without custom mouse handling overlay
    // This allows the flutter_rfb package to handle mouse events natively
    return RemoteFrameBufferWidget(
      hostName: _vncHost!,
      password: _vncPassword!,
      port: _vncPort,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('VNC Error: $error')),
        );
        setState(() {
          _isVncConnected = false;
          _vncService.disconnect();
        });
      },
    );
  }
  
  // Note: Custom mouse handling methods (_handleMouseMove and _handleMouseClick) have been removed
  // as we're now using the native mouse handling from the flutter_rfb package
  
  // Connect to VNC server
  Future<void> _connectVnc() async {
    // Get settings provider
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Get VNC connection details from settings
    String? vncHost;
    if (settingsProvider.hostHistory.isNotEmpty) {
      vncHost = settingsProvider.hostHistory.first;
    }
    
    if (vncHost == null || vncHost.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set Edge Device IP in Settings first')),
      );
      return;
    }
    
    final vncPort = 5900; // Fixed port as per requirements
    final vncPassword = settingsProvider.vncPassword;
    
    if (vncPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set VNC Password in Settings first')),
      );
      return;
    }
    
    // SSH connection details from settings (using same host as VNC)
    final sshHost = vncHost;
    final sshPort = settingsProvider.sshPort;
    final sshUsername = settingsProvider.sshUsername;
    final sshPassword = settingsProvider.sshPassword;
    
    // Save to history
    settingsProvider.addHostToHistory(vncHost);
    
    // Store VNC connection parameters
    _vncService.setConnectionParams(
      hostname: vncHost,
      port: vncPort,
      password: vncPassword,
      // No longer passing SSH service for input handling as we're using native mouse handling
    );
    
    // Show connection details in a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to VNC at $vncHost:$vncPort')),
    );
    
    // Connect to SSH for MQTT commands
    final sshConnected = await _sshService.connect(
      host: sshHost,
      port: sshPort,
      username: sshUsername,
      password: sshPassword,
    );
    
    setState(() {
      _vncHost = vncHost;
      _vncPassword = vncPassword;
      _vncPort = vncPort;
      _isVncConnected = true;
      _isSshConnected = sshConnected;
      _vncService.setConnected(true);
    });
    
    if (sshConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to VNC and SSH')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to VNC, but SSH connection failed')),
      );
    }
  }
  
  // Disconnect from VNC server
  Future<void> _disconnectVnc() async {
    // Disconnect VNC
    _vncService.disconnect();
    
    // Stop MQTT subscription if active
    if (_isSubscribed) {
      await _sshService.stopMqttSubscription();
      _isSubscribed = false;
    }
    
    // Disconnect SSH
    await _sshService.disconnect();
    
    setState(() {
      _isVncConnected = false;
      _isSshConnected = false;
      _mqttMessages.clear();
      _vncHost = null;
      _vncPassword = null;
      _vncPort = 5900;
      
      // Reset mouse tracking variables
      _lastMouseX = -1;
      _lastMouseY = -1;
      _lastMouseMoveTime = DateTime.now();
      
      // Reset click feedback variables
      _showClickFeedback = false;
      _clickX = 0;
      _clickY = 0;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Disconnected from VNC and SSH')),
    );
  }
  
  // Publish MQTT message
  Future<void> _publishMqttMessage() async {
    // Check if SSH is connected
    if (!_isSshConnected) {
      // Try to connect to SSH if not already connected
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      String? host;
      if (settingsProvider.hostHistory.isNotEmpty) {
        host = settingsProvider.hostHistory.first;
      }
      
      if (host == null || host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set Edge Device IP in Settings first')),
        );
        return;
      }
      
      final sshPort = settingsProvider.sshPort;
      final sshUsername = settingsProvider.sshUsername;
      final sshPassword = settingsProvider.sshPassword;
      
      final sshConnected = await _sshService.connect(
        host: host,
        port: sshPort,
        username: sshUsername,
        password: sshPassword,
      );
      
      setState(() {
        _isSshConnected = sshConnected;
      });
      
      if (!sshConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to SSH. Check your settings.')),
        );
        return;
      }
    }
    
    // Get topic and value from text fields
    final topic = _mqttTopicController.text.trim();
    final value = _mqttValueController.text.trim();
    
    if (topic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an MQTT topic')),
      );
      return;
    }
    
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value to publish')),
      );
      return;
    }
    
    // Publish the message
    final success = await _sshService.publishMqttMessage(topic, value);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Published "$value" to topic "$topic"')),
      );
      
      // Clear the value field but keep the topic
      _mqttValueController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to publish MQTT message')),
      );
    }
  }
  
  // Toggle MQTT subscription
  Future<void> _toggleMqttSubscription() async {
    // If already subscribed, stop the subscription
    if (_isSubscribed) {
      await _sshService.stopMqttSubscription();
      setState(() {
        _isSubscribed = false;
      });
      return;
    }
    
    // Check if SSH is connected
    if (!_isSshConnected) {
      // Try to connect to SSH if not already connected
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      String? host;
      if (settingsProvider.hostHistory.isNotEmpty) {
        host = settingsProvider.hostHistory.first;
      }
      
      if (host == null || host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please set Edge Device IP in Settings first')),
        );
        return;
      }
      
      final sshPort = settingsProvider.sshPort;
      final sshUsername = settingsProvider.sshUsername;
      final sshPassword = settingsProvider.sshPassword;
      
      final sshConnected = await _sshService.connect(
        host: host,
        port: sshPort,
        username: sshUsername,
        password: sshPassword,
      );
      
      setState(() {
        _isSshConnected = sshConnected;
      });
      
      if (!sshConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to SSH. Check your settings.')),
        );
        return;
      }
    }
    
    // Clear previous messages
    setState(() {
      _mqttMessages.clear();
    });
    
    // Start the subscription
    await _sshService.startMqttSubscription((message) {
      setState(() {
        // Add the message to the list
        _mqttMessages.add(message);
        
        // Limit the number of messages to prevent memory issues
        if (_mqttMessages.length > 100) {
          _mqttMessages.removeAt(0);
        }
      });
    });
    
    setState(() {
      _isSubscribed = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('MQTT subscription started')),
    );
  }
}
