import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final code = _assetCode(index);
                final booking = _latestBookingForLab(bookings, item.labId);
                final imageUrl = _facilityImageUrl(item.namaAlat, index);
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
                          imageUrl: imageUrl,
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
                                    imageUrl,
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
                              onPressed: () => _showFacilityImage(
                                context,
                                item,
                                booking,
                                imageUrl,
                              ),
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
    String imageUrl,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _ImageDialog(
        title: item.namaAlat,
        subtitle: 'Kode aset dan dokumentasi visual sarana.',
        imageUrl: imageUrl,
        booking: booking,
        icon: Icons.precision_manufacturing_outlined,
      ),
    );
  }

  String _facilityImageUrl(String name, int index) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('arduino')) {
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/Arduino_Uno_-_R3.jpg';
    }
    if (lowerName.contains('ultrasonik') || lowerName.contains('ultrasonic')) {
      return 'https://commons.wikimedia.org/wiki/Special:FilePath/HC-SR04_Ultrasonic_Sensor.jpg';
    }
    if (lowerName.contains('sensor')) {
      return 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('proyektor')) {
      return 'https://images.unsplash.com/photo-1560472355-536de3962603?auto=format&fit=crop&w=900&q=80';
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
    const pool = [
      'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1581092921461-39b9d08a9b21?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1581091215367-59ab6b3f563d?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1581091870622-7c40f7fef4a0?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1581093458791-9d81cc7d2c81?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1593640408182-31c70c8268f5?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=900&q=80',
    ];
    return pool[index % pool.length];
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
    if (lowerName.contains('rpl')) {
      return 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('jaringan')) {
      return 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80';
    }
    if (lowerName.contains('iot')) {
      return 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=900&q=80';
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

  static const _campuses = [
    _CampusMapData(
      title: 'Kampus Rektorat',
      address: 'Jl. Ki Mangun Sarkoro No.20, Nusukan, Banjarsari, Surakarta',
      subtitle: 'Pusat administrasi dan layanan akademik utama.',
      layout: _CampusLayout.rektorat,
      bannerImageUrl:
          'https://images.unsplash.com/photo-1503387762-592deb58ef4e?auto=format&fit=crop&w=1200&q=80',
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
      bannerImageUrl:
          'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
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
      bannerImageUrl:
          'https://images.unsplash.com/photo-1580281657521-47d7f5f1ab02?auto=format&fit=crop&w=1200&q=80',
      rooms: ['Klinik', 'Lab Simulasi', 'Farmasi', 'Ruang Dosen', 'Admin'],
    ),
    _CampusMapData(
      title: 'Kampus 3',
      address: 'Jl. Pinang Raya No.47, Jati, Cemani, Grogol, Sukoharjo',
      subtitle: 'Area pengembangan berbasis riset dan kegiatan lintas prodi.',
      layout: _CampusLayout.campus3,
      bannerImageUrl:
          'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80',
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
      bannerImageUrl:
          'https://images.unsplash.com/photo-1518005020951-eccb494ad742?auto=format&fit=crop&w=1200&q=80',
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
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _BlueprintImage(
                imageUrl: campus.bannerImageUrl,
                height: 180,
                fallbackIcon: Icons.map_outlined,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(18),
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
                            imageUrl: _campusRoomImageUrl(campus.layout, room),
                            accent: campus.accent,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    required this.imageUrl,
    required this.accent,
  });

  final String label;
  final String imageUrl;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            color: Colors.white.withValues(alpha: 0.10),
            colorBlendMode: BlendMode.modulate,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.cyberGradient,
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.55),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlueprintImage extends StatelessWidget {
  const _BlueprintImage({
    required this.imageUrl,
    required this.height,
    required this.fallbackIcon,
  });

  final String imageUrl;
  final double height;
  final IconData fallbackIcon;

  static const _grayscaleMatrix = <double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(_grayscaleMatrix),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                  ),
                  child: Icon(fallbackIcon, color: Colors.white, size: 42),
                );
              },
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.10),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }
}

String _campusRoomImageUrl(_CampusLayout layout, String room) {
  final lowerRoom = room.toLowerCase();
  if (lowerRoom.contains('ruang rektor') ||
      lowerRoom.contains('front office')) {
    return 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('biro') || lowerRoom.contains('administrasi')) {
    return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('lobby')) {
    return 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('aula') || lowerRoom.contains('auditorium')) {
    return 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('rapat') || lowerRoom.contains('seminar')) {
    return 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('kelas')) {
    return 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('perpustakaan')) {
    return 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('kantin')) {
    return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('studio') || lowerRoom.contains('multimedia')) {
    return 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('rpl')) {
    return 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('jaringan')) {
    return 'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('iot')) {
    return 'https://images.unsplash.com/photo-1518773553398-650c184e0bb3?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('klinik')) {
    return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('simulasi')) {
    return 'https://images.unsplash.com/photo-1580281657521-47d7f5f1ab02?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('farmasi')) {
    return 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('dosen')) {
    return 'https://images.unsplash.com/photo-1497366412874-3415097a27e7?auto=format&fit=crop&w=900&q=80';
  }
  if (lowerRoom.contains('diskusi') || lowerRoom.contains('co-working')) {
    return 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=900&q=80';
  }
  if (layout == _CampusLayout.campus2) {
    return 'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=900&q=80';
  }
  if (layout == _CampusLayout.campus3) {
    return 'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=900&q=80';
  }
  if (layout == _CampusLayout.campus4) {
    return 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=900&q=80';
  }
  return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=900&q=80';
}

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

enum _CampusLayout { rektorat, campus1, campus2, campus3, campus4 }

class _CampusMapData {
  const _CampusMapData({
    required this.title,
    required this.address,
    required this.subtitle,
    required this.layout,
    required this.bannerImageUrl,
    required this.rooms,
  });

  final String title;
  final String address;
  final String subtitle;
  final _CampusLayout layout;
  final String bannerImageUrl;
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
