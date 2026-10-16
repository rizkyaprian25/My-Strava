import 'package:flutter/material.dart';

/// Design tokens dan tema aplikasi My Strava berakar pada Apple HIG & Strava Orange.
class AppTheme {
  // Palet Warna Khas Strava Sports & Apple Dark Theme
  static const Color stravaOrange = Color(0xFFFC5200);
  static const Color stravaOrangeDark = Color(0xFFE04500);
  static const Color darkBackground = Color(0xFF111113);
  static const Color cardSurface = Color(0xFF1D1D21);
  static const Color cardSurfaceLight = Color(0xFF28282E);
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accentGreen = Color(0xFF34C759); // Apple Success Green
  static const Color accentRed = Color(0xFFFF3B30); // Apple Danger Red
  static const Color accentAmber = Color(0xFFFF9500); // Apple Warning Orange

  /// Tema gelap utama (Dark Mode Default untuk kenyamanan olahraga outdoor/indoor).
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: stravaOrange,
      colorScheme: const ColorScheme.dark(
        primary: stravaOrange,
        secondary: stravaOrange,
        surface: cardSurface,
        error: accentRed,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardSurface,
        selectedItemColor: stravaOrange,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: stravaOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
