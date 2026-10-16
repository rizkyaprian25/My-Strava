import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../contracts/activity_model.dart';
import '../theme/app_theme.dart';
import 'image_saver.dart';

/// Gaya tampilan kartu berbagi Strava (Strava Share Studio).
enum ShareBackgroundStyle {
  transparent, // Latar transparan (stiker PNG tembus pandang)
  stravaDark, // Latar belakang gelap khas Strava
  runnerPhoto, // Latar foto atlet lari
  cyclingPhoto, // Latar foto pesepeda
}

/// Format aspek rasio kartu berbagi.
enum ShareAspectRatio {
  story9x16, // Story / Reels / Status (9:16)
  feed1x1, // Square Feed (1:1)
}

/// Studio Berbagi Aktivitas ala Strava Stories & Feed (Mendukung Transparan & Foto).
class ShareCardDialog extends StatefulWidget {
  final ActivityModel activity;

  const ShareCardDialog({super.key, required this.activity});

  static Future<void> show(BuildContext context, ActivityModel activity) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => ShareCardDialog(activity: activity),
    );
  }

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  ShareBackgroundStyle _selectedBg = ShareBackgroundStyle.stravaDark;
  ShareAspectRatio _selectedRatio = ShareAspectRatio.story9x16;
  bool _showRoute = true;
  bool _showStats = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.share, color: AppTheme.stravaOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Bagikan Aktivitas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Pilihan Mode Background & Rasio
          _buildControlsBar(),
          const SizedBox(height: 12),

          // Area Preview Kartu
          Flexible(
            child: SingleChildScrollView(
              child: Center(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildShareCard(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Simpan PNG Gambar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stravaOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _saveImage,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              label: Text(
                _isSaving
                    ? 'Menyimpan...'
                    : _selectedBg == ShareBackgroundStyle.transparent
                        ? 'Simpan Stiker PNG Transparan'
                        : 'Simpan Gambar Ultra HD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Baris 1: Pilihan Tema Background
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBgOption(
                  label: 'Transparan',
                  icon: Icons.opacity,
                  style: ShareBackgroundStyle.transparent,
                ),
                _buildBgOption(
                  label: 'Strava Dark',
                  icon: Icons.dark_mode,
                  style: ShareBackgroundStyle.stravaDark,
                ),
                _buildBgOption(
                  label: 'Foto Lari',
                  icon: Icons.directions_run,
                  style: ShareBackgroundStyle.runnerPhoto,
                ),
                _buildBgOption(
                  label: 'Foto Sepeda',
                  icon: Icons.directions_bike,
                  style: ShareBackgroundStyle.cyclingPhoto,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Baris 2: Format Rasio & Toggle Elemen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Story 9:16', style: TextStyle(fontSize: 11)),
                    selected: _selectedRatio == ShareAspectRatio.story9x16,
                    selectedColor: AppTheme.stravaOrange,
                    labelStyle: TextStyle(
                      color: _selectedRatio == ShareAspectRatio.story9x16
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedRatio = ShareAspectRatio.story9x16);
                    },
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Feed 1:1', style: TextStyle(fontSize: 11)),
                    selected: _selectedRatio == ShareAspectRatio.feed1x1,
                    selectedColor: AppTheme.stravaOrange,
                    labelStyle: TextStyle(
                      color: _selectedRatio == ShareAspectRatio.feed1x1
                          ? Colors.white
                          : AppTheme.textSecondary,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedRatio = ShareAspectRatio.feed1x1);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showRoute ? Icons.route : Icons.route_outlined,
                      color: _showRoute ? AppTheme.stravaOrange : Colors.white38,
                      size: 20,
                    ),
                    tooltip: 'Tampilkan/Sembunyikan Rute',
                    onPressed: () => setState(() => _showRoute = !_showRoute),
                  ),
                  IconButton(
                    icon: Icon(
                      _showStats ? Icons.bar_chart : Icons.bar_chart_outlined,
                      color: _showStats ? AppTheme.stravaOrange : Colors.white38,
                      size: 20,
                    ),
                    tooltip: 'Tampilkan/Sembunyikan Statistik',
                    onPressed: () => setState(() => _showStats = !_showStats),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBgOption({
    required String label,
    required IconData icon,
    required ShareBackgroundStyle style,
  }) {
    final isSelected = _selectedBg == style;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppTheme.stravaOrange),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        selectedColor: AppTheme.stravaOrange,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          if (val) setState(() => _selectedBg = style);
        },
      ),
    );
  }

  Widget _buildShareCard() {
    final isStory = _selectedRatio == ShareAspectRatio.story9x16;
    final cardWidth = isStory ? 280.0 : 300.0;
    final cardHeight = isStory ? 490.0 : 300.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedBg == ShareBackgroundStyle.transparent
              ? Colors.white24
              : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 4)),
        ],
        gradient: _getCardGradient(),
      ),
      child: Stack(
        children: [
          // Background Pola Catur jika mode Transparan (hanya terlihat di preview)
          if (_selectedBg == ShareBackgroundStyle.transparent)
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: CustomPaint(painter: _CheckerboardPainter()),
              ),
            ),

          // Latar Foto jika mode Photo
          if (_selectedBg == ShareBackgroundStyle.runnerPhoto ||
              _selectedBg == ShareBackgroundStyle.cyclingPhoto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

          // Rute Polyline di Belakang
          if (_showRoute && widget.activity.routePoints.length >= 2)
            Positioned.fill(
              child: Opacity(
                opacity: _selectedBg == ShareBackgroundStyle.transparent ? 0.9 : 0.8,
                child: _buildRouteMap(),
              ),
            ),

          // Konten Overlay Utama (Teks & Telemetri)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Watermark Brand & Jenis Olahraga
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.stravaOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.activity.sportType.icon,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MY STRAVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                fontSize: 13,
                                shadows: _textShadows(),
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMM yyyy', 'id_ID')
                                  .format(widget.activity.startTime),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                shadows: _textShadows(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        widget.activity.sportType.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Center / Bottom: Statistik Utama
                if (_showStats)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Aktivitas
                      Text(
                        widget.activity.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: _textShadows(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Angka Jarak Tempuh Raksasa
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.activity.distanceKm.toStringAsFixed(2),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isStory ? 48 : 38,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              shadows: _textShadows(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'KM',
                            style: TextStyle(
                              color: AppTheme.stravaOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              shadows: _textShadows(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Baris Metrik Sekunder
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildShareMetric(
                            label: 'Waktu',
                            value: widget.activity.formattedDuration,
                          ),
                          _buildShareMetric(
                            label: 'Pace Rata-rata',
                            value: widget.activity.avgPaceFormatted,
                          ),
                          _buildShareMetric(
                            label: 'Elevasi',
                            value: '${widget.activity.elevationGainMeters.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            shadows: _textShadows(),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            shadows: _textShadows(),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteMap() {
    final points = widget.activity.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return IgnorePointer(
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(32),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          PolylineLayer(
            polylines: [
              // Efek Glow / Bayangan polyline
              Polyline(
                points: points,
                strokeWidth: 9.0,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              // Polyline Utama Strava Orange
              Polyline(
                points: points,
                strokeWidth: 4.5,
                color: const Color(0xFFFC5200),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Shadow> _textShadows() {
    return const [
      Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1.5)),
      Shadow(color: Colors.black, blurRadius: 12, offset: Offset(0, 2)),
    ];
  }

  Color _getBackgroundColor() {
    switch (_selectedBg) {
      case ShareBackgroundStyle.transparent:
        return Colors.transparent;
      case ShareBackgroundStyle.stravaDark:
        return const Color(0xFF121212);
      case ShareBackgroundStyle.runnerPhoto:
        return const Color(0xFF1E2832);
      case ShareBackgroundStyle.cyclingPhoto:
        return const Color(0xFF263238);
    }
  }

  Gradient? _getCardGradient() {
    switch (_selectedBg) {
      case ShareBackgroundStyle.transparent:
        return null;
      case ShareBackgroundStyle.stravaDark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
        );
      case ShareBackgroundStyle.runnerPhoto:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        );
      case ShareBackgroundStyle.cyclingPhoto:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF000000)],
        );
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    final savedPath = await ImageSaver.captureAndSavePng(
      _cardKey,
      filenamePrefix: _selectedBg == ShareBackgroundStyle.transparent
          ? 'my_strava_transparent_sticker'
          : 'my_strava_story',
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          content: Text(
            'Berhasil disimpan ke: $savedPath',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Gagal membuat gambar share card.'),
        ),
      );
    }
  }
}

/// CustomPainter untuk pola catur transparan di editor preview.
class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 10.0;
    final paint1 = Paint()..color = Colors.white12;
    final paint2 = Paint()..color = Colors.white24;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
