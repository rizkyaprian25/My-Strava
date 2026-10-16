import 'package:flutter/material.dart';
import '../../contracts/location_point.dart';
import '../theme/app_theme.dart';

/// Widget visualisasi profil ketinggian (3D Elevation Profile) interaktif.
class ElevationProfileChart extends StatefulWidget {
  final List<LocationPoint> points;
  final ValueChanged<int>? onIndexHovered;
  final int? selectedIndex;

  const ElevationProfileChart({
    super.key,
    required this.points,
    this.onIndexHovered,
    this.selectedIndex,
  });

  @override
  State<ElevationProfileChart> createState() => _ElevationProfileChartState();
}

class _ElevationProfileChartState extends State<ElevationProfileChart> {
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _hoverIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant ElevationProfileChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _hoverIndex = widget.selectedIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        child: const Text(
          'Data ketinggian belum mencukupi',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      );
    }

    double minAlt = double.infinity;
    double maxAlt = -double.infinity;

    for (final p in widget.points) {
      if (p.altitude < minAlt) minAlt = p.altitude;
      if (p.altitude > maxAlt) maxAlt = p.altitude;
    }

    final currentPoint = (_hoverIndex != null &&
            _hoverIndex! >= 0 &&
            _hoverIndex! < widget.points.length)
        ? widget.points[_hoverIndex!]
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.terrain, color: AppTheme.stravaOrange, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Profil Ketinggian 3D',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (currentPoint != null)
                Text(
                  '${currentPoint.altitude.toStringAsFixed(1)} m | ${currentPoint.speedKmh.toStringAsFixed(1)} km/h',
                  style: const TextStyle(
                    color: AppTheme.stravaOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              else
                Text(
                  'Min: ${minAlt.toStringAsFixed(0)}m • Max: ${maxAlt.toStringAsFixed(0)}m',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                return GestureDetector(
                  onPanDown: (details) =>
                      _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  onPanUpdate: (details) =>
                      _handleTouch(details.localPosition.dx, constraints.maxWidth),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _ElevationPainter(
                      points: widget.points,
                      minAlt: minAlt,
                      maxAlt: maxAlt,
                      hoverIndex: _hoverIndex,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mulai (0 km)',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
              Text(
                'Geser kurva untuk memindai titik rute',
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
              Text(
                'Selesai',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTouch(double localX, double totalWidth) {
    if (totalWidth <= 0 || widget.points.isEmpty) return;
    final ratio = (localX / totalWidth).clamp(0.0, 1.0);
    final index = (ratio * (widget.points.length - 1)).round();
    setState(() {
      _hoverIndex = index;
    });
    widget.onIndexHovered?.call(index);
  }
}

class _ElevationPainter extends CustomPainter {
  final List<LocationPoint> points;
  final double minAlt;
  final double maxAlt;
  final int? hoverIndex;

  _ElevationPainter({
    required this.points,
    required this.minAlt,
    required this.maxAlt,
    this.hoverIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final range = (maxAlt - minAlt) == 0 ? 10.0 : (maxAlt - minAlt);
    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y agar titik tinggi di atas
      final normY = (points[i].altitude - minAlt) / range;
      final y = size.height - (normY * (size.height - 12)) - 4;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gambar area gradient di bawah kurva ketinggian
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.stravaOrange.withValues(alpha: 0.45),
        AppTheme.stravaOrange.withValues(alpha: 0.05),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Gambar garis kontur kurva
    final strokePaint = Paint()
      ..color = AppTheme.stravaOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);

    // Gambar pointer garis vertikal jika sedang disentuh
    if (hoverIndex != null && hoverIndex! >= 0 && hoverIndex! < points.length) {
      final hX = hoverIndex! * stepX;
      final normY = (points[hoverIndex!].altitude - minAlt) / range;
      final hY = size.height - (normY * (size.height - 12)) - 4;

      final guidePaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(hX, 0), Offset(hX, size.height), guidePaint);

      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(hX, hY), 5.0, dotBorderPaint);

      final dotPaint = Paint()
        ..color = AppTheme.stravaOrange
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(hX, hY), 3.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ElevationPainter oldDelegate) {
    return oldDelegate.hoverIndex != hoverIndex ||
        oldDelegate.points != points;
  }
}
