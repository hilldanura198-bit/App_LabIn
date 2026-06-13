import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class SaprasFacilityPage extends StatelessWidget {
  const SaprasFacilityPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: const GlassAppBar(
          title: 'SAPRAS Kampus',
          bottom: TabBar(
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
      builder: (context, inventorySnapshot) {
        if (inventorySnapshot.hasError) {
          return Center(child: Text(inventorySnapshot.error.toString()));
        }
        if (!inventorySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return StreamBuilder<List<LabBooking>>(
          stream: repository.watchRoomSchedule(),
          builder: (context, bookingSnapshot) {
            final items = inventorySnapshot.data!;
            final bookings = bookingSnapshot.data ?? const <LabBooking>[];
            return GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 620,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final code = _assetCode(index);
                final booking = _latestBookingForLab(bookings, item.labId);
                final odd = index.isOdd;
                return Container(
                  decoration: BoxDecoration(
                    color: odd ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: odd
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFE0E7FF),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        final image = _FacilityImage(
                          imageUrl: _facilityImageUrl(item.namaAlat),
                          height: compact ? 150 : 112,
                        );
                        final detail = _FacilityDetail(
                          item: item,
                          code: code,
                          booking: booking,
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              image,
                              const SizedBox(height: 14),
                              detail,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _DetailButton(
                                  onPressed: () => _showFacilityImage(
                                    context,
                                    item,
                                    booking,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            SizedBox(width: 150, child: image),
                            const SizedBox(width: 14),
                            Expanded(child: detail),
                            const SizedBox(width: 12),
                            _DetailButton(
                              onPressed: () =>
                                  _showFacilityImage(context, item, booking),
                            ),
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
      },
    );
  }

  String _assetCode(int index) {
    return '1.B.18.19.A01.${(index + 15).toString().padLeft(3, '0')}';
  }

  LabBooking? _latestBookingForLab(List<LabBooking> bookings, String labId) {
    final activeBookings =
        bookings
            .where(
              (booking) =>
                  booking.labId == labId &&
                  booking.status != 'returned' &&
                  booking.status != 'rejected',
            )
            .toList()
          ..sort((a, b) => b.tanggalPinjam.compareTo(a.tanggalPinjam));
    return activeBookings.isEmpty ? null : activeBookings.first;
  }

  void _showFacilityImage(
    BuildContext context,
    LabInventory item,
    LabBooking? booking,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _ImageDialog(
        title: item.namaAlat,
        subtitle: 'Kode aset dan dokumentasi visual sarana.',
        imageUrl: _facilityImageUrl(item.namaAlat),
        booking: booking,
        icon: Icons.precision_manufacturing_outlined,
      ),
    );
  }

  String _facilityImageUrl(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('proyektor')) {
      return 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('ac') || lowerName.contains('pendingin')) {
      return 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('komputer') || lowerName.contains('pc')) {
      return 'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('mikro') || lowerName.contains('alat')) {
      return 'https://images.unsplash.com/photo-1581093588401-fbb62a02f120?auto=format&fit=crop&w=900&q=80';
    }
    return 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&w=900&q=80';
  }
}

class _FacilityDetail extends StatelessWidget {
  const _FacilityDetail({
    required this.item,
    required this.code,
    required this.booking,
  });

  final LabInventory item;
  final String code;
  final LabBooking? booking;

  @override
  Widget build(BuildContext context) {
    final good = item.kondisi == 'bagus';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
                color:
                    (good ? const Color(0xFF22F55E) : const Color(0xFFFF4D6D))
                        .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: good
                      ? const Color(0xFF22F55E)
                      : const Color(0xFFFF4D6D),
                ),
              ),
              child: Text(
                good ? 'Baik' : 'Rusak',
                style: TextStyle(
                  color: good
                      ? const Color(0xFF22F55E)
                      : const Color(0xFFFF4D6D),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _DataPill(
              label: 'Jumlah Stok',
              value: '${item.stokTersedia}/${item.totalStok}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _UsageStatusChip(status: booking?.status ?? 'available'),
            _UsageScheduleChip(booking: booking),
          ],
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
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityImage extends StatelessWidget {
  const _FacilityImage({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            decoration: const BoxDecoration(gradient: AppTheme.cyberGradient),
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: const Icon(Icons.open_in_full_rounded),
      label: const Text('Lihat Detail'),
    );
  }
}

class _UsageStatusChip extends StatelessWidget {
  const _UsageStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return InputChip(
      onPressed: () {},
      avatar: Icon(_statusIcon(status), color: color, size: 18),
      label: Text(_statusLabel(status)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.70)),
    );
  }
}

class _UsageScheduleChip extends StatelessWidget {
  const _UsageScheduleChip({required this.booking});

  final LabBooking? booking;

  @override
  Widget build(BuildContext context) {
    final label = booking == null
        ? 'Jadwal penggunaan: tersedia'
        : 'Jadwal penggunaan: ${_twoDigits(booking!.tanggalPinjam.hour)}:${_twoDigits(booking!.tanggalPinjam.minute)}';
    return Chip(
      avatar: const Icon(Icons.event_available_outlined, size: 18),
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
      backgroundColor: AppTheme.electricBlue.withValues(alpha: 0.10),
      side: BorderSide(color: AppTheme.electricBlue.withValues(alpha: 0.20)),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'approved_aslab' || 'approved_kalab' || 'active' => const Color(0xFF22F55E),
    'pending' => const Color(0xFFFFB020),
    'rejected' => const Color(0xFFFF4D6D),
    _ => AppTheme.electricBlue,
  };
}

IconData _statusIcon(String status) {
  return switch (status) {
    'approved_aslab' || 'approved_kalab' || 'active' => Icons.verified_rounded,
    'pending' => Icons.pending_actions_rounded,
    'rejected' => Icons.cancel_rounded,
    _ => Icons.check_circle_outline_rounded,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'approved_aslab' || 'approved_kalab' => 'Disetujui',
    'active' => 'Sedang Dipakai',
    'pending' => 'Pending',
    'rejected' => 'Ditolak',
    _ => 'Tersedia',
  };
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

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
                  imageUrl: _roomImageUrl(room.name),
                  booking: null,
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
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            _roomImageUrl(room.name),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.cyberGradient,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.meeting_room_outlined,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  String _roomImageUrl(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('rektor')) {
      return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('convention')) {
      return 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('gudang')) {
      return 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('area')) {
      return 'https://images.unsplash.com/photo-1497366412874-3415097a27e7?auto=format&fit=crop&w=900&q=80';
    }
    return 'https://images.unsplash.com/photo-1581092160607-ee22731c8f4e?auto=format&fit=crop&w=900&q=80';
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
            color: AppTheme.richBronze.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.richBronze.withValues(alpha: 0.35),
            ),
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
              backgroundColor: AppTheme.richBronze.withValues(alpha: 0.16),
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
    required this.imageUrl,
    required this.booking,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final LabBooking? booking;
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.cyberGradient,
                    ),
                    child: Icon(icon, size: 88, color: Colors.white),
                  );
                },
              ),
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
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _UsageStatusChip(status: booking?.status ?? 'available'),
                _UsageScheduleChip(booking: booking),
              ],
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
