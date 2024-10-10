// lib/pages/main_page.dart

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'configuration_list_page.dart';
import 'connection_history_page.dart';
import 'configuration_edit_page.dart'; // Import if needed
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0; // Tracks the selected tab

  // Initialize all pages here to keep their state
  late final List<Widget> _pages = <Widget>[
    HomePage(
      onNavigate: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
    ConfigurationListPage(
      onNavigate: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
    const ConnectionHistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter VPN App'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Servers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue, // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 1 // Show FAB only on Servers tab
          ? FloatingActionButton(
              onPressed: appState.isConnected
                  ? null // Disable FAB when connected
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfigurationEditPage(),
                        ),
                      );
                    },
              tooltip: appState.isConnected
                  ? 'Cannot add while connected'
                  : 'Add Configuration',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
