import 'dart:math';
import '../../contracts/location_point.dart';
import '../../contracts/sport_type.dart';

/// Mesin kalkulasi geospasial presisi tinggi setara algoritma Strava GPS Engine:
/// 1. Jarak Geodesik WGS-84 Ellipsoid (Formula Vincenty Inverse) dengan akurasi sub-milimeter.
/// 2. Kompensasi Jarak Permukaan 3D (Pythagorean 3D Topographic Terrain Distance).
/// 3. Filter noise GPS anti-drift, deadband titik diam, dan eliminasi loncatan tower satelit.
class GeoCalculator {
  static const double _earthRadiusMeters = 6371000.0;

  /// Parameter Sferoid Referensi WGS-84 (Standar GPS Dunia)
  static const double _wgs84A = 6378137.0; // Semi-major axis (meter)
  static const double _wgs84B = 6356752.314245; // Semi-minor axis (meter)
  static const double _wgs84F = 1.0 / 298.257223563; // Flattening ellipsoid

  /// Menghitung jarak geodesik WGS-84 Ellipsoid (Vincenty Formula) persis seperti Strava.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    if (lat1 == lat2 && lon1 == lon2) return 0.0;

    final phi1 = _degreesToRadians(lat1);
    final phi2 = _degreesToRadians(lat2);
    final deltaLambda = _degreesToRadians(lon2 - lon1);

    final u1 = atan((1.0 - _wgs84F) * tan(phi1));
    final u2 = atan((1.0 - _wgs84F) * tan(phi2));

    final sinU1 = sin(u1), cosU1 = cos(u1);
    final sinU2 = sin(u2), cosU2 = cos(u2);

    double lambda = deltaLambda;
    double lambdaP = 2 * pi;
    int iterLimit = 25;

    double cosSqAlpha = 0.0;
    double sinSigma = 0.0;
    double cos2SigmaM = 0.0;
    double cosSigma = 0.0;
    double sigma = 0.0;

    while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0) {
      final sinLambda = sin(lambda);
      final cosLambda = cos(lambda);

      sinSigma = sqrt(
        (cosU2 * sinLambda) * (cosU2 * sinLambda) +
            (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
                (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda),
      );

      if (sinSigma == 0.0) return 0.0;

      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);

      final sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1.0 - sinAlpha * sinAlpha;

      cos2SigmaM = cosSqAlpha != 0.0
          ? (cosSigma - 2.0 * sinU1 * sinU2 / cosSqAlpha)
          : 0.0;

      final c = _wgs84F / 16.0 * cosSqAlpha * (4.0 + _wgs84F * (4.0 - 3.0 * cosSqAlpha));
      lambdaP = lambda;
      lambda = deltaLambda +
          (1.0 - c) *
              _wgs84F *
              sinAlpha *
              (sigma +
                  c *
                      sinSigma *
                      (cos2SigmaM +
                          c * cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM)));
    }

    // Jika terjadi kondisi non-konvergen (titik antipodal ekstrim), fallback ke Haversine
    if (iterLimit == 0) {
      return haversineDistance(lat1, lon1, lat2, lon2);
    }

    final uSq = cosSqAlpha * (_wgs84A * _wgs84A - _wgs84B * _wgs84B) / (_wgs84B * _wgs84B);
    final a = 1.0 + uSq / 16384.0 * (4096.0 + uSq * (-768.0 + uSq * (320.0 - 175.0 * uSq)));
    final b = uSq / 1024.0 * (256.0 + uSq * (-128.0 + uSq * (74.0 - 47.0 * uSq)));
    final deltaSigma = b *
        sinSigma *
        (cos2SigmaM +
            b /
                4.0 *
                (cosSigma * (-1.0 + 2.0 * cos2SigmaM * cos2SigmaM) -
                    b /
                        6.0 *
                        cos2SigmaM *
                        (-3.0 + 4.0 * sinSigma * sinSigma) *
                        (-3.0 + 4.0 * cos2SigmaM * cos2SigmaM)));

    final distance = _wgs84B * a * (sigma - deltaSigma);
    return distance.abs();
  }

  /// Menghitung jarak permukaan 3D dengan memperhitungkan kemiringan/elevasi kontur medan.
  static double calculateDistance3D(
    double lat1,
    double lon1,
    double alt1,
    double lat2,
    double lon2,
    double alt2,
  ) {
    final d2D = calculateDistance(lat1, lon1, lat2, lon2);
    final dAlt = (alt2 - alt1).abs();

    // Kompensasi hipotenusa 3D tanjakan/turunan jika beda elevasi wajar (< 100m per interval)
    if (dAlt > 0.3 && dAlt < 100.0) {
      return sqrt(d2D * d2D + dAlt * dAlt);
    }
    return d2D;
  }

  /// Filter cerdas noise GPS & kalkulasi pertambahan jarak real-time ala Strava:
  /// - Menolak titik dengan akurasi rendah (> 25m).
  /// - Mencegah 'jarak bertambah sendiri' saat berhenti (Deadband Jitter Filter).
  /// - Menolak loncatan koordinat yang melebihi batas kecepatan fisik olahraga.
  static double filterAndCalculateDelta({
    required LocationPoint prevPoint,
    required LocationPoint newPoint,
    SportType sportType = SportType.run,
  }) {
    // 1. Filter Akurasi Sinyal (Abaikan jika GPS lemah / dalam ruangan)
    if (newPoint.accuracy > 25.0) {
      return 0.0;
    }

    // 2. Hitung jarak 3D WGS-84
    final dist3D = calculateDistance3D(
      prevPoint.latitude,
      prevPoint.longitude,
      prevPoint.altitude,
      newPoint.latitude,
      newPoint.longitude,
      newPoint.altitude,
    );

    final timeDeltaSecs =
        newPoint.timestamp.difference(prevPoint.timestamp).inMilliseconds /
            1000.0;
    if (timeDeltaSecs <= 0.05) return 0.0;

    final impliedSpeedKmh = (dist3D / timeDeltaSecs) * 3.6;

    // 3. Batas Kecepatan Maksimal Fisik Manusia (Spike / Loncatan Tower Celular)
    // Lari/Jalan max 45 km/jam, Sepeda max 120 km/jam
    final maxSpeedCap = (sportType == SportType.ride) ? 120.0 : 45.0;
    if (impliedSpeedKmh > maxSpeedCap) {
      return 0.0;
    }

    // 4. Deadband Filter Titik Diam (Paling Penting untuk Mencegah Jarak Membengkak!)
    // Saat atlet berhenti, GPS tetap bergetar 1-3 meter. Jangan tambahkan jarak!
    if (newPoint.speed < 0.40 && dist3D < 1.8) {
      return 0.0;
    }

    return dist3D;
  }

  /// Pasca-pemrosesan trek rute lengkap untuk harmonisasi total jarak & elevasi persis Strava.
  static double calculateTotalDistanceStrava(
    List<LocationPoint> points, {
    SportType sportType = SportType.run,
  }) {
    if (points.length < 2) return 0.0;

    double totalMeters = 0.0;
    for (int i = 1; i < points.length; i++) {
      final p1 = points[i - 1];
      final p2 = points[i];

      final delta = filterAndCalculateDelta(
        prevPoint: p1,
        newPoint: p2,
        sportType: sportType,
      );
      totalMeters += delta;
    }

    return totalMeters;
  }

  /// Formula klasik Haversine (Sferikal) sebagai pembanding/fallback.
  static double haversineDistance(
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
    final hours = durationSeconds / 3600.0;
    final calories = sportType.metValue * userWeightKg * hours;
    return calories.round();
  }
}
