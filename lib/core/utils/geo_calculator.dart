import 'dart:math';
import '../../contracts/sport_type.dart';

/// Utilitas kalkulasi geospasial, jarak Haversine, dan metrik olahraga.
class GeoCalculator {
  static const double _earthRadiusMeters = 6371000.0;

  /// Menghitung jarak lurus permukaan bumi antara 2 titik koordinat (Haversine).
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Menghitung estimasi kalori terbakar berdasarkan berat badan (default 65 kg).
  static int estimateCalories({
    required SportType sportType,
    required int durationSeconds,
    double userWeightKg = 65.0,
  }) {
    if (durationSeconds <= 0) return 0;
    // Formula standar MET: Kalori = MET x Berat Badan (kg) x Waktu (jam)
    final hours = durationSeconds / 3600.0;
    final calories = sportType.metValue * userWeightKg * hours;
    return calories.round();
  }
}
