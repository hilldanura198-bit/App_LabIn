import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

class SaprasFacilityPage extends StatelessWidget {
  const SaprasFacilityPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SAPRAS Kampus'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Sarana'),
              Tab(text: 'Prasarana'),
              Tab(text: 'Denah'),
              Tab(text: 'Kepuasan'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _FacilityList(repository: repository),
              _InfrastructureList(repository: repository),
              const _CampusMapTabs(),
              _SatisfactionAnalytics(repository: repository),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityList extends StatelessWidget {
  const _FacilityList({required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabInventory>>(
      stream: repository.watchInventories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final code = _assetCode(index);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final detail = _FacilityDetail(item: item, code: code);
                    final imageButton = IconButton.filledTonal(
                      tooltip: 'Gambar',
                      onPressed: () => _showFacilityImage(context, item),
                      icon: const Icon(Icons.image_outlined),
                    );
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          detail,
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: imageButton,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: detail),
                        imageButton,
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _assetCode(int index) {
    return '1.B.18.19.A01.${(index + 15).toString().padLeft(3, '0')}';
  }

  void _showFacilityImage(BuildContext context, LabInventory item) {
    showDialog<void>(
      context: context,
      builder: (_) => _ImageDialog(
        title: item.namaAlat,
        subtitle: 'Kode aset dan dokumentasi visual sarana.',
        icon: Icons.precision_manufacturing_outlined,
      ),
    );
  }
}

class _FacilityDetail extends StatelessWidget {
  const _FacilityDetail({required this.item, required this.code});

  final LabInventory item;
  final String code;

  @override
  Widget build(BuildContext context) {
    final good = item.kondisi == 'bagus';
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DataPill(label: 'Kode Aset', value: code),
        _DataPill(label: 'Nama Sarana', value: item.namaAlat),
        _DataPill(label: 'Nama Ruangan', value: _roomName(item.labId)),
        const _DataPill(label: 'Gedung', value: 'Gedung Teknologi'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: good ? const Color(0xFFE9F8EF) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            good ? 'Baik' : 'Rusak',
            style: TextStyle(
              color: good ? AppTheme.deepTeal : Colors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _DataPill(
          label: 'Jumlah Stok',
          value: '${item.stokTersedia}/${item.totalStok}',
        ),
      ],
    );
  }

  String _roomName(String labId) {
    if (labId.startsWith('1111')) return 'Lab RPL';
    if (labId.startsWith('2222')) return 'Lab IoT';
    if (labId.startsWith('3333')) return 'Lab Jaringan';
    return 'Ruang Lab';
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfrastructureList extends StatelessWidget {
  const _InfrastructureList({required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabRoom>>(
      stream: repository.watchLaboratories(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? const <LabRoom>[];
        final displayRooms = [
          ...rooms,
          const LabRoom(
            id: 'area-luar',
            name: 'Area Luar Ruangan',
            location: 'Kampus 1',
            status: 'aktif',
          ),
          const LabRoom(
            id: 'rektor',
            name: 'Ruang Rektor',
            location: 'Gedung A',
            status: 'aktif',
          ),
        ];
        return GridView.builder(
          padding: const EdgeInsets.all(18),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: displayRooms.length,
          itemBuilder: (context, index) {
            final room = displayRooms[index];
            return InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _ImageDialog(
                  title: room.name,
                  subtitle: '${room.location} - Status ${room.status}',
                  icon: Icons.apartment_rounded,
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        color: AppTheme.deepTeal,
                        size: 34,
                      ),
                      const Spacer(),
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        room.location,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CampusMapTabs extends StatelessWidget {
  const _CampusMapTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Kampus 1'),
              Tab(text: 'Kampus 2'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _CampusMap(
                  title: 'Gedung A - Laboratorium & Administrasi',
                  rooms: const [
                    'Lab RPL',
                    'Keuangan',
                    'Convention Hall',
                    'Area Luar',
                  ],
                ),
                _CampusMap(
                  title: 'Gedung B - Riset & Jaringan',
                  rooms: const [
                    'Lab IoT',
                    'Lab Jaringan',
                    'Gudang',
                    'Ruang Rektor',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusMap extends StatelessWidget {
  const _CampusMap({required this.title, required this.rooms});

  final String title;
  final List<String> rooms;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFAF6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCDE9DF)),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rooms.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.deepTeal.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppTheme.deepTeal,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rooms[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SatisfactionAnalytics extends StatefulWidget {
  const _SatisfactionAnalytics({required this.repository});

  final DashboardRepository repository;

  @override
  State<_SatisfactionAnalytics> createState() => _SatisfactionAnalyticsState();
}

class _SatisfactionAnalyticsState extends State<_SatisfactionAnalytics> {
  String _period = 'Semester Genap 2026';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SatisfactionScore>>(
      stream: widget.repository.watchSatisfactionScores(),
      builder: (context, snapshot) {
        final scores = snapshot.data ?? const <SatisfactionScore>[];
        final periods = scores.map((score) => score.period).toSet().toList();
        final filtered = scores
            .where((score) => score.period == _period)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Analisis Kepuasan Pengguna',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: periods.contains(_period)
                          ? _period
                          : (periods.isEmpty ? null : periods.first),
                      items: periods
                          .map(
                            (period) => DropdownMenuItem(
                              value: period,
                              child: Text(period),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _period = value ?? _period),
                      decoration: const InputDecoration(
                        labelText: 'Pilih Periode',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.bar_chart_rounded),
                      label: const Text('Tampilkan'),
                    ),
                    const SizedBox(height: 18),
                    if (filtered.isEmpty)
                      const Text('Data kuisioner belum tersedia.')
                    else
                      ...filtered.map((score) => _ScoreBar(score: score)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});

  final SatisfactionScore score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  score.category,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text('${score.score}%'),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: score.score / 100,
              minHeight: 16,
              color: AppTheme.emerald,
              backgroundColor: const Color(0xFFDDE8E4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageDialog extends StatelessWidget {
  const _ImageDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.deepTeal, AppTheme.emerald],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, size: 88, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}
