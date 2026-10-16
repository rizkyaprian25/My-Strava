import 'package:intl/intl.dart';
import 'sport_type.dart';

/// Model data Segmen Lintasan (Strava Segment & King/Queen of the Mountain).
class SegmentModel {
  final String id;
  final String name;
  final String description;
  final SportType sportType;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double distanceMeters;
  final double elevationGainMeters;
  final int? personalBestSeconds; // Rekor waktu terbaik pengguna (detik)
  final DateTime? pbAchievedAt;
  final int attemptsCount; // Jumlah berapa kali segmen ini telah dilewati

  const SegmentModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.sportType,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distanceMeters,
    this.elevationGainMeters = 0.0,
    this.personalBestSeconds,
    this.pbAchievedAt,
    this.attemptsCount = 0,
  });

  double get distanceKm => distanceMeters / 1000.0;

  /// Format waktu terbaik menjadi mm:ss atau jj:mm:ss.
  String get formattedPB {
    if (personalBestSeconds == null) return '--:--';
    final mins = personalBestSeconds! ~/ 60;
    final secs = personalBestSeconds! % 60;
    final hours = mins ~/ 60;
    if (hours > 0) {
      return '$hours:${(mins % 60).toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format tanggal pencapaian PR segmen.
  String get formattedPBAchievedDate {
    if (pbAchievedAt == null) return '';
    return DateFormat('d MMM yyyy').format(pbAchievedAt!);
  }

  /// Membuat salinan objek dengan rekor baru jika waktu tempuh lebih cepat.
  SegmentModel updateAttempt(int elapsedSeconds, DateTime date) {
    final isNewPB =
        personalBestSeconds == null || elapsedSeconds < personalBestSeconds!;
    return SegmentModel(
      id: id,
      name: name,
      description: description,
      sportType: sportType,
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      distanceMeters: distanceMeters,
      elevationGainMeters: elevationGainMeters,
      personalBestSeconds:
          isNewPB ? elapsedSeconds : personalBestSeconds,
      pbAchievedAt: isNewPB ? date : pbAchievedAt,
      attemptsCount: attemptsCount + 1,
    );
  }

  factory SegmentModel.fromJson(Map<String, dynamic> json) {
    return SegmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      sportType: SportType.fromString(json['sportType'] as String),
      startLat: (json['startLat'] as num).toDouble(),
      startLng: (json['startLng'] as num).toDouble(),
      endLat: (json['endLat'] as num).toDouble(),
      endLng: (json['endLng'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      elevationGainMeters:
          (json['elevationGainMeters'] as num?)?.toDouble() ?? 0.0,
      personalBestSeconds: json['personalBestSeconds'] as int?,
      pbAchievedAt: json['pbAchievedAt'] != null
          ? DateTime.parse(json['pbAchievedAt'] as String)
          : null,
      attemptsCount: json['attemptsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sportType': sportType.name,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distanceMeters': distanceMeters,
      'elevationGainMeters': elevationGainMeters,
      'personalBestSeconds': personalBestSeconds,
      'pbAchievedAt': pbAchievedAt?.toIso8601String(),
      'attemptsCount': attemptsCount,
    };
  }
}
