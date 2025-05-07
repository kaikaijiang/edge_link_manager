import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _hostHistoryKey = 'host_history';
  static const String _sshUsernameKey = 'ssh_username';
  static const String _sshPasswordKey = 'ssh_password';
  static const String _sshPortKey = 'ssh_port';
  static const String _vncPasswordKey = 'vnc_password';
  static const String _dbUsernameKey = 'db_username';
  static const String _dbPasswordKey = 'db_password';
  
  // Save theme mode (0 = system, 1 = light, 2 = dark)
  Future<void> saveThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode);
  }
  
  // Get theme mode
  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeKey) ?? 0; // Default to system theme
  }
  
  // Save host to history
  Future<void> saveHostToHistory(String host) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_hostHistoryKey) ?? [];
    
    // Remove if exists (to avoid duplicates) and add to the beginning
    if (history.contains(host)) {
      history.remove(host);
    }
    history.insert(0, host);
    
    // Keep only the last 10 entries
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await prefs.setStringList(_hostHistoryKey, history);
  }
  
  // Get host history
  Future<List<String>> getHostHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_hostHistoryKey) ?? [];
  }
  
  // Clear host history
  Future<void> clearHostHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hostHistoryKey, []);
  }
  
  // SSH Credentials
  
  // Save SSH username
  Future<void> saveSshUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sshUsernameKey, username);
  }
  
  // Get SSH username
  Future<String> getSshUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sshUsernameKey) ?? 'user'; // Default username
  }
  
  // Save SSH password
  Future<void> saveSshPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sshPasswordKey, password);
  }
  
  // Get SSH password
  Future<String> getSshPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sshPasswordKey) ?? 'password'; // Default password
  }
  
  // Save SSH port
  Future<void> saveSshPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sshPortKey, port);
  }
  
  // Get SSH port
  Future<int> getSshPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sshPortKey) ?? 22; // Default SSH port
  }
  
  // VNC Credentials
  
  // Save VNC password
  Future<void> saveVncPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vncPasswordKey, password);
  }
  
  // Get VNC password
  Future<String> getVncPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vncPasswordKey) ?? ''; // Default empty password
  }
  
  // Database Credentials
  
  // Save DB username
  Future<void> saveDbUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbUsernameKey, username);
  }
  
  // Get DB username
  Future<String> getDbUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dbUsernameKey) ?? ''; // Default empty username
  }
  
  // Save DB password
  Future<void> saveDbPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dbPasswordKey, password);
  }
  
  // Get DB password
  Future<String> getDbPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dbPasswordKey) ?? ''; // Default empty password
  }
}
