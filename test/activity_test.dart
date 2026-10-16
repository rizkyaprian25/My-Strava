import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_strava/contracts/activity_model.dart';
import 'package:my_strava/contracts/gear_model.dart';
import 'package:my_strava/contracts/km_split.dart';
import 'package:my_strava/contracts/location_point.dart';
import 'package:my_strava/contracts/map_style.dart';
import 'package:my_strava/contracts/personal_record.dart';
import 'package:my_strava/contracts/segment_model.dart';
import 'package:my_strava/contracts/sport_type.dart';
import 'package:my_strava/core/services/geocoding_service.dart';
import 'package:my_strava/core/services/weather_service.dart';
import 'package:my_strava/core/utils/geo_calculator.dart';
import 'package:my_strava/core/utils/gpx_exporter.dart';
import 'package:my_strava/core/utils/route_gradient_helper.dart';

void main() {
  group('GeoCalculator Tests', () {
    test('Menghitung jarak WGS-84 Vincenty dengan akurasi tinggi antara dua titik', () {
      // Titik A: Monas Jakarta (-6.1754, 106.8272)
      // Titik B: Bundaran HI (-6.1950, 106.8230)
      final distance = GeoCalculator.calculateDistance(
        -6.1754,
        106.8272,
        -6.1950,
        106.8230,
      );

      // Jarak aktual sekitar 2.22 km (2220-2230 meter)
      expect(distance, greaterThan(2200.0));
      expect(distance, lessThan(2250.0));
    });

    test('calculateDistance3D memperhitungkan hipotenusa kemiringan kontur', () {
      final flatDist = GeoCalculator.calculateDistance(
        -6.1754,
        106.8272,
        -6.1764,
        106.8272,
      );

      // Tanjakan 40 meter
      final dist3D = GeoCalculator.calculateDistance3D(
        -6.1754,
        106.8272,
        10.0,
        -6.1764,
        106.8272,
        50.0,
      );

      expect(dist3D, greaterThan(flatDist));
    });

    test('filterAndCalculateDelta menolak jitter saat diam dan loncatan kecepatan mustahil', () {
      final now = DateTime.now();
      final p1 = LocationPoint(
        latitude: -6.1754,
        longitude: 106.8272,
        altitude: 10.0,
        speed: 0.2, // Kecepatan diam (< 0.4 m/s)
        accuracy: 4.0,
        timestamp: now,
      );

      // Jitter kecil 0.8 meter saat diam
      final pJitter = LocationPoint(
        latitude: -6.175405,
        longitude: 106.827205,
        altitude: 10.0,
        speed: 0.1,
        accuracy: 5.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      final jitterDelta = GeoCalculator.filterAndCalculateDelta(
        prevPoint: p1,
        newPoint: pJitter,
        sportType: SportType.run,
      );
      // Harus ditolak (0 meter) agar jarak tidak bertambah sendiri saat atlet diam
      expect(jitterDelta, equals(0.0));

      // Loncatan satelit ekstrem (pindah 2 km dalam 1 detik)
      final pSpike = LocationPoint(
        latitude: -6.1950,
        longitude: 106.8230,
        altitude: 10.0,
        speed: 15.0,
        accuracy: 4.0,
        timestamp: now.add(const Duration(seconds: 1)),
      );

      final spikeDelta = GeoCalculator.filterAndCalculateDelta(
        prevPoint: p1,
        newPoint: pSpike,
        sportType: SportType.run,
      );
      // Harus ditolak (0 meter) karena melebihi batas fisik lari manusia
      expect(spikeDelta, equals(0.0));
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

  group('SegmentModel & KOM Contract Tests', () {
    test('Format waktu PB segmen dan pembaruan rekor baru', () {
      final now = DateTime(2026, 10, 16, 8, 0);
      final segment = SegmentModel(
        id: 'seg-1',
        name: 'Sprint Senayan 400m',
        sportType: SportType.run,
        startLat: -6.2185,
        startLng: 106.8020,
        endLat: -6.2150,
        endLng: 106.8025,
        distanceMeters: 400.0,
        personalBestSeconds: 85, // 1m 25s
        attemptsCount: 2,
      );

      expect(segment.distanceKm, equals(0.4));
      expect(segment.formattedPB, equals('01:25'));

      // Upayakan rekor baru yang lebih cepat: 78 detik (01:18)
      final improved = segment.updateAttempt(78, now);
      expect(improved.personalBestSeconds, equals(78));
      expect(improved.formattedPB, equals('01:18'));
      expect(improved.attemptsCount, equals(3));

      // Upayakan rekor yang lebih lambat: 90 detik (PB tetap 78 detik)
      final slower = improved.updateAttempt(90, now);
      expect(slower.personalBestSeconds, equals(78));
      expect(slower.attemptsCount, equals(4));

      // Validasi serialisasi JSON
      final json = improved.toJson();
      final restored = SegmentModel.fromJson(json);
      expect(restored.id, equals('seg-1'));
      expect(restored.name, equals('Sprint Senayan 400m'));
      expect(restored.personalBestSeconds, equals(78));
    });
  });

  group('AppMapStyle & Tile Layers Tests', () {
    test('Memastikan semua gaya peta memiliki URL template yang valid', () {
      for (final style in AppMapStyle.values) {
        expect(style.displayName, isNotEmpty);
        expect(style.urlTemplate, contains('{z}'));
        expect(style.urlTemplate, contains('{x}'));
        expect(style.urlTemplate, contains('{y}'));
        expect(style.icon, isNotNull);
      }
    });
  });

  group('RouteGradientHelper Tests', () {
    test('Menghasilkan polyline solid dan gradien multi-segmen', () {
      final now = DateTime.now();
      final points = [
        LocationPoint(
          latitude: -6.1754,
          longitude: 106.8272,
          altitude: 10.0,
          speed: 2.0,
          timestamp: now,
        ),
        LocationPoint(
          latitude: -6.1760,
          longitude: 106.8275,
          altitude: 15.0,
          speed: 4.5,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        LocationPoint(
          latitude: -6.1770,
          longitude: 106.8280,
          altitude: 20.0,
          speed: 3.0,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
      ];

      // Test solid orange
      final solidLines = RouteGradientHelper.generatePolylines(
        points: points,
        mode: RouteColorMode.solidOrange,
      );
      expect(solidLines.length, equals(1));
      expect(solidLines.first.color, equals(const Color(0xFFFC5200)));

      // Test speed gradient (3 titik menghasilkan 2 segmen bergradien)
      final speedLines = RouteGradientHelper.generatePolylines(
        points: points,
        mode: RouteColorMode.speedGradient,
      );
      expect(speedLines.length, equals(2));

      // Test elevation gradient (3 titik menghasilkan 2 segmen bergradien)
      final elevationLines = RouteGradientHelper.generatePolylines(
        points: points,
        mode: RouteColorMode.elevationGradient,
      );
      expect(elevationLines.length, equals(2));
    });
  });

  group('Zero-API-Key Services Tests', () {
    test('GeocodingService mengestimasi kota secara offline tanpa API key', () async {
      // Koordinat Jakarta (-6.1754, 106.8272)
      final jakarta = await GeocodingService.reverseGeocode(-6.1754, 106.8272);
      expect(jakarta, isNotNull);
      expect(jakarta, contains('Jakarta'));

      // Koordinat Bandung (-6.9175, 107.6191)
      final bandung = await GeocodingService.reverseGeocode(-6.9175, 107.6191);
      expect(bandung, isNotNull);
      expect(bandung, contains('Bandung'));
    });

    test('WeatherInfo memformat ringkasan cuaca dengan benar', () {
      const weather = WeatherInfo(
        temperatureCelsius: 28.4,
        humidityPercent: 75,
        conditionDescription: 'Cerah Berawan',
      );

      expect(weather.formattedSummary, equals('28°C Cerah Berawan'));
    });

    test('ActivityModel menyimpan field lokasi dan cuaca secara persisten', () {
      final now = DateTime.now();
      final activity = ActivityModel(
        id: 'zero-api-act',
        title: 'Lari Pagi di Jakarta',
        sportType: SportType.run,
        startTime: now,
        durationSeconds: 1800,
        distanceMeters: 5000.0,
        calories: 320,
        avgSpeedKmh: 10.0,
        maxSpeedKmh: 12.0,
        elevationGainMeters: 15.0,
        routePoints: [],
        splits: [],
        locationName: 'Jakarta Pusat',
        temperatureCelsius: 29.0,
        weatherCondition: 'Cerah',
      );

      expect(activity.weatherSummary, equals('29°C Cerah'));

      final json = activity.toJson();
      final restored = ActivityModel.fromJson(json);

      expect(restored.locationName, equals('Jakarta Pusat'));
      expect(restored.temperatureCelsius, equals(29.0));
      expect(restored.weatherCondition, equals('Cerah'));
      expect(restored.weatherSummary, equals('29°C Cerah'));
    });
  });
}



