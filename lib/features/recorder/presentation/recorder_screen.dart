import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/gear_model.dart';
import '../../../contracts/location_point.dart';
import '../../../contracts/map_style.dart';
import '../../../contracts/sport_type.dart';
import '../../../core/services/background_service.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/storage/profile_gear_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_calculator.dart';
import '../../../core/widgets/map_layer_selector_button.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'save_activity_dialog.dart';

/// Status siklus hidup mesin perekam aktivitas.
enum RecorderState { idle, recording, paused }

/// Layar utama perekam aktivitas GPS langsung dengan HUD telemetri dan peta rute.
class RecorderScreen extends StatefulWidget {
  final VoidCallback? onActivitySaved;

  const RecorderScreen({super.key, this.onActivitySaved});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final MapController _mapController = MapController();
  final ActivityRepository _repository = ActivityRepository();

  RecorderState _state = RecorderState.idle;
  SportType _selectedSport = SportType.run;
  AppMapStyle _mapStyle = AppMapStyle.dark;

  // Data telemetri sesi berjalan
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _totalDistanceMeters = 0.0;
  double _currentSpeedKmh = 0.0;
  double _maxSpeedKmh = 0.0;
  double _elevationGainMeters = 0.0;
  DateTime? _sessionStartTime;

  // Jejak titik koordinat GPS
  final List<LocationPoint> _routePoints = [];
  LatLng? _currentLatLng;
  StreamSubscription<Position>? _positionStream;

  // Pengaturan cerdas khas Strava
  final bool _autoPauseEnabled = true;
  int _lowSpeedCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetInitialPosition();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  /// Menerima perintah tombol dari notifikasi lockscreen (Jeda, Lanjutkan, Selesai).
  void _onReceiveTaskData(dynamic data) {
    if (data is Map && data.containsKey('action')) {
      final action = data['action'];
      if (action == 'pause') {
        _pauseRecording();
      } else if (action == 'resume') {
        _resumeRecording();
      } else if (action == 'stop') {
        _stopRecording();
      }
    }
  }

  /// Memeriksa izin GPS Android dan mengambil posisi awal atlet.
  Future<void> _checkPermissionsAndGetInitialPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showToast('Silakan aktifkan layanan GPS di pengaturan perangkat.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showToast('Izin lokasi GPS ditolak oleh pengguna.');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showToast('Izin lokasi ditolak permanen. Buka pengaturan aplikasi.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentLatLng = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(_currentLatLng!, 16.5);
      }
    } catch (e) {
      debugPrint('Error mendapatkan posisi GPS: $e');
    }
  }

  /// Memulai sesi perekaman GPS baru dengan layanan background lockscreen.
  void _startRecording() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _checkPermissionsAndGetInitialPosition();
      return;
    }

    // Minta izin notifikasi & pengecualian baterai Android
    await BackgroundServiceManager.requestPermissions();

    setState(() {
      _state = RecorderState.recording;
      _elapsedSeconds = 0;
      _totalDistanceMeters = 0.0;
      _currentSpeedKmh = 0.0;
      _maxSpeedKmh = 0.0;
      _elevationGainMeters = 0.0;
      _sessionStartTime = DateTime.now();
      _routePoints.clear();
      _lowSpeedCounter = 0;
    });

    // Jalankan Foreground Service agar tetap aktif saat layar mati
    await BackgroundServiceManager.startService(
      sportName: _selectedSport.displayName,
      initialMetrics: '0.00 km • 00:00 • Pace: -:--',
    );

    // Mulai timer hitungan waktu bergerak
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == RecorderState.recording) {
        setState(() {
          _elapsedSeconds++;
        });

        // Perbarui tampilan notifikasi di lockscreen secara konstan
        final distKm = _totalDistanceMeters / 1000.0;
        final paceStr = _calculatePace();
        final calories = GeoCalculator.estimateCalories(
          sportType: _selectedSport,
          durationSeconds: _elapsedSeconds,
        );

        BackgroundServiceManager.updateNotification(
          title: '${_selectedSport.displayName} • ${_formatElapsedTime(_elapsedSeconds)}',
          text: '${distKm.toStringAsFixed(2)} km • Pace: $paceStr /km • $calories kcal',
          isPaused: false,
        );
      }
    });

    // Mulai streaming stream lokasi GPS dari hardware
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Update setiap perpindahan minimal 3 meter
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      // Mekanisme Jeda Otomatis (Auto-Pause) saat atlet berhenti
      if (_autoPauseEnabled) {
        if (position.speed < 0.45) { // Di bawah 1.6 km/jam dianggap berhenti
          _lowSpeedCounter++;
          if (_lowSpeedCounter >= 4 && _state == RecorderState.recording) {
            _pauseRecording();
            _showToast('Jeda Otomatis aktif (Anda berhenti bergerak).');
          }
        } else {
          _lowSpeedCounter = 0;
          if (_state == RecorderState.paused) {
            _resumeRecording();
            _showToast('Melanjutkan otomatis (Gerakan terdeteksi).');
          }
        }
      }

      if (_state != RecorderState.recording) return;

      final newPoint = LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
        speed: position.speed > 0 ? position.speed : 0.0,
        timestamp: DateTime.now(),
      );

      final newLatLng = newPoint.toLatLng();

      setState(() {
        if (_routePoints.isNotEmpty) {
          final lastPoint = _routePoints.last;
          final dist = GeoCalculator.calculateDistance(
            lastPoint.latitude,
            lastPoint.longitude,
            newPoint.latitude,
            newPoint.longitude,
          );

          // Filter anomali loncatan GPS (abaikan jika perpindahan > 50 meter per detik)
          if (dist < 50.0 && dist > 1.5) {
            _totalDistanceMeters += dist;

            // Hitung kenaikan elevasi kumulatif
            final altDiff = newPoint.altitude - lastPoint.altitude;
            if (altDiff > 0.5) {
              _elevationGainMeters += altDiff;
            }
          }
        }

        // Kecepatan dalam km/jam (meter/detik x 3.6)
        _currentSpeedKmh = (position.speed * 3.6).clamp(0.0, 120.0);
        if (_currentSpeedKmh > _maxSpeedKmh) {
          _maxSpeedKmh = _currentSpeedKmh;
        }

        _routePoints.add(newPoint);
        _currentLatLng = newLatLng;
      });

      _mapController.move(newLatLng, _mapController.camera.zoom);
    });
  }

  /// Menjeda sementara sesi perekaman.
  void _pauseRecording() {
    setState(() {
      _state = RecorderState.paused;
      _currentSpeedKmh = 0.0;
    });

    final distKm = _totalDistanceMeters / 1000.0;
    BackgroundServiceManager.updateNotification(
      title: '${_selectedSport.displayName} • DIJEDA',
      text: '${distKm.toStringAsFixed(2)} km • ${_formatElapsedTime(_elapsedSeconds)}',
      isPaused: true,
    );
  }

  /// Melanjutkan sesi perekaman setelah dijeda.
  void _resumeRecording() {
    setState(() {
      _state = RecorderState.recording;
    });

    final distKm = _totalDistanceMeters / 1000.0;
    BackgroundServiceManager.updateNotification(
      title: '${_selectedSport.displayName} • ${_formatElapsedTime(_elapsedSeconds)}',
      text: '${distKm.toStringAsFixed(2)} km • Pace: ${_calculatePace()} /km',
      isPaused: false,
    );
  }

  /// Mengakhiri sesi dan menampilkan dialog simpan aktivitas.
  Future<void> _stopRecording() async {
    _timer?.cancel();
    _positionStream?.cancel();
    await BackgroundServiceManager.stopService();

    if (!mounted) return;

    if (_totalDistanceMeters < 50 && _elapsedSeconds < 15) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          title: const Text('Aktivitas Terlalu Singkat'),
          content: const Text(
            'Jarak atau durasi latihan terlalu pendek untuk disimpan. Hapus sesi ini?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjutkan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buang Sesi'),
            ),
          ],
        ),
      );

      if (discard == true) {
        setState(() {
          _state = RecorderState.idle;
          _elapsedSeconds = 0;
          _totalDistanceMeters = 0.0;
          _routePoints.clear();
        });
        return;
      }
    }

    if (!mounted) return;

    // Tampilkan dialog simpan
    final savedActivity = await showDialog<ActivityModel>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SaveActivityDialog(
        initialSportType: _selectedSport,
        durationSeconds: _elapsedSeconds,
        distanceMeters: _totalDistanceMeters,
        maxSpeedKmh: _maxSpeedKmh,
        elevationGainMeters: _elevationGainMeters,
        routePoints: List.from(_routePoints),
        startTime: _sessionStartTime ?? DateTime.now(),
      ),
    );

    if (savedActivity != null) {
      await _repository.saveActivity(savedActivity);

      // Tambahkan akumulasi jarak tempuh ke perlengkapan default (sepatu/sepeda)
      final gearType = savedActivity.sportType == SportType.ride
          ? GearType.bike
          : GearType.shoes;
      await ProfileGearRepository()
          .addMileageToDefaultGear(gearType, savedActivity.distanceMeters);

      if (mounted) {
        _showToast('Aktivitas berhasil disimpan & perlengkapan diperbarui!');
        widget.onActivitySaved?.call();
      }
    }

    setState(() {
      _state = RecorderState.idle;
      _elapsedSeconds = 0;
      _totalDistanceMeters = 0.0;
      _routePoints.clear();
      _currentSpeedKmh = 0.0;
      _maxSpeedKmh = 0.0;
      _elevationGainMeters = 0.0;
    });
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.cardSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Menghitung pace saat ini dalam format mm:ss /km.
  String _calculatePace() {
    if (_currentSpeedKmh <= 0.5) return '-:--';
    // Menit per kilometer = 60 / kecepatan (km/jam)
    final totalMinutes = 60.0 / _currentSpeedKmh;
    if (totalMinutes > 30.0) return '-:--';
    final mins = totalMinutes.toInt();
    final secs = ((totalMinutes - mins) * 60).toInt();
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _totalDistanceMeters / 1000.0;
    final polylinePoints = _routePoints.map((p) => p.toLatLng()).toList();
    final calories = GeoCalculator.estimateCalories(
      sportType: _selectedSport,
      durationSeconds: _elapsedSeconds,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Lapisan 1: Peta Interaktif (OpenStreetMap Leaflet Engine)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLatLng ?? const LatLng(-6.2088, 106.8456), // Jakarta default
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapStyle.urlTemplate,
                userAgentPackageName: 'com.mystrava.app',
                maxZoom: 19,
              ),
              // Garis Trek Rute Olahraga (Warna Khas Strava Orange)
              if (polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5.0,
                      color: AppTheme.stravaOrange,
                    ),
                  ],
                ),
              // Titik Posisi Atlet Saat Ini
              if (_currentLatLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLatLng!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.stravaOrange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.stravaOrange.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Lapisan 2: Header Pilihan Olahraga (Hanya saat idle)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Pilihan Mode Olahraga
                    if (_state == RecorderState.idle)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<SportType>(
                            value: _selectedSport,
                            dropdownColor: AppTheme.cardSurface,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppTheme.stravaOrange,
                            ),
                            items: SportType.values.map((type) {
                              return DropdownMenuItem<SportType>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      type.icon,
                                      color: AppTheme.stravaOrange,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      type.displayName,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSport = val;
                                });
                              }
                            },
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _state == RecorderState.recording
                              ? AppTheme.accentGreen.withValues(alpha: 0.2)
                              : AppTheme.accentAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _state == RecorderState.recording
                                ? AppTheme.accentGreen
                                : AppTheme.accentAmber,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _state == RecorderState.recording
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentAmber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _state == RecorderState.recording
                                  ? 'MEREKAM GPS'
                                  : 'DIJEDA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _state == RecorderState.recording
                                    ? AppTheme.accentGreen
                                    : AppTheme.accentAmber,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        MapLayerSelectorButton(
                          currentStyle: _mapStyle,
                          onStyleChanged: (newStyle) {
                            setState(() => _mapStyle = newStyle);
                          },
                        ),
                        const SizedBox(width: 8),
                        FloatingActionButton.small(
                          heroTag: 'recenter_gps',
                          backgroundColor: AppTheme.cardSurface,
                          onPressed: () {
                            if (_currentLatLng != null) {
                              _mapController.move(_currentLatLng!, 17.0);
                            } else {
                              _checkPermissionsAndGetInitialPosition();
                            }
                          },
                          child: const Icon(
                            Icons.my_location,
                            color: AppTheme.stravaOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lapisan 3: Panel Telemetri Bawah (HUD Metrik Langsung)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Angka Utama: Jarak & Waktu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPrimaryMetric(
                        label: 'JARAK',
                        value: distanceKm.toStringAsFixed(2),
                        unit: 'km',
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _buildPrimaryMetric(
                        label: 'WAKTU',
                        value: _formatElapsedTime(_elapsedSeconds),
                        unit: '',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metrik Sekunder: Pace/Kecepatan, Elevasi, Kalori
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSecondaryMetric(
                        label: _selectedSport == SportType.ride
                            ? 'KECEPATAN'
                            : 'PACE',
                        value: _selectedSport == SportType.ride
                            ? '${_currentSpeedKmh.toStringAsFixed(1)} km/h'
                            : '${_calculatePace()} /km',
                      ),
                      _buildSecondaryMetric(
                        label: 'ELEVASI',
                        value: '${_elevationGainMeters.toStringAsFixed(0)} m',
                      ),
                      _buildSecondaryMetric(
                        label: 'KALORI',
                        value: '$calories kcal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Baris Tombol Kontrol (Start, Pause, Resume, Stop)
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun tombol kontrol berdasarkan status saat ini.
  Widget _buildControlButtons() {
    if (_state == RecorderState.idle) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.stravaOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(27),
            ),
          ),
          onPressed: _startRecording,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text(
            'MULAI LATIHAN',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    if (_state == RecorderState.recording) {
      return SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          heroTag: 'pause_btn',
          backgroundColor: AppTheme.accentAmber,
          elevation: 4,
          onPressed: _pauseRecording,
          child: const Icon(
            Icons.pause_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
      );
    }

    // State == Paused: Tampilkan Resume (Hijau) & Finish (Merah)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Tombol Lanjutkan (Resume)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: FloatingActionButton(
                heroTag: 'resume_btn',
                backgroundColor: AppTheme.accentGreen,
                elevation: 4,
                onPressed: _resumeRecording,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lanjutkan',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // Tombol Selesai (Stop & Save)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 68,
              height: 68,
              child: FloatingActionButton(
                heroTag: 'stop_btn',
                backgroundColor: AppTheme.accentRed,
                elevation: 4,
                onPressed: _stopRecording,
                child: const Icon(
                  Icons.stop_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selesai',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryMetric({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -1.0,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  String _formatElapsedTime(int seconds) {
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
