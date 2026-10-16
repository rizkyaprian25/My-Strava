import 'package:flutter/material.dart';

/// Jenis perlengkapan olahraga (Sepatu Lari atau Sepeda).
enum GearType {
  shoes,
  bike;

  String get displayName => this == GearType.shoes ? 'Sepatu Lari' : 'Sepeda';
  IconData get icon =>
      this == GearType.shoes ? Icons.directions_run : Icons.directions_bike;
}

/// Model data perlengkapan olahraga untuk melacak jarak tempuh dan keausan.
class GearModel {
  final String id;
  final String name;
  final String brand;
  final GearType type;
  final double distanceMeters; // Jarak tempuh saat ini dalam meter
  final double maxDistanceKm; // Batas rekomendasi jarak pakai (km)
  final bool isDefault;

  const GearModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.type,
    this.distanceMeters = 0.0,
    this.maxDistanceKm = 600.0, // Standar rekomendasi masa pakai sepatu lari
    this.isDefault = false,
  });

  double get distanceKm => distanceMeters / 1000.0;

  /// Rasio masa pakai dari 0.0 sampai 1.0 (atau lebih jika melebihi batas).
  double get wearProgress => (distanceKm / maxDistanceKm).clamp(0.0, 1.5);

  /// Peringatan jika perlengkapan sudah melewati masa pakai optimal.
  bool get isWornOut => distanceKm >= maxDistanceKm;

  /// Membuat salinan objek dengan penambahan jarak baru setelah sesi latihan.
  GearModel addDistance(double additionalMeters) {
    return GearModel(
      id: id,
      name: name,
      brand: brand,
      type: type,
      distanceMeters: distanceMeters + additionalMeters,
      maxDistanceKm: maxDistanceKm,
      isDefault: isDefault,
    );
  }

  factory GearModel.fromJson(Map<String, dynamic> json) {
    return GearModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      type: json['type'] == 'shoes' ? GearType.shoes : GearType.bike,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble() ?? 600.0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'type': type.name,
      'distanceMeters': distanceMeters,
      'maxDistanceKm': maxDistanceKm,
      'isDefault': isDefault,
    };
  }
}
