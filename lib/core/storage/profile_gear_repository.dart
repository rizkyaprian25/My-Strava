import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../contracts/activity_model.dart';
import '../../contracts/gear_model.dart';
import '../../contracts/personal_record.dart';

/// Repository untuk mengelola profil atlet, perlengkapan (sepatu & sepeda), dan kalkulasi Rekor Pribadi (PR).
class ProfileGearRepository {
  static const String _gearFileName = 'my_strava_gears.json';
  static const String _keyAthleteName = 'athlete_name';
  static const String _keyAthleteBio = 'athlete_bio';
  static const String _keyAthleteWeight = 'athlete_weight';
  static const String _keyWeeklyGoal = 'weekly_goal_km';

  // --- PROFIL ATLET ---
  Future<Map<String, dynamic>> getAthleteProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyAthleteName) ?? 'Atlet My Strava',
      'bio': prefs.getString(_keyAthleteBio) ?? 'Pelari & Pesepeda Mandiri 🏃🚴',
      'weight': prefs.getDouble(_keyAthleteWeight) ?? 65.0,
      'weeklyGoalKm': prefs.getDouble(_keyWeeklyGoal) ?? 25.0,
    };
  }

  Future<void> saveAthleteProfile({
    required String name,
    required String bio,
    required double weight,
    required double weeklyGoalKm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAthleteName, name);
    await prefs.setString(_keyAthleteBio, bio);
    await prefs.setDouble(_keyAthleteWeight, weight);
    await prefs.setDouble(_keyWeeklyGoal, weeklyGoalKm);
  }

  // --- GEAR MANAGEMENT ---
  Future<File> _getGearFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_gearFileName');
  }

  Future<List<GearModel>> getAllGears() async {
    try {
      final file = await _getGearFile();
      if (!await file.exists()) {
        // Berikan contoh default perlengkapan pertama jika belum ada
        final defaultGears = [
          const GearModel(
            id: 'default-shoes-1',
            name: 'Running Shoes Pro',
            brand: 'Nike / Asics',
            type: GearType.shoes,
            distanceMeters: 0.0,
            maxDistanceKm: 600.0,
            isDefault: true,
          ),
          const GearModel(
            id: 'default-bike-1',
            name: 'Road Bike Carbon',
            brand: 'Polygon / Specialized',
            type: GearType.bike,
            distanceMeters: 0.0,
            maxDistanceKm: 3000.0,
            isDefault: true,
          ),
        ];
        await saveAllGears(defaultGears);
        return defaultGears;
      }

      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
      return jsonList
          .map((item) => GearModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error membaca daftar perlengkapan: $e');
      return [];
    }
  }

  Future<void> saveAllGears(List<GearModel> gears) async {
    final file = await _getGearFile();
    final jsonStr = jsonEncode(gears.map((g) => g.toJson()).toList());
    await file.writeAsString(jsonStr);
  }

  Future<void> addGear(GearModel gear) async {
    final gears = await getAllGears();
    gears.add(gear);
    await saveAllGears(gears);
  }

  Future<void> deleteGear(String id) async {
    final gears = await getAllGears();
    gears.removeWhere((g) => g.id == id);
    await saveAllGears(gears);
  }

  Future<void> addMileageToDefaultGear(
    GearType type,
    double additionalMeters,
  ) async {
    final gears = await getAllGears();
    final index = gears.indexWhere((g) => g.type == type && g.isDefault);
    if (index != -1) {
      gears[index] = gears[index].addDistance(additionalMeters);
      await saveAllGears(gears);
    }
  }

  // --- REKOR PRIBADI (PERSONAL RECORDS / PR) ---
  /// Menghitung Rekor Terbaik (PR) secara otomatis dari seluruh data aktivitas yang tersimpan.
  List<PersonalRecord> computePersonalRecords(List<ActivityModel> activities) {
    if (activities.isEmpty) return [];

    PersonalRecord? best1k;
    PersonalRecord? best5k;
    PersonalRecord? best10k;
    PersonalRecord? longestDistance;
    PersonalRecord? topSpeed;

    for (final act in activities) {
      // 1. Rekor Jarak Terjauh
      if (longestDistance == null || act.distanceMeters > longestDistance.value) {
        longestDistance = PersonalRecord(
          category: 'distance',
          label: 'Jarak Terjauh',
          durationSeconds: act.durationSeconds,
          value: act.distanceMeters,
          activityId: act.id,
          achievedAt: act.startTime,
        );
      }

      // 2. Kecepatan Puncak
      if (topSpeed == null || act.maxSpeedKmh > topSpeed.value) {
        topSpeed = PersonalRecord(
          category: 'speed',
          label: 'Kecepatan Puncak',
          durationSeconds: 0,
          value: act.maxSpeedKmh,
          activityId: act.id,
          achievedAt: act.startTime,
        );
      }

      // 3. Rekor Split 1k tercepat
      for (final split in act.splits) {
        if (split.durationSeconds > 60 && split.durationSeconds < 1800) {
          if (best1k == null || split.durationSeconds < best1k.durationSeconds) {
            best1k = PersonalRecord(
              category: '1k',
              label: '1 Kilometer Tercepat',
              durationSeconds: split.durationSeconds,
              value: 1000.0,
              activityId: act.id,
              achievedAt: act.startTime,
            );
          }
        }
      }

      // 4. Rekor 5K (jika aktivitas >= 4.9 km)
      if (act.distanceMeters >= 4900 && act.durationSeconds > 300) {
        if (best5k == null || act.durationSeconds < best5k.durationSeconds) {
          best5k = PersonalRecord(
            category: '5k',
            label: '5 Kilometer Tercepat',
            durationSeconds: act.durationSeconds,
            value: 5000.0,
            activityId: act.id,
            achievedAt: act.startTime,
          );
        }
      }

      // 5. Rekor 10K (jika aktivitas >= 9.9 km)
      if (act.distanceMeters >= 9900 && act.durationSeconds > 600) {
        if (best10k == null || act.durationSeconds < best10k.durationSeconds) {
          best10k = PersonalRecord(
            category: '10k',
            label: '10 Kilometer Tercepat',
            durationSeconds: act.durationSeconds,
            value: 10000.0,
            activityId: act.id,
            achievedAt: act.startTime,
          );
        }
      }
    }

    final records = <PersonalRecord>[];
    if (best1k != null) records.add(best1k);
    if (best5k != null) records.add(best5k);
    if (best10k != null) records.add(best10k);
    if (longestDistance != null) records.add(longestDistance);
    if (topSpeed != null) records.add(topSpeed);

    return records;
  }
}
