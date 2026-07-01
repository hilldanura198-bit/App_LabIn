import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'booking_history_detail_page.dart';
import 'widgets/glass_app_bar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.repository,
    required this.role,
    this.showAppBar = true,
  });

  final DashboardRepository repository;
  final UserRole role;
  final bool showAppBar;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar ? const GlassAppBar(title: 'Riwayat') : null,
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: _historyStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = _filterBookings(snapshot.data!);
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HistoryFilter(
                          value: _filter,
                          onChanged: (value) => setState(() {
                            _filter = value;
                          }),
                        ),
                        const SizedBox(height: 16),
                        if (bookings.isEmpty)
                          const _EmptyHistory()
                        else
                          ...bookings.map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryCard(
                                booking: booking,
                                repository: widget.repository,
                                role: widget.role,
                                isInfrastructure: _isInfrastructureBooking(
                                  booking,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Stream<List<LabBooking>> _historyStream() {
    return widget.repository.watchHistoryBookings(
      includeAllUsers:
          widget.role == UserRole.aslab || widget.role == UserRole.kalab,
    );
  }

  List<LabBooking> _filterBookings(List<LabBooking> bookings) {
    final currentUserId = widget.repository.currentUserId;
    final isMahasiswa = widget.role == UserRole.mahasiswa;
    final filtered = bookings.where((booking) {
      if (isMahasiswa &&
          (currentUserId == null || booking.userId != currentUserId)) {
        return false;
      }
      if (_filter == 'Semua') return true;
      final hasRoom = _isInfrastructureBooking(booking);
      return _filter == 'Ruangan Lab' ? hasRoom : !hasRoom;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  bool _isInfrastructureItem(BookingSnapshotItem item) {
    final name = item.name.toLowerCase();
    return name.contains('ruang') ||
        name.startsWith('lab ') ||
        name.contains('laboratorium');
  }

  bool _isInfrastructureBooking(LabBooking booking) {
    final labName = booking.labDisplayName.toLowerCase();
    return labName.contains('lab') ||
        labName.contains('ruang') ||
        booking.itemsSnapshot.any(_isInfrastructureItem);
  }
}

class _HistoryFilter extends StatelessWidget {
  const _HistoryFilter({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = ['Semua', 'Alat', 'Ruangan Lab'];
    return SegmentedButton<String>(
      segments: filters
          .map(
            (filter) => ButtonSegment<String>(
              value: filter,
              icon: Icon(_icon(filter)),
              label: Text(filter),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selected) => onChanged(selected.first),
    );
  }

  IconData _icon(String filter) {
    return switch (filter) {
      'Alat' => Icons.construction_rounded,
      'Ruangan Lab' => Icons.meeting_room_outlined,
      _ => Icons.history_rounded,
    };
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.booking,
    required this.repository,
    required this.role,
    required this.isInfrastructure,
  });

  final LabBooking booking;
  final DashboardRepository repository;
  final UserRole role;
  final bool isInfrastructure;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd MMM yyyy').format(booking.tanggalPinjam);
    final time =
        '${DateFormat.Hm().format(booking.tanggalPinjam)} - ${DateFormat.Hm().format(booking.tanggalKembali)}';
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingHistoryDetailPage(
              bookingId: booking.id,
              role: role,
              repository: repository,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppTheme.campusGradientOf(context),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.reservationNo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${booking.borrowerName} | ${booking.labDisplayName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(booking.statusLabel),
                    labelStyle: TextStyle(
                      color: booking.statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                    backgroundColor: booking.statusColor.withValues(
                      alpha: 0.14,
                    ),
                    side: BorderSide(
                      color: booking.statusColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$date | $time',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                booking.itemNames.isEmpty
                    ? 'Tidak ada item tercatat.'
                    : booking.itemNames.join(', '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.history_toggle_off, size: 44),
            const SizedBox(height: 10),
            Text(
              'Belum ada riwayat pada kategori ini.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
