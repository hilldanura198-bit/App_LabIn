import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class RoomSchedulePage extends StatefulWidget {
  const RoomSchedulePage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<RoomSchedulePage> createState() => _RoomSchedulePageState();
}

class _RoomSchedulePageState extends State<RoomSchedulePage> {
  late Stream<List<LabBooking>> _scheduleStream;
  late Stream<List<LabRoom>> _roomStream;
  DateTime _selectedDay = DateTime.now();
  final Set<String> _manualBlockedSlots = <String>{};

  @override
  void initState() {
    super.initState();
    _scheduleStream = widget.repository.watchRoomSchedule();
    _roomStream = widget.repository.watchLaboratories();
  }

  void _refresh() {
    setState(() {
      _scheduleStream = widget.repository.watchRoomSchedule();
      _roomStream = widget.repository.watchLaboratories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayFormatter = DateFormat.yMMMMEEEEd(locale);
    final role = _currentRole(context);
    final canManageSlots = role != UserRole.mahasiswa;
    return Scaffold(
      appBar: const GlassAppBar(title: 'Jadwal Ruangan'),
      body: SafeArea(
        child: StreamBuilder<List<LabRoom>>(
          stream: _roomStream,
          builder: (context, roomSnapshot) {
            if (roomSnapshot.hasError) {
              return Center(child: Text(roomSnapshot.error.toString()));
            }
            if (!roomSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rooms = roomSnapshot.data ?? const <LabRoom>[];
            final globallyLocked = rooms.any(
              (room) => room.status.toLowerCase() != 'aktif',
            );
            return StreamBuilder<List<LabBooking>>(
              stream: _scheduleStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bookings =
                    snapshot.data!.where(_isRelevantBooking).toList()..sort(
                      (a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam),
                    );
                final todaysBookings = bookings
                    .where((booking) => _matchesDay(booking, _selectedDay))
                    .toList();
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Jadwal Keterpakaian Ruangan',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Kalender berikut menampilkan reservasi aktif, pending, dan approved yang masih berjalan.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppTheme.muted),
                                      ),
                                      const SizedBox(height: 8),
                                      if (canManageSlots) ...[
                                        _StatusBanner(
                                          title: 'Mode Kalab',
                                          message:
                                              'Kalab dapat mengetuk slot untuk block atau unblock manual. Status booking yang sudah ada tetap menjadi acuan utama.',
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ketuk slot untuk block/unblock manual.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (globallyLocked) ...[
                                          const SizedBox(height: 8),
                                          _StatusBanner(
                                            title: 'Tutup Lab aktif',
                                            message:
                                                'Satu atau lebih laboratorium sedang ditutup sehingga slot mahasiswa ditandai tidak tersedia.',
                                          ),
                                        ],
                                      ] else ...[
                                        Text(
                                          'Mahasiswa hanya melihat slot booking aktif agar pengajuan tidak dobel.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: AppTheme.muted),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: CalendarDatePicker(
                                    initialDate: _selectedDay,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 90),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 180),
                                    ),
                                    onDateChanged: (date) {
                                      setState(() => _selectedDay = date);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.campusGradientOf(
                                            context,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dayFormatter.format(_selectedDay),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${todaysBookings.length} reservasi pada tanggal ini',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppTheme.muted,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (canManageSlots) ...[
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Ketersediaan Slot Hari Ini',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 10),
                                        ..._availabilitySlots(
                                          bookings: todaysBookings,
                                          day: _selectedDay,
                                        ).map((slot) {
                                          final blocked = _manualBlockedSlots
                                              .contains(_slotKey(slot.start));
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: _AvailabilitySlotCard(
                                              slot: slot,
                                              manuallyBlocked: blocked,
                                              globallyLocked:
                                                  globallyLocked &&
                                                  role == UserRole.mahasiswa,
                                              canManage: canManageSlots,
                                              onTap: canManageSlots
                                                  ? () =>
                                                        _toggleManualBlock(slot)
                                                  : null,
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.event_available_outlined,
                                          size: 42,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          todaysBookings.isEmpty
                                              ? 'Ruangan Kosong (Tersedia untuk dipinjam)'
                                              : 'Ruangan Telah Dipinjam (Tidak tersedia)',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          todaysBookings.isEmpty
                                              ? 'Belum ada booking aktif pada tanggal ini.'
                                              : '${todaysBookings.length} reservasi aktif pada tanggal ini',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (canManageSlots) ...[
                                const SizedBox(height: 16),
                                if (todaysBookings.isEmpty)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.event_busy_outlined,
                                            size: 42,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Tidak ada jadwal ruangan pada hari ini.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else ...[
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppTheme.campusGradientOf(
                                                    context,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: const Icon(
                                              Icons.event_available_rounded,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ruangan Telah Dipinjam (Tidak tersedia)',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${todaysBookings.length} reservasi aktif pada tanggal ini',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppTheme.muted,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...todaysBookings.map(
                                    (booking) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _ScheduleCard(booking: booking),
                                    ),
                                  ),
                                ],
                              ] else if (todaysBookings.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ...todaysBookings.map(
                                  (booking) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ScheduleCard(booking: booking),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  UserRole _currentRole(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      return state.role;
    }
    return UserRole.mahasiswa;
  }

  void _toggleManualBlock(_RoomAvailabilitySlot slot) {
    final key = _slotKey(slot.start);
    if (slot.booking != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot ini sedang dipakai booking aktif.')),
      );
      return;
    }
    setState(() {
      if (_manualBlockedSlots.contains(key)) {
        _manualBlockedSlots.remove(key);
      } else {
        _manualBlockedSlots.add(key);
      }
    });
  }

  String _slotKey(DateTime start) {
    return DateFormat('yyyy-MM-dd-HH').format(start);
  }

  bool _isRelevantBooking(LabBooking booking) {
    return switch (booking.status) {
      'pending' ||
      'approved_aslab' ||
      'approved_kalab' ||
      'active' ||
      'late' => true,
      _ => false,
    };
  }

  bool _matchesDay(LabBooking booking, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return booking.tanggalPinjam.isBefore(end) &&
        booking.tanggalKembali.isAfter(start);
  }

  List<_RoomAvailabilitySlot> _availabilitySlots({
    required List<LabBooking> bookings,
    required DateTime day,
  }) {
    final slots = <_RoomAvailabilitySlot>[];
    for (var hour = 7; hour <= 16; hour++) {
      final start = DateTime(day.year, day.month, day.day, hour, 0);
      final end = start.add(const Duration(hours: 1));
      final activeBooking = bookings.where((booking) {
        return booking.tanggalPinjam.isBefore(end) &&
            booking.tanggalKembali.isAfter(start);
      }).toList();
      slots.add(
        _RoomAvailabilitySlot(
          start: start,
          end: end,
          booking: activeBooking.isEmpty ? null : activeBooking.first,
        ),
      );
    }
    return slots;
  }
}

class _RoomAvailabilitySlot {
  const _RoomAvailabilitySlot({
    required this.start,
    required this.end,
    required this.booking,
  });

  final DateTime start;
  final DateTime end;
  final LabBooking? booking;
}

class _AvailabilitySlotCard extends StatelessWidget {
  const _AvailabilitySlotCard({
    required this.slot,
    required this.manuallyBlocked,
    required this.globallyLocked,
    required this.canManage,
    this.onTap,
  });

  final _RoomAvailabilitySlot slot;
  final bool manuallyBlocked;
  final bool globallyLocked;
  final bool canManage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBooked = slot.booking != null;
    final isBusy = isBooked || manuallyBlocked || globallyLocked;
    final color = isBooked
        ? _statusColor(context, slot.booking!.status)
        : isBusy
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;
    final time =
        '${DateFormat.Hm().format(slot.start)} - ${DateFormat.Hm().format(slot.end)}';
    final description = isBooked
        ? '${slot.booking!.labDisplayName} | ${slot.booking!.statusLabel}'
        : manuallyBlocked
        ? 'Slot diblokir manual oleh Kalab'
        : globallyLocked
        ? 'Tutup Lab aktif untuk mahasiswa'
        : 'Ruangan Kosong (Tersedia untuk dipinjam)';
    final badgeLabel = isBusy ? 'Tidak Tersedia' : 'Tersedia';
    final effectiveTap = canManage ? onTap : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isBusy ? Icons.event_busy_outlined : Icons.event_available,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text(badgeLabel),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
                backgroundColor: color.withValues(alpha: 0.12),
                side: BorderSide(color: color.withValues(alpha: 0.22)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(context, booking.status);
    final startTime = booking.startTime.isNotEmpty
        ? booking.startTime
        : DateFormat.Hm().format(booking.tanggalPinjam);
    final endTime = booking.endTime.isNotEmpty
        ? booking.endTime
        : DateFormat.Hm().format(booking.tanggalKembali);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.meeting_room_outlined, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.labDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.reservationNo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Chip(
              label: const Text('Tidak Tersedia'),
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              backgroundColor: const Color(0xFFEF4444),
              side: BorderSide.none,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.do_not_disturb_on_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

Color _statusColor(BuildContext context, String status) {
  return switch (status) {
    'pending' => Theme.of(context).colorScheme.secondary,
    'approved_aslab' => Theme.of(context).colorScheme.primary,
    'approved_kalab' => Theme.of(context).colorScheme.tertiary,
    'active' => Theme.of(context).colorScheme.primaryContainer,
    'late' => Theme.of(context).colorScheme.error,
    _ => Theme.of(context).colorScheme.secondary,
  };
}
