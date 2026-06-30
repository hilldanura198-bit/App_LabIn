import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import 'widgets/glass_app_bar.dart';

class BookingHistoryDetailPage extends StatelessWidget {
  const BookingHistoryDetailPage({super.key, required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    final schedule =
        '${DateFormat('dd MMM yyyy HH:mm').format(booking.tanggalPinjam)} - ${DateFormat('HH:mm').format(booking.tanggalKembali)}';
    return Scaffold(
      appBar: const GlassAppBar(title: 'Detail Riwayat'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    booking.reservationNo,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                Chip(
                                  label: Text(booking.statusLabel),
                                  labelStyle: TextStyle(
                                    color: booking.statusColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  backgroundColor: booking.statusColor
                                      .withValues(alpha: 0.14),
                                  side: BorderSide(
                                    color: booking.statusColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${booking.borrowerName} | ${booking.borrowerIdentity ?? '-'}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 14),
                            _MetaRow(
                              icon: Icons.meeting_room_outlined,
                              label: 'Ruangan Laboratorium',
                              value: booking.labDisplayName,
                            ),
                            _MetaRow(
                              icon: Icons.schedule_rounded,
                              label: 'Jadwal',
                              value: schedule,
                            ),
                            if (booking.purpose.trim().isNotEmpty)
                              _MetaRow(
                                icon: Icons.assignment_outlined,
                                label: 'Keperluan',
                                value: booking.purpose,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_canRenderQr(booking))
                      _QrEvidenceCard(booking: booking)
                    else
                      const _QrLockedCard(),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Manifes Barang',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 8),
                            if (booking.itemsSnapshot.isEmpty)
                              const Text('Tidak ada item tercatat.')
                            else
                              ...booking.itemsSnapshot.map(
                                (item) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.inventory_2_outlined,
                                  ),
                                  title: Text(item.name),
                                  trailing: Text(
                                    'x${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canRenderQr(LabBooking booking) {
    return switch (booking.status) {
      'approved_kalab' || 'active' || 'returned' || 'late' => true,
      _ => false,
    };
  }
}

class _QrEvidenceCard extends StatelessWidget {
  const _QrEvidenceCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              'QR Code Serah Terima',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            QrImageView(
              data: booking.qrToken.trim().isEmpty
                  ? booking.id
                  : '${booking.id}|${booking.qrToken}',
              version: QrVersions.auto,
              size: 190,
            ),
            const SizedBox(height: 8),
            Text(
              'Status ${booking.statusLabel}. Tunjukkan QR ini saat validasi fisik serah-terima.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrLockedCard extends StatelessWidget {
  const _QrLockedCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: AppTheme.richBronze),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'QR Code resmi tersedia setelah pengajuan memperoleh ACC Aslab dan ACC Kalab.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppTheme.deepTeal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
