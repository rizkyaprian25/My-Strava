import 'package:flutter/material.dart';

/// Pilihan tipe lapisan peta (Map Layer Styles) khas Strava.
enum AppMapStyle {
  standard,
  satellite,
  terrain,
  dark;

  String get displayName {
    switch (this) {
      case AppMapStyle.standard:
        return 'Standar';
      case AppMapStyle.satellite:
        return 'Satelit 3D';
      case AppMapStyle.terrain:
        return 'Topografi / Kontur';
      case AppMapStyle.dark:
        return 'Strava Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case AppMapStyle.standard:
        return Icons.map_outlined;
      case AppMapStyle.satellite:
        return Icons.satellite_alt_outlined;
      case AppMapStyle.terrain:
        return Icons.terrain_outlined;
      case AppMapStyle.dark:
        return Icons.dark_mode_outlined;
    }
  }

  /// URL template tile OpenStreetMap / Esri / OpenTopoMap / Carto.
  String get urlTemplate {
    switch (this) {
      case AppMapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case AppMapStyle.satellite:
        // Esri World Imagery (resolusi tinggi publik, tanpa API key)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case AppMapStyle.terrain:
        // OpenTopoMap (kontur ketinggian dan topografi alami)
        return 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
      case AppMapStyle.dark:
        // CartoDB Dark Matter (tema gelap kontras tinggi untuk jalur oranye menyala)
        return 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  /// Warna teks dan ornamen yang cocok dengan latar belakang peta.
  Color get overlayTextColor {
    switch (this) {
      case AppMapStyle.satellite:
      case AppMapStyle.dark:
        return Colors.white;
      case AppMapStyle.standard:
      case AppMapStyle.terrain:
        return const Color(0xFF222222);
    }
  }
}
