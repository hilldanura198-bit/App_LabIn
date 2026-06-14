import 'package:flutter/material.dart';
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
  const _BookingPdfCard({required this.booking, required this.onDownload});

  final LabBooking booking;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final schedule = [
      DateFormat('dd/MM/yyyy').format(booking.tanggalPinjam),
      DateFormat.Hm().format(booking.tanggalPinjam),
      DateFormat.Hm().format(booking.tanggalKembali),
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
                      Text(
                        booking.reservationNo,
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
          ],
        ),
      ),
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
