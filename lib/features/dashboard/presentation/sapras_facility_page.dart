import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

const _facilityAssetPath = 'assets/images/facility_lab.png';
const _roomAssetPath = 'assets/images/facility_room.png';

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
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final code = _assetCode(index);
                final booking = _latestBookingForLab(bookings, item.labId);
                final odd = index.isOdd;
                return Container(
                  decoration: BoxDecoration(
                    color: odd
                        ? const Color(0xFF111827)
                        : const Color(0xFF0F1B33),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: odd
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.electricBlue.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        final image = _FacilityImage(
                          imageUrl: item.imageUrl,
                          fallbackAssetPath: _facilityAssetPath,
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
        imageUrl: item.imageUrl,
        fallbackAssetPath: _facilityAssetPath,
        booking: booking,
        icon: Icons.precision_manufacturing_outlined,
      ),
    );
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityImage extends StatelessWidget {
  const _FacilityImage({
    required this.imageUrl,
    required this.fallbackAssetPath,
    required this.height,
  });

  final String? imageUrl;
  final String fallbackAssetPath;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _RealtimeImage(
        imageUrl: imageUrl,
        fallbackAssetPath: fallbackAssetPath,
        height: height,
      ),
    );
  }
}

class _RealtimeImage extends StatelessWidget {
  const _RealtimeImage({
    required this.imageUrl,
    required this.fallbackAssetPath,
    required this.height,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String? imageUrl;
  final String fallbackAssetPath;
  final double height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _FallbackImage(
        assetPath: fallbackAssetPath,
        height: height,
        icon: fallbackIcon,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        height: height,
        decoration: const BoxDecoration(gradient: AppTheme.cyberGradient),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      errorWidget: (context, _, _) => _FallbackImage(
        assetPath: fallbackAssetPath,
        height: height,
        icon: fallbackIcon,
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({
    required this.assetPath,
    required this.height,
    required this.icon,
  });

  final String assetPath;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          decoration: const BoxDecoration(gradient: AppTheme.cyberGradient),
          child: Icon(icon, color: Colors.white, size: 36),
        );
      },
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
      label: const Text('Detail'),
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
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
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
        final displayRooms = <LabRoom>[...rooms];
        void addRoom(LabRoom room) {
          if (displayRooms.any((item) => item.name == room.name)) {
            return;
          }
          displayRooms.add(room);
        }

        addRoom(
          const LabRoom(
            id: 'area-luar',
            name: 'Area Luar Ruangan',
            location: 'Kampus 1',
            status: 'aktif',
          ),
        );
        addRoom(
          const LabRoom(
            id: 'rektor',
            name: 'Ruang Rektor',
            location: 'Gedung A',
            status: 'aktif',
          ),
        );
        addRoom(
          const LabRoom(
            id: 'fik-rpl-hall',
            name: 'Lab RPL',
            location: 'Gedung Teknologi Lt. 2',
            status: 'aktif',
          ),
        );
        addRoom(
          const LabRoom(
            id: 'fik-jaringan',
            name: 'Lab Jaringan',
            location: 'Gedung Teknologi Lt. 3',
            status: 'aktif',
          ),
        );
        addRoom(
          const LabRoom(
            id: 'fik-iot-hall',
            name: 'Lab IoT',
            location: 'Gedung Teknologi Lt. 3',
            status: 'aktif',
          ),
        );
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
                  imageUrl: room.imageUrl,
                  fallbackAssetPath: _roomAssetPath,
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
                          child: _RealtimeImage(
                            imageUrl: room.imageUrl,
                            fallbackAssetPath: _roomAssetPath,
                            height: double.infinity,
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
}

class _CampusMapTabs extends StatelessWidget {
  const _CampusMapTabs();

  static const _campuses = [
    _CampusMapData(
      title: 'Kampus Rektorat',
      address: 'Jl. Ki Mangun Sarkoro No.20, Nusukan, Banjarsari, Surakarta',
      subtitle: 'Pusat administrasi dan layanan akademik utama.',
      layout: _CampusLayout.rektorat,
      rooms: [
        'Lobby Utama',
        'Ruang Rektor',
        'Biro Akademik',
        'Ruang Rapat',
        'Aula',
        'Front Office',
      ],
    ),
    _CampusMapData(
      title: 'Kampus 1',
      address: 'Jl. Bhayangkara No.55, Tipes, Serengan, Surakarta',
      subtitle: 'Ruang kelas utama dan pusat aktivitas praktikum FIK.',
      layout: _CampusLayout.campus1,
      rooms: [
        'Lab RPL',
        'Lab IoT',
        'Perpustakaan',
        'Kelas',
        'Kantin',
        'Studio',
      ],
    ),
    _CampusMapData(
      title: 'Kampus 2',
      address: 'Jl. KH Samanhudi No.93, Sondakan, Laweyan, Surakarta',
      subtitle: 'Fokus pada klinik, simulasi, dan layanan kesehatan.',
      layout: _CampusLayout.campus2,
      rooms: ['Klinik', 'Lab Simulasi', 'Farmasi', 'Ruang Dosen', 'Admin'],
    ),
    _CampusMapData(
      title: 'Kampus 3',
      address: 'Jl. Pinang Raya No.47, Jati, Cemani, Grogol, Sukoharjo',
      subtitle: 'Area pengembangan berbasis riset dan kegiatan lintas prodi.',
      layout: _CampusLayout.campus3,
      rooms: [
        'Lab Legal Tech',
        'Lab Mediasi',
        'Auditorium',
        'Seminar',
        'Parkir',
      ],
    ),
    _CampusMapData(
      title: 'Kampus 4',
      address: 'Jl. Pinang Raya No.47, Jati, Cemani, Grogol, Sukoharjo',
      subtitle: 'Blok lanjutan untuk praktikum, diskusi, dan kegiatan modern.',
      layout: _CampusLayout.campus4,
      rooms: [
        'Ruang Diskusi',
        'Lab Presentasi',
        'Studio Multimedia',
        'Co-Working',
        'Rooftop',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _campuses.length,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Kampus Rektorat'),
              Tab(text: 'Kampus 1'),
              Tab(text: 'Kampus 2'),
              Tab(text: 'Kampus 3'),
              Tab(text: 'Kampus 4'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: _campuses
                  .map((campus) => _CampusMapPanel(campus: campus))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusMapPanel extends StatelessWidget {
  const _CampusMapPanel({required this.campus});

  final _CampusMapData campus;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final denah = _CampusDenahPreview(campus: campus);
        final info = _CampusInfoCard(campus: campus);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    campus.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campus.subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: denah),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: info),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [denah, const SizedBox(height: 16), info],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CampusDenahPreview extends StatelessWidget {
  const _CampusDenahPreview({required this.campus});

  final _CampusMapData campus;

  @override
  Widget build(BuildContext context) {
    final rooms = campus.rooms;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            campus.accent.withValues(alpha: 0.16),
            AppTheme.vibrantPurple.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: campus.accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: campus.accent.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Denah ${campus.title}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.grid_view_rounded, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Layout blueprint terstruktur untuk ruang, koridor, dan loker alat.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 14),
                  const _BlueprintLegend(),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 520 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rooms.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.15,
                        ),
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return _RoomBlock(
                            label: room,
                            accent: campus.accent,
                            type: _zoneTypeFor(index),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _RoomBlock(
                    label: 'Loker Alat Utama',
                    accent: AppTheme.cleanCyan,
                    type: _BlueprintZoneType.locker,
                    wide: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BlueprintZoneType _zoneTypeFor(int index) {
    if (index == 0) return _BlueprintZoneType.entry;
    if (index == 1 || index == 4) return _BlueprintZoneType.locker;
    return _BlueprintZoneType.room;
  }
}

class _CampusInfoCard extends StatelessWidget {
  const _CampusInfoCard({required this.campus});

  final _CampusMapData campus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: campus.accent.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: campus.accent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Informasi ${campus.title}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            campus.address,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(campus.mapUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buka Google Maps'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: campus.rooms
                .map(
                  (room) => Chip(
                    label: Text(room),
                    backgroundColor: campus.accent.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: campus.accent.withValues(alpha: 0.24),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RoomBlock extends StatelessWidget {
  const _RoomBlock({
    required this.label,
    required this.accent,
    required this.type,
    this.wide = false,
  });

  final String label;
  final Color accent;
  final _BlueprintZoneType type;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final zoneColor = switch (type) {
      _BlueprintZoneType.entry => AppTheme.electricBlue,
      _BlueprintZoneType.locker => AppTheme.cleanCyan,
      _BlueprintZoneType.room => accent,
    };
    final icon = switch (type) {
      _BlueprintZoneType.entry => Icons.login_rounded,
      _BlueprintZoneType.locker => Icons.inventory_2_outlined,
      _BlueprintZoneType.room => Icons.meeting_room_outlined,
    };
    final typeLabel = switch (type) {
      _BlueprintZoneType.entry => 'Akses',
      _BlueprintZoneType.locker => 'Loker Alat',
      _BlueprintZoneType.room => 'Ruangan',
    };
    return Container(
      constraints: wide
          ? const BoxConstraints(minHeight: 72)
          : const BoxConstraints(),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: zoneColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: zoneColor.withValues(alpha: 0.48),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: zoneColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: zoneColor.withValues(alpha: 0.34)),
            ),
            child: Icon(icon, color: zoneColor, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  typeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: zoneColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintLegend extends StatelessWidget {
  const _BlueprintLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: const [
        _LegendChip(color: AppTheme.vibrantPurple, label: 'Ruangan'),
        _LegendChip(color: AppTheme.cleanCyan, label: 'Loker Alat'),
        _LegendChip(color: AppTheme.electricBlue, label: 'Akses'),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BlueprintZoneType { room, locker, entry }

class _SatisfactionAnalytics extends StatefulWidget {
  const _SatisfactionAnalytics({required this.repository});

  final DashboardRepository repository;

  @override
  State<_SatisfactionAnalytics> createState() => _SatisfactionAnalyticsState();
}

class _SatisfactionAnalyticsState extends State<_SatisfactionAnalytics> {
  String _period = 'Semester Genap 2025/2026';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SatisfactionScore>>(
      stream: widget.repository.watchSatisfactionScores(),
      builder: (context, snapshot) {
        final scores = snapshot.data ?? const <SatisfactionScore>[];
        final periods = <String>{
          'Semester Genap 2025/2026',
          'Awal Tahun 2026',
          ...scores.map((score) => score.period),
        }.toList();
        final filtered = scores
            .where((score) => score.period == _period)
            .toList();
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const _SatisfactionSummaryCard(),
            const SizedBox(height: 14),
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
                    const SizedBox(height: 12),
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
                    if (filtered.isEmpty)
                      const Column(
                        children: [
                          _MiniScoreRow(
                            label: 'Kemudahan Peminjaman',
                            score: 96,
                          ),
                          _MiniScoreRow(label: 'Kualitas Sarpras', score: 94),
                          _MiniScoreRow(label: 'Kecepatan Layanan', score: 97),
                        ],
                      )
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

class _SatisfactionSummaryCard extends StatelessWidget {
  const _SatisfactionSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cyberGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vibrantPurple.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD166),
              size: 54,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rata-rata Penilaian',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '4.8/5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Dashboard mini kepuasan pengguna LabIn',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScoreRow extends StatelessWidget {
  const _MiniScoreRow({required this.label, required this.score});

  final String label;
  final int score;

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
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 14,
              color: AppTheme.vibrantPurple,
              backgroundColor: AppTheme.electricBlue.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
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
    required this.fallbackAssetPath,
    required this.booking,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAssetPath;
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
              child: _RealtimeImage(
                imageUrl: imageUrl,
                fallbackAssetPath: fallbackAssetPath,
                height: 220,
                fallbackIcon: icon,
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

enum _CampusLayout { rektorat, campus1, campus2, campus3, campus4 }

class _CampusMapData {
  const _CampusMapData({
    required this.title,
    required this.address,
    required this.subtitle,
    required this.layout,
    required this.rooms,
  });

  final String title;
  final String address;
  final String subtitle;
  final _CampusLayout layout;
  final List<String> rooms;

  String get mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

  Color get accent {
    return switch (layout) {
      _CampusLayout.rektorat => AppTheme.electricBlue,
      _CampusLayout.campus1 => AppTheme.vibrantPurple,
      _CampusLayout.campus2 => AppTheme.emerald,
      _CampusLayout.campus3 => AppTheme.deepTeal,
      _CampusLayout.campus4 => AppTheme.richBronze,
    };
  }
}
