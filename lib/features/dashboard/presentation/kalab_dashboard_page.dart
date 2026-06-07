import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'settings_page.dart';
import 'widgets/scan_page.dart';
import 'widgets/signature_pad_dialog.dart';

class KalabDashboardPage extends StatelessWidget {
  const KalabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(
            DashboardRepository(context.read<AuthRepository>().client),
          )..add(
            const DashboardStarted(inventoryStream: true, bookingStream: true),
          ),
      child: const _KalabDashboardView(),
    );
  }
}

class _KalabDashboardView extends StatelessWidget {
  const _KalabDashboardView();

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
        appBar: AppBar(
          title: const Text('LabIN Kalab'),
          actions: [
            IconButton(
              tooltip: 'Audit barcode',
              onPressed: () => _scanBarcode(context),
              icon: const Icon(Icons.barcode_reader),
            ),
            IconButton(
              tooltip: 'Pengaturan',
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final approvals = state.bookings
                .where((booking) => booking.status == 'approved_aslab')
                .toList();
            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 940
                      ? 820.0
                      : constraints.maxWidth;
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _KalabHero(
                              approvalCount: approvals.length,
                              criticalCount: state.criticalInventories.length,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'High-Level Approval',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            if (approvals.isEmpty)
                              const _InfoCard('Belum ada approval Aslab.')
                            else
                              ...approvals.map(
                                (booking) =>
                                    _KalabApprovalCard(booking: booking),
                              ),
                            const SizedBox(height: 16),
                            _InventoryAlert(
                              inventories: state.criticalInventories,
                              onScan: () => _scanBarcode(context),
                            ),
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

  Future<void> _scanBarcode(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScanPage(title: 'Audit Barcode Aset'),
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<DashboardBloc>().add(DashboardAuditScanRequested(result));
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

class _KalabHero extends StatelessWidget {
  const _KalabHero({required this.approvalCount, required this.criticalCount});

  final int approvalCount;
  final int criticalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.deepTeal,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.admin_panel_settings_outlined,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$approvalCount dokumen menunggu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$criticalCount aset kritis butuh perhatian',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KalabApprovalCard extends StatelessWidget {
  const _KalabApprovalCard({required this.booking});

  final LabBooking booking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking ${booking.id.substring(0, 8)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Tanggal pinjam: ${booking.tanggalPinjam}'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => _approve(context),
                icon: const Icon(Icons.draw_outlined),
                label: const Text('Setujui & Tanda Tangan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const SignaturePadDialog(),
    );
    if (bytes == null || !context.mounted) {
      return;
    }
    context.read<DashboardBloc>().add(
      DashboardKalabApprovalRequested(
        bookingId: booking.id,
        signatureBytes: bytes,
      ),
    );
  }
}

class _InventoryAlert extends StatelessWidget {
  const _InventoryAlert({required this.inventories, required this.onScan});

  final List<LabInventory> inventories;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.richBronze,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Smart Inventory Alert',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (inventories.isEmpty)
              const Text('Tidak ada aset kritis saat ini.')
            else
              ...inventories.map(
                (inventory) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.richBronze.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.richBronze),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          inventory.namaAlat,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('Stok ${inventory.stokTersedia}'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Audit Mode: Scan Barcode'),
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
