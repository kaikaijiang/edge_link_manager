import 'package:flutter/material.dart';

/*
 * VNC Service
 * 
 * This service manages the VNC connection state.
 * 
 * Note: The custom mouse handling for UINPUT has been removed as the VNC server
 * no longer uses the -pipeinput UINPUT:direct_abs option. Mouse events are now
 * handled directly by the flutter_rfb package.
 */

// Service class for managing VNC connection state
class VncService {
  // Connection state
  bool _isConnected = false;
  String? _hostname;
  int? _port;
  String? _password;
  
  // Set connection parameters
  void setConnectionParams({
    required String hostname,
    required int port,
    required String password,
  }) {
    _hostname = hostname;
    _port = port;
    _password = password;
  }
  
  // Get connection parameters
  String? get hostname => _hostname;
  int? get port => _port;
  String? get password => _password;
  
  // Set connection state
  void setConnected(bool connected) {
    _isConnected = connected;
  }
  
  // Check if connected to VNC server
  bool get isConnected => _isConnected;
  
  // Clear connection data
  void disconnect() {
    _isConnected = false;
  }
  
  // Note: Custom mouse handling methods have been removed as they are no longer needed.
  // Mouse events are now handled directly by the flutter_rfb package.
}
