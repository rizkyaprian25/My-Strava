import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Handler tugas background yang dijalankan di isolate terpisah oleh flutter_foreground_task.
class MyStravaTaskHandler extends TaskHandler {
  // Callback saat tombol notifikasi di lockscreen ditekan
  static void Function(String actionId)? onNotificationAction;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('Foreground service My Strava dimulai: $timestamp');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Tidak digunakan karena update notifikasi dipicu oleh state perekam
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint('Foreground service My Strava dihentikan: $timestamp');
  }

  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('Tombol notifikasi lockscreen ditekan: $id');
    // Kirim event ke main isolate
    FlutterForegroundTask.sendDataToMain({'action': id});
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}

/// Fungsi entry-point tingkat teratas untuk isolate latar belakang Android.
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(MyStravaTaskHandler());
}

/// Manajer layanan background dan notifikasi lockscreen untuk My Strava.
class BackgroundServiceManager {
  static bool _isInitialized = false;

  /// Inisialisasi opsi notifikasi Android agar muncul di Lock Screen dengan prioritas tinggi.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'my_strava_recording_channel',
        channelName: 'Perekaman Aktivitas My Strava',
        channelDescription:
            'Menampilkan status telemetri waktu, jarak, dan pace secara langsung di lock screen.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC, // Kunci agar muncul di lock screen
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;
  }

  /// Meminta izin notifikasi dan optimasi baterai agar Android tidak mematikan aplikasi di background.
  static Future<void> requestPermissions() async {
    final notifPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // Minta pengecualian penghemat baterai jika belum aktif
    final isIgnoringBattery =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;
    if (!isIgnoringBattery) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  /// Memulai Foreground Service dengan notifikasi persisten di lock screen.
  static Future<void> startService({
    required String sportName,
    required String initialMetrics,
  }) async {
    await initialize();

    if (await FlutterForegroundTask.isRunningService) {
      await updateNotification(
        title: '$sportName • Berjalan di Background',
        text: initialMetrics,
        isPaused: false,
      );
      return;
    }

    await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: '$sportName Sedang Berlangsung',
      notificationText: initialMetrics,
      notificationButtons: [
        const NotificationButton(id: 'pause', text: 'Jeda'),
        const NotificationButton(id: 'stop', text: 'Selesai'),
      ],
      callback: startForegroundCallback,
    );
  }

  /// Memperbarui isi notifikasi di lock screen secara real-time (Jarak, Waktu, Pace).
  static Future<void> updateNotification({
    required String title,
    required String text,
    required bool isPaused,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationButtons: isPaused
          ? [
              const NotificationButton(id: 'resume', text: 'Lanjutkan'),
              const NotificationButton(id: 'stop', text: 'Selesai'),
            ]
          : [
              const NotificationButton(id: 'pause', text: 'Jeda'),
              const NotificationButton(id: 'stop', text: 'Selesai'),
            ],
    );
  }

  /// Menghentikan Foreground Service saat latihan selesai.
  static Future<void> stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}
