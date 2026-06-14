import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/status_timeline.dart';

class CheckReservationPage extends StatefulWidget {
  const CheckReservationPage({
    super.key,
    required this.repository,
    this.initialQuery = '',
  });

  final DashboardRepository repository;
  final String initialQuery;

  @override
  State<CheckReservationPage> createState() => _CheckReservationPageState();
}

class _CheckReservationPageState extends State<CheckReservationPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _query = widget.initialQuery.trim();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Pencarian Pintar'),
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: widget.repository.watchCurrentUserBookings(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookings = _filterBookings(snapshot.data!);
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
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
                                'Smart Search Reservasi',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Cari berdasarkan nomor peminjaman, reservation number, atau ID pengajuan.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.muted),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: _controller,
                                textCapitalization:
                                    TextCapitalization.characters,
                                onChanged: (value) =>
                                    setState(() => _query = value.trim()),
                                decoration: InputDecoration(
                                  labelText: 'Cari reservasi',
                                  hintText: 'PMJ-ABCDE atau UUID booking',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _controller.clear();
                                            setState(() => _query = '');
                                          },
                                          icon: const Icon(Icons.clear_rounded),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_query.isEmpty)
                        const _EmptyHint()
                      else if (bookings.isEmpty)
                        const _EmptyHint(
                          title: 'Data tidak ditemukan',
                          subtitle:
                              'Periksa kembali nomor peminjaman atau ID pengajuan yang Anda masukkan.',
                        )
                      else
                        ...bookings.map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _BookingResultCard(booking: booking),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<LabBooking> _filterBookings(List<LabBooking> bookings) {
    if (_query.trim().isEmpty) {
      return bookings;
    }
    final query = _query.trim().toLowerCase();
    return bookings.where((booking) {
      return booking.reservationNo.toLowerCase().contains(query) ||
          booking.id.toLowerCase().contains(query) ||
          booking.borrowerName.toLowerCase().contains(query);
    }).toList()..sort((a, b) => b.tanggalPinjam.compareTo(a.tanggalPinjam));
  }
}

class _BookingResultCard extends StatelessWidget {
  const _BookingResultCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(booking.tanggalPinjam);
    final time =
        '${DateFormat.Hm().format(booking.tanggalPinjam)} - ${DateFormat.Hm().format(booking.tanggalKembali)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.white,
                  ),
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
                        booking.labDisplayName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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
                  backgroundColor: booking.statusColor.withValues(alpha: 0.14),
                  side: BorderSide(
                    color: booking.statusColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetaPill(label: 'Peminjam', value: booking.borrowerName),
                _MetaPill(label: 'Tanggal', value: date),
                _MetaPill(label: 'Jam', value: time),
                _MetaPill(label: 'Fakultas', value: booking.facultyLabel),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Keperluan: ${booking.purpose.isEmpty ? '-' : booking.purpose}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (booking.itemNames.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Barang: ${booking.itemNames.join(', ')}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 16),
            StatusTimeline(booking: booking),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.electricBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    this.title = 'Mulai pencarian',
    this.subtitle =
        'Masukkan nomor peminjaman untuk melacak status reservasi secara instan.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.manage_search_outlined,
              color: AppTheme.electricBlue,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
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
