import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    this.showAppBar = true,
  });

  final DashboardRepository repository;
  final String initialQuery;
  final bool showAppBar;

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
      appBar: widget.showAppBar
          ? const GlassAppBar(title: 'Pencarian Pintar')
          : null,
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
                            child: _BookingResultCard(
                              booking: booking,
                              repository: widget.repository,
                            ),
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
  const _BookingResultCard({required this.booking, required this.repository});

  final LabBooking booking;
  final DashboardRepository repository;

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
                    gradient: AppTheme.campusGradientOf(context),
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
            if (_canRenderQr(booking.status)) ...[
              const SizedBox(height: 16),
              _InlineQrTicket(booking: booking),
            ],
            if (_canShowRating(booking)) ...[
              const SizedBox(height: 16),
              _BookingRatingCard(booking: booking, repository: repository),
            ],
          ],
        ),
      ),
    );
  }

  bool _canRenderQr(String status) {
    return switch (status) {
      'approved_kalab' || 'active' || 'returned' || 'late' => true,
      _ => false,
    };
  }

  bool _canShowRating(LabBooking booking) {
    return (booking.status == 'returned' || booking.status == 'selesai') &&
        booking.ratingReview == null;
  }
}

class _InlineQrTicket extends StatelessWidget {
  const _InlineQrTicket({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: AppTheme.electricBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'QR Code Peminjaman',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = constraints.maxWidth < 360 ? 178.0 : 220.0;
              return Center(
                child: QrImageView(
                  data: booking.id,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            booking.reservationNo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'QR ini berisi booking_id untuk validasi serah terima barang.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _BookingRatingCard extends StatefulWidget {
  const _BookingRatingCard({required this.booking, required this.repository});

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  State<_BookingRatingCard> createState() => _BookingRatingCardState();
}

class _BookingRatingCardState extends State<_BookingRatingCard> {
  int _rating = 0;
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_rating < 1 || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.repository.submitBookingReview(
        bookingId: widget.booking.id,
        rating: _rating,
        review: '',
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating peminjaman berhasil dikirim.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim rating: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cleanCyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.deepTeal),
            SizedBox(width: 10),
            Expanded(child: Text('Terima kasih, penilaian sudah terkirim.')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.richBronze.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.richBronze.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Beri Penilaian',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: '$value bintang',
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _rating = value),
                iconSize: 34,
                icon: Icon(
                  value <= _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppTheme.richBronze,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _rating > 0 && !_isSubmitting ? _submit : null,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Kirim Rating'),
          ),
        ],
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
