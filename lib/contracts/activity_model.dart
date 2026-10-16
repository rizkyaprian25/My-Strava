import 'km_split.dart';
import 'location_point.dart';
import 'sport_type.dart';

/// Single Source of Truth (SSOT) untuk entitas Aktivitas Olahraga.
class ActivityModel {
  final String id;
  final String title;
  final String description;
  final SportType sportType;
  final DateTime startTime;
  final int durationSeconds; // Durasi bergerak (moving time) dalam detik
  final double distanceMeters; // Jarak total dalam meter
  final int calories; // Estimasi kalori terbakar
  final double avgSpeedKmh; // Kecepatan rata-rata (km/jam)
  final double maxSpeedKmh; // Kecepatan puncak (km/jam)
  final double elevationGainMeters; // Total kenaikan ketinggian (meter)
  final List<LocationPoint> routePoints; // Rangkaian titik trek koordinat
  final List<KmSplit> splits; // Pembagian waktu per kilometer

  const ActivityModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.sportType,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.calories,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.routePoints,
    required this.splits,
  });

  /// Jarak total dalam format kilometer (misal: 5.42 km).
  double get distanceKm => distanceMeters / 1000.0;

  /// Pace rata-rata dalam format menit:detik per km (misal: "5:24 /km").
  String get avgPaceFormatted {
    if (distanceMeters <= 50 || durationSeconds <= 0) return '-:-- /km';
    final secondsPerKm = (durationSeconds / (distanceMeters / 1000.0)).round();
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  /// Format durasi waktu bergerak (misal: "45m 12s" atau "1h 15m 04s").
  String get durationFormatted {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours}j ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  /// Deserialisasi dari JSON.
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      sportType: SportType.values.firstWhere(
        (e) => e.name == json['sportType'],
        orElse: () => SportType.run,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      durationSeconds: json['durationSeconds'] as int,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      calories: json['calories'] as int,
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num).toDouble(),
      routePoints: (json['routePoints'] as List<dynamic>)
          .map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      splits: (json['splits'] as List<dynamic>?)
              ?.map((e) => KmSplit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Serialisasi ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'sportType': sportType.name,
      'startTime': startTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'calories': calories,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'elevationGainMeters': elevationGainMeters,
      'routePoints': routePoints.map((e) => e.toJson()).toList(),
      'splits': splits.map((e) => e.toJson()).toList(),
    };
  }
}
