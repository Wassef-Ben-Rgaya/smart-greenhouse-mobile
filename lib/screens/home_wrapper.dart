import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ai_prediction_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'grafana_webview_screen.dart';
import 'manual_control_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AnalyticsDashboardScreen(),
    const ManualControlScreen(),
    const AIPredictionScreen(),
    const GrafanaWebviewScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Greenhouse"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_remote),
            label: 'Manuel',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'IA'),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Grafana',
          ),
        ],
      ),
    );
  }
}
