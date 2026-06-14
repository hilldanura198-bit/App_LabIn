import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/brand.dart';
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
            'Pencarian Pintar',
            'Notifikasi',
            'Pengaturan',
          ][_selectedIndex],
          showProfileAvatar: true,
          onProfilePressed: () => _openSettings(context),
          actions: [
            BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    tooltip: 'Keranjang',
                    onPressed: () => _openCart(context, state),
                    icon: Badge(
                      isLabelVisible: state.cartCount > 0,
                      label: Text('${state.cartCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
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

  void _openCart(BuildContext context, DashboardState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.94,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.muted.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppTheme.deepTeal,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Keranjang ${AppBrand.name}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemBuilder: (context, index) {
                          final item = state.cart.values.elementAt(index);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppTheme.cleanCyan.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cyberGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.inventory.namaAlat,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Jumlah ${item.quantity} | Sisa ${item.inventory.stokTersedia - item.quantity}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppTheme.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      context.read<DashboardBloc>().add(
                                        DashboardCartItemRemoved(
                                          item.inventory.id,
                                        ),
                                      ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemCount: state.cart.values.length,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: ElevatedButton.icon(
                        onPressed: state.cart.isEmpty || state.isLoading
                            ? null
                            : () {
                                context.read<DashboardBloc>().add(
                                  const DashboardCheckoutRequested(),
                                );
                                Navigator.of(context).pop();
                              },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Checkout Keranjang'),
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
              ? 920.0
              : constraints.maxWidth;
          final gridColumns = constraints.maxWidth >= 760 ? 3 : 2;
          final previewInventories = _previewInventories(state.inventories);
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
                        AppBrand.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppBrand.tagline,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 16),
                      _StockCalendar(state: state),
                      const SizedBox(height: 16),
                      _QuickModuleGrid(repository: repository),
                      const SizedBox(height: 16),
                      const _CampusInsights(),
                      const SizedBox(height: 16),
                      _InventoryGrid(
                        inventories: previewInventories,
                        columns: gridColumns,
                        cart: state.cart,
                        repository: repository,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SaprasFacilityPage(repository: repository),
                              ),
                            ),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Buka Katalog Lengkap'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CartCheckout(state: state),
                      const SizedBox(height: 16),
                      if (state.latestBooking != null) ...[
                        _DynamicQrPass(booking: state.latestBooking!),
                        const SizedBox(height: 16),
                        StatusTimeline(booking: state.latestBooking!),
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

class _QuickModuleGrid extends StatelessWidget {
  const _QuickModuleGrid({required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.manage_search_outlined,
        title: 'Pencarian Pintar',
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modul LabIn & Sarpras',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columns == 3 ? 1.02 : 1.06,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _QuickModuleCard(
                      icon: item.icon,
                      title: item.title,
                      subtitle: _moduleSubtitle(index),
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => item.page)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _moduleSubtitle(int index) {
    return switch (index) {
      0 => 'Reservasi cepat dan presisi',
      1 => 'Cari nomor peminjaman instan',
      2 => 'Dokumen terhubung cloud',
      3 => 'Jadwal ruang multi-lab',
      4 => 'Pantau status instan',
      _ => 'Katalog fasilitas kampus',
    };
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
      'Siapa saja yang bisa menggunakan LabIn?',
      'LabIn dapat digunakan oleh mahasiswa, asisten laboratorium, dan kepala laboratorium sesuai hak akses masing-masing.',
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

class _QuickModuleCard extends StatelessWidget {
  const _QuickModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.cyberGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricBlue.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<LabInventory> _previewInventories(List<LabInventory> inventories) {
  final sorted = [...inventories]
    ..sort((a, b) => b.stokTersedia.compareTo(a.stokTersedia));
  return sorted.take(8).toList();
}

class _StockCalendar extends StatefulWidget {
  const _StockCalendar({required this.state});

  final DashboardState state;

  @override
  State<_StockCalendar> createState() => _StockCalendarState();
}

class _StockCalendarState extends State<_StockCalendar> {
  static const _pageSpan = 24;
  late final PageController _pageController;
  late final DateTime _baseMonth;
  late int _visiblePage;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month, 1);
    _visiblePage = _pageSpan;
    _visibleMonth = _monthForPage(_visiblePage);
    _pageController = PageController(initialPage: _visiblePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAvailable = widget.state.inventories.fold(
      0,
      (sum, item) => sum + item.stokTersedia,
    );
    final stockColor = totalAvailable > 0 ? AppTheme.cleanCyan : AppTheme.sepia;
    final totalLabel = '$totalAvailable stok tersedia saat ini';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Live Stock & Smart Calendar',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Geser bulan untuk menelusuri tanggal lain',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _goToPreviousMonth,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      _monthLabel(_visibleMonth),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    IconButton(
                      onPressed: _goToNextMonth,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    totalLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 330,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _visiblePage = page;
                        _visibleMonth = _monthForPage(page);
                      });
                    },
                    itemBuilder: (context, index) {
                      final month = _monthForPage(index);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: TableCalendar<void>(
                          firstDay: DateTime(month.year, month.month, 1)
                              .subtract(const Duration(days: 7)),
                          lastDay: DateTime(month.year, month.month + 1, 0)
                              .add(const Duration(days: 7)),
                          focusedDay: month,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, widget.state.selectedDate),
                          calendarFormat: CalendarFormat.month,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Bulan',
                          },
                          availableGestures: AvailableGestures.none,
                          headerVisible: false,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          sixWeekMonthsEnforced: false,
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
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            todayDecoration: BoxDecoration(
                              color: AppTheme.electricBlue.withValues(
                                alpha: 0.16,
                              ),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              gradient: AppTheme.cyberGradient,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: stockColor,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                            todayTextStyle: const TextStyle(
                              color: AppTheme.electricBlue,
                              fontWeight: FontWeight.w900,
                            ),
                            weekendTextStyle: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                  color: AppTheme.vibrantPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle:
                                TextStyle(fontWeight: FontWeight.w700),
                            weekendStyle: TextStyle(fontWeight: FontWeight.w700),
                          ),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime _monthForPage(int page) {
    final offset = page - _pageSpan;
    return DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
  }

  String _monthLabel(DateTime month) {
    return '${_monthName(month.month)} ${month.year}';
  }

  String _monthName(int month) {
    return switch (month) {
      1 => 'Januari',
      2 => 'Februari',
      3 => 'Maret',
      4 => 'April',
      5 => 'Mei',
      6 => 'Juni',
      7 => 'Juli',
      8 => 'Agustus',
      9 => 'September',
      10 => 'Oktober',
      11 => 'November',
      _ => 'Desember',
    };
  }

  Future<void> _goToPreviousMonth() async {
    if (_visiblePage <= 0) return;
    final target = _visiblePage - 1;
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToNextMonth() async {
    final target = _visiblePage + 1;
    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }
}

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({
    required this.inventories,
    required this.columns,
    required this.cart,
    required this.repository,
  });

  final List<LabInventory> inventories;
  final int columns;
  final Map<String, BookingItemDraft> cart;
  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return _EmptyCard(
        text: 'Inventaris belum tersedia.',
        actionLabel: 'Buka Katalog Lengkap',
        onAction: () => _openCatalog(context),
      );
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
        final reserved = cart[inventory.id]?.quantity ?? 0;
        final remaining = inventory.stokTersedia - reserved;
        final available = remaining > 0 && inventory.isAvailable;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    inventory.isAvailable
                        ? Icons.precision_manufacturing_outlined
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  inventory.namaAlat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: available
                        ? AppTheme.cleanCyan.withValues(alpha: 0.12)
                        : Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    available ? 'Sisa $remaining' : 'Stok Habis',
                    style: TextStyle(
                      color: available ? AppTheme.deepTeal : Colors.redAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tersedia ${inventory.stokTersedia}/${inventory.totalStok}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: available
                      ? () => context.read<DashboardBloc>().add(
                          DashboardCartItemAdded(inventory),
                        )
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(available ? 'Tambah' : 'Stok Habis'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SaprasFacilityPage(repository: repository),
      ),
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
  const _EmptyCard({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.storefront_outlined),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
