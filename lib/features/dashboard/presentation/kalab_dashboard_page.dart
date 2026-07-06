import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../core/brand.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'history_page.dart';
import 'kalab_daily_report_page.dart';
import 'kalab_detail_pengajuan_page.dart';
import 'kalab_inventory_crud_page.dart';
import 'kalab_user_management_page.dart';
import 'room_schedule_page.dart';
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
  late Future<List<MaintenanceReportEntry>> _maintenanceFuture;
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _approvalFuture = _fetchKalabQueue();
    _maintenanceFuture = _fetchMaintenanceReports();
  }

  Future<List<Map<String, dynamic>>> _fetchKalabQueue() async {
    final client = context.read<AuthRepository>().client;
    if (client == null) {
      throw Exception('Sistem backend belum dikonfigurasi.');
    }
    final rows = await client
        .from('bookings')
        .select(
          '*, laboratories(nama_lab), peminjam:profiles!fk_bookings_profiles(*), kalab:profiles!bookings_approved_by_kalab_id_fkey(*)',
        )
        .eq('status', 'approved_aslab')
        .order('tanggal_pinjam');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<List<MaintenanceReportEntry>> _fetchMaintenanceReports() async {
    final repository = DashboardRepository(
      context.read<AuthRepository>().client,
    );
    return repository.fetchMaintenanceReports();
  }

  void _refreshQueue() {
    setState(() {
      _approvalFuture = _fetchKalabQueue();
      _maintenanceFuture = _fetchMaintenanceReports();
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
        body: _buildBody(),
        bottomNavigationBar: _KalabBottomNav(
          selectedIndex: _selectedIndex,
          onTabChange: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final repository = DashboardRepository(
      context.read<AuthRepository>().client,
    );
    if (_selectedIndex == 1) {
      return KalabControlPanel(
        repository: repository,
        maintenanceFuture: _maintenanceFuture,
        onMaintenanceUpdated: _refreshQueue,
      );
    }
    if (_selectedIndex == 2) {
      return HistoryPage(
        repository: repository,
        role: UserRole.kalab,
        showAppBar: false,
      );
    }
    return BlocBuilder<DashboardBloc, DashboardState>(
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
                                snapshot.data ?? const <Map<String, dynamic>>[];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _KalabHero(
                                  approvalCount: approvals.length,
                                  criticalCount:
                                      state.lowStockInventories.length,
                                ),
                                const SizedBox(height: 16),
                                RoomStockStreamBanner(repository: repository),
                                const SizedBox(height: 16),
                                Text(
                                  'Persetujuan Final Kalab',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
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
                                  const _InfoCard('Belum ada approval Aslab.')
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
                                        onTap: () =>
                                            _openKalabDetail(context, booking),
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _InventoryAlert(
                          inventories: state.lowStockInventories,
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

class _KalabBottomNav extends StatelessWidget {
  const _KalabBottomNav({
    required this.selectedIndex,
    required this.onTabChange,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GNav(
              selectedIndex: selectedIndex,
              onTabChange: onTabChange,
              gap: 8,
              tabBorderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              activeColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              tabBackgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.18),
              tabs: const [
                GButton(icon: Icons.dashboard_outlined, text: 'Beranda'),
                GButton(icon: Icons.admin_panel_settings, text: 'Panel'),
                GButton(icon: Icons.history_rounded, text: 'Riwayat'),
              ],
            ),
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
    final campus = AppTheme.campusColorsOf(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: campus.gradient,
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

class KalabControlPanel extends StatelessWidget {
  const KalabControlPanel({
    super.key,
    required this.repository,
    required this.maintenanceFuture,
    required this.onMaintenanceUpdated,
  });

  final DashboardRepository repository;
  final Future<List<MaintenanceReportEntry>> maintenanceFuture;
  final VoidCallback onMaintenanceUpdated;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: _PanelShortcutGrid(
                repository: repository,
                maintenanceFuture: maintenanceFuture,
                onMaintenanceUpdated: onMaintenanceUpdated,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelShortcutGrid extends StatelessWidget {
  const _PanelShortcutGrid({
    required this.repository,
    required this.maintenanceFuture,
    required this.onMaintenanceUpdated,
  });

  final DashboardRepository repository;
  final Future<List<MaintenanceReportEntry>> maintenanceFuture;
  final VoidCallback onMaintenanceUpdated;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    final actions = [
      (
        Icons.inventory_2_outlined,
        'CRUD Sarpras',
        'Kelola inventaris alat dan ruangan',
        () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KalabInventoryCrudPage(repository: repository),
            ),
          );
        },
      ),
      (
        Icons.manage_accounts_outlined,
        'Kontrol User',
        'Verifikasi dan pantau akun pengguna',
        () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KalabUserManagementPage(repository: repository),
            ),
          );
        },
      ),
      (
        Icons.meeting_room_outlined,
        'Jadwal Ruangan',
        'Cek penggunaan dan ketersediaan ruang',
        () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoomSchedulePage(repository: repository),
            ),
          );
        },
      ),
      (
        Icons.analytics_outlined,
        'Laporan Peminjaman',
        'Ringkasan transaksi dan aktivitas lab',
        () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KalabDailyReportPage(repository: repository),
            ),
          );
        },
      ),
      (
        Icons.build_circle_outlined,
        'Laporan Maintenance',
        'Cek laporan kerusakan dan tindak lanjut',
        () {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _MaintenanceReportPage(
                repository: repository,
                maintenanceFuture: maintenanceFuture,
                onUpdated: onMaintenanceUpdated,
              ),
            ),
          );
        },
      ),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: campus.gradient,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Kalab',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: campus.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Akses cepat ke fitur inti pengelolaan laboratorium.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map((action) {
              final radius = BorderRadius.circular(14);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: Ink(
                    decoration: BoxDecoration(
                      color: campus.primary.withValues(alpha: 0.06),
                      borderRadius: radius,
                    ),
                    child: InkWell(
                      onTap: action.$4,
                      borderRadius: radius,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: campus.gradient,
                              ),
                              child: Icon(
                                action.$1,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: campus.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    action.$3,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: campus.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceReportPage extends StatelessWidget {
  const _MaintenanceReportPage({
    required this.repository,
    required this.maintenanceFuture,
    required this.onUpdated,
  });

  final DashboardRepository repository;
  final Future<List<MaintenanceReportEntry>> maintenanceFuture;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Maintenance')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _MaintenanceReportCard(
            repository: repository,
            maintenanceFuture: maintenanceFuture,
            onUpdated: onUpdated,
          ),
        ),
      ),
    );
  }
}

class _MaintenanceReportCard extends StatelessWidget {
  const _MaintenanceReportCard({
    required this.repository,
    required this.maintenanceFuture,
    required this.onUpdated,
  });

  final DashboardRepository repository;
  final Future<List<MaintenanceReportEntry>> maintenanceFuture;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<List<MaintenanceReportEntry>>(
          future: maintenanceFuture,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <MaintenanceReportEntry>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Laporan Maintenance Mahasiswa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (rows.isEmpty)
                  const Text('Belum ada laporan kerusakan dari mahasiswa.')
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: campus.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showDetail(context, row),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child:
                                      row.photoUrl == null ||
                                          row.photoUrl!.trim().isEmpty
                                      ? Container(
                                          width: 52,
                                          height: 52,
                                          color: campus.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: campus.primary,
                                          ),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: row.photoUrl!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          placeholder: (context, _) =>
                                              Container(
                                                width: 52,
                                                height: 52,
                                                color: AppTheme.vibrantPurple
                                                    .withValues(alpha: 0.12),
                                              ),
                                          errorWidget: (context, _, _) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                              ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        row.inventoryName ?? row.inventoryId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        row.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _maintenanceStatusColor(
                                      row.statusLabel,
                                      campus,
                                    ).withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _maintenanceStatusColor(
                                        row.statusLabel,
                                        campus,
                                      ).withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    row.statusLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _maintenanceStatusColor(
                                            row.statusLabel,
                                            campus,
                                          ),
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: campus.secondary,
                                ),
                              ],
                            ),
                          ),
                        ),
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

  void _showDetail(BuildContext context, MaintenanceReportEntry row) {
    final campus = AppTheme.campusColorsOf(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (row.photoUrl != null && row.photoUrl!.trim().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: row.photoUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => Container(
                        height: 180,
                        color: AppTheme.vibrantPurple.withValues(alpha: 0.12),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, _, _) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  row.inventoryName ?? row.inventoryId,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _maintenanceStatusColor(
                      row.statusLabel,
                      campus,
                    ).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _maintenanceStatusColor(
                        row.statusLabel,
                        campus,
                      ).withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    row.statusLabel,
                    style: Theme.of(sheetContext).textTheme.labelMedium
                        ?.copyWith(
                          color: _maintenanceStatusColor(
                            row.statusLabel,
                            campus,
                          ),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deskripsi Kerusakan',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(row.description),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          try {
                            await repository.rejectMaintenanceReport(row.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Laporan maintenance ditolak.'),
                                ),
                              );
                            }
                            onUpdated();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          try {
                            await repository.acceptMaintenanceReport(row.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Laporan maintenance diproses.',
                                  ),
                                ),
                              );
                            }
                            onUpdated();
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.build_circle_outlined),
                        label: const Text('Proses'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Color _maintenanceStatusColor(String status, CampusThemeExtension campus) {
  return switch (status.toLowerCase()) {
    'pending' => const Color(0xFFF59E0B),
    'diproses' => const Color(0xFF3B82F6),
    'selesai' => const Color(0xFF10B981),
    'ditolak' => const Color(0xFFEF4444),
    _ => campus.primary,
  };
}

class _KalabApprovalCard extends StatelessWidget {
  const _KalabApprovalCard({required this.booking, required this.onTap});

  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profile = _asMap(booking['peminjam'] ?? booking['profiles']);
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
    final campus = AppTheme.campusColorsOf(context);
    return Chip(
      label: const Text('Menunggu Kalab'),
      avatar: const Icon(Icons.verified_user_outlined, size: 16),
      labelStyle: const TextStyle(fontWeight: FontWeight.w900),
      backgroundColor: campus.primary.withValues(alpha: 0.12),
      side: BorderSide(color: campus.primary.withValues(alpha: 0.24)),
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
    final campus = AppTheme.campusColorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: campus.primary, size: 18),
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
    final campus = AppTheme.campusColorsOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: campus.secondary),
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
              const Text('Tidak ada stok rendah saat ini.')
            else
              ...inventories.map(
                (inventory) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: campus.secondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: campus.secondary.withValues(alpha: 0.26),
                    ),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          inventory.namaAlat,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('Stok Rendah: ${inventory.stokTersedia}'),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                        backgroundColor: campus.secondary,
                        side: BorderSide.none,
                      ),
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
