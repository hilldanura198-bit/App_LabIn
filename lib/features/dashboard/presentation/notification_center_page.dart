import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Notification Center')),
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: repository.watchCurrentUserBookings(),
          builder: (context, bookingSnapshot) {
            return StreamBuilder<List<LabInventory>>(
              stream: repository.watchInventories(),
              builder: (context, inventorySnapshot) {
                final logs = _buildLogs(
                  bookings: bookingSnapshot.data ?? const [],
                  inventories: inventorySnapshot.data ?? const [],
                );
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('Belum ada notifikasi realtime.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: log.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(log.icon, color: log.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.message,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  List<_NotificationLog> _buildLogs({
    required List<LabBooking> bookings,
    required List<LabInventory> inventories,
  }) {
    final logs = <_NotificationLog>[];
    for (final booking in bookings.take(8)) {
      logs.add(
        _NotificationLog(
          icon: booking.status == 'approved_kalab'
              ? Icons.verified_user_outlined
              : Icons.receipt_long_outlined,
          color: booking.status == 'approved_kalab'
              ? AppTheme.emerald
              : AppTheme.deepTeal,
          title: 'Reservasi ${booking.reservationNo}',
          message: _bookingMessage(booking),
        ),
      );
    }
    for (final item in inventories.where((inventory) => inventory.isCritical)) {
      logs.add(
        _NotificationLog(
          icon: Icons.warning_amber_rounded,
          color: Colors.red,
          title: 'Peringatan Stok Kritis',
          message:
              'Stok ${item.namaAlat} tersisa ${item.stokTersedia}. Segera koordinasikan dengan laboran.',
        ),
      );
    }
    return logs;
  }

  String _bookingMessage(LabBooking booking) {
    return switch (booking.status) {
      'approved_aslab' => 'Pengajuan disetujui Aslab dan menunggu Kalab.',
      'approved_kalab' =>
        'Pengajuan ${booking.reservationNo} disetujui oleh Kalab.',
      'active' => 'Alat sudah diambil. Jangan lupa checkout pengembalian.',
      'returned' => 'Transaksi peminjaman selesai dan tercatat.',
      'rejected' => 'Pengajuan ditolak. Silakan cek detail dan ajukan ulang.',
      _ => 'Pengajuan sedang diproses dengan status ${booking.status}.',
    };
  }
}

class _NotificationLog {
  const _NotificationLog({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
}
