import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_repository.dart';

class RoomSchedulePage extends StatelessWidget {
  const RoomSchedulePage({super.key, required this.repository});

  final DashboardRepository repository;

  static const _rooms = ['Area Luar', 'Convention Hall', 'Gudang', 'Keuangan'];
  static const _hours = ['07:30', '09:00', '10:30', '13:00', '14:30', '16:30'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Pemakaian Ruangan')),
      body: SafeArea(
        child: StreamBuilder(
          stream: repository.watchRoomSchedule(),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? const [];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 150),
                        ..._hours.map((hour) => _HeaderCell(text: hour)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_rooms.length, (roomIndex) {
                      return Row(
                        children: [
                          _RoomCell(text: _rooms[roomIndex]),
                          ...List.generate(_hours.length, (hourIndex) {
                            final borrowed =
                                bookings.length > (roomIndex + hourIndex) &&
                                bookings[(roomIndex + hourIndex) %
                                            (bookings.isEmpty
                                                ? 1
                                                : bookings.length)]
                                        .status !=
                                    'returned';
                            return _ScheduleCell(borrowed: borrowed);
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RoomCell extends StatelessWidget {
  const _RoomCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _ScheduleCell extends StatelessWidget {
  const _ScheduleCell({required this.borrowed});

  final bool borrowed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: borrowed
            ? AppTheme.richBronze.withValues(alpha: 0.24)
            : AppTheme.richBronze.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borrowed
              ? AppTheme.richBronze
              : AppTheme.richBronze.withValues(alpha: 0.55),
        ),
      ),
      child: Text(
        borrowed ? 'Dipinjam' : 'Tersedia',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: borrowed ? AppTheme.espresso : AppTheme.sepia,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
