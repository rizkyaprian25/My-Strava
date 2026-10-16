import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/map_style.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/storage/segment_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/gpx_exporter.dart';
import '../../../core/utils/route_gradient_helper.dart';
import '../../../core/utils/share_card_dialog.dart';
import '../../../core/widgets/elevation_profile_chart.dart';
import '../../../core/widgets/map_layer_selector_button.dart';
import '../../replay/presentation/route_replay_screen.dart';

/// Layar rincian aktivitas komprehensif: peta multi-layer, 3D flyover replay,
/// grafik elevasi interaktif, pewarnaan rute gradien, dan segmen KOM.
class ActivityDetailScreen extends StatefulWidget {
  final ActivityModel activity;
  final VoidCallback? onActivityDeleted;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.onActivityDeleted,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final MapController _mapController = MapController();
  final SegmentRepository _segmentRepo = SegmentRepository();

  AppMapStyle _mapStyle = AppMapStyle.dark;
  RouteColorMode _colorMode = RouteColorMode.solidOrange;
  int? _scrubbedPointIndex;
  List<SegmentMatchResult> _segmentMatches = [];

  @override
  void initState() {
    super.initState();
    _checkSegmentMatches();
  }

  Future<void> _checkSegmentMatches() async {
    final matches =
        await _segmentRepo.evaluateActivityAgainstSegments(widget.activity);
    if (!mounted) return;
    setState(() {
      _segmentMatches = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = widget.activity.routePoints;
    final latLngPoints =
        routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');

    LatLng center = const LatLng(-6.2088, 106.8456);
    if (latLngPoints.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (final p in latLngPoints) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      center = LatLng(sumLat / latLngPoints.length, sumLng / latLngPoints.length);
    }

    final polylines = RouteGradientHelper.generatePolylines(
      points: routePoints,
      mode: _colorMode,
      strokeWidth: 4.5,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.title),
        actions: [
          // Tombol 3D Flyover Replay
          if (routePoints.length >= 2)
            IconButton(
              icon: const Icon(Icons.flight_takeoff, color: AppTheme.stravaOrange),
              tooltip: '3D Flyover Replay',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) =>
                        RouteReplayScreen(activity: widget.activity),
                  ),
                );
              },
            ),
          // Tombol Bagikan Kartu
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Bagikan Kartu Transparan / Foto',
            onPressed: () {
              ShareCardDialog.show(context, widget.activity);
            },
          ),
          // Tombol Ekspor GPX
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Ekspor GPX',
            onPressed: () => _showGpxExportDialog(context),
          ),
          // Tombol Hapus Aktivitas
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.accentRed),
            tooltip: 'Hapus',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Peta Rute Interaktif dengan Pilihan Layer dan Polylines
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: latLngPoints.length > 1 ? 14.5 : 16.0,
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
                      PolylineLayer(polylines: polylines),
                      if (latLngPoints.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            // Titik Mulai (Start - Hijau)
                            Marker(
                              point: latLngPoints.first,
                              width: 22,
                              height: 22,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                            // Titik Selesai (Finish - Merah)
                            if (latLngPoints.length > 1)
                              Marker(
                                point: latLngPoints.last,
                                width: 22,
                                height: 22,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            // Marker Titik yang Sedang Di-scrub di Grafik Elevasi
                            if (_scrubbedPointIndex != null &&
                                _scrubbedPointIndex! >= 0 &&
                                _scrubbedPointIndex! < latLngPoints.length)
                              Marker(
                                point: latLngPoints[_scrubbedPointIndex!],
                                width: 28,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.stravaOrange,
                                      width: 4,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),

                  // Floating Layer Switcher di Kanan Atas
                  Positioned(
                    top: 12,
                    right: 12,
                    child: MapLayerSelectorButton(
                      currentStyle: _mapStyle,
                      onStyleChanged: (newStyle) {
                        setState(() => _mapStyle = newStyle);
                      },
                    ),
                  ),

                  // Tombol Putar Ulang 3D di Kiri Bawah Peta
                  if (routePoints.length >= 2)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: AppTheme.stravaOrange),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) =>
                                  RouteReplayScreen(activity: widget.activity),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_fill,
                            color: AppTheme.stravaOrange, size: 18),
                        label: const Text(
                          '3D Flyover Replay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector Warna Jalur Rute (Klasik, Kecepatan, Elevasi 3D)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Visualisasi Jalur:',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      DropdownButton<RouteColorMode>(
                        value: _colorMode,
                        dropdownColor: AppTheme.cardSurface,
                        style: const TextStyle(
                          color: AppTheme.stravaOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        underline: const SizedBox(),
                        items: RouteColorMode.values.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m.displayName),
                          );
                        }).toList(),
                        onChanged: (mode) {
                          if (mode != null) {
                            setState(() => _colorMode = mode);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Header Aktivitas
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.activity.sportType.icon,
                          color: AppTheme.stravaOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.activity.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(widget.activity.startTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (widget.activity.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.activity.description,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Grafik Profil Ketinggian 3D Interaktif
                  if (routePoints.length >= 2) ...[
                    ElevationProfileChart(
                      points: routePoints,
                      selectedIndex: _scrubbedPointIndex,
                      onIndexHovered: (idx) {
                        setState(() {
                          _scrubbedPointIndex = idx;
                        });
                        final pt = routePoints[idx];
                        _mapController.move(
                          LatLng(pt.latitude, pt.longitude),
                          _mapController.camera.zoom,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Segmen Lintasan & Mahkota KOM jika terdeteksi
                  if (_segmentMatches.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Segmen Terlewati (${_segmentMatches.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._segmentMatches.map((m) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: m.isNewPB ? Colors.amber : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m.segment.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (m.isNewPB) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'PR BARU!',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${m.segment.distanceMeters.toStringAsFixed(0)} m • Rata-rata ${m.avgSpeedKmh.toStringAsFixed(1)} km/h',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              m.formattedEffort,
                              style: TextStyle(
                                color: m.isNewPB
                                    ? Colors.amber
                                    : AppTheme.stravaOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Grid Statistik Khas Strava
                  const Text(
                    'Ringkasan Latihan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildMetricCard(
                        title: 'Jarak',
                        value:
                            '${widget.activity.distanceKm.toStringAsFixed(2)} km',
                      ),
                      _buildMetricCard(
                        title: 'Waktu Bergerak',
                        value: widget.activity.durationFormatted,
                      ),
                      _buildMetricCard(
                        title: 'Rata-rata Pace',
                        value: widget.activity.avgPaceFormatted,
                      ),
                      _buildMetricCard(
                        title: 'Kenaikan Elevasi',
                        value:
                            '${widget.activity.elevationGainMeters.toStringAsFixed(0)} m',
                      ),
                      _buildMetricCard(
                        title: 'Kecepatan Rata-rata',
                        value:
                            '${widget.activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                      ),
                      _buildMetricCard(
                        title: 'Kalori',
                        value: '${widget.activity.calories} kcal',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tabel KM Splits
                  if (widget.activity.splits.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pecahan Jarak (KM Splits)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.activity.splits.length} km selesai',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.activity.splits.length,
                        separatorBuilder: (ctx, i) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (ctx, index) {
                          final split = widget.activity.splits[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardSurfaceLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${split.kilometer}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kilometer ke-${split.kilometer}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Elevasi: ${split.elevationChange >= 0 ? '+' : ''}${split.elevationChange.toStringAsFixed(0)} m',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  split.paceFormatted,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.stravaOrange,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showGpxExportDialog(BuildContext context) {
    final gpxContent = GpxExporter.exportToGpx(widget.activity);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Ekspor File GPX 1.1'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Format GPX 1.1 standar kompatibel dengan Garmin Connect, Strava resmi, Komoot, dan Google Earth.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total ${widget.activity.routePoints.length} titik koordinat terekam.',
                style: const TextStyle(
                  color: AppTheme.stravaOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.stravaOrange),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: gpxContent));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Konten XML GPX 1.1 berhasil disalin ke papan klip!',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin GPX XML'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Hapus Aktivitas?'),
        content: const Text(
          'Aktivitas ini akan dihapus secara permanen dari penyimpanan perangkat Anda.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () async {
              final repo = ActivityRepository();
              await repo.deleteActivity(widget.activity.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                widget.onActivityDeleted?.call();
                Navigator.pop(context);
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
