import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../../contracts/gear_model.dart';
import '../../../contracts/personal_record.dart';
import '../../../core/storage/activity_repository.dart';
import '../../../core/storage/profile_gear_repository.dart';
import '../../../core/theme/app_theme.dart';

/// Layar Profil Atlet, Manajemen Perlengkapan (Sepatu & Sepeda), serta Rekor Terbaik (PR).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final ProfileGearRepository _profileRepo = ProfileGearRepository();
  final ActivityRepository _activityRepo = ActivityRepository();

  Map<String, dynamic> _profile = {};
  List<GearModel> _gears = [];
  List<PersonalRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    setState(() => _isLoading = true);
    final profile = await _profileRepo.getAthleteProfile();
    final gears = await _profileRepo.getAllGears();
    final activities = await _activityRepo.getAllActivities();
    final records = _profileRepo.computePersonalRecords(activities);

    if (mounted) {
      setState(() {
        _profile = profile;
        _gears = gears;
        _records = records;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Rekor Atlet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah Profil',
            onPressed: _showEditProfileDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profil Atlet
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.stravaOrange,
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _profile['name'] as String? ?? 'Atlet My Strava',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile['bio'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Berat: ${(_profile['weight'] as double? ?? 65.0).toStringAsFixed(0)} kg',
                                style: const TextStyle(
                                  color: AppTheme.stravaOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Target: ${(_profile['weeklyGoalKm'] as double? ?? 25.0).toStringAsFixed(0)} km/mgg',
                                style: const TextStyle(
                                  color: AppTheme.accentGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kartu Panduan Background & Lockscreen Service
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.stravaOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.stravaOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security_update_good_rounded,
                    color: AppTheme.stravaOrange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pelacakan GPS di Lockscreen Aktif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aplikasi akan terus merekam rute dan menampilkan kontrol saat layar HP terkunci.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
                    },
                    child: const Text(
                      'Optimasi',
                      style: TextStyle(
                        color: AppTheme.stravaOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bagian Rekor Pribadi (PR)
            Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                SizedBox(width: 8),
                Text(
                  'Rekor Pribadi (Personal Bests)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_records.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Selesaikan sesi latihan untuk membuka rekor 1K, 5K, dan kecepatan terbaik Anda!',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (ctx, i) {
                  final rec = _records[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                rec.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          rec.category == 'speed'
                              ? '${rec.value.toStringAsFixed(1)} km/h'
                              : rec.category == 'distance'
                                  ? '${(rec.value / 1000.0).toStringAsFixed(2)} km'
                                  : rec.formattedTime,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 28),

            // Bagian Perlengkapan Olahraga (Gear Tracker)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.backpack_outlined,
                      color: AppTheme.stravaOrange,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Perlengkapan Olahraga (Gear)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppTheme.stravaOrange,
                  ),
                  tooltip: 'Tambah Perlengkapan',
                  onPressed: _showAddGearDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            ..._gears.map((gear) {
              final progress = gear.wearProgress;
              final isWorn = gear.isWornOut;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWorn
                        ? AppTheme.accentRed.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppTheme.stravaOrange.withValues(alpha: 0.15),
                          child: Icon(
                            gear.type.icon,
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
                                gear.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                '${gear.brand} • ${gear.type.displayName}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          onPressed: () async {
                            await _profileRepo.deleteGear(gear.id);
                            loadProfileData();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jarak Tempuh: ${gear.distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isWorn
                                ? AppTheme.accentRed
                                : AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Batas: ${gear.maxDistanceKm.toStringAsFixed(0)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress > 1.0 ? 1.0 : progress,
                        backgroundColor: AppTheme.cardSurfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isWorn ? AppTheme.accentRed : AppTheme.stravaOrange,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    if (isWorn) ...[
                      const SizedBox(height: 6),
                      const Text(
                        '⚠️ Perlengkapan telah mencapai batas keausan yang disarankan.',
                        style: TextStyle(
                          color: AppTheme.accentRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Bagian Arsitektur & Status Ekosistem Bebas API Key
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified,
                            color: AppTheme.accentGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: 100% Bebas API Key',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Arsitektur mandiri tanpa kartu kredit & biaya server',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  _buildZeroApiRow('🗺️ Peta 4 Lapisan',
                      'OpenStreetMap, Esri 3D, Carto Dark (Bebas Token)'),
                  _buildZeroApiRow('🛰️ GPS & Elevasi',
                      'Chip Satelit Native HP (Tanpa Google Maps API)'),
                  _buildZeroApiRow('📍 Lokasi Otomatis',
                      'Nominatim OSM & Offline Bounding Bounds'),
                  _buildZeroApiRow('☀️ Cuaca Otomatis',
                      'Open-Meteo Global Science API (Bebas Kunci)'),
                  _buildZeroApiRow('💾 Penyimpanan Data',
                      'Sandbox Dokumen Lokal JSON (Privasi Penuh 100%)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl =
        TextEditingController(text: _profile['name'] as String? ?? '');
    final bioCtrl =
        TextEditingController(text: _profile['bio'] as String? ?? '');
    final weightCtrl = TextEditingController(
      text: (_profile['weight'] as double? ?? 65.0).toStringAsFixed(0),
    );
    final goalCtrl = TextEditingController(
      text: (_profile['weeklyGoalKm'] as double? ?? 25.0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Ubah Profil Atlet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Atlet'),
            ),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio / Motto'),
            ),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Berat Badan (kg)'),
            ),
            TextField(
              controller: goalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Jarak Mingguan (km)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.stravaOrange),
            onPressed: () async {
              await _profileRepo.saveAthleteProfile(
                name: nameCtrl.text.trim(),
                bio: bioCtrl.text.trim(),
                weight: double.tryParse(weightCtrl.text) ?? 65.0,
                weeklyGoalKm: double.tryParse(goalCtrl.text) ?? 25.0,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                loadProfileData();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddGearDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final maxKmCtrl = TextEditingController(text: '600');
    GearType selectedType = GearType.shoes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          title: const Text('Tambah Perlengkapan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: const Text('Sepatu Lari'),
                    selected: selectedType == GearType.shoes,
                    selectedColor: AppTheme.stravaOrange,
                    onSelected: (val) {
                      setDlgState(() {
                        selectedType = GearType.shoes;
                        maxKmCtrl.text = '600';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Sepeda'),
                    selected: selectedType == GearType.bike,
                    selectedColor: AppTheme.stravaOrange,
                    onSelected: (val) {
                      setDlgState(() {
                        selectedType = GearType.bike;
                        maxKmCtrl.text = '3000';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Model (contoh: Vaporfly 3)',
                ),
              ),
              TextField(
                controller: brandCtrl,
                decoration: const InputDecoration(
                  labelText: 'Merek (contoh: Nike, Asics)',
                ),
              ),
              TextField(
                controller: maxKmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Batas Masa Pakai (km)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stravaOrange,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final newGear = GearModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  brand: brandCtrl.text.trim().isEmpty
                      ? 'Custom'
                      : brandCtrl.text.trim(),
                  type: selectedType,
                  maxDistanceKm: double.tryParse(maxKmCtrl.text) ?? 600.0,
                );
                await _profileRepo.addGear(newGear);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  loadProfileData();
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroApiRow(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

