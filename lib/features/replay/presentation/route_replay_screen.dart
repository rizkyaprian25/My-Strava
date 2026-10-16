import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/map_style.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/elevation_profile_chart.dart';
import '../../../core/widgets/map_layer_selector_button.dart';

/// Layar 3D Route Flyover Replay (Animasi Putar Ulang Rute GPS ala Strava 3D Replay).
class RouteReplayScreen extends StatefulWidget {
  final ActivityModel activity;

  const RouteReplayScreen({super.key, required this.activity});

  @override
  State<RouteReplayScreen> createState() => _RouteReplayScreenState();
}

class _RouteReplayScreenState extends State<RouteReplayScreen> {
  final MapController _mapController = MapController();
  AppMapStyle _mapStyle = AppMapStyle.satellite; // Default satelit untuk kesan 3D alam

  int _currentIndex = 0;
  bool _isPlaying = false;
  double _playbackSpeed = 2.0; // 1x, 2x, 5x, 10x
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _isPlaying = true;

    final intervalMs = (100 / _playbackSpeed).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) return;
      if (_currentIndex < widget.activity.routePoints.length - 1) {
        setState(() {
          _currentIndex++;
        });

        // Geser kamera peta secara berkala mengikuti titik atlet
        if (_currentIndex % 3 == 0) {
          final pt = widget.activity.routePoints[_currentIndex];
          _mapController.move(LatLng(pt.latitude, pt.longitude), _mapController.camera.zoom);
        }
      } else {
        // Sampai di garis finish
        _playbackTimer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      if (_currentIndex >= widget.activity.routePoints.length - 1) {
        _currentIndex = 0;
      }
      _startPlayback();
    }
  }

  void _seekTo(int index) {
    setState(() {
      _currentIndex = index.clamp(0, widget.activity.routePoints.length - 1);
    });
    final pt = widget.activity.routePoints[_currentIndex];
    _mapController.move(LatLng(pt.latitude, pt.longitude), _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.activity.routePoints;
    if (points.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Flyover Replay')),
        body: const Center(child: Text('Tidak ada titik koordinat untuk diputar.')),
      );
    }

    final currentPoint = points[_currentIndex];
    final passedPoints = points
        .sublist(0, _currentIndex + 1)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    final allPoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    // Hitung jarak tempuh saat ini
    final currentDistanceKm = (_currentIndex / (points.length - 1)) *
        widget.activity.distanceKm;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Peta Layar Penuh
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(currentPoint.latitude, currentPoint.longitude),
              initialZoom: 16.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _mapStyle.urlTemplate,
                userAgentPackageName: 'com.mystrava.app',
                maxZoom: 19,
              ),
              // Jalur Keseluruhan (Transparan)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: allPoints,
                    strokeWidth: 4.0,
                    color: Colors.white38,
                  ),
                  // Jalur yang Sudah Dilalui (Strava Orange Menyala)
                  Polyline(
                    points: passedPoints,
                    strokeWidth: 6.0,
                    color: const Color(0xFFFC5200),
                  ),
                ],
              ),
              // Marker Atlet yang Bergerak
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(currentPoint.latitude, currentPoint.longitude),
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.stravaOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.activity.sportType.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header Overlay (Back Button, Title & Map Layer Selector)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flight_takeoff,
                            color: AppTheme.stravaOrange, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '3D Flyover Replay (${_playbackSpeed.toInt()}x)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  MapLayerSelectorButton(
                    currentStyle: _mapStyle,
                    onStyleChanged: (newStyle) {
                      setState(() => _mapStyle = newStyle);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Panel Kontrol & Telemetri di Bagian Bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grafik Profil Elevasi Sinkron
                ElevationProfileChart(
                  points: points,
                  selectedIndex: _currentIndex,
                  onIndexHovered: (idx) => _seekTo(idx),
                ),
                const SizedBox(height: 8),

                // Kartu Kontrol Utama
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // HUD Angka Telemetri Live
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTelemetryItem(
                            label: 'JARAK',
                            value: '${currentDistanceKm.toStringAsFixed(2)} km',
                          ),
                          _buildTelemetryItem(
                            label: 'KECEPATAN',
                            value: '${currentPoint.speedKmh.toStringAsFixed(1)} km/h',
                          ),
                          _buildTelemetryItem(
                            label: 'KETINGGIAN',
                            value: '${currentPoint.altitude.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Slider Scrubber Rute
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape:
                              const RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: AppTheme.stravaOrange,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _currentIndex.toDouble(),
                          min: 0.0,
                          max: (points.length - 1).toDouble(),
                          onChanged: (val) => _seekTo(val.toInt()),
                        ),
                      ),

                      // Tombol Putar & Pengatur Kecepatan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Selector Kecepatan (1x, 2x, 5x, 10x)
                          DropdownButton<double>(
                            value: _playbackSpeed,
                            dropdownColor: AppTheme.cardSurface,
                            style: const TextStyle(
                              color: AppTheme.stravaOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(value: 1.0, child: Text('1x Laju')),
                              DropdownMenuItem(value: 2.0, child: Text('2x Laju')),
                              DropdownMenuItem(value: 5.0, child: Text('5x Laju')),
                              DropdownMenuItem(value: 10.0, child: Text('10x Laju')),
                            ],
                            onChanged: (speed) {
                              if (speed != null) {
                                setState(() => _playbackSpeed = speed);
                                if (_isPlaying) _startPlayback();
                              }
                            },
                          ),

                          // Tombol Play / Pause Utama
                          GestureDetector(
                            onTap: _togglePlayback,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppTheme.stravaOrange,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),

                          // Tombol Reset ke Awal
                          IconButton(
                            icon: const Icon(Icons.replay,
                                color: Colors.white70, size: 20),
                            tooltip: 'Ulangi dari Start',
                            onPressed: () => _seekTo(0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
