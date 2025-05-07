import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edge_link_manager/models/navigation_provider.dart';
import 'package:edge_link_manager/models/settings_provider.dart';
import 'package:edge_link_manager/pages/vnc_page.dart';
import 'package:edge_link_manager/pages/diagnose_page.dart';
import 'package:edge_link_manager/pages/tools_page.dart';
import 'package:edge_link_manager/pages/ssh_page.dart';
import 'package:edge_link_manager/pages/settings_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return MaterialApp(
      title: 'Edge Link Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: settingsProvider.themeMode,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentIndex = navigationProvider.currentIndex;
    
    // List of pages to display
    final pages = [
      const VncPage(),
      const DiagnosePage(),
      const ToolsPage(),
      const SshPage(),
      const SettingsPage(),
    ];
    
    // List of app bar titles
    final titles = [
      'VNC Connection',
      'Network Diagnostics',
      'Network Tools',
      'SSH Connection',
      'Settings',
    ];
    
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          navigationProvider.setIndex(index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.desktop_windows),
            label: 'VNC',
          ),
          NavigationDestination(
            icon: Icon(Icons.network_check),
            label: 'Diagnose',
          ),
          NavigationDestination(
            icon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            label: 'SSH',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
