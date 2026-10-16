import 'package:flutter/material.dart';

/// Jenis olahraga yang didukung oleh My Strava.
enum SportType {
  run,
  ride,
  walk,
  hike;

  /// Label berbahasa Indonesia yang ramah pengguna.
  String get displayName {
    switch (this) {
      case SportType.run:
        return 'Lari';
      case SportType.ride:
        return 'Bersepeda';
      case SportType.walk:
        return 'Jalan Kaki';
      case SportType.hike:
        return 'Hiking';
    }
  }

  /// Ikon representasi olahraga.
  IconData get icon {
    switch (this) {
      case SportType.run:
        return Icons.directions_run;
      case SportType.ride:
        return Icons.directions_bike;
      case SportType.walk:
        return Icons.directions_walk;
      case SportType.hike:
        return Icons.hiking;
    }
  }

  /// Nilai MET (Metabolic Equivalent of Task) untuk estimasi kalori terbakar.
  double get metValue {
    switch (this) {
      case SportType.run:
        return 9.8; // Lari intensitas sedang (sekitar 6 min/km)
      case SportType.ride:
        return 8.0; // Bersepeda santai-sedang
      case SportType.walk:
        return 3.8; // Jalan kaki biasa
      case SportType.hike:
        return 6.0; // Mendaki medan alam
    }
  }
}
