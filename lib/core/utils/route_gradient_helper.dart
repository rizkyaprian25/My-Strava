import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../contracts/location_point.dart';

/// Pilihan mode pewarnaan polyline jalur rute.
enum RouteColorMode {
  solidOrange,
  speedGradient,
  elevationGradient;

  String get displayName {
    switch (this) {
      case RouteColorMode.solidOrange:
        return 'Strava Orange Klasik';
      case RouteColorMode.speedGradient:
        return 'Gradien Kecepatan';
      case RouteColorMode.elevationGradient:
        return 'Gradien Ketinggian (3D)';
    }
  }
}

/// Helper untuk menghasilkan polyline multi-warna bergradien khas visualisasi Strava.
class RouteGradientHelper {
  /// Mengonversi titik koordinat menjadi polylines bergradien berdasarkan mode yang dipilih.
  static List<Polyline> generatePolylines({
    required List<LocationPoint> points,
    required RouteColorMode mode,
    double strokeWidth = 5.0,
  }) {
    if (points.isEmpty) return [];

    if (mode == RouteColorMode.solidOrange || points.length < 2) {
      return [
        Polyline(
          points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          strokeWidth: strokeWidth,
          color: const Color(0xFFFC5200), // Strava Orange
        ),
      ];
    }

    final polylines = <Polyline>[];

    if (mode == RouteColorMode.speedGradient) {
      // Cari kecepatan min dan max
      double minSpeed = double.infinity;
      double maxSpeed = -double.infinity;

      for (final p in points) {
        final spd = p.speedKmh;
        if (spd < minSpeed) minSpeed = spd;
        if (spd > maxSpeed) maxSpeed = spd;
      }

      if (maxSpeed <= minSpeed) maxSpeed = minSpeed + 1.0;

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final avgSpd = (p1.speedKmh + p2.speedKmh) / 2.0;
        final ratio = ((avgSpd - minSpeed) / (maxSpeed - minSpeed)).clamp(0.0, 1.0);

        // Biru/Merah (lambat) -> Oranye (sedang) -> Hijau Terang (kencang)
        final color = Color.lerp(
          const Color(0xFFFC5200),
          const Color(0xFF00E676),
          ratio,
        ) ?? const Color(0xFFFC5200);

        polylines.add(
          Polyline(
            points: [
              LatLng(p1.latitude, p1.longitude),
              LatLng(p2.latitude, p2.longitude),
            ],
            strokeWidth: strokeWidth,
            color: color,
          ),
        );
      }
    } else if (mode == RouteColorMode.elevationGradient) {
      // Cari ketinggian min dan max
      double minAlt = double.infinity;
      double maxAlt = -double.infinity;

      for (final p in points) {
        if (p.altitude < minAlt) minAlt = p.altitude;
        if (p.altitude > maxAlt) maxAlt = p.altitude;
      }

      if (maxAlt <= minAlt) maxAlt = minAlt + 5.0;

      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final avgAlt = (p1.altitude + p2.altitude) / 2.0;
        final ratio = ((avgAlt - minAlt) / (maxAlt - minAlt)).clamp(0.0, 1.0);

        // Ungu/Biru (lembah) -> Oranye -> Merah Terang (puncak tanjakan)
        final color = Color.lerp(
          const Color(0xFF2979FF),
          const Color(0xFFFF1744),
          ratio,
        ) ?? const Color(0xFFFC5200);

        polylines.add(
          Polyline(
            points: [
              LatLng(p1.latitude, p1.longitude),
              LatLng(p2.latitude, p2.longitude),
            ],
            strokeWidth: strokeWidth,
            color: color,
          ),
        );
      }
    }

    return polylines;
  }
}
