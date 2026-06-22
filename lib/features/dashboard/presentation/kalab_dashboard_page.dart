import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/brand.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'kalab_detail_pengajuan_page.dart';
import 'settings_page.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/room_stock_stream_banner.dart';
import 'widgets/scan_page.dart';

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

class _KalabDashboardView extends StatefulWidget {
  const _KalabDashboardView();

  @override
  State<_KalabDashboardView> createState() => _KalabDashboardViewState();
}

class _KalabDashboardViewState extends State<_KalabDashboardView> {
  late Future<List<Map<String, dynamic>>> _approvalFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _approvalFuture = _fetchKalabQueue();
  }

  Future<List<Map<String, dynamic>>> _fetchKalabQueue() async {
    final client = context.read<AuthRepository>().client;
    if (client == null) {
      throw Exception('Sistem backend belum dikonfigurasi.');
    }
    final rows = await client
        .from('bookings')
        .select('*, profiles(nama, nim_nip), laboratories(name)')
        .eq('status', 'approved_aslab')
        .order('tanggal_pinjam');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void _refreshQueue() {
    setState(() {
      _approvalFuture = _fetchKalabQueue();
    });
  }

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
          title: '${AppBrand.name} Kalab',
          showProfileAvatar: true,
          onProfilePressed: () => _openSettings(context),
          actions: [
            HeaderActionButton(
              tooltip: 'Audit barcode',
              onPressed: () => _scanBarcode(context),
              icon: const Icon(Icons.barcode_reader),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final repository = DashboardRepository(
              context.read<AuthRepository>().client,
            );
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
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _approvalFuture,
                              builder: (context, snapshot) {
                                final approvals =
                                    snapshot.data ??
                                    const <Map<String, dynamic>>[];
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _KalabHero(
                                      approvalCount: approvals.length,
                                      criticalCount:
                                          state.criticalInventories.length,
                                    ),
                                    const SizedBox(height: 16),
                                    RoomStockStreamBanner(
                                      repository: repository,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Persetujuan Final Kalab',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(28),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (snapshot.hasError)
                                      _InfoCard(snapshot.error.toString())
                                    else if (approvals.isEmpty)
                                      const _InfoCard(
                                        'Belum ada approval Aslab.',
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: approvals.length,
                                        itemBuilder: (context, index) {
                                          final booking = approvals[index];
                                          return _KalabApprovalCard(
                                            booking: booking,
                                            onTap: () => _openKalabDetail(
                                              context,
                                              booking,
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
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

  Future<void> _openKalabDetail(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => KalabDetailPengajuanPage(
          booking: booking,
          repository: DashboardRepository(
            context.read<AuthRepository>().client,
          ),
        ),
      ),
    );
    if (result != null && context.mounted) {
      _refreshQueue();
      context.read<DashboardBloc>().add(
        const DashboardStarted(inventoryStream: true, bookingStream: true),
      );
    }
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
            Icons.verified_user_outlined,
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
  const _KalabApprovalCard({required this.booking, required this.onTap});

  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = _asMap(booking['profiles']);
    final laboratory = _asMap(booking['laboratories']);
    final rawDate = booking['tanggal_pinjam']?.toString();
    final date = rawDate == null
        ? '-'
        : DateFormat('dd MMM yyyy').format(DateTime.parse(rawDate).toLocal());
    final start = booking['start_time']?.toString().trim().isNotEmpty == true
        ? booking['start_time'].toString()
        : '-';
    final end = booking['end_time']?.toString().trim().isNotEmpty == true
        ? booking['end_time'].toString()
        : '-';
    final borrowerName = _firstNotEmpty([
      profile['nama'],
      booking['borrower_name'],
      'Unknown',
    ]);
    final labName = _firstNotEmpty([
      laboratory['name'],
      laboratory['nama_lab'],
      booking['lab_name_snapshot'],
      booking['lab_id'],
      '-',
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          borrowerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const _KalabStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CompactInfo(
                    icon: Icons.meeting_room_outlined,
                    label: 'Ruangan',
                    value: labName,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactInfo(
                          icon: Icons.event_note_outlined,
                          label: 'Tanggal',
                          value: date,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactInfo(
                          icon: Icons.schedule_rounded,
                          label: 'Waktu',
                          value: '$start - $end',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _firstNotEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '-';
  }
}

class _KalabStatusBadge extends StatelessWidget {
  const _KalabStatusBadge();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: const Text('Menunggu Kalab'),
      avatar: const Icon(Icons.verified_user_outlined, size: 16),
      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
      backgroundColor: AppTheme.electricBlue.withValues(alpha: 0.12),
      side: BorderSide(color: AppTheme.electricBlue.withValues(alpha: 0.24)),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.electricBlue, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
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
