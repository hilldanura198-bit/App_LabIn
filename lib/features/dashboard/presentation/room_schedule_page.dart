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
  late DateTime _selectedDay;
  late Future<_RoomScheduleSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _snapshotFuture = _loadSnapshot(_selectedDay);
  }

  Future<_RoomScheduleSnapshot> _loadSnapshot(DateTime day) async {
    final rooms = await widget.repository.fetchLaboratories();
    final bookings = await widget.repository.fetchRoomScheduleForDay(day);
    return _RoomScheduleSnapshot(rooms: rooms, bookings: bookings);
  }

  void _refresh() {
    setState(() {
      _snapshotFuture = _loadSnapshot(_selectedDay);
    });
  }

  void _onDayChanged(DateTime day) {
    setState(() {
      _selectedDay = day;
      _snapshotFuture = _loadSnapshot(day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Jadwal Ruangan'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: FutureBuilder<_RoomScheduleSnapshot>(
                  future: _snapshotFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _ErrorCard(text: snapshot.error.toString());
                    }
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snapshot.data!;
                    final bookingsByRoomId = <String, List<LabBooking>>{};
                    for (final booking in data.bookings) {
                      bookingsByRoomId.putIfAbsent(booking.labId, () => []);
                      bookingsByRoomId[booking.labId]!.add(booking);
                    }
                    final bookedRoomCount = bookingsByRoomId.length;
                    final availableRoomCount =
                        data.rooms.length - bookedRoomCount;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(
                          selectedDay: _selectedDay,
                          bookedRoomCount: bookedRoomCount,
                          availableRoomCount: availableRoomCount < 0
                              ? 0
                              : availableRoomCount,
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
                              onDateChanged: _onDayChanged,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SelectedSummaryCard(
                          selectedDay: _selectedDay,
                          totalRooms: data.rooms.length,
                          bookedRooms: bookedRoomCount,
                        ),
                        const SizedBox(height: 16),
                        if (data.rooms.isEmpty)
                          const _EmptyStateCard(
                            title: 'Belum ada ruangan terdaftar.',
                            subtitle:
                                'Tambahkan ruangan melalui menu CRUD Sarpras.',
                          )
                        else
                          ...data.rooms.map((room) {
                            final roomBookings =
                                bookingsByRoomId[room.id] ??
                                const <LabBooking>[];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoomAvailabilityCard(
                                room: room,
                                bookings: roomBookings,
                                selectedDay: _selectedDay,
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomAvailabilityCard extends StatelessWidget {
  const _RoomAvailabilityCard({
    required this.room,
    required this.bookings,
    required this.selectedDay,
  });

  final LabRoom room;
  final List<LabBooking> bookings;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    final booked = bookings.isNotEmpty;
    final statusColor = booked
        ? const Color(0xFFEF4444)
        : const Color(0xFF22C55E);
    final dayLabel = DateFormat(
      'dd MMM yyyy',
      Localizations.localeOf(context).toString(),
    ).format(selectedDay);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              campus.primary.withValues(alpha: 0.05),
              campus.secondary.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoomPreview(imageUrl: room.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.location,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: Icon(
                              booked
                                  ? Icons.event_busy_outlined
                                  : Icons.check_circle_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              booked ? 'Terbooking' : 'Tersedia',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            backgroundColor: statusColor,
                            side: BorderSide.none,
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                            ),
                            label: Text(
                              booked
                                  ? 'Tidak Tersedia untuk Dipinjam'
                                  : 'Bisa Dipinjam',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              booked
                  ? '$dayLabel · ${bookings.length} booking aktif pada ruangan ini'
                  : '$dayLabel · Ruangan kosong pada tanggal ini',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (bookings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BookingMiniCard(booking: booking),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookingMiniCard extends StatelessWidget {
  const _BookingMiniCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_clock_outlined, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.labDisplayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  booking.scheduleLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            visualDensity: VisualDensity.compact,
            label: Text(
              booking.statusLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: statusColor,
            side: BorderSide.none,
          ),
        ],
      ),
    );
  }
}

class _RoomPreview extends StatelessWidget {
  const _RoomPreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.meeting_room_outlined),
    );
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: placeholder,
      );
    }
    final url = imageUrl!.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              )
            : Image.asset(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.selectedDay,
    required this.bookedRoomCount,
    required this.availableRoomCount,
  });

  final DateTime selectedDay;
  final int bookedRoomCount;
  final int availableRoomCount;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat.yMMMMEEEEd(locale).format(selectedDay);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppTheme.campusGradientOf(context),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Keterpakaian Ruangan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kalender menampilkan booking pending dan approved yang menutup ketersediaan ruang.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryPill(icon: Icons.event_note_outlined, label: dayLabel),
                _SummaryPill(
                  icon: Icons.meeting_room_outlined,
                  label: '$bookedRoomCount terbooking',
                ),
                _SummaryPill(
                  icon: Icons.check_circle_outline,
                  label: '$availableRoomCount tersedia',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSummaryCard extends StatelessWidget {
  const _SelectedSummaryCard({
    required this.selectedDay,
    required this.totalRooms,
    required this.bookedRooms,
  });

  final DateTime selectedDay;
  final int totalRooms;
  final int bookedRooms;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat.yMMMMEEEEd(locale).format(selectedDay);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.cyberGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$bookedRooms ruangan terbooking dari $totalRooms ruangan terdaftar',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.event_busy_outlined, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(22), child: Text(text)),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _RoomScheduleSnapshot {
  const _RoomScheduleSnapshot({required this.rooms, required this.bookings});

  final List<LabRoom> rooms;
  final List<LabBooking> bookings;
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
