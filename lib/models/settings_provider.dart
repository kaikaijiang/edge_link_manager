import 'package:flutter/material.dart';
import 'package:edge_link_manager/services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  
  ThemeMode _themeMode = ThemeMode.system;
  List<String> _hostHistory = [];
  String _sshUsername = 'user';
  String _sshPassword = 'password';
  int _sshPort = 22;
  String _vncPassword = '';
  String _dbUsername = '';
  String _dbPassword = '';
  
  ThemeMode get themeMode => _themeMode;
  List<String> get hostHistory => _hostHistory;
  String get sshUsername => _sshUsername;
  String get sshPassword => _sshPassword;
  int get sshPort => _sshPort;
  String get vncPassword => _vncPassword;
  String get dbUsername => _dbUsername;
  String get dbPassword => _dbPassword;
  
  SettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final themeMode = await _settingsService.getThemeMode();
    _themeMode = _getThemeModeFromInt(themeMode);
    
    _hostHistory = await _settingsService.getHostHistory();
    _sshUsername = await _settingsService.getSshUsername();
    _sshPassword = await _settingsService.getSshPassword();
    _sshPort = await _settingsService.getSshPort();
    _vncPassword = await _settingsService.getVncPassword();
    _dbUsername = await _settingsService.getDbUsername();
    _dbPassword = await _settingsService.getDbPassword();
    
    notifyListeners();
  }
  
  ThemeMode _getThemeModeFromInt(int mode) {
    switch (mode) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  int _getIntFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _settingsService.saveThemeMode(_getIntFromThemeMode(mode));
    notifyListeners();
  }
  
  Future<void> addHostToHistory(String host) async {
    await _settingsService.saveHostToHistory(host);
    _hostHistory = await _settingsService.getHostHistory();
    notifyListeners();
  }
  
  Future<void> clearHostHistory() async {
    await _settingsService.clearHostHistory();
    _hostHistory = [];
    notifyListeners();
  }
  
  // SSH Credentials
  
  Future<void> setSshUsername(String username) async {
    if (_sshUsername == username) return;
    
    _sshUsername = username;
    await _settingsService.saveSshUsername(username);
    notifyListeners();
  }
  
  Future<void> setSshPassword(String password) async {
    if (_sshPassword == password) return;
    
    _sshPassword = password;
    await _settingsService.saveSshPassword(password);
    notifyListeners();
  }
  
  Future<void> setSshPort(int port) async {
    if (_sshPort == port) return;
    
    _sshPort = port;
    await _settingsService.saveSshPort(port);
    notifyListeners();
  }
  
  // VNC Credentials
  
  Future<void> setVncPassword(String password) async {
    if (_vncPassword == password) return;
    
    _vncPassword = password;
    await _settingsService.saveVncPassword(password);
    notifyListeners();
  }
  
  // Database Credentials
  
  Future<void> setDbUsername(String username) async {
    if (_dbUsername == username) return;
    
    _dbUsername = username;
    await _settingsService.saveDbUsername(username);
    notifyListeners();
  }
  
  Future<void> setDbPassword(String password) async {
    if (_dbPassword == password) return;
    
    _dbPassword = password;
    await _settingsService.saveDbPassword(password);
    notifyListeners();
  }
}
