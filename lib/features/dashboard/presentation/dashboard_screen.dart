import 'package:flutter/material.dart';
import '../../../contracts/activity_model.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../heatmap/presentation/personal_heatmap_screen.dart';
import '../../history/presentation/activity_detail_screen.dart';
import '../../segments/presentation/segment_list_screen.dart';

/// Layar Dashboard Atlet: ringkasan jarak mingguan, target latihan, dan statistik all-time.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onStartRecordingTap;

  const DashboardScreen({super.key, required this.onStartRecordingTap});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final ActivityRepository _repository = ActivityRepository();
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

  // Target jarak mingguan default (25.0 km)
  static const double _weeklyGoalKm = 25.0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  /// Memuat data ringkasan aktivitas.
  Future<void> loadDashboardData() async {
    setState(() => _isLoading = true);
    final list = await _repository.getAllActivities();
    if (mounted) {
      setState(() {
        _activities = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.stravaOrange),
        ),
      );
    }

    // Hitung jarak dan aktivitas 7 hari terakhir
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final weeklyActivities = _activities
        .where((a) => a.startTime.isAfter(sevenDaysAgo))
        .toList();

    double weeklyDistanceKm = 0.0;
    int weeklyDurationSecs = 0;
    int weeklyCalories = 0;

    for (final a in weeklyActivities) {
      weeklyDistanceKm += a.distanceKm;
      weeklyDurationSecs += a.durationSeconds;
      weeklyCalories += a.calories;
    }

    // Statistik All-Time
    double totalDistanceKm = 0.0;
    for (final a in _activities) {
      totalDistanceKm += a.distanceKm;
    }

    final goalProgress = (weeklyDistanceKm / _weeklyGoalKm).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.stravaOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'My Strava',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_fire_department, color: AppTheme.stravaOrange),
            tooltip: 'Personal Heatmap',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const PersonalHeatmapScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            tooltip: 'Segmen & Rekor KOM',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => const SegmentListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.stravaOrange,
        backgroundColor: AppTheme.cardSurface,
        onRefresh: loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Target Mingguan (Weekly Goal)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.stravaOrange.withValues(alpha: 0.9),
                      AppTheme.stravaOrangeDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.stravaOrange.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TARGET MINGGU INI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          '${(goalProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          weeklyDistanceKm.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ ${_weeklyGoalKm.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goalProgress,
                        backgroundColor: Colors.black26,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      weeklyDistanceKm >= _weeklyGoalKm
                          ? '🎉 Target mingguan tercapai! Kerja bagus!'
                          : '${(_weeklyGoalKm - weeklyDistanceKm).toStringAsFixed(1)} km lagi menuju target Anda.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Pintasan Fitur Legendaris Strava (Heatmap & Segmen)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => const PersonalHeatmapScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.stravaOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.local_fire_department,
                                color: AppTheme.stravaOrange, size: 22),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Heatmap',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Peta jejak neon',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => const SegmentListScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emoji_events,
                                color: Colors.amber, size: 22),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Segmen & KOM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Mahkota & Rekor',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid Metrik Mingguan
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.timer_outlined,
                      label: 'Waktu Minggu Ini',
                      value: _formatHours(weeklyDurationSecs),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.local_fire_department_outlined,
                      label: 'Kalori Terbakar',
                      value: '$weeklyCalories kcal',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.fitness_center_outlined,
                      label: 'Total Sesi',
                      value: '${_activities.length} latihan',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.public_outlined,
                      label: 'Jarak Kumulatif',
                      value: '${totalDistanceKm.toStringAsFixed(1)} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tombol Pintas Mulai Latihan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardSurfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppTheme.stravaOrange,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onPressed: widget.onStartRecordingTap,
                  icon: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppTheme.stravaOrange,
                    size: 26,
                  ),
                  label: const Text(
                    'Mulai Rekam Sesi Baru',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bagian Latihan Terbaru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Aktivitas Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_activities.isNotEmpty)
                    Text(
                      '${_activities.length} total',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_activities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada data aktivitas. Ketuk tombol di atas untuk mulai berolahraga!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ..._activities.take(3).map((activity) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.stravaOrange.withValues(alpha: 0.15),
                        child: Icon(
                          activity.sportType.icon,
                          color: AppTheme.stravaOrange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${activity.distanceKm.toStringAsFixed(2)} km • ${activity.durationFormatted}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ActivityDetailScreen(
                              activity: activity,
                              onActivityDeleted: loadDashboardData,
                            ),
                          ),
                        );
                        loadDashboardData();
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.stravaOrange, size: 22),
          const SizedBox(height: 10),
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
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(int seconds) {
    final hours = seconds / 3600.0;
    if (hours < 1.0) {
      final mins = seconds ~/ 60;
      return '$mins menit';
    }
    return '${hours.toStringAsFixed(1)} jam';
  }
}
