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
  late Future<List<Map<String, dynamic>>> _approvalFuture;
  int _selectedIndex = 0;

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
        .select(
          '*, laboratories(nama_lab), peminjam:profiles!fk_bookings_profiles(*), kalab:profiles!bookings_approved_by_kalab_id_fkey(*)',
        )
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
      return KalabControlPanel(repository: repository);
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

class KalabControlPanel extends StatefulWidget {
  const KalabControlPanel({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<KalabControlPanel> createState() => _KalabControlPanelState();
}

class _KalabControlPanelState extends State<KalabControlPanel> {
  late Future<List<LabRoom>> _roomsFuture;
  late Future<List<UserAccountSummary>> _usersFuture;
  late Future<List<BorrowedInventoryReport>> _reportFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _roomsFuture = widget.repository.fetchLaboratories();
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
                    _InventoryCreateCard(
                      roomsFuture: _roomsFuture,
                      repository: widget.repository,
                      onSaved: () => setState(_refresh),
                    ),
                    const SizedBox(height: 16),
                    _RoomCreateCard(
                      repository: widget.repository,
                      onSaved: () => setState(_refresh),
                    ),
                    const SizedBox(height: 16),
                    _AslabVerificationCard(
                      usersFuture: _usersFuture,
                      repository: widget.repository,
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
        'Reservasi Ruangan',
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
                      Icon(action.$1, color: AppTheme.deepTeal, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          action.$2,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<UserAccountSummary>>(
          future: usersFuture,
          builder: (context, snapshot) {
            final users = snapshot.data ?? const <UserAccountSummary>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Verifikasi Akun Aslab',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else if (users.isEmpty)
                  const Text('Belum ada akun pengguna.')
                else
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
            );
          },
        ),
      ),
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
              const Text('Tidak ada stok rendah saat ini.')
            else
              ...inventories.map(
                (inventory) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE11D48)),
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
                        backgroundColor: const Color(0xFFE11D48),
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
