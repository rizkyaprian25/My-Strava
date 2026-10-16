/// Model data untuk Rekor Pribadi (Personal Best / PR) atlet.
class PersonalRecord {
  final String category; // '1k', '5k', '10k', '21k', 'Jarak Terjauh', 'Kecepatan Puncak'
  final String label; // '1 Kilometer', '5 Kilometer', dst.
  final int durationSeconds; // Durasi tercepat (untuk kategori jarak)
  final double value; // Nilai angka (misal km atau km/h)
  final String activityId;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.category,
    required this.label,
    required this.durationSeconds,
    required this.value,
    required this.activityId,
    required this.achievedAt,
  });

  /// Format waktu rekor.
  String get formattedTime {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final hours = mins ~/ 60;
    if (hours > 0) {
      return '${hours}j ${(mins % 60).toString().padLeft(2, '0')}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      category: json['category'] as String,
      label: json['label'] as String,
      durationSeconds: json['durationSeconds'] as int,
      value: (json['value'] as num).toDouble(),
      activityId: json['activityId'] as String,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'label': label,
      'durationSeconds': durationSeconds,
      'value': value,
      'activityId': activityId,
      'achievedAt': achievedAt.toIso8601String(),
    };
  }
}
