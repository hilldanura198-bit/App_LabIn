import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
import 'widgets/booking_status_ui.dart';
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
            const DashboardStarted(inventoryStream: true, bookingStream: true),
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return _LabInTopNavbar(
                cartCount: state.cartCount,
                onDashboard: () => setState(() => _selectedIndex = 0),
                onCalendar: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomSchedulePage(repository: _repository(context)),
                  ),
                ),
                onBooking: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingFormPage(repository: _repository(context)),
                  ),
                ),
                onSchedule: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RoomSchedulePage(repository: _repository(context)),
                  ),
                ),
                onSapras: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SaprasFacilityPage(repository: _repository(context)),
                  ),
                ),
                onReport: () => setState(() => _selectedIndex = 0),
                onProfile: () => _openSettings(context),
                onNotification: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationCenterPage(
                      repository: _repository(context),
                    ),
                  ),
                ),
              );
            },
          ),
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
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 720
            ? SafeArea(
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
                          GButton(
                            icon: Icons.search_rounded,
                            text: 'Reservasi',
                          ),
                          GButton(
                            icon: Icons.notifications_outlined,
                            text: 'Notifikasi',
                          ),
                          GButton(
                            icon: Icons.settings_outlined,
                            text: 'Pengaturan',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
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

class _LabInTopNavbar extends StatelessWidget {
  const _LabInTopNavbar({
    required this.cartCount,
    required this.onDashboard,
    required this.onCalendar,
    required this.onBooking,
    required this.onSchedule,
    required this.onSapras,
    required this.onReport,
    required this.onProfile,
    required this.onNotification,
  });

  final int cartCount;
  final VoidCallback onDashboard;
  final VoidCallback onCalendar;
  final VoidCallback onBooking;
  final VoidCallback onSchedule;
  final VoidCallback onSapras;
  final VoidCallback onReport;
  final VoidCallback onProfile;
  final VoidCallback onNotification;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 1120;
    final primaryMenu = [
      ('Dashboard', Icons.dashboard_outlined, onDashboard),
      ('Kalender', Icons.calendar_month_outlined, onCalendar),
      ('Peminjaman', Icons.assignment_add, onBooking),
      ('Jadwal Ruangan', Icons.meeting_room_outlined, onSchedule),
    ];
    final secondaryMenu = [
      ('Sarpras', Icons.apartment_outlined, onSapras),
      ('Laporan', Icons.report_problem_outlined, onReport),
      ('Profil', Icons.person_outline, onProfile),
    ];
    final visibleMenu = compact
        ? primaryMenu
        : [...primaryMenu, ...secondaryMenu];

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 18,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.electricBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.science_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            'LabIN',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in visibleMenu)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextButton.icon(
                        onPressed: item.$3,
                        icon: Icon(item.$2, size: 18),
                        label: Text(item.$1),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (compact)
                    PopupMenuButton<VoidCallback>(
                      tooltip: 'Menu lainnya',
                      onSelected: (callback) => callback(),
                      itemBuilder: (context) => [
                        for (final item in secondaryMenu)
                          PopupMenuItem<VoidCallback>(
                            value: item.$3,
                            child: Row(
                              children: [
                                Icon(item.$2, size: 18),
                                const SizedBox(width: 10),
                                Text(item.$1),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.more_horiz_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Lainnya'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        Badge(
          label: Text('$cartCount'),
          child: IconButton(
            tooltip: 'Keranjang peminjaman',
            onPressed: onBooking,
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: onNotification,
          icon: const Icon(Icons.notifications_outlined),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: IconButton.filledTonal(
            tooltip: 'Profil',
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ),
      ],
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
                    bookingStream: true,
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
                      _DashboardHeader(state: state),
                      const SizedBox(height: 16),
                      _DashboardSummary(state: state),
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
                      _SaprasUsageSchedule(
                        bookings: state.bookings,
                        inventories: state.inventories,
                      ),
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
        color: const Color(0xFFEFF6FF),
        page: CheckReservationPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.playlist_add_check_rounded,
        title: 'Form Peminjaman',
        color: const Color(0xFFECFDF5),
        page: BookingFormPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.file_download_outlined,
        title: 'Unduh Berkas',
        color: const Color(0xFFFFF7ED),
        page: DownloadDocsPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.view_timeline_outlined,
        title: 'Jadwal Ruangan',
        color: const Color(0xFFE0F2FE),
        page: RoomSchedulePage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.notifications_active_outlined,
        title: 'Notifikasi',
        color: const Color(0xFFFFF1F2),
        page: NotificationCenterPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.location_city_outlined,
        title: 'SAPRAS Kampus',
        color: const Color(0xFFF0FDFA),
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
            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 760;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: desktop ? 3 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: desktop ? 2.55 : 1.48,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => item.page)),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(item.icon, color: AppTheme.deepTeal),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _SaprasUsageSchedule extends StatelessWidget {
  const _SaprasUsageSchedule({
    required this.bookings,
    required this.inventories,
  });

  final List<LabBooking> bookings;
  final List<LabInventory> inventories;

  @override
  Widget build(BuildContext context) {
    final rows = bookings
        .where(
          (booking) =>
              booking.status == 'pending' ||
              booking.status == 'approved_aslab' ||
              booking.status == 'approved_kalab' ||
              booking.status == 'active',
        )
        .take(5)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Jadwal Pemakaian Sarpras',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Status pengajuan sarana prasarana ditampilkan sebagai pending atau disetujui.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              const Text('Belum ada pemakaian sarpras aktif.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStatePropertyAll(
                    AppTheme.electricBlue.withValues(alpha: 0.10),
                  ),
                  columns: const [
                    DataColumn(label: Text('Sarpras')),
                    DataColumn(label: Text('Peminjam')),
                    DataColumn(label: Text('Tanggal')),
                    DataColumn(label: Text('Waktu')),
                    DataColumn(label: Text('Keperluan')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (var index = 0; index < rows.length; index++)
                      _usageDataRow(index, rows[index]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  DataRow _usageDataRow(int index, LabBooking booking) {
    final background = index.isEven ? Colors.white : const Color(0xFFEFF6FF);
    return DataRow(
      color: WidgetStatePropertyAll(background),
      cells: [
        DataCell(Text(_facilityName(index))),
        const DataCell(Text('Mahasiswa LabIN')),
        DataCell(Text(DateFormat('d MMM y').format(booking.tanggalPinjam))),
        DataCell(
          Text(
            '${DateFormat.Hm().format(booking.tanggalPinjam)} - '
            '${DateFormat.Hm().format(booking.tanggalKembali)}',
          ),
        ),
        const DataCell(Text('Praktikum / riset')),
        DataCell(_SmallStatusBadge(status: booking.status)),
      ],
    );
  }

  String _facilityName(int index) {
    if (inventories.isEmpty) {
      return 'Sarpras Kampus';
    }
    return inventories[index % inventories.length].namaAlat;
  }
}

class _SmallStatusBadge extends StatelessWidget {
  const _SmallStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = BookingStatusUi.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        BookingStatusUi.label(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final todayBookings = state.bookings
        .where((booking) => isSameDay(booking.tanggalPinjam, DateTime.now()))
        .length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.electricBlue.withValues(alpha: 0.14),
            AppTheme.vibrantPurple.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3FF)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final text = Column(
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard LabIN',
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pantau kalender, peminjaman, jadwal ruangan, dan pemakaian sarpras kampus dalam satu workspace.',
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
            ],
          );
          final badge = _TodayBadge(count: todayBookings);
          if (compact) {
            return Column(children: [text, const SizedBox(height: 14), badge]);
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 18),
              badge,
            ],
          );
        },
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  const _TodayBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E3FF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: AppTheme.electricBlue,
          ),
          const SizedBox(height: 8),
          Text(
            '$count jadwal hari ini',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.bookings
        .where((item) => item.status == 'pending')
        .length;
    final approved = state.bookings
        .where((item) => BookingStatusUi.isApprovedOrActive(item.status))
        .length;
    final available = state.inventories
        .where((item) => item.isAvailable)
        .length;
    final nextSchedule = [...state.bookings]
      ..sort((a, b) => a.tanggalPinjam.compareTo(b.tanggalPinjam));
    final nextLabel = nextSchedule.isEmpty
        ? 'Belum ada'
        : DateFormat('d MMM, HH:mm').format(nextSchedule.first.tanggalPinjam);

    final cards = [
      _SummaryItem(
        icon: Icons.pending_actions_outlined,
        label: 'Pengajuan pending',
        value: '$pending',
        color: const Color(0xFFFF9800),
      ),
      _SummaryItem(
        icon: Icons.verified_outlined,
        label: 'Disetujui/aktif',
        value: '$approved',
        color: const Color(0xFF16A34A),
      ),
      _SummaryItem(
        icon: Icons.inventory_2_outlined,
        label: 'Sarpras tersedia',
        value: '$available',
        color: AppTheme.electricBlue,
      ),
      _SummaryItem(
        icon: Icons.schedule_outlined,
        label: 'Jadwal terdekat',
        value: nextLabel,
        color: AppTheme.vibrantPurple,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 860
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 4.0 : 2.2,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
              'Kalender Aktivitas Laboratorium',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Praktikum, pemakaian ruangan, dan peminjaman sarpras ditandai dengan warna berbeda.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
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
            Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const _CalendarLegendDot(
                  color: AppTheme.electricBlue,
                  label: 'Praktikum',
                ),
                const _CalendarLegendDot(
                  color: Color(0xFF16A34A),
                  label: 'Ruangan',
                ),
                _CalendarLegendDot(
                  color: stockColor,
                  label: 'Sarpras tersedia: $totalAvailable',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarLegendDot extends StatelessWidget {
  const _CalendarLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 8),
        Text(label),
      ],
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
