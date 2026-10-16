import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/map_style.dart';
import '../../../contracts/sport_type.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/map_layer_selector_button.dart';

/// Layar Personal Heatmap (Peta Panas Pribadi) ala Strava Subscriber Heatmap.
class PersonalHeatmapScreen extends StatefulWidget {
  const PersonalHeatmapScreen({super.key});

  @override
  State<PersonalHeatmapScreen> createState() => _PersonalHeatmapScreenState();
}

class _PersonalHeatmapScreenState extends State<PersonalHeatmapScreen> {
  final ActivityRepository _activityRepo = ActivityRepository();
  final MapController _mapController = MapController();

  AppMapStyle _mapStyle = AppMapStyle.dark; // Default Strava Dark untuk kontras neon
  SportType? _selectedFilter; // null = semua olahraga
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    setState(() => _isLoading = true);
    final list = await _activityRepo.getAllActivities();
    if (!mounted) return;
    setState(() {
      _activities = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == null
        ? _activities
        : _activities.where((a) => a.sportType == _selectedFilter).toList();

    // Kumpulkan seluruh polylines dari semua aktivitas
    final List<Polyline> heatmapPolylines = [];
    final List<LatLng> allCoordinates = [];

    for (final act in filtered) {
      if (act.routePoints.length < 2) continue;
      final points =
          act.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
      allCoordinates.addAll(points);

      // Garis glow dasar
      heatmapPolylines.add(
        Polyline(
          points: points,
          strokeWidth: 4.5,
          color: const Color(0xFFFC5200).withValues(alpha: 0.35),
        ),
      );

      // Inti garis terang
      heatmapPolylines.add(
        Polyline(
          points: points,
          strokeWidth: 2.0,
          color: const Color(0xFFFF9100).withValues(alpha: 0.55),
        ),
      );
    }

    final totalKm =
        filtered.fold<double>(0.0, (sum, a) => sum + a.distanceKm);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: AppTheme.stravaOrange),
            SizedBox(width: 8),
            Text('Personal Heatmap'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHeatmapData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.stravaOrange))
          : Stack(
              children: [
                // Peta Heatmap Layar Penuh
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: allCoordinates.isNotEmpty
                        ? allCoordinates.first
                        : const LatLng(-6.2088, 106.8456), // Monas default
                    initialZoom: 13.0,
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
                    PolylineLayer(
                      polylines: heatmapPolylines,
                    ),
                  ],
                ),

                // Floating Map Layer Switcher di Kanan Atas
                Positioned(
                  top: 16,
                  right: 16,
                  child: MapLayerSelectorButton(
                    currentStyle: _mapStyle,
                    onStyleChanged: (style) {
                      setState(() => _mapStyle = style);
                    },
                  ),
                ),

                // Panel Atas: Filter Jenis Olahraga
                Positioned(
                  top: 16,
                  left: 16,
                  right: 80,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', null),
                        const SizedBox(width: 6),
                        _buildFilterChip('Lari', SportType.run),
                        const SizedBox(width: 6),
                        _buildFilterChip('Sepeda', SportType.ride),
                        const SizedBox(width: 6),
                        _buildFilterChip('Jalan', SportType.walk),
                      ],
                    ),
                  ),
                ),

                // Panel Bawah: Ringkasan Total Jejak
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          label: 'TOTAL JALUR',
                          value: '${filtered.length} Aktivitas',
                        ),
                        Container(
                          width: 1,
                          height: 28,
                          color: Colors.white12,
                        ),
                        _buildSummaryItem(
                          label: 'JEJAK TERPETAKAN',
                          value: '${totalKm.toStringAsFixed(1)} km',
                        ),
                      ],
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text(
                        'Belum ada data aktivitas untuk digambar di Heatmap.\nSelesaikan latihan dan simpan rute Anda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, SportType? type) {
    final isSelected = _selectedFilter == type;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppTheme.stravaOrange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = type);
      },
    );
  }

  Widget _buildSummaryItem({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            color: AppTheme.stravaOrange,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
