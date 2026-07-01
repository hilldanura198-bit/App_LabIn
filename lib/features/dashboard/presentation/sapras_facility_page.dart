import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class SaprasFacilityPage extends StatelessWidget {
  const SaprasFacilityPage({
    super.key,
    required this.repository,
    this.selectedCampus = 'Kampus Rektorat',
  });

  final DashboardRepository repository;
  final String selectedCampus;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.campusTheme(Theme.of(context), selectedCampus),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: GlassAppBar(
            title: 'sapras_campus'.tr(),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'facility'.tr()),
                Tab(text: 'infrastructure'.tr()),
                Tab(text: 'blueprint'.tr()),
                Tab(text: 'satisfaction_tab'.tr()),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                _FacilityList(
                  repository: repository,
                  selectedCampus: selectedCampus,
                ),
                _InfrastructureList(repository: repository),
                _CampusMapTabs(selectedCampus: selectedCampus),
                _SatisfactionReviewTab(repository: repository),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacilityList extends StatelessWidget {
  const _FacilityList({required this.repository, required this.selectedCampus});

  final DashboardRepository repository;
  final String selectedCampus;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabInventory>>(
      stream: repository.watchInventoriesByCampus(selectedCampus),
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
            final items = DashboardModel.mergeWithLocalFacilities(
              inventorySnapshot.data!,
            );
            final bookings = bookingSnapshot.data ?? const <LabBooking>[];
            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return const _FacilityReviewCard();
                }
                final item = items[index];
                final code = _assetCode(index);
                final booking = _latestBookingForLab(bookings, item.labId);
                final labBookings = _bookingsForLab(bookings, item.labId);
                final scheme = Theme.of(context).colorScheme;
                final accent = index.isOdd ? scheme.secondary : scheme.primary;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.14),
                        scheme.tertiary.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent.withValues(alpha: 0.18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 620;
                        final image = _FacilityImage(
                          assetName: item.imageUrl ?? item.namaAlat,
                          height: compact ? 150 : 112,
                          fallbackIcon: Icons.inventory_2_rounded,
                        );
                        final detail = _FacilityDetail(
                          item: item,
                          code: code,
                          booking: booking,
                          bookings: labBookings,
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              image,
                              const SizedBox(height: 14),
                              _FacilityTextPanel(child: detail),
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
                            Expanded(child: _FacilityTextPanel(child: detail)),
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

  List<LabBooking> _bookingsForLab(List<LabBooking> bookings, String labId) {
    return bookings
        .where(
          (booking) =>
              booking.labId == labId &&
              booking.status != 'returned' &&
              booking.status != 'rejected',
        )
        .toList()
      ..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
  }

  void _showFacilityImage(
    BuildContext context,
    LabInventory item,
    LabBooking? booking,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _ImageDialog(
        title: item.namaAlat.capitalize(),
        subtitle: 'Kode aset dan dokumentasi visual sarana.',
        imageUrl: item.imageUrl ?? item.namaAlat,
        booking: booking,
        icon: Icons.inventory_2_rounded,
      ),
    );
  }
}

class _FacilityDetail extends StatelessWidget {
  const _FacilityDetail({
    required this.item,
    required this.code,
    required this.booking,
    required this.bookings,
  });

  final LabInventory item;
  final String code;
  final LabBooking? booking;
  final List<LabBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final good = item.kondisi == 'bagus';
    final positiveColor = Theme.of(context).colorScheme.tertiary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _DataPill(label: 'asset_code'.tr(), value: code),
            _DataPill(
              label: 'facility_name'.tr(),
              value: item.namaAlat.capitalize(),
            ),
            _DataPill(label: 'room_name'.tr(), value: _roomName(item.labId)),
            _DataPill(
              label: 'building'.tr(),
              value: 'technology_building'.tr(),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: (good ? positiveColor : const Color(0xFFFF4D6D))
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: good ? positiveColor : const Color(0xFFFF4D6D),
                ),
              ),
              child: Text(
                good ? 'good'.tr() : 'broken'.tr(),
                style: TextStyle(
                  color: good ? Colors.white : const Color(0xFFFFD7DF),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _DataPill(
              label: 'stock_total'.tr(),
              value: 'available_stock'.tr(
                namedArgs: {
                  'available': '${item.stokTersedia}',
                  'total': '${item.totalStok}',
                },
              ),
            ),
          ],
        ),
        if (bookings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _UsageScheduleChip(bookings: bookings),
        ],
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

class _FacilityTextPanel extends StatelessWidget {
  const _FacilityTextPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? AppTheme.nightPanel.withValues(alpha: 0.96)
            : AppTheme.cyberInk.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.24 : 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
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
    required this.assetName,
    required this.height,
    required this.fallbackIcon,
  });

  final String assetName;
  final double height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _RealtimeImage(
        assetName: assetName,
        height: height,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}

class _RealtimeImage extends StatelessWidget {
  const _RealtimeImage({
    required this.assetName,
    required this.height,
    this.fallbackIcon = Icons.image_outlined,
  });

  final String assetName;
  final double height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    if (assetName.startsWith('http://') || assetName.startsWith('https://')) {
      return Image.network(
        assetName,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, _, _) =>
            _ImagePlaceholder(height: height, icon: fallbackIcon),
      );
    }
    return Image.asset(
      DashboardModel.getLocalAssetPath(assetName),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) {
        return Image.asset(
          DashboardModel.fallbackAssetPath,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) =>
              _ImagePlaceholder(height: height, icon: fallbackIcon),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.height, required this.icon});

  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.86),
      ),
      child: Center(
        child: Icon(
          icon == Icons.image_outlined ? Icons.image_rounded : icon,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.72),
          size: 38,
        ),
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
      label: Text('detail'.tr()),
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
  const _UsageScheduleChip({required this.bookings});

  final List<LabBooking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Chip(
        avatar: const Icon(Icons.event_available_outlined, size: 18),
        label: Text('operational_fallback'.tr()),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        backgroundColor: Colors.white.withValues(alpha: 0.10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: bookings.map((booking) {
          final start = _timeLabel(booking.tanggalPinjam, booking.startTime);
          final end = _timeLabel(booking.tanggalKembali, booking.endTime);
          final label = start == end || (start == '00:00' && end == '00:00')
              ? 'operational_fallback'.tr()
              : '$start-$end';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: const Icon(Icons.event_available_outlined, size: 18),
              label: Text(label),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _timeLabel(DateTime value, String storedTime) {
    final normalized = storedTime.trim();
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(normalized) &&
        normalized != '00:00') {
      return normalized;
    }
    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }
}

Color _statusColor(String status) {
  final primary = AppTheme.electricBlue;
  return switch (status) {
    'approved_aslab' || 'approved_kalab' || 'active' => primary,
    'pending' => const Color(0xFFFFB020),
    'rejected' => const Color(0xFFFF4D6D),
    _ => const Color(0xFF22D3EE),
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
    'used' => 'Terpakai',
    'approved_aslab' => 'status_approved_aslab'.tr(),
    'approved_kalab' => 'status_approved_kalab'.tr(),
    'active' => 'status_active'.tr(),
    'returned' => 'status_returned'.tr(),
    'late' => 'status_late'.tr(),
    'pending' => 'Terpakai',
    'rejected' => 'rejected'.tr(),
    _ => 'available'.tr(),
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            return GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: compact ? 220 : 280,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: compact ? 0.92 : 1.05,
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
                      imageUrl: room.name,
                      booking: null,
                      icon: Icons.apartment_rounded,
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _RealtimeImage(
                                assetName: room.name,
                                height: double.infinity,
                                fallbackIcon: Icons.apartment_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            room.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
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
      },
    );
  }
}

class _CampusMapTabs extends StatelessWidget {
  const _CampusMapTabs({required this.selectedCampus});

  final String selectedCampus;

  static const _campuses = [
    _CampusMapData(
      title: 'Kampus Rektorat',
      address: 'Jl. Ki Mangun Sarkoro No.20, Nusukan, Banjarsari, Surakarta',
      subtitle: 'Pusat administrasi dan layanan akademik utama.',
      layout: _CampusLayout.rektorat,
      mapAssetPath: 'assets/images/denah 5.jpeg',
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
      mapAssetPath: 'assets/images/denah 1.jpeg',
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
      mapAssetPath: 'assets/images/denah 2.jpeg',
      rooms: ['Klinik', 'Lab Simulasi', 'Farmasi', 'Ruang Dosen', 'Admin'],
    ),
    _CampusMapData(
      title: 'Kampus 3',
      address: 'Jl. Pinang Raya No.47, Jati, Cemani, Grogol, Sukoharjo',
      subtitle: 'Area pengembangan berbasis riset dan kegiatan lintas prodi.',
      layout: _CampusLayout.campus3,
      mapAssetPath: 'assets/images/denah 3.jpeg',
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
      mapAssetPath: 'assets/images/denah 4.jpeg',
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
    final initialIndex = _campuses.indexWhere(
      (campus) => campus.title == selectedCampus,
    );
    return DefaultTabController(
      length: _campuses.length,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: _campuses.map((campus) => Tab(text: campus.title)).toList(),
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
                  const SizedBox(height: 16),
                  const _FacilityReviewCard(),
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
    final scheme = Theme.of(context).colorScheme;
    final rooms = campus.rooms;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            campus.accent.withValues(alpha: 0.16),
            campus.secondaryAccent.withValues(alpha: 0.10),
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
                color: scheme.surface,
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
                          'blueprint_campus_title'.tr(
                            namedArgs: {'campus': campus.title},
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.grid_view_rounded, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'blueprint_body'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      campus.mapAssetPath,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) => Image.asset(
                        DashboardModel.fallbackAssetPath,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    label: 'main_equipment_locker'.tr(),
                    accent: campus.secondaryAccent,
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
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
            'campus_info_title'.tr(namedArgs: {'campus': campus.title}),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            campus.address,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(campus.mapUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.map_outlined),
            label: Text('maps_open'.tr()),
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
    final scheme = Theme.of(context).colorScheme;
    final zoneColor = switch (type) {
      _BlueprintZoneType.entry => scheme.primary,
      _BlueprintZoneType.locker => scheme.secondary,
      _BlueprintZoneType.room => accent,
    };
    final icon = switch (type) {
      _BlueprintZoneType.entry => Icons.login_rounded,
      _BlueprintZoneType.locker => Icons.inventory_2_outlined,
      _BlueprintZoneType.room => Icons.meeting_room_outlined,
    };
    final typeLabel = switch (type) {
      _BlueprintZoneType.entry => 'access_zone'.tr(),
      _BlueprintZoneType.locker => 'equipment_locker'.tr(),
      _BlueprintZoneType.room => 'rooms_tag'.tr(),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            typeLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: zoneColor,
              fontWeight: FontWeight.w900,
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
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendChip(
          color: Theme.of(context).colorScheme.primary,
          label: 'rooms_tag'.tr(),
        ),
        _LegendChip(
          color: Theme.of(context).colorScheme.secondary,
          label: 'equipment_locker'.tr(),
        ),
        _LegendChip(
          color: Theme.of(context).colorScheme.tertiary,
          label: 'access_zone'.tr(),
        ),
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
    final scheme = Theme.of(context).colorScheme;
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
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityReviewCard extends StatelessWidget {
  const _FacilityReviewCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final testimonials = ['testimonial_1'.tr(), 'testimonial_2'.tr()];
    return Card(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'satisfaction_title'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'satisfaction_subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    '4.8/5',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.vibrantPurple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'average_rating'.tr(),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...testimonials.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: AppTheme.electricBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SatisfactionReviewTab extends StatefulWidget {
  const _SatisfactionReviewTab({required this.repository});

  final DashboardRepository repository;

  @override
  State<_SatisfactionReviewTab> createState() => _SatisfactionReviewTabState();
}

class _SatisfactionReviewTabState extends State<_SatisfactionReviewTab> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final message = _controller.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('review_required'.tr())));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.repository.submitFeedback(rating: _rating, message: message);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _rating = 5;
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('review_sent'.tr())));
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('review_failed'.tr(args: ['$error']))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedbackEntry>>(
      stream: widget.repository.watchFeedbackEntries(),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <FeedbackEntry>[];
        final average = reviews.isEmpty
            ? 4.8
            : reviews.fold<double>(0, (sum, item) => sum + item.rating) /
                  reviews.length;
        final displayReviews = reviews.isEmpty
            ? _fallbackReviews()
            : reviews.take(12).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReviewSummaryCard(
                    average: average,
                    totalReviews: reviews.isEmpty ? 24 : reviews.length,
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'write_review'.tr(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          _StarInput(
                            rating: _rating,
                            onChanged: (value) =>
                                setState(() => _rating = value),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _controller,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              labelText: 'review_field_label'.tr(),
                              hintText: 'review_field_hint'.tr(),
                              prefixIcon: const Icon(
                                Icons.rate_review_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppTheme.campusGradientOf(context),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: FilledButton.icon(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: _submitting
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text('send_review'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'student_reviews'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...displayReviews.map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReviewQuoteCard(review: review),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<FeedbackEntry> _fallbackReviews() {
    final now = DateTime.now();
    return [
      FeedbackEntry(
        id: 'fallback-1',
        userId: 'sample',
        rating: 5,
        message: 'testimonial_1'.tr(),
        createdAt: now,
      ),
      FeedbackEntry(
        id: 'fallback-2',
        userId: 'sample',
        rating: 5,
        message: 'testimonial_2'.tr(),
        createdAt: now,
      ),
    ];
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.average, required this.totalReviews});

  final double average;
  final int totalReviews;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    final iconBox = compact ? 58.0 : 66.0;
    final iconSize = compact ? 38.0 : 46.0;
    final scoreSize = compact ? 26.0 : 30.0;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: AppTheme.campusGradientOf(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD166),
              size: iconSize,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'average_rating'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${average.toStringAsFixed(1)}/5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scoreSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'review_count'.tr(args: ['$totalReviews']),
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

class _StarInput extends StatelessWidget {
  const _StarInput({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        final active = value <= rating;
        return IconButton(
          onPressed: () => onChanged(value),
          icon: Icon(
            active ? Icons.star_rounded : Icons.star_border_rounded,
            color: active ? const Color(0xFFFFB020) : AppTheme.muted,
            size: 34,
          ),
        );
      }),
    );
  }
}

class _ReviewQuoteCard extends StatelessWidget {
  const _ReviewQuoteCard({required this.review});

  final FeedbackEntry review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.vibrantPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.format_quote_rounded,
              color: AppTheme.vibrantPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: const Color(0xFFFFB020),
                        size: 18,
                      );
                    }),
                    const Spacer(),
                    Text(
                      _dateLabel(review.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  review.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.4,
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

  String _dateLabel(DateTime value) {
    return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
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
                      'satisfaction_analysis'.tr(),
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
                      decoration: InputDecoration(
                        labelText: 'period_choose'.tr(),
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
    final compact = MediaQuery.sizeOf(context).width < 380;
    final iconBox = compact ? 58.0 : 66.0;
    final iconSize = compact ? 38.0 : 46.0;
    final scoreSize = compact ? 26.0 : 30.0;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        gradient: AppTheme.campusGradientOf(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Icon(
              Icons.star_rounded,
              color: Color(0xFFFFD166),
              size: iconSize,
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
                Text(
                  '4.8/5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scoreSize,
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
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.16),
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
  final String? imageUrl;
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
                assetName: imageUrl ?? title,
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
                _UsageScheduleChip(bookings: booking == null ? [] : [booking!]),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr()),
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
    required this.mapAssetPath,
    required this.rooms,
  });

  final String title;
  final String address;
  final String subtitle;
  final _CampusLayout layout;
  final String mapAssetPath;
  final List<String> rooms;

  String get mapUrl =>
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';

  CampusPalette get palette => AppTheme.campusPalette(title);

  Color get accent => palette.primary;

  Color get secondaryAccent => palette.secondary;
}
