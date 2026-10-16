import 'package:flutter_test/flutter_test.dart';
import 'package:my_strava/contracts/activity_model.dart';
import 'package:my_strava/contracts/gear_model.dart';
import 'package:my_strava/contracts/km_split.dart';
import 'package:my_strava/contracts/location_point.dart';
import 'package:my_strava/contracts/personal_record.dart';
import 'package:my_strava/contracts/sport_type.dart';
import 'package:my_strava/core/utils/geo_calculator.dart';
import 'package:my_strava/core/utils/gpx_exporter.dart';

void main() {
  group('GeoCalculator Tests', () {
    test('Menghitung jarak Haversine dengan akurat antara dua titik', () {
      // Titik A: Monas Jakarta (-6.1754, 106.8272)
      // Titik B: Bundaran HI (-6.1950, 106.8230)
      final distance = GeoCalculator.calculateDistance(
        -6.1754,
        106.8272,
        -6.1950,
        106.8230,
      );

      // Jarak aktual sekitar 2.2 km (2200 meter)
      expect(distance, greaterThan(2000.0));
      expect(distance, lessThan(2400.0));
    });

    test('Estimasi kalori terbakar menghasilkan nilai logis', () {
      final calories = GeoCalculator.estimateCalories(
        sportType: SportType.run,
        durationSeconds: 3600, // 1 jam lari
        userWeightKg: 65.0,
      );

      // 9.8 MET x 65 kg x 1 jam = 637 kcal
      expect(calories, equals(637));
    });
  });

  group('ActivityModel Contract Tests', () {
    test('Serialisasi dan deserialisasi JSON konsisten tanpa kehilangan data', () {
      final now = DateTime.now();
      final point = LocationPoint(
        latitude: -6.1754,
        longitude: 106.8272,
        altitude: 15.0,
        speed: 3.2,
        timestamp: now,
      );

      final split = KmSplit(
        kilometer: 1,
        durationSeconds: 330,
        elevationChange: 5.0,
      );

      final activity = ActivityModel(
        id: 'test-123',
        title: 'Lari Pagi Senayan',
        description: 'Latihan interval 5k',
        sportType: SportType.run,
        startTime: now,
        durationSeconds: 1500,
        distanceMeters: 5000.0,
        calories: 320,
        avgSpeedKmh: 12.0,
        maxSpeedKmh: 15.4,
        elevationGainMeters: 25.0,
        routePoints: [point],
        splits: [split],
      );

      final json = activity.toJson();
      final restored = ActivityModel.fromJson(json);

      expect(restored.id, equals('test-123'));
      expect(restored.title, equals('Lari Pagi Senayan'));
      expect(restored.distanceKm, equals(5.0));
      expect(restored.avgPaceFormatted, equals('5:00 /km'));
      expect(restored.routePoints.length, equals(1));
      expect(restored.splits.length, equals(1));
    });

    test('GpxExporter menghasilkan format XML GPX 1.1 yang valid', () {
      final now = DateTime.now();
      final activity = ActivityModel(
        id: 'gpx-test',
        title: 'Lari Monas',
        description: 'Rute putaran Monas',
        sportType: SportType.run,
        startTime: now,
        durationSeconds: 600,
        distanceMeters: 2000.0,
        calories: 150,
        avgSpeedKmh: 12.0,
        maxSpeedKmh: 14.0,
        elevationGainMeters: 10.0,
        routePoints: [
          LocationPoint(
            latitude: -6.1754,
            longitude: 106.8272,
            altitude: 12.0,
            speed: 3.0,
            timestamp: now,
          ),
        ],
        splits: [],
      );

      final gpx = GpxExporter.exportToGpx(activity);

      expect(gpx, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('<trkpt lat="-6.1754" lon="106.8272">'));
      expect(gpx, contains('<name>Lari Monas</name>'));
    });
  });

  group('GearModel Contract Tests', () {
    test('Akumulasi jarak dan kalkulasi keausan sepatu lari', () {
      final shoe = GearModel(
        id: 'shoe-1',
        name: 'Vaporfly 3',
        brand: 'Nike',
        type: GearType.shoes,
        distanceMeters: 300000.0, // 300 km
        maxDistanceKm: 600.0,
        isDefault: true,
      );

      expect(shoe.distanceKm, equals(300.0));
      expect(shoe.wearProgress, closeTo(0.5, 0.01));
      expect(shoe.isWornOut, isFalse);

      // Tambahkan 350 km latihan lagi
      final updated = shoe.addDistance(350000.0);
      expect(updated.distanceKm, equals(650.0));
      expect(updated.isWornOut, isTrue);

      // Cek serialisasi JSON
      final json = updated.toJson();
      final restored = GearModel.fromJson(json);
      expect(restored.id, equals('shoe-1'));
      expect(restored.name, equals('Vaporfly 3'));
      expect(restored.type, equals(GearType.shoes));
      expect(restored.distanceKm, equals(650.0));
      expect(restored.isWornOut, isTrue);
    });
  });

  group('PersonalRecord Contract Tests', () {
    test('Format waktu rekor pribadi dan serialisasi JSON', () {
      final achievedDate = DateTime(2026, 10, 15, 6, 30);
      final pr = PersonalRecord(
        category: '5k',
        label: '5 Kilometer',
        durationSeconds: 1245, // 20 menit 45 detik
        value: 5.0,
        activityId: 'act-99',
        achievedAt: achievedDate,
      );

      expect(pr.formattedTime, equals('20m 45s'));

      // Test format dengan jam (cth: half marathon 1j 45m 12s)
      final halfMarathon = PersonalRecord(
        category: '21k',
        label: 'Half Marathon',
        durationSeconds: 6312,
        value: 21.1,
        activityId: 'act-100',
        achievedAt: achievedDate,
      );
      expect(halfMarathon.formattedTime, equals('1j 45m 12s'));

      final json = pr.toJson();
      final restored = PersonalRecord.fromJson(json);
      expect(restored.category, equals('5k'));
      expect(restored.durationSeconds, equals(1245));
      expect(restored.formattedTime, equals('20m 45s'));
    });
  });
}

