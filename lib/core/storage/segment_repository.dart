import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../contracts/activity_model.dart';
import '../../contracts/segment_model.dart';
import '../../contracts/sport_type.dart';
import '../utils/geo_calculator.dart';

/// Hasil pencocokan aktivitas terhadap suatu segmen rute.
class SegmentMatchResult {
  final SegmentModel segment;
  final int effortSeconds;
  final bool isNewPB;
  final double avgSpeedKmh;

  const SegmentMatchResult({
    required this.segment,
    required this.effortSeconds,
    required this.isNewPB,
    required this.avgSpeedKmh,
  });

  String get formattedEffort {
    final mins = effortSeconds ~/ 60;
    final secs = effortSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Repositori penyimpanan dan evaluasi segmen rute (KOM & Segmen Lintasan).
class SegmentRepository {
  static const String _segmentsKey = 'my_strava_segments_v1';

  /// Mendapatkan seluruh daftar segmen lintasan yang tersimpan.
  Future<List<SegmentModel>> getSegments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_segmentsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Inisialisasi dengan beberapa segmen bawaan jika masih kosong
      final initialSegments = _getDefaultSegments();
      await saveSegments(initialSegments);
      return initialSegments;
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => SegmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _getDefaultSegments();
    }
  }

  /// Menyimpan daftar segmen ke penyimpanan lokal.
  Future<void> saveSegments(List<SegmentModel> segments) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr =
        jsonEncode(segments.map((s) => s.toJson()).toList());
    await prefs.setString(_segmentsKey, jsonStr);
  }

  /// Menambahkan segmen lintasan baru.
  Future<void> addSegment(SegmentModel newSegment) async {
    final segments = await getSegments();
    segments.insert(0, newSegment);
    await saveSegments(segments);
  }

  /// Menghapus segmen.
  Future<void> deleteSegment(String segmentId) async {
    final segments = await getSegments();
    segments.removeWhere((s) => s.id == segmentId);
    await saveSegments(segments);
  }

  /// Mendeteksi dan mencocokkan apakah rekaman aktivitas melewati segmen-segmen yang ada.
  Future<List<SegmentMatchResult>> evaluateActivityAgainstSegments(
      ActivityModel activity) async {
    if (activity.routePoints.length < 2) return [];

    final segments = await getSegments();
    final List<SegmentMatchResult> matches = [];
    final List<SegmentModel> updatedSegments = [];

    for (final seg in segments) {
      // Cocokkan jenis olahraga
      if (seg.sportType != activity.sportType) {
        updatedSegments.add(seg);
        continue;
      }

      int startIndex = -1;
      int endIndex = -1;

      // Ambang batas toleransi radius kedekatan titik (45 meter)
      const double radiusMeters = 45.0;

      for (int i = 0; i < activity.routePoints.length; i++) {
        final pt = activity.routePoints[i];
        final distToStart = GeoCalculator.calculateDistance(
          pt.latitude,
          pt.longitude,
          seg.startLat,
          seg.startLng,
        );

        if (distToStart <= radiusMeters && startIndex == -1) {
          startIndex = i;
        }

        if (startIndex != -1 && i > startIndex) {
          final distToEnd = GeoCalculator.calculateDistance(
            pt.latitude,
            pt.longitude,
            seg.endLat,
            seg.endLng,
          );

          if (distToEnd <= radiusMeters) {
            endIndex = i;
            break;
          }
        }
      }

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final startPt = activity.routePoints[startIndex];
        final endPt = activity.routePoints[endIndex];
        final effortSeconds =
            endPt.timestamp.difference(startPt.timestamp).inSeconds;

        if (effortSeconds > 0) {
          final isNewPB = seg.personalBestSeconds == null ||
              effortSeconds < seg.personalBestSeconds!;
          final updatedSeg =
              seg.updateAttempt(effortSeconds, activity.startTime);
          updatedSegments.add(updatedSeg);

          final speedKmh =
              (seg.distanceMeters / effortSeconds) * 3.6;

          matches.add(SegmentMatchResult(
            segment: updatedSeg,
            effortSeconds: effortSeconds,
            isNewPB: isNewPB,
            avgSpeedKmh: speedKmh,
          ));
          continue;
        }
      }

      updatedSegments.add(seg);
    }

    if (matches.isNotEmpty) {
      await saveSegments(updatedSegments);
    }

    return matches;
  }

  /// Daftar segmen bawaan (default) sebagai contoh awal.
  List<SegmentModel> _getDefaultSegments() {
    return [
      const SegmentModel(
        id: 'seg-senayan-loop',
        name: 'Sprint Lurus Gelora Senayan',
        description: 'Lintasan lurus lingkar luar Senayan Jakarta',
        sportType: SportType.run,
        startLat: -6.2185,
        startLng: 106.8020,
        endLat: -6.2150,
        endLng: 106.8025,
        distanceMeters: 400.0,
        elevationGainMeters: 2.0,
      ),
      const SegmentModel(
        id: 'seg-monas-sprint',
        name: 'Monas Merdeka Barat Loop',
        description: 'Jalur pedestrian barat Monumen Nasional',
        sportType: SportType.run,
        startLat: -6.1754,
        startLng: 106.8240,
        endLat: -6.1710,
        endLng: 106.8245,
        distanceMeters: 550.0,
        elevationGainMeters: 3.0,
      ),
      const SegmentModel(
        id: 'seg-dago-climb',
        name: 'Tanjakan Dago Atas Ride',
        description: 'Segmen tanjakan pesepeda Bandung',
        sportType: SportType.ride,
        startLat: -6.8650,
        startLng: 107.6180,
        endLat: -6.8520,
        endLng: 107.6210,
        distanceMeters: 1600.0,
        elevationGainMeters: 85.0,
      ),
    ];
  }
}
