import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../contracts/activity_model.dart';

/// Repository lokal untuk menyimpan dan membaca riwayat aktivitas olahraga.
class ActivityRepository {
  static const String _fileName = 'my_strava_activities.json';

  /// Mendapatkan path file penyimpanan lokal.
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Membaca seluruh daftar aktivitas yang tersimpan.
  Future<List<ActivityModel>> getAllActivities() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(contents) as List<dynamic>;
      final activities = jsonList
          .map((item) => ActivityModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Urutkan aktivitas dari yang paling baru ke lama
      activities.sort((a, b) => b.startTime.compareTo(a.startTime));
      return activities;
    } catch (e) {
      debugPrint('Error saat membaca file aktivitas: $e');
      return [];
    }
  }

  /// Menyimpan satu aktivitas baru ke penyimpanan lokal.
  Future<void> saveActivity(ActivityModel activity) async {
    final activities = await getAllActivities();
    // Tambahkan di awal daftar
    activities.insert(0, activity);

    final file = await _getLocalFile();
    final jsonString = jsonEncode(activities.map((a) => a.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  /// Menghapus aktivitas berdasarkan ID.
  Future<void> deleteActivity(String id) async {
    final activities = await getAllActivities();
    activities.removeWhere((a) => a.id == id);

    final file = await _getLocalFile();
    final jsonString = jsonEncode(activities.map((a) => a.toJson()).toList());
    await file.writeAsString(jsonString);
  }
}
