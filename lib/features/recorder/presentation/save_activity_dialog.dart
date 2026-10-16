import 'package:flutter/material.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/km_split.dart';
import '../../../contracts/location_point.dart';
import '../../../contracts/sport_type.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_calculator.dart';

/// Dialog konfirmasi untuk menamai dan menyimpan sesi aktivitas yang baru selesai.
class SaveActivityDialog extends StatefulWidget {
  final SportType initialSportType;
  final int durationSeconds;
  final double distanceMeters;
  final double maxSpeedKmh;
  final double elevationGainMeters;
  final List<LocationPoint> routePoints;
  final DateTime startTime;

  const SaveActivityDialog({
    super.key,
    required this.initialSportType,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.routePoints,
    required this.startTime,
  });

  @override
  State<SaveActivityDialog> createState() => _SaveActivityDialogState();
}

class _SaveActivityDialogState extends State<SaveActivityDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late SportType _selectedSportType;
  String? _detectedLocation;
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    _selectedSportType = widget.initialSportType;
    _titleController = TextEditingController(text: _generateDefaultTitle());
    _descController = TextEditingController();
    _fetchContextData();
  }

  Future<void> _fetchContextData() async {
    if (widget.routePoints.isEmpty) return;
    final startPt = widget.routePoints.first;

    // Panggil geocoding dan cuaca secara paralel (100% bebas API key)
    final results = await Future.wait([
      GeocodingService.reverseGeocode(startPt.latitude, startPt.longitude),
      WeatherService.fetchWeather(startPt.latitude, startPt.longitude),
    ]);

    if (!mounted) return;
    final loc = results[0] as String?;
    final weather = results[1] as WeatherInfo?;

    setState(() {
      _detectedLocation = loc;
      _weatherInfo = weather;
      if (loc != null && _titleController.text == _generateDefaultTitle()) {
        _titleController.text = '${_generateDefaultTitle()} di $loc';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Menghasilkan nama aktivitas bawaan berdasarkan waktu dan jenis olahraga.
  String _generateDefaultTitle() {
    final hour = widget.startTime.hour;
    String timeOfDay;
    if (hour >= 4 && hour < 11) {
      timeOfDay = 'Pagi';
    } else if (hour >= 11 && hour < 15) {
      timeOfDay = 'Siang';
    } else if (hour >= 15 && hour < 18) {
      timeOfDay = 'Sore';
    } else {
      timeOfDay = 'Malam';
    }
    return '${_selectedSportType.displayName} $timeOfDay';
  }

  /// Menghitung kalkulasi split per kilometer otomatis dari data rute.
  List<KmSplit> _calculateSplits() {
    if (widget.routePoints.length < 2 || widget.distanceMeters < 100) return [];

    final splits = <KmSplit>[];
    double accumulatedDistance = 0.0;
    int currentKm = 1;
    DateTime lastKmTime = widget.startTime;
    double lastKmAlt = widget.routePoints.first.altitude;

    for (int i = 1; i < widget.routePoints.length; i++) {
      final p1 = widget.routePoints[i - 1];
      final p2 = widget.routePoints[i];

      final dist = GeoCalculator.calculateDistance3D(
        p1.latitude,
        p1.longitude,
        p1.altitude,
        p2.latitude,
        p2.longitude,
        p2.altitude,
      );
      accumulatedDistance += dist;

      if (accumulatedDistance >= currentKm * 1000.0) {
        final splitDuration =
            p2.timestamp.difference(lastKmTime).inSeconds.clamp(1, 7200);
        final elevDiff = p2.altitude - lastKmAlt;

        splits.add(KmSplit(
          kilometer: currentKm,
          durationSeconds: splitDuration,
          elevationChange: elevDiff,
        ));

        currentKm++;
        lastKmTime = p2.timestamp;
        lastKmAlt = p2.altitude;
      }
    }

    return splits;
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = widget.distanceMeters / 1000.0;
    final avgSpeedKmh = widget.durationSeconds > 0
        ? (distanceKm / (widget.durationSeconds / 3600.0))
        : 0.0;
    final calories = GeoCalculator.estimateCalories(
      sportType: _selectedSportType,
      durationSeconds: widget.durationSeconds,
    );

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.stravaOrange,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Simpan Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ringkasan metrik singkat
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardSurfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricPreview(
                    label: 'Jarak',
                    value: '${distanceKm.toStringAsFixed(2)} km',
                  ),
                  _buildMetricPreview(
                    label: 'Waktu',
                    value: _formatDuration(widget.durationSeconds),
                  ),
                  _buildMetricPreview(
                    label: 'Kalori',
                    value: '$calories kcal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pilihan jenis olahraga
            const Text(
              'Jenis Olahraga',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SportType.values.map((type) {
                  final isSelected = _selectedSportType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        children: [
                          Icon(
                            type.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(type.displayName),
                        ],
                      ),
                      selectedColor: AppTheme.stravaOrange,
                      backgroundColor: AppTheme.cardSurfaceLight,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSportType = type;
                            _titleController.text = _generateDefaultTitle();
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            // Badge Lokasi & Cuaca Otomatis (100% Bebas API Key)
            if (_detectedLocation != null || _weatherInfo != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (_detectedLocation != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.stravaOrange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              color: AppTheme.stravaOrange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _detectedLocation!,
                            style: const TextStyle(
                              color: AppTheme.stravaOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_weatherInfo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_outlined,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _weatherInfo!.formattedSummary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Form Judul
            const Text(
              'Judul Aktivitas',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.cardSurfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),

            // Form Deskripsi
            const Text(
              'Catatan / Deskripsi (Opsional)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bagaimana perasaan Anda selama sesi ini?',
                hintStyle:
                    const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppTheme.cardSurfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.stravaOrange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      final newActivity = ActivityModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: _titleController.text.trim().isEmpty
                            ? _generateDefaultTitle()
                            : _titleController.text.trim(),
                        description: _descController.text.trim(),
                        sportType: _selectedSportType,
                        startTime: widget.startTime,
                        durationSeconds: widget.durationSeconds,
                        distanceMeters: widget.distanceMeters,
                        calories: calories,
                        avgSpeedKmh: avgSpeedKmh,
                        maxSpeedKmh: widget.maxSpeedKmh,
                        elevationGainMeters: widget.elevationGainMeters,
                        routePoints: widget.routePoints,
                        splits: _calculateSplits(),
                        locationName: _detectedLocation,
                        temperatureCelsius: _weatherInfo?.temperatureCelsius,
                        weatherCondition: _weatherInfo?.conditionDescription,
                      );
                      Navigator.of(context).pop(newActivity);
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPreview({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}
