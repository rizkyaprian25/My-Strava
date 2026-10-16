import 'package:flutter/material.dart';
import '../../../contracts/segment_model.dart';
import '../../../contracts/sport_type.dart';
import '../../../core/storage/segment_repository.dart';
import '../../../core/theme/app_theme.dart';

/// Layar Segmen Lintasan & Mahkota KOM (King/Queen of the Mountain).
class SegmentListScreen extends StatefulWidget {
  const SegmentListScreen({super.key});

  @override
  State<SegmentListScreen> createState() => _SegmentListScreenState();
}

class _SegmentListScreenState extends State<SegmentListScreen> {
  final SegmentRepository _segmentRepo = SegmentRepository();
  List<SegmentModel> _segments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  Future<void> _loadSegments() async {
    setState(() => _isLoading = true);
    final list = await _segmentRepo.getSegments();
    if (!mounted) return;
    setState(() {
      _segments = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Segmen & Rekor KOM'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.stravaOrange),
            tooltip: 'Buat Segmen Kustom Baru',
            onPressed: _showCreateSegmentDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.stravaOrange))
          : _segments.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada segmen rute yang terdaftar.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _segments.length,
                  itemBuilder: (ctx, index) {
                    final seg = _segments[index];
                    return _buildSegmentCard(seg);
                  },
                ),
    );
  }

  Widget _buildSegmentCard(SegmentModel seg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.stravaOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(seg.sportType.icon,
                        color: AppTheme.stravaOrange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seg.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        seg.description.isNotEmpty
                            ? seg.description
                            : '${seg.distanceMeters.toStringAsFixed(0)} m • Elevasi +${seg.elevationGainMeters.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 20),
                onPressed: () async {
                  await _segmentRepo.deleteSegment(seg.id);
                  _loadSegments();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'REKOR TERBAIK (PR)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        seg.formattedPB,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DICOBA',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${seg.attemptsCount} kali',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateSegmentDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final distCtrl = TextEditingController(text: '500');
    final sLatCtrl = TextEditingController(text: '-6.2088');
    final sLngCtrl = TextEditingController(text: '106.8456');
    final eLatCtrl = TextEditingController(text: '-6.2050');
    final eLngCtrl = TextEditingController(text: '106.8450');
    SportType selectedSport = SportType.run;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppTheme.cardSurface,
          title: const Text('Buat Segmen Lintasan Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Segmen (cth: Sprint Senayan 400m)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Lokasi',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: distCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi Jarak (meter)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SportType>(
                  initialValue: selectedSport,
                  decoration: const InputDecoration(labelText: 'Jenis Olahraga'),
                  dropdownColor: AppTheme.cardSurface,
                  items: SportType.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.displayName),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedSport = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sLatCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Start Lat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: sLngCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Start Lng'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: eLatCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Finish Lat'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: eLngCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Finish Lng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.stravaOrange),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final newSeg = SegmentModel(
                  id: 'seg-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  sportType: selectedSport,
                  startLat: double.tryParse(sLatCtrl.text) ?? -6.2088,
                  startLng: double.tryParse(sLngCtrl.text) ?? 106.8456,
                  endLat: double.tryParse(eLatCtrl.text) ?? -6.2050,
                  endLng: double.tryParse(eLngCtrl.text) ?? 106.8450,
                  distanceMeters: double.tryParse(distCtrl.text) ?? 500.0,
                );
                await _segmentRepo.addSegment(newSeg);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) _loadSegments();
              },
              child: const Text('Simpan Segmen'),
            ),
          ],
        ),
      ),
    );
  }
}
