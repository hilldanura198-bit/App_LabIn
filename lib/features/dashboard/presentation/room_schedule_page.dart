import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
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
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scheduleStream = widget.repository.watchRoomSchedule();
  }

  void _refresh() {
    setState(() {
      _scheduleStream = widget.repository.watchRoomSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayFormatter = DateFormat.yMMMMEEEEd(locale);
    return Scaffold(
      appBar: const GlassAppBar(title: 'Jadwal Ruangan'),
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: _scheduleStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = snapshot.data!.where(_isRelevantBooking).toList()
              ..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Jadwal Keterpakaian Ruangan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Kalender berikut menampilkan reservasi aktif, pending, dan approved yang masih berjalan.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
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
                                      gradient: AppTheme.cyberGradient,
                                      borderRadius: BorderRadius.circular(16),
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
                                              ?.copyWith(color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                      'Ruangan Kosong (Tersedia untuk dipinjam)',
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
                          else
                            ...todaysBookings.map(
                              (booking) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ScheduleCard(booking: booking),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(booking.status);
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
              label: Text(_statusLabel(booking.status)),
              labelStyle: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
              ),
              backgroundColor: statusColor.withValues(alpha: 0.12),
              side: BorderSide(color: statusColor.withValues(alpha: 0.24)),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'pending' => const Color(0xFFF59E0B),
    'approved_aslab' => const Color(0xFF3B82F6),
    'approved_kalab' => const Color(0xFF8B5CF6),
    'active' => const Color(0xFF10B981),
    'late' => const Color(0xFFEF4444),
    _ => AppTheme.electricBlue,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Pending',
    'approved_aslab' => 'Approved Aslab',
    'approved_kalab' => 'Approved Kalab',
    'active' => 'Active',
    'late' => 'Terlambat',
    _ => 'Selesai',
  };
}
