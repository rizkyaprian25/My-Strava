import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/error_boundary.dart';
import 'features/shell/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi format tanggal dan angka bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const MyStravaApp());
}

/// Root widget aplikasi My Strava.
class MyStravaApp extends StatelessWidget {
  const MyStravaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalErrorBoundary(
      child: MaterialApp(
        title: 'My Strava',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
