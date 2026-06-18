import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'settings_page.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/room_stock_stream_banner.dart';
import 'widgets/scan_page.dart';

class AslabDashboardPage extends StatelessWidget {
  const AslabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(
            DashboardRepository(context.read<AuthRepository>().client),
          )..add(
            const DashboardStarted(inventoryStream: false, bookingStream: true),
          ),
      child: const _AslabDashboardView(),
    );
  }
}

class _AslabDashboardView extends StatelessWidget {
  const _AslabDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: '${AppBrand.name} Aslab',
          showProfileAvatar: true,
          onProfilePressed: () => _openSettings(context),
          actions: [
            HeaderActionButton(
              tooltip: 'Scan QR',
              onPressed: () => _scanQr(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final pending = state.bookings
                .where((booking) => booking.status == 'pending')
                .toList();
            final active = state.bookings
                .where(
                  (booking) =>
                      booking.status == 'approved_kalab' ||
                      booking.status == 'active',
                )
                .toList();
            final repository = DashboardRepository(
              context.read<AuthRepository>().client,
            );

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 900
                      ? 760.0
                      : constraints.maxWidth;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AslabHero(
                              pendingCount: pending.length,
                              activeCount: active.length,
                            ),
                            const SizedBox(height: 16),
                            RoomStockStreamBanner(repository: repository),
                            const SizedBox(height: 16),
                            Text(
                              'Swipe Right Approval',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            if (pending.isEmpty)
                              const _InfoCard('Tidak ada antrean pending.')
                            else
                              ...pending.map(
                                (booking) =>
                                    _SwipeApprovalCard(booking: booking),
                              ),
                            const SizedBox(height: 16),
                            _ScannerPrompt(onScan: () => _scanQr(context)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _scanQr(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanPage(title: 'Scan QR Pass')),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final repository = DashboardRepository(
      context.read<AuthRepository>().client,
    );
    try {
      final booking = await repository.fetchBookingForQr(result);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _QrHandoverSheet(
          booking: booking,
          onConfirm: () async {
            await repository.confirmItemHandover(booking.id);
            if (!context.mounted) return;
            context.read<DashboardBloc>().add(
              const DashboardStarted(
                inventoryStream: false,
                bookingStream: true,
              ),
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Serah terima barang berhasil dikonfirmasi.'),
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _openSettings(BuildContext context) {
    final repository = DashboardRepository(
      context.read<AuthRepository>().client,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider.value(
          value: context.read<AuthRepository>(),
          child: BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: SettingsPage(repository: repository),
          ),
        ),
      ),
    );
  }
}

class _QrHandoverSheet extends StatefulWidget {
  const _QrHandoverSheet({required this.booking, required this.onConfirm});

  final LabBooking booking;
  final Future<void> Function() onConfirm;

  @override
  State<_QrHandoverSheet> createState() => _QrHandoverSheetState();
}

class _QrHandoverSheetState extends State<_QrHandoverSheet> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bukti Pengambilan Barang',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _SheetInfoRow(
                label: 'Nama Peminjam',
                value: booking.borrowerName,
              ),
              _SheetInfoRow(
                label: 'NIM',
                value: booking.borrowerIdentity?.trim().isNotEmpty == true
                    ? booking.borrowerIdentity!
                    : '-',
              ),
              _SheetInfoRow(
                label: 'Nomor Reservasi',
                value: booking.reservationNo,
              ),
              const SizedBox(height: 12),
              Text(
                'Daftar Item',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (booking.itemsSnapshot.isEmpty)
                const Text('Tidak ada item tercatat.')
              else
                ...booking.itemsSnapshot.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(item.name),
                    trailing: Text(
                      'x${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _confirm,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.handshake_outlined),
                label: const Text('Konfirmasi Serah Terima Barang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    try {
      setState(() => _submitting = true);
      await widget.onConfirm();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AslabHero extends StatelessWidget {
  const _AslabHero({required this.pendingCount, required this.activeCount});

  final int pendingCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, size: 42),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingCount pending approval',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('$activeCount tiket siap scan/check-out'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeApprovalCard extends StatelessWidget {
  const _SwipeApprovalCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(booking.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppTheme.richBronze,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.verified_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        context.read<DashboardBloc>().add(
          DashboardAslabApprovalRequested(booking.id),
        );
        return false;
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('Booking ${booking.id.substring(0, 8)}'),
            subtitle: Text(
              '${booking.tanggalPinjam.hour}:00 - ${booking.tanggalKembali.hour}:00',
            ),
            trailing: const Icon(Icons.swipe_right_rounded),
          ),
        ),
      ),
    );
  }
}

class _ScannerPrompt extends StatelessWidget {
  const _ScannerPrompt({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QR Code Scanner Mode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR mahasiswa untuk mengubah status Approved Kalab menjadi Active, atau Active menjadi Returned.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Buka Scanner'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: Text(text)),
    );
  }
}
