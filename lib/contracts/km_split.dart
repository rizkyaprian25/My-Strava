/// Model data untuk segmen split per kilometer.
class KmSplit {
  final int kilometer; // Kilometer ke-1, ke-2, dst.
  final int durationSeconds; // Durasi untuk menyelesaikan 1 kilometer ini
  final double elevationChange; // Perubahan elevasi (meter) dalam kilometer ini

  const KmSplit({
    required this.kilometer,
    required this.durationSeconds,
    required this.elevationChange,
  });

  /// Format kecepatan rata-rata split dalam format pace mm:ss /km.
  String get paceFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')} /km';
  }

  /// Konversi dari JSON ke objek KmSplit.
  factory KmSplit.fromJson(Map<String, dynamic> json) {
    return KmSplit(
      kilometer: json['kilometer'] as int,
      durationSeconds: json['durationSeconds'] as int,
      elevationChange: (json['elevationChange'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Serialisasi ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'kilometer': kilometer,
      'durationSeconds': durationSeconds,
      'elevationChange': elevationChange,
    };
  }
}
