import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../core/brand.dart';
import '../../../core/lab_catalog.dart';
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
  late final DashboardRepository _repository;
  late Future<List<Map<String, dynamic>>> _approvalFuture;
  late Future<List<MaintenanceReportEntry>> _maintenanceFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _repository = DashboardRepository(context.read<AuthRepository>().client);
    _loadInitialData();
  }

  void _loadInitialData() {
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
    return _repository.fetchMaintenanceReports();
  }

  void _refreshQueue() {
    setState(() {
      _loadInitialData();
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
    if (_selectedIndex == 1) {
      return KalabControlPanel(
        repository: _repository,
        maintenanceFuture: _maintenanceFuture,
      );
    }
    if (_selectedIndex == 2) {
      return HistoryPage(
        repository: _repository,
        role: UserRole.kalab,
        showAppBar: false,
      );
    }
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
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
                                RoomStockStreamBanner(repository: _repository),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider.value(
          value: context.read<AuthRepository>(),
          child: BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: SettingsPage(repository: _repository),
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
        builder: (_) =>
            KalabDetailPengajuanPage(booking: booking, repository: _repository),
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

class KalabControlPanel extends StatefulWidget {
  const KalabControlPanel({
    super.key,
    required this.repository,
    required this.maintenanceFuture,
  });

  final DashboardRepository repository;
  final Future<List<MaintenanceReportEntry>> maintenanceFuture;

  @override
  State<KalabControlPanel> createState() => _KalabControlPanelState();
}

class _KalabControlPanelState extends State<KalabControlPanel> {
  late Future<List<UserAccountSummary>> _usersFuture;
  late Future<List<BorrowedInventoryReport>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _usersFuture = widget.repository.fetchUserAccounts();
    _reportFuture = widget.repository.fetchBorrowedInventoryReport();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => setState(_refresh),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PanelShortcutGrid(repository: widget.repository),
                    const SizedBox(height: 16),
                    _AslabVerificationCard(
                      usersFuture: _usersFuture,
                      repository: widget.repository,
                      onUpdated: () => setState(_refresh),
                    ),
                    const SizedBox(height: 16),
                    _MaintenanceReportCard(
                      repository: widget.repository,
                      maintenanceFuture: widget.maintenanceFuture,
                      onUpdated: () => setState(_refresh),
                    ),
                    const SizedBox(height: 16),
                    _BorrowedReportCard(reportFuture: _reportFuture),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelShortcutGrid extends StatelessWidget {
  const _PanelShortcutGrid({required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    final actions = [
      (
        Icons.inventory_2_outlined,
        'CRUD Sarpras',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabInventoryCrudPage(repository: repository),
          ),
        ),
      ),
      (
        Icons.manage_accounts_outlined,
        'Kontrol User',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabUserManagementPage(repository: repository),
          ),
        ),
      ),
      (
        Icons.meeting_room_outlined,
        'Jadwal Ruangan',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RoomSchedulePage(repository: repository),
          ),
        ),
      ),
      (
        Icons.analytics_outlined,
        'Laporan Peminjaman',
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabDailyReportPage(repository: repository),
          ),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 2 : 1;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 3.8 : 2.6,
          children: actions.map((action) {
            return Card(
              child: InkWell(
                onTap: action.$3,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(action.$1, color: campus.primary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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
            );
          }).toList(),
        );
      },
    );
  }
}

class _InventoryCreateCard extends StatefulWidget {
  const _InventoryCreateCard({
    required this.roomsFuture,
    required this.repository,
    required this.onSaved,
  });

  final Future<List<LabRoom>> roomsFuture;
  final DashboardRepository repository;
  final VoidCallback onSaved;

  @override
  State<_InventoryCreateCard> createState() => _InventoryCreateCardState();
}

class _InventoryCreateCardState extends State<_InventoryCreateCard> {
  final _name = TextEditingController();
  final _total = TextEditingController(text: '1');
  final _available = TextEditingController(text: '1');
  final _picker = ImagePicker();
  String? _labId;
  String _type = 'alat';
  XFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _available.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<LabRoom>>(
          future: widget.roomsFuture,
          builder: (context, snapshot) {
            final rooms = snapshot.data ?? const <LabRoom>[];
            _labId ??= rooms.isEmpty ? null : rooms.first.id;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tambah Inventaris',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Nama barang/instrumen',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _labId,
                  decoration: const InputDecoration(labelText: 'Ruangan'),
                  items: rooms
                      .map(
                        (room) => DropdownMenuItem(
                          value: room.id,
                          child: Text(room.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _labId = value),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 20) / 3
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _total,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: TextField(
                            controller: _available,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tersedia',
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Jenis',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'alat',
                                child: Text('Alat'),
                              ),
                              DropdownMenuItem(
                                value: 'ruangan',
                                child: Text('Ruangan Laboratorium'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _type = value ?? 'alat'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _InventoryImagePickerButton(
                  imageName: _image?.name,
                  onPick: _pickImage,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving || _labId == null ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text('Simpan Inventaris'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1280,
    );
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      await widget.repository.createInventory(
        labId: _labId!,
        name: _name.text,
        totalStock: int.tryParse(_total.text) ?? 0,
        availableStock: int.tryParse(_available.text) ?? 0,
        type: _type,
        image: _image,
      );
      _name.clear();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _image = null;
      });
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventaris berhasil ditambahkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _InventoryImagePickerButton extends StatelessWidget {
  const _InventoryImagePickerButton({
    required this.imageName,
    required this.onPick,
  });

  final String? imageName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                imageName == null
                    ? 'Tambah Gambar Barang'
                    : 'Gambar dipilih: $imageName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _RoomCreateCard extends StatefulWidget {
  const _RoomCreateCard({required this.repository, required this.onSaved});

  final DashboardRepository repository;
  final VoidCallback onSaved;

  @override
  State<_RoomCreateCard> createState() => _RoomCreateCardState();
}

class _RoomCreateCardState extends State<_RoomCreateCard> {
  final _name = TextEditingController();
  late String _location;
  bool _saving = false;

  static final _locationOptions = <String>{
    for (final lab in AppLabCatalog.labs) lab.location,
    'Gedung Rektorat Lt. 1',
    'Gedung Rektorat Lt. 2',
    'Area Luar Ruangan',
  }.toList();

  @override
  void initState() {
    super.initState();
    _location = _locationOptions.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tambah Ruangan Laboratorium',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama ruangan'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Lokasi'),
              items: _locationOptions
                  .map(
                    (location) => DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _location = value ?? _locationOptions.first;
              }),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.meeting_room_outlined),
              label: const Text('Simpan Ruangan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    try {
      setState(() => _saving = true);
      await widget.repository.createLaboratory(
        name: _name.text,
        location: _location,
      );
      _name.clear();
      _location = _locationOptions.first;
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruangan berhasil ditambahkan.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _AslabVerificationCard extends StatelessWidget {
  const _AslabVerificationCard({
    required this.usersFuture,
    required this.repository,
    required this.onUpdated,
  });

  final Future<List<UserAccountSummary>> usersFuture;
  final DashboardRepository repository;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAccountSummary>>(
      future: usersFuture,
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <UserAccountSummary>[];
        if (!snapshot.hasData || users.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verifikasi Akun Aslab',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ...users.map(
                  (user) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      user.role == 'aslab'
                          ? Icons.verified_user_outlined
                          : Icons.person_outline,
                    ),
                    title: Text(user.name),
                    subtitle: Text('${user.identity} | ${user.email}'),
                    trailing: user.role == 'aslab'
                        ? const Chip(label: Text('Aslab'))
                        : user.role == 'kalab'
                        ? const Chip(label: Text('Kalab'))
                        : FilledButton(
                            onPressed: () async {
                              await repository.verifyAslabAccount(user.id);
                              onUpdated();
                            },
                            child: const Text('Jadikan Aslab'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BorrowedReportCard extends StatelessWidget {
  const _BorrowedReportCard({required this.reportFuture});

  final Future<List<BorrowedInventoryReport>> reportFuture;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<BorrowedInventoryReport>>(
          future: reportFuture,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <BorrowedInventoryReport>[];
            final max = rows.isEmpty ? 1 : rows.first.quantity;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Laporan Barang Dipinjam',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ekspor ringkasan',
                      onPressed: rows.isEmpty
                          ? null
                          : () {
                              final text = rows
                                  .map((row) => '${row.name},${row.quantity}')
                                  .join('\n');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('CSV siap: $text')),
                              );
                            },
                      icon: const Icon(Icons.ios_share_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (rows.isEmpty)
                  const Text('Tidak ada barang yang sedang dipinjam.')
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  row.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${row.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: row.quantity / max,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ],
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
        child: SizedBox(
          height: 400,
          child: FutureBuilder<List<MaintenanceReportEntry>>(
            future: maintenanceFuture,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <MaintenanceReportEntry>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    icon: Icons.build_circle_outlined,
                    title: 'Laporan Maintenance Mahasiswa',
                    subtitle:
                        'Klik salah satu kartu untuk mengecek detail dan mengambil tindakan.',
                  ),
                  const SizedBox(height: 12),
                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (rows.isEmpty)
                    const _EmptyStateCard(
                      title: 'Belum ada laporan maintenance.',
                      subtitle:
                          'Mahasiswa belum mengirim laporan kerusakan pada data ini.',
                    )
                  else
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == rows.length - 1 ? 0 : 12,
                            ),
                            child: _MaintenanceReportTile(
                              row: row,
                              campus: campus,
                              onTap: () => _openMaintenanceDetail(
                                context,
                                repository,
                                row,
                                onUpdated,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenanceReportTile extends StatelessWidget {
  const _MaintenanceReportTile({
    required this.row,
    required this.campus,
    required this.onTap,
  });

  final MaintenanceReportEntry row;
  final CampusThemeExtension campus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(row.statusLabel, campus);
    final imageUrl = row.photoUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                campus.primary.withValues(alpha: 0.06),
                campus.secondary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: campus.primary.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textWidth = (constraints.maxWidth - 124)
                  .clamp(0.0, 9999.0)
                  .toDouble();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MaintenancePreview(imageUrl: imageUrl),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: textWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.inventoryName ?? row.inventoryId,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.reporterName == null
                              ? 'Pelapor: -'
                              : 'Pelapor: ${row.reporterName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: row.statusLabel,
                            ),
                            _InfoChip(
                              icon: Icons.person_outline,
                              label: row.reporterIdentity ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            'Tap untuk buka detail laporan',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: campus.secondary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenancePreview extends StatelessWidget {
  const _MaintenancePreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.build_circle_outlined),
    );
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 192,
          memCacheHeight: 192,
          filterQuality: FilterQuality.low,
          placeholder: (context, url) => placeholder,
          errorWidget: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}

Future<void> _openMaintenanceDetail(
  BuildContext context,
  DashboardRepository repository,
  MaintenanceReportEntry row,
  VoidCallback onUpdated,
) async {
  final noteController = TextEditingController();
  final result = await showModalBottomSheet<_MaintenanceActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MaintenanceDetailSheet(
        row: row,
        noteController: noteController,
        onApprove: () =>
            Navigator.of(sheetContext).pop(_MaintenanceActionResult.approve),
        onReject: () =>
            Navigator.of(sheetContext).pop(_MaintenanceActionResult.reject),
      );
    },
  );
  noteController.dispose();
  if (result == null || !context.mounted) {
    return;
  }
  try {
    if (result == _MaintenanceActionResult.approve) {
      await repository.acceptMaintenanceReport(row.id);
    } else {
      await repository.rejectMaintenanceReport(row.id);
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == _MaintenanceActionResult.approve
              ? 'Laporan maintenance diproses.'
              : 'Laporan maintenance ditolak.',
        ),
      ),
    );
    onUpdated();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

enum _MaintenanceActionResult { approve, reject }

class _MaintenanceDetailSheet extends StatelessWidget {
  const _MaintenanceDetailSheet({
    required this.row,
    required this.noteController,
    required this.onApprove,
    required this.onReject,
  });

  final MaintenanceReportEntry row;
  final TextEditingController noteController;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final campus = AppTheme.campusColorsOf(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(title: 'Detail Maintenance'),
              const SizedBox(height: 16),
              _MaintenancePreview(imageUrl: row.photoUrl),
              const SizedBox(height: 16),
              Text(
                row.inventoryName ?? row.inventoryId,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                row.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _DetailLine(
                icon: Icons.person_outline,
                label: 'Pelapor',
                value: row.reporterName ?? '-',
              ),
              _DetailLine(
                icon: Icons.badge_outlined,
                label: 'NIM',
                value: row.reporterIdentity ?? '-',
              ),
              _DetailLine(
                icon: Icons.schedule_rounded,
                label: 'Status',
                value: row.statusLabel,
              ),
              _DetailLine(
                icon: Icons.event_outlined,
                label: 'Dibuat',
                value: DateFormat('dd MMM yyyy HH:mm').format(row.createdAt),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Kalab',
                  hintText: 'Opsional, jelaskan tindak lanjut maintenance...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.campusGradientOf(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: onApprove,
                        icon: const Icon(Icons.done_rounded),
                        label: const Text('Diproses'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Status dan keterangan akan diteruskan ke mahasiswa melalui notifikasi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: campus.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppTheme.campusGradientOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: campus.primary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
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
