import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

// Regular expression to match ANSI escape sequences only (not other control characters)
final RegExp _ansiEscapePattern = RegExp(
  r'\x1B(?:[@-Z\\-_]|\[[0-9?;]*[0-9A-Za-z]|\].*?(?:\x1B\\|[\a\x07]))'
);

// Helper function to strip ANSI escape sequences from a string (preserves newlines and other formatting)
String stripAnsiEscapes(String text) {
  return text.replaceAll(_ansiEscapePattern, '');
}

// Helper function to clean up top command output
String cleanTopOutput(String text) {
  // First strip ANSI escape sequences but preserve newlines
  String cleaned = stripAnsiEscapes(text);
  
  // Remove any remaining control characters except newlines and carriage returns
  cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F\x7F]'), '');
  
  // Replace carriage returns with newlines if they're not followed by a newline
  cleaned = cleaned.replaceAll(RegExp(r'\r(?!\n)'), '\n');
  
  // Fix any broken lines (lines that might have been split by control characters)
  List<String> lines = cleaned.split('\n');
  List<String> fixedLines = [];
  
  for (String line in lines) {
    // Skip completely empty lines
    if (line.isEmpty) continue;
    
    // Keep lines with content, even if it's just whitespace
    fixedLines.add(line);
  }
  
  return fixedLines.join('\n');
}

class SshService {
  SSHClient? _client;
  SSHSession? _subscriptionSession;
  SSHSession? _interactiveSession;
  bool _isConnected = false;
  bool _isInteractiveSessionActive = false;
  
  bool get isConnected => _isConnected;
  bool get isInteractiveSessionActive => _isInteractiveSessionActive;
  
  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }
  
  Future<void> disconnect() async {
    stopInteractiveSession();
    
    if (_subscriptionSession != null) {
      _subscriptionSession!.close();
      _subscriptionSession = null;
    }
    
    if (_client != null) {
      _client!.close();
      _client = null;
    }
    
    _isConnected = false;
  }
  
  // Start an interactive session with PTY allocation
  Future<bool> startInteractiveSession(
    String command,
    Function(String) onOutput,
  ) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    // Close any existing interactive session
    stopInteractiveSession();
    
    try {
      // Create a session with PTY allocation
      _interactiveSession = await _client!.shell(
        pty: SSHPtyConfig(
          width: 80,
          height: 24,
        ),
      );
      
      _isInteractiveSessionActive = true;
      
      // Check if this is the top command
      final isTopCommand = command.trim() == "top" || command.startsWith("top ");
      
      // Set up a listener for the session output
      // Use latin1 decoder for better compatibility with terminal output
      _interactiveSession!.stdout.listen((data) {
        try {
          // Try UTF-8 first
          final line = utf8.decode(data, allowMalformed: true);
          
          // Use special cleaning for top command
          if (isTopCommand) {
            onOutput(cleanTopOutput(line));
          } else {
            // Strip ANSI escape sequences before sending to output
            onOutput(stripAnsiEscapes(line));
          }
        } catch (e) {
          // Fall back to latin1 if UTF-8 fails
          try {
            final line = latin1.decode(data);
            
            // Use special cleaning for top command
            if (isTopCommand) {
              onOutput(cleanTopOutput(line));
            } else {
              // Strip ANSI escape sequences before sending to output
              onOutput(stripAnsiEscapes(line));
            }
          } catch (e) {
            // If all else fails, just show the raw bytes as hex
            onOutput('[Binary data: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}]');
          }
        }
      });
      
      // Also listen for stderr
      _interactiveSession!.stderr.listen((data) {
        try {
          // Try UTF-8 first
          final line = utf8.decode(data, allowMalformed: true);
          // Strip ANSI escape sequences before sending to output
          onOutput('Error: ${stripAnsiEscapes(line)}');
        } catch (e) {
          // Fall back to latin1 if UTF-8 fails
          try {
            final line = latin1.decode(data);
            // Strip ANSI escape sequences before sending to output
            onOutput('Error: ${stripAnsiEscapes(line)}');
          } catch (e) {
            // If all else fails, just show the raw bytes as hex
            onOutput('Error: [Binary data: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}]');
          }
        }
      });
      
      // Send the initial command
      sendInput(command + '\n');
      
      return true;
    } catch (e) {
      print("Error starting interactive session: $e");
      _isInteractiveSessionActive = false;
      return false;
    }
  }
  
  // Send input to the interactive session
  void sendInput(String input) {
    if (_isInteractiveSessionActive && _interactiveSession != null) {
      try {
        _interactiveSession!.stdin.add(utf8.encode(input));
      } catch (e) {
        print("Error sending input to interactive session: $e");
      }
    }
  }
  
  // Stop the interactive session
  void stopInteractiveSession() {
    if (_interactiveSession != null) {
      try {
        // Send CTRL+C to terminate any running command
        _interactiveSession!.stdin.add(utf8.encode('\x03'));
        // Wait a bit and then close the session
        Future.delayed(const Duration(milliseconds: 100), () {
          _interactiveSession!.close();
          _interactiveSession = null;
          _isInteractiveSessionActive = false;
        });
      } catch (e) {
        print("Error stopping interactive session: $e");
        _interactiveSession = null;
        _isInteractiveSessionActive = false;
      }
    }
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
  
  // Execute a command, handling both interactive and non-interactive commands
  Future<String?> executeCommand(String command, [Function(String)? onInteractiveOutput]) async {
    if (!_isConnected || _client == null) {
      return null;
    }
    
    try {
      print("Executing command: $command");
      
      // Check if this is an interactive command
      if (_isInteractiveCommand(command)) {
        if (onInteractiveOutput != null) {
          // Start an interactive session for this command
          final success = await startInteractiveSession(command, onInteractiveOutput);
          if (success) {
            return "Started interactive session for '$command'.\nUse the input field to interact with the command.";
          } else {
            return "Failed to start interactive session for '$command'.";
          }
        } else {
          // If no callback is provided for interactive output, show a message
          final baseCommand = command.split(' ').first.trim();
          return "Interactive command '$baseCommand' requires special handling.\n"
                 "Please use the interactive terminal feature for this command.";
        }
      }
      
      // For common commands that should produce output, add special handling
      if (command == "ls") {
        return _executeListCommand();
      } else if (command.startsWith("ls ")) {
        return _executeListCommand(command);
      }
      
      // For all other commands
      return _executeStandardCommand(command);
    } catch (e) {
      print("Error executing command '$command': $e");
      return 'Error: $e';
    }
  }
  
  Future<String> _executeListCommand([String? fullCommand]) async {
    try {
      // Use a more reliable command to list files
      final command = fullCommand ?? "ls -la";
      
      // First get the current directory for context
      final pwdSession = await _client!.execute("pwd");
      
      // Collect PWD output
      final pwdData = <int>[];
      final pwdCompleter = Completer<void>();
      
      pwdSession.stdout.listen(
        (data) {
          pwdData.addAll(data);
        },
        onDone: () {
          pwdCompleter.complete();
        },
        onError: (e) {
          print("Error reading pwd stdout: $e");
          if (!pwdCompleter.isCompleted) pwdCompleter.complete();
        },
      );
      
      await pwdCompleter.future;
      pwdSession.close();
      
      // Decode the PWD output
      String currentDir = "";
      if (pwdData.isNotEmpty) {
        try {
          currentDir = utf8.decode(pwdData, allowMalformed: true).trim();
        } catch (e) {
          try {
            currentDir = latin1.decode(pwdData).trim();
          } catch (e) {
            currentDir = "[Unknown directory]";
          }
        }
      }
      
      // Then execute the ls command
      final lsSession = await _client!.execute(command);
      
      // Collect LS output
      final lsStdoutData = <int>[];
      final lsStderrData = <int>[];
      
      final lsStdoutCompleter = Completer<void>();
      final lsStderrCompleter = Completer<void>();
      
      lsSession.stdout.listen(
        (data) {
          lsStdoutData.addAll(data);
        },
        onDone: () {
          lsStdoutCompleter.complete();
        },
        onError: (e) {
          print("Error reading ls stdout: $e");
          if (!lsStdoutCompleter.isCompleted) lsStdoutCompleter.complete();
        },
      );
      
      lsSession.stderr.listen(
        (data) {
          lsStderrData.addAll(data);
        },
        onDone: () {
          lsStderrCompleter.complete();
        },
        onError: (e) {
          print("Error reading ls stderr: $e");
          if (!lsStderrCompleter.isCompleted) lsStderrCompleter.complete();
        },
      );
      
      await Future.wait([lsStdoutCompleter.future, lsStderrCompleter.future]);
      lsSession.close();
      
      // Decode the LS output
      String stdoutOutput = "";
      String stderrOutput = "";
      
      if (lsStdoutData.isNotEmpty) {
        try {
          // Decode and strip ANSI escape sequences
          stdoutOutput = stripAnsiEscapes(utf8.decode(lsStdoutData, allowMalformed: true));
        } catch (e) {
          try {
            // Fall back to latin1 if UTF-8 fails
            stdoutOutput = stripAnsiEscapes(latin1.decode(lsStdoutData));
          } catch (e) {
            stdoutOutput = "[Binary data: ${lsStdoutData.length} bytes]";
          }
        }
      }
      
      if (lsStderrData.isNotEmpty) {
        try {
          // Decode and strip ANSI escape sequences
          stderrOutput = stripAnsiEscapes(utf8.decode(lsStderrData, allowMalformed: true));
        } catch (e) {
          try {
            // Fall back to latin1 if UTF-8 fails
            stderrOutput = stripAnsiEscapes(latin1.decode(lsStderrData));
          } catch (e) {
            stderrOutput = "[Binary data: ${lsStderrData.length} bytes]";
          }
        }
      }
      
      print("PWD result: '$currentDir'");
      print("LS stdout: '$stdoutOutput'");
      print("LS stderr: '$stderrOutput'");
      
      // Combine the outputs
      final result = [
        "Current directory: $currentDir",
        if (stderrOutput.isNotEmpty) stderrOutput,
        if (stdoutOutput.isNotEmpty) stdoutOutput else "(No files found)",
      ].join('\n');
      
      return result;
    } catch (e) {
      print("Error in _executeListCommand: $e");
      return "Error listing files: $e";
    }
  }
  
  Future<String> _executeStandardCommand(String command) async {
    try {
      final session = await _client!.execute(command);
      
      // Collect all stdout data
      final stdoutData = <int>[];
      final stderrData = <int>[];
      
      // Set up listeners for stdout and stderr
      final stdoutCompleter = Completer<void>();
      final stderrCompleter = Completer<void>();
      
      session.stdout.listen(
        (data) {
          stdoutData.addAll(data);
        },
        onDone: () {
          stdoutCompleter.complete();
        },
        onError: (e) {
          print("Error reading stdout: $e");
          if (!stdoutCompleter.isCompleted) stdoutCompleter.complete();
        },
      );
      
      session.stderr.listen(
        (data) {
          stderrData.addAll(data);
        },
        onDone: () {
          stderrCompleter.complete();
        },
        onError: (e) {
          print("Error reading stderr: $e");
          if (!stderrCompleter.isCompleted) stderrCompleter.complete();
        },
      );
      
      // Wait for both streams to complete
      await Future.wait([stdoutCompleter.future, stderrCompleter.future]);
      
      // Decode the collected data
      String stdoutOutput = "";
      String stderrOutput = "";
      
      if (stdoutData.isNotEmpty) {
        try {
          // Decode and strip ANSI escape sequences
          stdoutOutput = stripAnsiEscapes(utf8.decode(stdoutData, allowMalformed: true));
        } catch (e) {
          try {
            // Fall back to latin1 if UTF-8 fails
            stdoutOutput = stripAnsiEscapes(latin1.decode(stdoutData));
          } catch (e) {
            stdoutOutput = "[Binary data: ${stdoutData.length} bytes]";
          }
        }
      }
      
      if (stderrData.isNotEmpty) {
        try {
          // Decode and strip ANSI escape sequences
          stderrOutput = stripAnsiEscapes(utf8.decode(stderrData, allowMalformed: true));
        } catch (e) {
          try {
            // Fall back to latin1 if UTF-8 fails
            stderrOutput = stripAnsiEscapes(latin1.decode(stderrData));
          } catch (e) {
            stderrOutput = "[Binary data: ${stderrData.length} bytes]";
          }
        }
      }
      
      // Log the outputs for debugging
      print("Command: $command");
      print("Stdout: '$stdoutOutput'");
      print("Stderr: '$stderrOutput'");
      
      // Combine the outputs (stderr first, then stdout)
      final combinedOutput = [
        if (stderrOutput.isNotEmpty) stderrOutput,
        if (stdoutOutput.isNotEmpty) stdoutOutput,
      ].join('\n');
      
      session.close();
      // Return empty string instead of null for successful commands with no output
      return combinedOutput.isNotEmpty ? combinedOutput : "Command executed successfully (no output)";
    } catch (e) {
      print("Error in _executeStandardCommand: $e");
      return "Error: $e";
    }
  }
  
  Future<bool> publishMqttMessage(String topic, String message) async {
    if (!_isConnected || _client == null) {
      return false;
    }
    
    try {
      final command = 'mosquitto_pub -t "$topic" -m "$message"';
      final result = await executeCommand(command);
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> startMqttSubscription(Function(String) onMessage) async {
    if (!_isConnected || _client == null) {
      return;
    }
    
    // Close any existing subscription
    if (_subscriptionSession != null) {
      _subscriptionSession!.close();
    }
    
    try {
      _subscriptionSession = await _client!.execute('mosquitto_sub -v -t "#"');
      
      // Set up a listener for the session output with improved encoding handling
      _subscriptionSession!.stdout.listen((data) {
        try {
          // Try UTF-8 first
          final line = utf8.decode(data, allowMalformed: true);
          if (line.isNotEmpty) {
            // Strip ANSI escape sequences before sending to output
            onMessage(stripAnsiEscapes(line));
          }
        } catch (e) {
          // Fall back to latin1 if UTF-8 fails
          try {
            final line = latin1.decode(data);
            if (line.isNotEmpty) {
              // Strip ANSI escape sequences before sending to output
              onMessage(stripAnsiEscapes(line));
            }
          } catch (e) {
            // If all else fails, just show the raw bytes as hex
            onMessage('[Binary data: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}]');
          }
        }
      });
    } catch (e) {
      print("Error starting MQTT subscription: $e");
    }
  }
  
  Future<void> stopMqttSubscription() async {
    if (_subscriptionSession != null) {
      _subscriptionSession!.close();
      _subscriptionSession = null;
    }
  }
}
