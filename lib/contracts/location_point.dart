import 'package:latlong2/latlong.dart';

/// Titik koordinat GPS tunggal dari trek aktivitas.
class LocationPoint {
  final double latitude;
  final double longitude;
  final double altitude; // Elevasi dalam meter di atas permukaan laut
  final double speed; // Kecepatan instan dalam meter/detik
  final DateTime timestamp;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  /// Mengonversi ke tipe data koordinat LatLng untuk rendering flutter_map.
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Konversi dari JSON ke objek LocationPoint.
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Serialisasi objek LocationPoint ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
