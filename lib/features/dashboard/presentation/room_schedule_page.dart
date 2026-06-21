import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String? _selectedLabId;
  late final Future<List<LabRoom>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.repository.fetchLaboratories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Jadwal Ruangan'),
      body: SafeArea(
        child: FutureBuilder<List<LabRoom>>(
          future: _roomsFuture,
          builder: (context, roomSnapshot) {
            final rooms = roomSnapshot.data ?? const <LabRoom>[];
            final roomNames = {for (final room in rooms) room.id: room.name};
            return StreamBuilder<List<LabBooking>>(
              stream: widget.repository.watchRoomSchedule(),
              builder: (context, scheduleSnapshot) {
                final bookings = scheduleSnapshot.data ?? const <LabBooking>[];
                final selectedBookings = _filterBookings(bookings);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth >= 860
                        ? 760.0
                        : constraints.maxWidth;
                    return Center(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: maxWidth),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CalendarPanel(
                                    focusedDay: _focusedDay,
                                    selectedDay: _selectedDay,
                                    bookings: bookings,
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = selectedDay;
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _RoomFilter(
                                    rooms: rooms,
                                    selectedLabId: _selectedLabId,
                                    onSelected: (labId) {
                                      setState(() => _selectedLabId = labId);
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Jadwal Ruangan',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 12),
                                  if (!scheduleSnapshot.hasData &&
                                      scheduleSnapshot.connectionState ==
                                          ConnectionState.waiting)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (selectedBookings.isEmpty)
                                    _EmptyScheduleCard(date: _selectedDay)
                                  else
                                    ...selectedBookings.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final booking = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _ScheduleCard(
                                          booking: booking,
                                          roomName:
                                              roomNames[booking.labId] ??
                                              'Ruang Laboratorium',
                                          accentColor: _accentForIndex(index),
                                        ),
                                      );
                                    }),
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
            );
          },
        ),
      ),
    );
  }

  List<LabBooking> _filterBookings(List<LabBooking> bookings) {
    final filtered = bookings.where((booking) {
      final sameDay = isSameDay(booking.tanggalPinjam, _selectedDay);
      final sameRoom =
          _selectedLabId == null || booking.labId == _selectedLabId;
      return sameDay && sameRoom && booking.status != 'returned';
    }).toList()..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
    return filtered;
  }
}

Color _accentForIndex(int index) {
  const palette = [
    AppTheme.electricBlue,
    AppTheme.vibrantPurple,
    AppTheme.cleanCyan,
    AppTheme.deepTeal,
    AppTheme.emerald,
    AppTheme.richBronze,
    Color(0xFF5A67FF),
    Color(0xFF8B5CF6),
  ];
  return palette[index % palette.length];
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.focusedDay,
    required this.selectedDay,
    required this.bookings,
    required this.onDaySelected,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<LabBooking> bookings;
  final OnDaySelected onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: TableCalendar<LabBooking>(
          firstDay: DateTime.now().subtract(const Duration(days: 60)),
          lastDay: DateTime.now().add(const Duration(days: 120)),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          eventLoader: (day) => bookings
              .where(
                (booking) =>
                    isSameDay(booking.tanggalPinjam, day) &&
                    booking.status != 'returned',
              )
              .toList(),
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarFormat: CalendarFormat.week,
          availableCalendarFormats: const {CalendarFormat.week: 'Minggu'},
          onDaySelected: onDaySelected,
          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextStyle:
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ) ??
                const TextStyle(fontWeight: FontWeight.w900),
            formatButtonVisible: false,
            leftChevronIcon: const Icon(Icons.chevron_left_rounded),
            rightChevronIcon: const Icon(Icons.chevron_right_rounded),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontWeight: FontWeight.w700),
            weekendStyle: TextStyle(fontWeight: FontWeight.w700),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              gradient: AppTheme.cyberGradient,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppTheme.vibrantPurple,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            todayTextStyle: const TextStyle(
              color: AppTheme.electricBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomFilter extends StatelessWidget {
  const _RoomFilter({
    required this.rooms,
    required this.selectedLabId,
    required this.onSelected,
  });

  final List<LabRoom> rooms;
  final String? selectedLabId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua Lab'),
              selected: selectedLabId == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...rooms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(room.name),
                selected: selectedLabId == room.id,
                onSelected: (_) => onSelected(room.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.booking,
    required this.roomName,
    required this.accentColor,
  });

  final LabBooking booking;
  final String roomName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final timeRange =
        '${DateFormat.Hm().format(booking.tanggalPinjam)} - '
        '${DateFormat.Hm().format(booking.tanggalKembali)}';
    return Card(
      color: accentColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, AppTheme.vibrantPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat.Hm().format(booking.tanggalPinjam),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activityLabel(booking.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$roomName - $timeRange',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dosen/PIC: ${_lecturerForRoom(roomName)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusChip(booking: booking),
          ],
        ),
      ),
    );
  }

  String _activityLabel(String status) {
    return switch (status) {
      'active' => 'Praktikum berlangsung',
      'approved_kalab' || 'approved_aslab' => 'Sesi lab terjadwal',
      'rejected' => 'Reservasi ditolak',
      _ => 'Menunggu approval pemakaian',
    };
  }

  String _lecturerForRoom(String roomName) {
    final lowerName = roomName.toLowerCase();
    if (lowerName.contains('iot')) return 'Dr. Raka Pratama';
    if (lowerName.contains('jaringan')) return 'Dian Puspita, M.Kom';
    if (lowerName.contains('rpl')) return 'Arif Wibowo, M.Cs';
    return 'PIC Laboratorium';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final color = booking.statusColor;
    final label = booking.statusLabel;
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.7)),
    );
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
        child: Column(
          children: [
            Container(
              width: 150,
              height: 118,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.electricBlue.withValues(alpha: 0.16),
                    AppTheme.vibrantPurple.withValues(alpha: 0.14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 18,
                    child: Container(
                      width: 86,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.electricBlue.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.electricBlue.withValues(
                              alpha: 0.14,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    child: Icon(
                      Icons.event_note_rounded,
                      color: AppTheme.electricBlue,
                      size: 62,
                    ),
                  ),
                  const Positioned(
                    bottom: 18,
                    right: 34,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.vibrantPurple,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum ada jadwal hari ini',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada pemakaian ruangan pada ${DateFormat('d MMMM y').format(date)}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
