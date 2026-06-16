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
import 'widgets/room_stock_stream_banner.dart';
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
  bool _cartSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message != null) {
          if (_cartSheetOpen && message.contains('Checkout berhasil')) {
            _cartSheetOpen = false;
            Navigator.of(context).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: message.contains('Checkout berhasil')
                  ? Colors.green.shade600
                  : null,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: GlassAppBar(
          title: '',
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
      1 => CheckReservationPage(repository: repository, showAppBar: false),
      2 => NotificationCenterPage(repository: repository, showAppBar: false),
      3 => RepositoryProvider.value(
        value: context.read<AuthRepository>(),
        child: BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: SettingsPage(repository: repository, showAppBar: false),
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

  Future<void> _openCart(BuildContext context, DashboardState state) async {
    _cartSheetOpen = true;
    await showModalBottomSheet<void>(
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
                        onPressed:
                            state.cart.isEmpty ||
                                state.isLoading ||
                                state.cart.values.any(
                                  (item) =>
                                      item.inventory.stokTersedia -
                                          item.quantity <=
                                      0,
                                )
                            ? null
                            : () {
                                context.read<DashboardBloc>().add(
                                  const DashboardCheckoutRequested(),
                                );
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
    if (mounted) {
      _cartSheetOpen = false;
    }
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
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                          children: const [
                            TextSpan(
                              text: 'Lab',
                              style: TextStyle(color: AppTheme.deepSpace),
                            ),
                            TextSpan(
                              text: 'In',
                              style: TextStyle(color: AppTheme.electricBlue),
                            ),
                          ],
                        ),
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
                      _StockCalendar(state: state, repository: repository),
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
              'Fasilitas Kampus Insight',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Rangkuman singkat pemanfaatan fasilitas kampus yang bergerak dinamis dan relevan dengan kebutuhan mahasiswa.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            const _InsightCarousel(),
          ],
        ),
      ),
    );
  }
}

class _InsightCarousel extends StatefulWidget {
  const _InsightCarousel();

  @override
  State<_InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends State<_InsightCarousel> {
  final _pageController = PageController(viewportFraction: 0.84);
  int _page = 0;

  static const _cards = [
    (
      AppTheme.cyberGradient,
      Icons.auto_awesome_outlined,
      'Standarisasi Ruang Praktikum',
      'Setiap ruang lab dikelompokkan berdasarkan fungsi, kapasitas, dan kesiapan alat agar proses belajar lebih presisi.',
    ),
    (
      LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF2F3C7E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      Icons.workspace_premium_outlined,
      'Modernisasi Sarana Prasarana',
      'Inventaris digital membantu kampus memantau kebutuhan perawatan, audit aset, dan pemanfaatan ruang secara berkala.',
    ),
    (
      LinearGradient(
        colors: [Color(0xFF102A43), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      Icons.explore_outlined,
      'Akses Insight Cepat',
      'Slider ringkas memudahkan mahasiswa membaca pola fasilitas tanpa menghabiskan banyak ruang di layar.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 184,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _page = value),
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: card.$1,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(card.$2, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          card.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.$4,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            height: 1.28,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cards.length, (index) {
            final active = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppTheme.vibrantPurple : AppTheme.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
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
  const _StockCalendar({required this.state, required this.repository});

  final DashboardState state;
  final DashboardRepository repository;

  @override
  State<_StockCalendar> createState() => _StockCalendarState();
}

class _StockCalendarState extends State<_StockCalendar> {
  static const _weekAnchor = 78;
  static const _weekCount = 156;
  late final PageController _pageController;
  late final DateTime _baseWeekStart;
  late int _visiblePage;
  late DateTime _visibleWeekStart;

  @override
  void initState() {
    super.initState();
    _baseWeekStart = _startOfWeek(DateTime.now());
    _visiblePage = _weekAnchor;
    _visibleWeekStart = _weekForPage(_visiblePage);
    _pageController = PageController(initialPage: _visiblePage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _goToPreviousWeek,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        _weekLabel(_visibleWeekStart),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _goToNextWeek,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RoomStockStreamBanner(repository: widget.repository),
                const SizedBox(height: 12),
                SizedBox(
                  height: 108,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _weekCount,
                    onPageChanged: (page) {
                      setState(() {
                        _visiblePage = page;
                        _visibleWeekStart = _weekForPage(page);
                      });
                    },
                    itemBuilder: (context, page) {
                      final weekStart = _weekForPage(page);
                      return Row(
                        children: List.generate(7, (index) {
                          final day = weekStart.add(Duration(days: index));
                          final selected = isSameDay(
                            day,
                            widget.state.selectedDate,
                          );
                          final isToday = isSameDay(day, DateTime.now());
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  context.read<DashboardBloc>().add(
                                    DashboardDateSelected(
                                      DateTime(day.year, day.month, day.day, 9),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppTheme.electricBlue.withValues(
                                            alpha: 0.10,
                                          )
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? AppTheme.electricBlue
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _weekdayShort(day.weekday),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: selected
                                                  ? AppTheme.electricBlue
                                                  : AppTheme.muted,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${day.day}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: selected || isToday
                                                  ? AppTheme.midnightNavy
                                                  : AppTheme.darkCharcoal,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: AppTheme.vibrantPurple,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
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

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _weekForPage(int page) {
    return _baseWeekStart.add(Duration(days: (page - _weekAnchor) * 7));
  }

  String _weekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    return '${_dayLabel(weekStart)} - ${_dayLabel(end)}';
  }

  String _dayLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _weekdayShort(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Sen',
      DateTime.tuesday => 'Sel',
      DateTime.wednesday => 'Rab',
      DateTime.thursday => 'Kam',
      DateTime.friday => 'Jum',
      DateTime.saturday => 'Sab',
      _ => 'Min',
    };
  }

  Future<void> _goToPreviousWeek() async {
    if (_visiblePage <= 0) return;
    await _pageController.animateToPage(
      _visiblePage - 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToNextWeek() async {
    if (_visiblePage >= _weekCount - 1) return;
    await _pageController.animateToPage(
      _visiblePage + 1,
      duration: const Duration(milliseconds: 240),
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
        childAspectRatio: 0.63,
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
                  maxLines: 1,
                  softWrap: false,
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
                    available ? 'Sisa $remaining' : 'Stok Sudah Habis',
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
                FilledButton.icon(
                  onPressed: available
                      ? () => context.read<DashboardBloc>().add(
                          DashboardCartItemAdded(inventory),
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: available
                        ? AppTheme.vibrantPurple
                        : Colors.grey.shade500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade500,
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size.fromHeight(42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(
                    available ? Icons.add_rounded : Icons.block_outlined,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(available ? 'Pinjam' : 'Stok Habis'),
                  ),
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
    final canCheckout = state.cart.isNotEmpty && !state.isLoading;
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
              onPressed: canCheckout
                  ? () => context.read<DashboardBloc>().add(
                      const DashboardCheckoutRequested(),
                    )
                  : null,
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
    if (widget.booking.status != 'approved_kalab') {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: AppTheme.muted),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'QR Code muncul setelah di-ACC Kepala Lab',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
