import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'booking_form_page.dart';
import 'check_reservation_page.dart';
import 'download_docs_page.dart';
import 'notification_center_page.dart';
import 'room_schedule_page.dart';
import 'sapras_facility_page.dart';
import 'settings_page.dart';
import 'widgets/busy_meter.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/status_timeline.dart';

class MahasiswaDashboardPage extends StatelessWidget {
  const MahasiswaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(
            DashboardRepository(context.read<AuthRepository>().client),
          )..add(
            const DashboardStarted(inventoryStream: true, bookingStream: false),
          ),
      child: const _MahasiswaDashboardView(),
    );
  }
}

class _MahasiswaDashboardView extends StatefulWidget {
  const _MahasiswaDashboardView();

  @override
  State<_MahasiswaDashboardView> createState() =>
      _MahasiswaDashboardViewState();
}

class _MahasiswaDashboardViewState extends State<_MahasiswaDashboardView> {
  int _selectedIndex = 0;

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
          title: [
            'Beranda',
            'Cek Reservasi',
            'Notifikasi',
            'Pengaturan',
          ][_selectedIndex],
          showProfileAvatar: true,
          onProfilePressed: () => _openSettings(context),
          actions: [
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Badge(
                    label: Text('${state.cartCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationCenterPage(repository: _repository(context)),
                ),
              ),
              icon: const Icon(Icons.notifications_outlined),
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
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: _buildTab(context, state),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: GNav(
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) =>
                      setState(() => _selectedIndex = index),
                  gap: 8,
                  tabBorderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  activeColor: AppTheme.espresso,
                  color: AppTheme.sepia,
                  tabBackgroundColor: AppTheme.richBronze.withValues(
                    alpha: 0.22,
                  ),
                  tabs: const [
                    GButton(icon: Icons.home_outlined, text: 'Beranda'),
                    GButton(icon: Icons.search_rounded, text: 'Reservasi'),
                    GButton(
                      icon: Icons.notifications_outlined,
                      text: 'Notifikasi',
                    ),
                    GButton(icon: Icons.settings_outlined, text: 'Pengaturan'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, DashboardState state) {
    final repository = _repository(context);
    return switch (_selectedIndex) {
      1 => CheckReservationPage(repository: repository),
      2 => NotificationCenterPage(repository: repository),
      3 => RepositoryProvider.value(
        value: context.read<AuthRepository>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: SettingsPage(repository: repository),
        ),
      ),
      _ => _HomeScrollContent(state: state, repository: repository),
    };
  }

  DashboardRepository _repository(BuildContext context) {
    return DashboardRepository(context.read<AuthRepository>().client);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider.value(
          value: context.read<AuthRepository>(),
          child: BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: SettingsPage(repository: _repository(context)),
          ),
        ),
      ),
    );
  }
}

class _HomeScrollContent extends StatelessWidget {
  const _HomeScrollContent({required this.state, required this.repository});

  final DashboardState state;
  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 1000
              ? 940.0
              : constraints.maxWidth;
          final gridColumns = constraints.maxWidth >= 720 ? 3 : 2;
          return Center(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(
                  const DashboardStarted(
                    inventoryStream: true,
                    bookingStream: false,
                  ),
                );
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Campus Sarpras Portal',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      _StockCalendar(state: state),
                      const SizedBox(height: 16),
                      _SimlabMenu(repository: repository),
                      const SizedBox(height: 16),
                      const _CampusInsights(),
                      const SizedBox(height: 16),
                      _InventoryGrid(
                        inventories: state.inventories,
                        columns: gridColumns,
                      ),
                      const SizedBox(height: 16),
                      _CartCheckout(state: state),
                      const SizedBox(height: 16),
                      if (state.latestBooking != null) ...[
                        _DynamicQrPass(booking: state.latestBooking!),
                        const SizedBox(height: 16),
                        StatusTimeline(status: state.latestBooking!.status),
                        const SizedBox(height: 16),
                      ],
                      BusyMeter(hours: state.busyHours),
                      const SizedBox(height: 16),
                      const _LiveUtilizationFeed(),
                      const SizedBox(height: 16),
                      _MaintenanceReport(inventories: state.inventories),
                      const SizedBox(height: 16),
                      const _FaqAccordion(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SimlabMenu extends StatelessWidget {
  const _SimlabMenu({required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.manage_search_outlined,
        title: 'Cek Status Reservasi',
        color: AppTheme.richBronze.withValues(alpha: 0.12),
        page: CheckReservationPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.playlist_add_check_rounded,
        title: 'Form Peminjaman',
        color: AppTheme.richBronze.withValues(alpha: 0.16),
        page: BookingFormPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.file_download_outlined,
        title: 'Unduh Berkas',
        color: AppTheme.richBronze.withValues(alpha: 0.20),
        page: DownloadDocsPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.view_timeline_outlined,
        title: 'Jadwal Ruangan',
        color: AppTheme.richBronze.withValues(alpha: 0.14),
        page: RoomSchedulePage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.notifications_active_outlined,
        title: 'Notifikasi',
        color: AppTheme.richBronze.withValues(alpha: 0.18),
        page: NotificationCenterPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.location_city_outlined,
        title: 'SAPRAS Kampus',
        color: AppTheme.richBronze.withValues(alpha: 0.22),
        page: SaprasFacilityPage(repository: repository),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modul SIMLAB & SAPRAS',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.48,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => item.page)),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(item.icon, color: AppTheme.deepTeal),
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CampusInsights extends StatelessWidget {
  const _CampusInsights();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fasilitas Kampus Insights',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _InsightTile(
              icon: Icons.auto_awesome_outlined,
              title: 'Standarisasi Ruang Praktikum',
              subtitle:
                  'Setiap ruang lab dikelompokkan berdasarkan fungsi, kapasitas, dan kesiapan alat agar proses belajar lebih presisi.',
            ),
            const SizedBox(height: 10),
            _InsightTile(
              icon: Icons.workspace_premium_outlined,
              title: 'Modernisasi Sarana Prasarana',
              subtitle:
                  'Inventaris digital membantu kampus memantau kebutuhan perawatan, audit aset, dan pemanfaatan ruang secara berkala.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveUtilizationFeed extends StatelessWidget {
  const _LiveUtilizationFeed();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Live Lab Utilization Feed',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const _InsightTile(
              icon: Icons.handyman_outlined,
              title: 'Rawat alat setelah digunakan',
              subtitle:
                  'Matikan perangkat, rapikan kabel, dan laporkan anomali sekecil apa pun melalui form maintenance.',
            ),
            const SizedBox(height: 10),
            const _InsightTile(
              icon: Icons.trending_up_rounded,
              title: 'Ruang paling aktif minggu ini',
              subtitle:
                  'Lab RPL dan Lab Jaringan menjadi ruang paling sering dipakai untuk praktikum dan penelitian mahasiswa.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.richBronze.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.richBronze),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.muted,
                    height: 1.4,
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

class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion();

  static const _items = [
    (
      'Siapa saja yang bisa menggunakan LabIN?',
      'LabIN dapat digunakan oleh mahasiswa, asisten laboratorium, dan kepala laboratorium sesuai hak akses masing-masing.',
    ),
    (
      'Apakah bisa meminjam lebih dari satu barang?',
      'Bisa. Sistem mendukung peminjaman banyak alat sekaligus melalui keranjang atau formulir multi-step.',
    ),
    (
      'Batas waktu pengajuan H-2',
      'Pengajuan idealnya dilakukan minimal H-2 sebelum jadwal penggunaan agar proses approval berjalan tertib.',
    ),
    (
      'Apa yang dilakukan jika barang rusak?',
      'Gunakan form laporan kerusakan dan sertakan foto bukti agar laboratorium dapat memproses maintenance.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Frequently Asked Questions',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.deepTeal,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ..._items.map(
              (item) => Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  iconColor: AppTheme.deepTeal,
                  collapsedIconColor: AppTheme.deepTeal,
                  title: Text(
                    item.$1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                      child: Text(
                        item.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.muted,
                          height: 1.45,
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
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget page;
}

class _StockCalendar extends StatelessWidget {
  const _StockCalendar({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final totalAvailable = state.inventories.fold(
      0,
      (sum, item) => sum + item.stokTersedia,
    );
    final stockColor = totalAvailable > 0
        ? AppTheme.richBronze
        : AppTheme.sepia;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Stock & Smart Calendar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TableCalendar<void>(
              firstDay: DateTime.now().subtract(const Duration(days: 1)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: state.selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, state.selectedDate),
              calendarFormat: CalendarFormat.week,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: false,
              ),
              onDaySelected: (selectedDay, _) {
                context.read<DashboardBloc>().add(
                  DashboardDateSelected(
                    DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                      9,
                    ),
                  ),
                );
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.circle, color: stockColor, size: 12),
                const SizedBox(width: 8),
                Text('$totalAvailable stok tersedia saat ini'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({required this.inventories, required this.columns});

  final List<LabInventory> inventories;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return const _EmptyCard(text: 'Inventaris belum tersedia.');
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: inventories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 3 ? 1.08 : 0.86,
      ),
      itemBuilder: (context, index) {
        final inventory = inventories[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  inventory.isAvailable
                      ? Icons.precision_manufacturing_outlined
                      : Icons.warning_amber_rounded,
                  color: inventory.isAvailable
                      ? AppTheme.richBronze
                      : AppTheme.sepia,
                ),
                const SizedBox(height: 10),
                Text(
                  inventory.namaAlat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text('Stok ${inventory.stokTersedia}/${inventory.totalStok}'),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: inventory.isAvailable
                      ? () => context.read<DashboardBloc>().add(
                          DashboardCartItemAdded(inventory),
                        )
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartCheckout extends StatelessWidget {
  const _CartCheckout({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Keranjang Peminjaman',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (state.cart.isEmpty)
              const Text('Tambahkan beberapa alat sebelum checkout.')
            else
              ...state.cart.values.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.inventory.namaAlat),
                  subtitle: Text('Jumlah ${item.quantity}'),
                  trailing: IconButton(
                    onPressed: () => context.read<DashboardBloc>().add(
                      DashboardCartItemRemoved(item.inventory.id),
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: state.cart.isEmpty || state.isLoading
                  ? null
                  : () => context.read<DashboardBloc>().add(
                      const DashboardCheckoutRequested(),
                    ),
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Checkout Pengajuan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicQrPass extends StatefulWidget {
  const _DynamicQrPass({required this.booking});

  final LabBooking booking;

  @override
  State<_DynamicQrPass> createState() => _DynamicQrPassState();
}

class _DynamicQrPassState extends State<_DynamicQrPass> {
  late Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(
      const Duration(seconds: 60),
      (tick) => tick,
    ).startWith(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (context, snapshot) {
        final slot = DateTime.now().millisecondsSinceEpoch ~/ 60000;
        final value = '${widget.booking.id}|${widget.booking.qrToken}|$slot';
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                QrImageView(data: value, version: QrVersions.auto, size: 118),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dynamic QR Pass',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text('Status: ${widget.booking.status}'),
                      const Text('Token berubah tiap 60 detik.'),
                    ],
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

class _MaintenanceReport extends StatefulWidget {
  const _MaintenanceReport({required this.inventories});

  final List<LabInventory> inventories;

  @override
  State<_MaintenanceReport> createState() => _MaintenanceReportState();
}

class _MaintenanceReportState extends State<_MaintenanceReport> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  LabInventory? _selected;
  XFile? _photo;

  @override
  void dispose() {
    _controller.dispose();
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
              'Crowdsourced Maintenance Report',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LabInventory>(
              initialValue: _selected,
              items: widget.inventories
                  .map(
                    (inventory) => DropdownMenuItem(
                      value: inventory,
                      child: Text(inventory.namaAlat),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selected = value),
              decoration: const InputDecoration(
                labelText: 'Pilih alat/fasilitas',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Deskripsi kerusakan',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(_photo == null ? 'Ambil Foto Bukti' : _photo!.name),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _selected == null || _photo == null
                  ? null
                  : () {
                      context.read<DashboardBloc>().add(
                        DashboardMaintenanceReportSubmitted(
                          inventory: _selected!,
                          description: _controller.text,
                          photo: _photo!,
                        ),
                      );
                      _controller.clear();
                      setState(() => _photo = null);
                    },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
    );
    if (photo != null) {
      setState(() => _photo = photo);
    }
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(18), child: Text(text)),
    );
  }
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
