import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../contracts/activity_model.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/gpx_exporter.dart';

/// Layar rincian aktivitas lengkap: peta rute, metrik performa, tabel split KM, dan ekspor GPX.
class ActivityDetailScreen extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onActivityDeleted;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.onActivityDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final routePoints = activity.routePoints.map((p) => p.toLatLng()).toList();
    final dateFormat = DateFormat('EEEE, d MMMM yyyy • HH:mm', 'id_ID');

    // Menghitung titik tengah peta dan batas rute
    LatLng center = const LatLng(-6.2088, 106.8456);
    if (routePoints.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (final p in routePoints) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      center = LatLng(sumLat / routePoints.length, sumLng / routePoints.length);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        actions: [
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
            // Peta Rute Interaktif
            SizedBox(
              height: 280,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: routePoints.length > 1 ? 14.5 : 16.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mystrava.app',
                  ),
                  if (routePoints.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4.5,
                          color: AppTheme.stravaOrange,
                        ),
                      ],
                    ),
                  if (routePoints.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        // Titik Mulai (Start - Hijau)
                        Marker(
                          point: routePoints.first,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                        // Titik Selesai (Finish - Merah)
                        if (routePoints.length > 1)
                          Marker(
                            point: routePoints.last,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.accentRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          activity.sportType.icon,
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
                              activity.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormat.format(activity.startTime),
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

                  if (activity.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        activity.description,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

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
                        value: '${activity.distanceKm.toStringAsFixed(2)} km',
                      ),
                      _buildMetricCard(
                        title: 'Waktu Bergerak',
                        value: activity.durationFormatted,
                      ),
                      _buildMetricCard(
                        title: 'Rata-rata Pace',
                        value: activity.avgPaceFormatted,
                      ),
                      _buildMetricCard(
                        title: 'Kenaikan Elevasi',
                        value:
                            '${activity.elevationGainMeters.toStringAsFixed(0)} m',
                      ),
                      _buildMetricCard(
                        title: 'Kecepatan Rata-rata',
                        value: '${activity.avgSpeedKmh.toStringAsFixed(1)} km/h',
                      ),
                      _buildMetricCard(
                        title: 'Kalori',
                        value: '${activity.calories} kcal',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tabel KM Splits
                  if (activity.splits.isNotEmpty) ...[
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
                          '${activity.splits.length} km selesai',
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
                        itemCount: activity.splits.length,
                        separatorBuilder: (ctx, i) => Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        itemBuilder: (ctx, index) {
                          final split = activity.splits[index];
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog kode GPX dengan opsi salin ke clipboard.
  void _showGpxExportDialog(BuildContext context) {
    final gpxString = GpxExporter.exportToGpx(activity);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: Row(
          children: const [
            Icon(Icons.file_download, color: AppTheme.stravaOrange),
            SizedBox(width: 8),
            Text('Ekspor File GPX'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Format GPX 1.1 standar kompatibel dengan Garmin Connect, Strava resmi, Google Earth, dan Komoot.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardSurfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  gpxString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: AppTheme.textPrimary,
                  ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.stravaOrange),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Salin Data GPX'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: gpxString));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dokumen GPX berhasil disalin ke clipboard!'),
                  backgroundColor: AppTheme.stravaOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Konfirmasi hapus sesi aktivitas.
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Hapus Aktivitas?'),
        content: Text(
          'Sesi "${activity.title}" akan dihapus permanen dari penyimpanan lokal My Strava.',
          style: const TextStyle(color: AppTheme.textSecondary),
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
              await repo.deleteActivity(activity.id);
              if (context.mounted) {
                Navigator.pop(ctx); // Tutup dialog
                Navigator.pop(context); // Kembali ke riwayat
                onActivityDeleted?.call();
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
