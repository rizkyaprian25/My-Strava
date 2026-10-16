import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../contracts/activity_model.dart';
import '../../../contracts/sport_type.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'activity_detail_screen.dart';

/// Layar riwayat aktivitas olahraga dengan penyaringan jenis olahraga dan kartu ringkasan.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final ActivityRepository _repository = ActivityRepository();
  List<ActivityModel> _activities = [];
  bool _isLoading = true;
  SportType? _filterSportType;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  /// Memuat ulang daftar aktivitas dari penyimpanan lokal.
  Future<void> loadActivities() async {
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
    final filtered = _filterSportType == null
        ? _activities
        : _activities.where((a) => a.sportType == _filterSportType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
      ),
      body: Column(
        children: [
          // Filter Jenis Olahraga Horizontal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    icon: Icons.all_inclusive,
                    isSelected: _filterSportType == null,
                    onSelected: () => setState(() => _filterSportType = null),
                  ),
                  ...SportType.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildFilterChip(
                        label: type.displayName,
                        icon: type.icon,
                        isSelected: _filterSportType == type,
                        onSelected: () =>
                            setState(() => _filterSportType = type),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Daftar Aktivitas
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.stravaOrange,
                    ),
                  )
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppTheme.stravaOrange,
                        backgroundColor: AppTheme.cardSurface,
                        onRefresh: loadActivities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, index) {
                            return _buildActivityCard(filtered[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selectedColor: AppTheme.stravaOrange,
      backgroundColor: AppTheme.cardSurface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final dateFormat = DateFormat('d MMM yyyy • HH:mm', 'id_ID');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ActivityDetailScreen(
                activity: activity,
                onActivityDeleted: loadActivities,
              ),
            ),
          );
          loadActivities();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Kartu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.sportType.icon,
                      color: AppTheme.stravaOrange,
                      size: 20,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
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
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Baris Statistik Cepat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    label: 'Jarak',
                    value: '${activity.distanceKm.toStringAsFixed(2)} km',
                  ),
                  _buildStatItem(
                    label: 'Pace',
                    value: activity.avgPaceFormatted,
                  ),
                  _buildStatItem(
                    label: 'Waktu',
                    value: activity.durationFormatted,
                  ),
                  _buildStatItem(
                    label: 'Elevasi',
                    value: '${activity.elevationGainMeters.toStringAsFixed(0)} m',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                size: 56,
                color: AppTheme.stravaOrange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Riwayat Latihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mulai sesi perekaman GPS pertama Anda melalui tab Rekam di bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
