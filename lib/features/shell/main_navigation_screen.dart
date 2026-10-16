import 'package:flutter/material.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../history/presentation/history_screen.dart';
import '../recorder/presentation/recorder_screen.dart';

/// App Shell utama dengan navigasi Bottom Navigation Bar bergaya Apple HIG / Strava Sports.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final GlobalKey<DashboardScreenState> _dashboardKey =
      GlobalKey<DashboardScreenState>();
  final GlobalKey<HistoryScreenState> _historyKey =
      GlobalKey<HistoryScreenState>();

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      _dashboardKey.currentState?.loadDashboardData();
    } else if (index == 2) {
      _historyKey.currentState?.loadActivities();
    }
  }

  void _onActivitySaved() {
    _dashboardKey.currentState?.loadDashboardData();
    _historyKey.currentState?.loadActivities();
    // Beralih ke tab Riwayat untuk langsung melihat sesi yang baru disimpan
    _onTabSelected(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            key: _dashboardKey,
            onStartRecordingTap: () => _onTabSelected(1),
          ),
          RecorderScreen(
            onActivitySaved: _onActivitySaved,
          ),
          HistoryScreen(
            key: _historyKey,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked),
            activeIcon: Icon(Icons.radio_button_checked),
            label: 'Rekam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_outlined),
            activeIcon: Icon(Icons.format_list_bulleted),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
