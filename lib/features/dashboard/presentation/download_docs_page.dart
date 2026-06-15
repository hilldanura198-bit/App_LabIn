import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/booking_pdf_service.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'download_docs_saver.dart';
import 'widgets/glass_app_bar.dart';

class DownloadDocsPage extends StatelessWidget {
  const DownloadDocsPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Unduh Berkas'),
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: repository.watchCurrentUserBookings(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final bookings = snapshot.data!;
            if (bookings.isEmpty) {
              return const Center(
                child: Text('Belum ada booking yang bisa diunduh.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _BookingPdfCard(
                  booking: booking,
                  repository: repository,
                  onDownload: () async {
                    try {
                      final bytes = await BookingPdfService.buildBookingLetter(
                        booking,
                      );
                      final savedPath = await savePdfBytesToDevice(
                        bytes,
                        'LabIn-${booking.reservationNo}.pdf',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF tersimpan di $savedPath')),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingPdfCard extends StatelessWidget {
  const _BookingPdfCard({
    required this.booking,
    required this.repository,
    required this.onDownload,
  });

  final LabBooking booking;
  final DashboardRepository repository;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final createdTime = DateFormat('HH:mm').format(booking.createdAt);
    final endTime = booking.endTime.isNotEmpty
        ? booking.endTime
        : DateFormat('HH:mm').format(booking.tanggalKembali);
    final schedule = [
      DateFormat('dd/MM/yyyy').format(booking.tanggalPinjam),
      booking.startTime.isNotEmpty ? booking.startTime : createdTime,
      endTime,
    ].join(' - ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.reservationNo,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Salin nomor reservasi',
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: booking.reservationNo),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Nomor reservasi berhasil disalin! ✅',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        booking.labDisplayName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  status: booking.statusLabel,
                  color: booking.statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Peminjam: ${booking.borrowerName}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Jadwal: $schedule',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 4),
            Text(
              'Keperluan: ${booking.purpose.isEmpty ? '-' : booking.purpose}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            if (booking.itemNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Barang: ${booking.itemNames.join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CyberGradientButton(
                onPressed: onDownload,
                child: const Text('Unduh PDF'),
              ),
            ),
            if (booking.status == 'returned') ...[
              const SizedBox(height: 14),
              _ReturnedBookingReviewCard(
                booking: booking,
                repository: repository,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReturnedBookingReviewCard extends StatefulWidget {
  const _ReturnedBookingReviewCard({
    required this.booking,
    required this.repository,
  });

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  State<_ReturnedBookingReviewCard> createState() =>
      _ReturnedBookingReviewCardState();
}

class _ReturnedBookingReviewCardState
    extends State<_ReturnedBookingReviewCard> {
  final _controller = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.booking.ratingValue ?? 5;
    _controller.text = widget.booking.reviewMessage;
    _submitted = widget.booking.ratingReview != null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cleanCyan.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cleanCyan.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Rating terkirim: $_rating/5${_controller.text.trim().isEmpty ? '' : ' - ${_controller.text.trim()}'}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.richBronze.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.richBronze.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nilai sesi peminjaman selesai',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _StarRatingSelector(
            rating: _rating,
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Ulasan peminjaman',
              hintText: 'Tulis pengalaman penggunaan alat/ruangan...',
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Kirim Rating'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final review = _controller.text.trim();
    if (review.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ulasan wajib diisi.')));
      return;
    }
    try {
      setState(() => _submitting = true);
      await widget.repository.submitBookingReview(
        bookingId: widget.booking.id,
        rating: _rating,
        review: review,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating peminjaman berhasil dikirim.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _StarRatingSelector extends StatelessWidget {
  const _StarRatingSelector({required this.rating, required this.onChanged});

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
            color: active ? Colors.amber : AppTheme.muted,
          ),
        );
      }),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      backgroundColor: color.withValues(alpha: 0.14),
      side: BorderSide(color: color.withValues(alpha: 0.7)),
    );
  }
}
