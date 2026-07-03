import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/local_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'booking_form_page.dart';
import 'booking_success_page.dart';
import 'check_reservation_page.dart';
import 'download_docs_page.dart';
import 'history_page.dart';
import 'notification_center_page.dart';
import 'room_schedule_page.dart';
import 'sapras_facility_page.dart';
import 'settings_page.dart';
import 'widgets/busy_meter.dart';
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
  static const _campusOptions = [
    'Kampus Rektorat',
    'Kampus 1',
    'Kampus 2',
    'Kampus 3',
    'Kampus 4',
  ];

  int _selectedIndex = 0;
  String? _lastCheckoutBookingId;
  bool _isRatingSheetOpen = false;
  bool _notificationListenerStarted = false;
  bool _notificationsPrimed = false;
  final Set<String> _knownNotificationIds = {};
  final Set<String> _promptedRatingBookingIds = {};
  DashboardState? _lastDashboardState;
  StreamSubscription<List<AppNotification>>? _notificationSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notificationListenerStarted) {
      return;
    }
    _notificationListenerStarted = true;
    _notificationSubscription = _repository(
      context,
    ).watchNotifications().listen(_handleRealtimeNotifications);
  }

  void _handleRealtimeNotifications(List<AppNotification> notifications) {
    if (!_notificationsPrimed) {
      _knownNotificationIds.addAll(notifications.map((item) => item.id));
      _notificationsPrimed = true;
      return;
    }

    final freshNotifications = notifications
        .where(
          (item) => !_knownNotificationIds.contains(item.id) && !item.isRead,
        )
        .toList();
    _knownNotificationIds.addAll(notifications.map((item) => item.id));

    for (final notification in freshNotifications.take(3)) {
      LocalNotificationService.instance.show(
        title: notification.title,
        body: notification.message,
        payload: notification.targetId,
      );
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.bookings != current.bookings,
      listener: (context, state) {
        final previousState = _lastDashboardState;
        _lastDashboardState = state;
        final message = state.message;
        if (message != null) {
          final displayMessage = _localizedDashboardMessage(message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(displayMessage),
              backgroundColor: message == 'checkout_success'
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          );
        }
        if (message == 'checkout_success' &&
            state.activeHomeBooking != null &&
            state.activeHomeBooking!.id != _lastCheckoutBookingId) {
          final booking = state.activeHomeBooking!;
          _lastCheckoutBookingId = booking.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookingSuccessPage(booking: booking),
              ),
            );
          });
        }
        if (message != 'checkout_success' && !_isRatingSheetOpen) {
          if (previousState == null) {
            return;
          }
          final previousById = {
            for (final booking in previousState.bookings) booking.id: booking,
          };
          LabBooking? latestReturned;
          for (final booking in state.bookings) {
            if (booking.status != 'returned' ||
                booking.hasReviewed ||
                _promptedRatingBookingIds.contains(booking.id)) {
              continue;
            }
            final previousStatus = previousById[booking.id]?.status;
            if (previousStatus != 'active' && previousStatus != 'late') {
              continue;
            }
            latestReturned = booking;
            break;
          }
          if (latestReturned != null) {
            _promptedRatingBookingIds.add(latestReturned.id);
            _isRatingSheetOpen = true;
            _showRatingBottomSheet(context, latestReturned).whenComplete(() {
              _isRatingSheetOpen = false;
            });
          }
        }
      },
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final campusTheme = AppTheme.campusTheme(
            Theme.of(context),
            state.selectedCampus,
          );
          return Theme(
            data: campusTheme,
            child: Scaffold(
              body: Column(
                children: [
                  _ModernFloatingHeader(
                    cartCount: state.cartCount,
                    selectedCampus: state.selectedCampus,
                    campuses: _campusOptions,
                    onCampusChanged: (campus) {
                      context.read<DashboardBloc>().add(
                        DashboardCampusSelected(campus),
                      );
                    },
                    onCartPressed: () => _openCart(context, state),
                    onProfilePressed: () => _openSettings(context),
                    onNotifPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationCenterPage(
                          repository: _repository(context),
                        ),
                      ),
                    ),
                    onSearchSubmitted: (query) => _showGlobalSearch(
                      context,
                      query: query,
                      state: state,
                      repository: _repository(context),
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
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
                    ),
                  ),
                ],
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
                        activeColor: Theme.of(context).colorScheme.primary,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        tabBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.22),
                        tabs: [
                          GButton(icon: Icons.home_outlined, text: 'home'.tr()),
                          GButton(
                            icon: Icons.search_rounded,
                            text: 'reservation'.tr(),
                          ),
                          GButton(
                            icon: Icons.notifications_outlined,
                            text: 'notifications'.tr(),
                          ),
                          GButton(icon: Icons.history_rounded, text: 'Riwayat'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(BuildContext context, DashboardState state) {
    final repository = _repository(context);
    return switch (_selectedIndex) {
      1 => CheckReservationPage(repository: repository, showAppBar: false),
      2 => NotificationCenterPage(repository: repository, showAppBar: false),
      3 => HistoryPage(
        repository: repository,
        role: UserRole.mahasiswa,
        showAppBar: false,
      ),
      _ => _HomeScrollContent(
        state: state,
        repository: repository,
        selectedCampus: state.selectedCampus,
      ),
    };
  }

  DashboardRepository _repository(BuildContext context) {
    return DashboardRepository(context.read<AuthRepository>().client);
  }

  String _localizedDashboardMessage(String message) {
    const keys = {'checkout_success', 'stock_not_enough'};
    if (keys.contains(message)) {
      return message.tr();
    }
    return message;
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

  Future<void> _openCart(BuildContext context, DashboardState state) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<DashboardBloc>(),
          child: BlocListener<DashboardBloc, DashboardState>(
            listenWhen: (previous, current) =>
                previous.message != current.message,
            listener: (context, current) {
              if (current.message == 'checkout_success' &&
                  Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.34,
              maxChildSize: 0.90,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
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
                        const SizedBox(height: 18),
                        Text(
                          'checkout_cart'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        _CartCheckout(state: state),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showGlobalSearch(
    BuildContext context, {
    required String query,
    required DashboardState state,
    required DashboardRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GlobalSearchSheet(
          initialQuery: query,
          inventories: state.inventories,
          repository: repository,
        );
      },
    );
  }

  Future<void> _showRatingBottomSheet(
    BuildContext context,
    LabBooking booking,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              8,
              22,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: _RatingDialog(
              booking: booking,
              repository: _repository(context),
            ),
          ),
        );
      },
    );
  }
}

class _HomeScrollContent extends StatelessWidget {
  const _HomeScrollContent({
    required this.state,
    required this.repository,
    required this.selectedCampus,
  });

  final DashboardState state;
  final DashboardRepository repository;
  final String selectedCampus;

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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                          children: [
                            TextSpan(
                              text: 'Lab',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: 'In',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _StockCalendar(state: state, repository: repository),
                      const SizedBox(height: 16),
                      _QuickModuleGrid(
                        repository: repository,
                        selectedCampus: selectedCampus,
                      ),
                      const SizedBox(height: 16),
                      const _CampusInsights(),
                      const SizedBox(height: 16),
                      Text(
                        'inventory_section_title'.tr(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.isLoading && state.inventories.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else
                        _InventoryGrid(
                          inventories: previewInventories,
                          columns: gridColumns,
                          cart: state.cart,
                          repository: repository,
                          selectedCampus: state.selectedCampus,
                        ),
                      const SizedBox(height: 10),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaprasFacilityPage(
                                  repository: repository,
                                  selectedCampus: selectedCampus,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.storefront_outlined),
                            label: Text('open_full_catalog'.tr()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _CartCheckout(state: state),
                      const SizedBox(height: 16),
                      if (state.activeHomeBooking != null) ...[
                        StatusTimeline(booking: state.activeHomeBooking!),
                        const SizedBox(height: 16),
                      ],
                      BusyMeter(hours: state.busyHours),
                      const SizedBox(height: 16),
                      const _LiveUtilizationFeed(),
                      const SizedBox(height: 16),
                      _MaintenanceReport(
                        inventories: state.inventories,
                        repository: repository,
                      ),
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
  const _QuickModuleGrid({
    required this.repository,
    required this.selectedCampus,
  });

  final DashboardRepository repository;
  final String selectedCampus;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.playlist_add_check_rounded,
        title: 'loan_form'.tr(),
        page: BookingFormPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.file_download_outlined,
        title: 'download_docs'.tr(),
        page: DownloadDocsPage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.view_timeline_outlined,
        title: 'room_schedule'.tr(),
        page: RoomSchedulePage(repository: repository),
      ),
      _MenuItem(
        icon: Icons.location_city_outlined,
        title: 'sapras_campus'.tr(),
        page: SaprasFacilityPage(
          repository: repository,
          selectedCampus: selectedCampus,
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'labin_modules'.tr(),
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
                      subtitle: _moduleSubtitle(item.title),
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

  String _moduleSubtitle(String title) {
    if (title == 'loan_form'.tr()) return 'fast_reservation'.tr();
    if (title == 'download_docs'.tr()) return 'cloud_docs'.tr();
    if (title == 'room_schedule'.tr()) return 'multi_lab_schedule'.tr();
    return 'campus_facility_catalog'.tr();
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
              'campus_facility_insight'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'facility_insight_body'.tr(),
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
      Icons.auto_awesome_outlined,
      'insight_standardized_rooms_title',
      'insight_standardized_rooms_body',
    ),
    (
      Icons.workspace_premium_outlined,
      'insight_modern_facilities_title',
      'insight_modern_facilities_body',
    ),
    (
      Icons.explore_outlined,
      'insight_fast_access_title',
      'insight_fast_access_body',
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
                    gradient: AppTheme.campusGradientOf(context),
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
                          child: Icon(card.$1, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          card.$2.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          card.$3.tr(),
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
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.muted,
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
              'live_utilization_feed'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const _InsightTile(
              icon: Icons.handyman_outlined,
              titleKey: 'maintenance_tip_title',
              subtitleKey: 'maintenance_tip_body',
            ),
            const SizedBox(height: 10),
            const _InsightTile(
              icon: Icons.trending_up_rounded,
              titleKey: 'active_room_title',
              subtitleKey: 'active_room_body',
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
    required this.titleKey,
    required this.subtitleKey,
  });

  final IconData icon;
  final String titleKey;
  final String subtitleKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleKey.tr(),
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

  @override
  Widget build(BuildContext context) {
    final items = [
      ('faq_who_q'.tr(), 'faq_who_a'.tr()),
      ('faq_multi_q'.tr(), 'faq_multi_a'.tr()),
      ('faq_deadline_q'.tr(), 'faq_deadline_a'.tr()),
      ('faq_damage_q'.tr(), 'faq_damage_a'.tr()),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'faq_title'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                  iconColor: Theme.of(context).colorScheme.primary,
                  collapsedIconColor: Theme.of(context).colorScheme.primary,
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
    required this.page,
  });

  final IconData icon;
  final String title;
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppTheme.campusGradientOf(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.18),
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
  final sorted = DashboardModel.mergeWithLocalFacilities(inventories)
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
                        _weekLabel(
                          _visibleWeekStart,
                          Localizations.localeOf(context).toString(),
                        ),
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
                      final scheme = Theme.of(context).colorScheme;
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
                                        ? scheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.outlineVariant.withValues(
                                              alpha: isToday ? 0.88 : 0,
                                            ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _weekdayShort(
                                          day,
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: selected
                                                  ? scheme.onPrimary
                                                  : scheme.onSurfaceVariant,
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
                                              color: selected
                                                  ? scheme.onPrimary
                                                  : scheme.onSurface,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? scheme.onPrimary
                                              : (isToday
                                                    ? scheme.primary
                                                    : scheme.onSurfaceVariant
                                                          .withValues(
                                                            alpha: 0.56,
                                                          )),
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

  String _weekLabel(DateTime weekStart, String locale) {
    final end = weekStart.add(const Duration(days: 6));
    final formatter = DateFormat.yMMMMd(locale);
    return '${formatter.format(weekStart)} - ${formatter.format(end)}';
  }

  String _weekdayShort(DateTime date, String locale) {
    return DateFormat.E(locale).format(date);
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
    required this.selectedCampus,
  });

  final List<LabInventory> inventories;
  final int columns;
  final Map<String, BookingItemDraft> cart;
  final DashboardRepository repository;
  final String selectedCampus;

  @override
  Widget build(BuildContext context) {
    if (inventories.isEmpty) {
      return StreamBuilder<List<LabInventory>>(
        stream: repository.watchInventoriesByCampus(selectedCampus),
        builder: (context, snapshot) {
          final fallbackInventories = DashboardModel.mergeWithLocalFacilities(
            snapshot.data ?? const <LabInventory>[],
          );
          if (fallbackInventories.isEmpty) {
            return _EmptyCard(text: 'inventory_empty'.tr());
          }
          return _buildGrid(context, fallbackInventories);
        },
      );
    }
    return _buildGrid(context, inventories);
  }

  Widget _buildGrid(BuildContext context, List<LabInventory> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridColumns = constraints.maxWidth >= 760 ? columns : 2;
        final compact = constraints.maxWidth < 420;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: compact ? 0.58 : 0.68,
          ),
          itemBuilder: (context, index) {
            final inventory = items[index];
            final reserved = cart[inventory.id]?.quantity ?? 0;
            final remaining = inventory.stokTersedia - reserved;
            final available = remaining > 0 && inventory.isAvailable;
            return Card(
              child: Padding(
                padding: EdgeInsets.all(compact ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _InventoryRealtimeImage(inventory: inventory),
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    Text(
                      inventory.namaAlat.capitalize(),
                      maxLines: compact ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          available
                              ? 'remaining_stock'.tr(
                                  namedArgs: {'count': '$remaining'},
                                )
                              : 'out_of_stock'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: available
                                ? Theme.of(context).colorScheme.primary
                                : Colors.redAccent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      'available_stock'.tr(
                        namedArgs: {
                          'available': '${inventory.stokTersedia}',
                          'total': '${inventory.totalStok}',
                        },
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                    SizedBox(height: compact ? 7 : 10),
                    FilledButton.icon(
                      onPressed: available
                          ? () => context.read<DashboardBloc>().add(
                              DashboardCartItemAdded(inventory),
                            )
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: available
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey.shade500,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade500,
                        disabledForegroundColor: Colors.white70,
                        minimumSize: Size.fromHeight(compact ? 36 : 42),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                        ),
                      ),
                      icon: Icon(
                        available ? Icons.add_rounded : Icons.block_outlined,
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          available ? 'borrow'.tr() : 'out_of_stock'.tr(),
                        ),
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

class _InventoryRealtimeImage extends StatelessWidget {
  const _InventoryRealtimeImage({required this.inventory});

  final LabInventory inventory;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      DashboardModel.getLocalAssetPath(inventory.namaAlat),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, _, _) => Image.asset(
        DashboardModel.fallbackAssetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class _CartCheckout extends StatelessWidget {
  const _CartCheckout({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final canCheckout = state.cart.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'borrow_cart'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (state.cart.isEmpty)
              Text('empty_cart'.tr())
            else
              ...state.cart.values.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.inventory.namaAlat.capitalize()),
                  subtitle: Text(
                    'cart_quantity'.tr(
                      namedArgs: {'count': '${item.quantity}'},
                    ),
                  ),
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
                  ? () {
                      final start = state.selectedDate;
                      final end = start.add(
                        const Duration(hours: 2),
                      ); // Default peminjaman 2 jam
                      context.read<DashboardBloc>().add(
                        DashboardCheckoutRequested(
                          startDateTime: start,
                          endDateTime: end,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.task_alt_rounded),
              label: Text('checkout_submission'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceReport extends StatefulWidget {
  const _MaintenanceReport({
    required this.inventories,
    required this.repository,
  });

  final List<LabInventory> inventories;
  final DashboardRepository repository;

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
    if (widget.inventories.isEmpty) {
      return StreamBuilder<List<LabInventory>>(
        stream: widget.repository.watchInventories(),
        builder: (context, snapshot) {
          final inventories = DashboardModel.mergeWithLocalFacilities(
            snapshot.data ?? const <LabInventory>[],
          );
          return _buildCard(
            context,
            inventories,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
          );
        },
      );
    }
    return _buildCard(
      context,
      DashboardModel.mergeWithLocalFacilities(widget.inventories),
    );
  }

  Widget _buildCard(
    BuildContext context,
    List<LabInventory> inventories, {
    bool isLoading = false,
  }) {
    final selected = inventories.any((item) => item.id == _selected?.id)
        ? _selected
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'maintenance_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LabInventory>(
              initialValue: selected,
              items: inventories
                  .map(
                    (inventory) => DropdownMenuItem(
                      value: inventory,
                      child: Text(inventory.namaAlat.capitalize()),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selected = value),
              decoration: InputDecoration(
                labelText: isLoading
                    ? 'loading_inventory'.tr()
                    : 'maintenance_item_label'.tr(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'maintenance_description_label'.tr(),
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
              label: Text('send_report'.tr()),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Text(text, textAlign: TextAlign.center)],
        ),
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({required this.booking, required this.repository});

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 0;
  bool _isLoading = false;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) return;
    setState(() => _isLoading = true);
    try {
      await widget.repository.submitBookingReview(
        bookingId: widget.booking.id,
        rating: _rating,
        review: _reviewController.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim ulasan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Peminjaman Selesai! 🎉',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bagaimana pengalaman Anda menggunakan fasilitas laboratorium kali ini?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 36,
                padding: EdgeInsets.zero,
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AppTheme.richBronze,
                ),
                onPressed: () => setState(() => _rating = index + 1),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis ulasan singkat (opsional)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: _rating > 0 && !_isLoading ? _submit : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Kirim Ulasan'),
        ),
      ],
    );
  }
}

class _ModernFloatingHeader extends StatefulWidget {
  const _ModernFloatingHeader({
    required this.cartCount,
    required this.selectedCampus,
    required this.campuses,
    required this.onCampusChanged,
    required this.onCartPressed,
    required this.onProfilePressed,
    required this.onNotifPressed,
    required this.onSearchSubmitted,
  });

  final int cartCount;
  final String selectedCampus;
  final List<String> campuses;
  final ValueChanged<String> onCampusChanged;
  final VoidCallback onCartPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onNotifPressed;
  final ValueChanged<String> onSearchSubmitted;

  @override
  State<_ModernFloatingHeader> createState() => _ModernFloatingHeaderState();
}

class _ModernFloatingHeaderState extends State<_ModernFloatingHeader> {
  final _searchController = TextEditingController();

  static const _quickTagKeys = [
    'tools_tag',
    'rooms_tag',
    'modules_tag',
    'projector_tag',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(gradient: AppTheme.campusGradientOf(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showCampusSheet,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'location'.tr(),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.78,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  widget.selectedCampus,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _HeaderIconButton(
                  icon: Icons.shopping_bag_outlined,
                  badgeCount: widget.cartCount,
                  onTap: widget.onCartPressed,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.notifications_outlined,
                  onTap: widget.onNotifPressed,
                ),
                const SizedBox(width: 8),
                _HeaderIconButton(
                  icon: Icons.person_outline_rounded,
                  onTap: widget.onProfilePressed,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GlobalSearchField(
              controller: _searchController,
              onSubmitted: _submitSearch,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.sizeOf(context).width - 36,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _quickTagKeys.map((tagKey) {
                      final tag = tagKey.tr();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _HeaderQuickTag(
                          label: tag,
                          icon: _iconForTag(tag),
                          onTap: () {
                            _searchController.text = tag;
                            _submitSearch(tag);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitSearch(String value) {
    final query = value.trim();
    widget.onSearchSubmitted(query.isEmpty ? 'tools_tag'.tr() : query);
  }

  IconData _iconForTag(String tag) {
    return switch (tag.toLowerCase()) {
      'alat' => Icons.build_rounded,
      'ruangan' => Icons.meeting_room_rounded,
      'modul' => Icons.book_rounded,
      'proyektor' => Icons.videocam_rounded,
      _ => Icons.category_rounded,
    };
  }

  Future<void> _showCampusSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Text(
                'choose_campus'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              ...widget.campuses.map(
                (campus) => ListTile(
                  leading: const Icon(Icons.location_city_rounded),
                  title: Text(campus),
                  trailing: campus == widget.selectedCampus
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(campus),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      widget.onCampusChanged(selected);
    }
  }
}

class _HeaderQuickTag extends StatelessWidget {
  const _HeaderQuickTag({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: scheme.primary, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalSearchField extends StatelessWidget {
  const _GlobalSearchField({
    required this.controller,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => onSubmitted(controller.text),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'search_hint'.tr(),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.muted,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
        suffixIcon: IconButton(
          onPressed: () => onSubmitted(controller.text),
          icon: Icon(Icons.tune_rounded, color: scheme.primary),
        ),
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text('$badgeCount'),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _GlobalSearchSheet extends StatefulWidget {
  const _GlobalSearchSheet({
    required this.initialQuery,
    required this.inventories,
    required this.repository,
  });

  final String initialQuery;
  final List<LabInventory> inventories;
  final DashboardRepository repository;

  @override
  State<_GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<_GlobalSearchSheet> {
  late final TextEditingController _controller;
  late String _query;
  late final Future<List<LabRoom>> _roomsFuture;
  late Future<List<LabInventory>> _inventorySearchFuture;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: _query);
    _roomsFuture = widget.repository.fetchLaboratories();
    _inventorySearchFuture = widget.repository.searchInventories(_query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.44,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: FutureBuilder<List<LabRoom>>(
              future: _roomsFuture,
              builder: (context, snapshot) {
                final rooms = snapshot.data ?? const <LabRoom>[];
                return FutureBuilder<List<LabInventory>>(
                  future: _inventorySearchFuture,
                  builder: (context, inventorySnapshot) {
                    final remoteInventories =
                        inventorySnapshot.data ?? const <LabInventory>[];
                    final results = _buildSearchResults(
                      rooms,
                      remoteInventories,
                    );
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting ||
                        inventorySnapshot.connectionState ==
                            ConnectionState.waiting;
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
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
                        const SizedBox(height: 18),
                        Text(
                          'global_search'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          onChanged: _setQuery,
                          decoration: InputDecoration(
                            hintText: 'search_hint'.tr(),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                _controller.clear();
                                _setQuery('');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                ('tools_tag'.tr(), 'alat'),
                                ('rooms_tag'.tr(), 'ruangan'),
                                ('modules_tag'.tr(), 'modul'),
                                ('schedule_tag'.tr(), 'jadwal'),
                              ].map((tag) {
                                final selected =
                                    _query.toLowerCase() == tag.$2 ||
                                    _query.toLowerCase() ==
                                        tag.$1.toLowerCase();
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(tag.$1),
                                  onSelected: (_) {
                                    _controller.text = tag.$1;
                                    _setQuery(tag.$2);
                                  },
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 18),
                        if (loading)
                          const Center(child: CircularProgressIndicator())
                        else if (results.isEmpty)
                          _EmptyCard(text: 'search_empty'.tr())
                        else
                          ...results.map((result) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GlobalSearchResultTile(result: result),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _inventorySearchFuture = widget.repository.searchInventories(value);
    });
  }

  List<_GlobalSearchResult> _buildSearchResults(
    List<LabRoom> rooms,
    List<LabInventory> remoteInventories,
  ) {
    final normalized = _query.trim().toLowerCase();
    final query = normalized.isEmpty ? 'alat' : normalized;
    final results = <_GlobalSearchResult>[];

    bool matches(String value) => value.toLowerCase().contains(query);
    bool wantsTools = query == 'alat' || query == 'inventory';
    bool wantsRooms = query == 'ruangan' || query == 'room' || query == 'lab';
    bool wantsModules = query == 'modul' || query == 'module';

    final inventoriesById = <String, LabInventory>{
      for (final item in widget.inventories) item.id: item,
      for (final item in remoteInventories) item.id: item,
    };

    for (final inventory in inventoriesById.values) {
      final isRoom = inventory.isRoomStock;
      final shouldShow =
          matches(inventory.namaAlat) ||
          matches(inventory.type) ||
          matches(inventory.labId) ||
          (wantsTools && !isRoom) ||
          (wantsRooms && isRoom);
      if (!shouldShow) continue;
      results.add(
        _GlobalSearchResult(
          icon: isRoom ? Icons.meeting_room_outlined : Icons.inventory_2,
          title: inventory.namaAlat.capitalize(),
          subtitle: isRoom
              ? 'room_stock_label'.tr(
                  namedArgs: {'count': '${inventory.stokTersedia}'},
                )
              : 'tool_stock_label'.tr(
                  namedArgs: {
                    'available': '${inventory.stokTersedia}',
                    'total': '${inventory.totalStok}',
                  },
                ),
          tag: isRoom ? 'rooms_tag'.tr() : 'tools_tag'.tr(),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SaprasFacilityPage(repository: widget.repository),
              ),
            );
          },
        ),
      );
    }

    for (final room in rooms) {
      final shouldShow =
          matches(room.name) ||
          matches(room.location) ||
          matches(room.status) ||
          wantsRooms;
      if (!shouldShow) continue;
      results.add(
        _GlobalSearchResult(
          icon: Icons.location_city_outlined,
          title: room.name,
          subtitle: '${room.location} | ${room.status}',
          tag: 'rooms_tag'.tr(),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RoomSchedulePage(repository: widget.repository),
              ),
            );
          },
        ),
      );
    }

    for (final module in _searchableModules(widget.repository)) {
      final shouldShow =
          matches(module.title) || matches(module.subtitle) || wantsModules;
      if (!shouldShow) continue;
      results.add(
        _GlobalSearchResult(
          icon: module.icon,
          title: module.title,
          subtitle: module.subtitle,
          tag: 'modules_tag'.tr(),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => module.page));
          },
        ),
      );
    }

    return results.take(18).toList();
  }
}

class _GlobalSearchResult {
  const _GlobalSearchResult({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
}

class _GlobalSearchResultTile extends StatelessWidget {
  const _GlobalSearchResultTile({required this.result});

  final _GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: result.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppTheme.campusGradientOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(result.icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    result.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                result.tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableModule {
  const _SearchableModule({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget page;
}

List<_SearchableModule> _searchableModules(DashboardRepository repository) {
  return [
    _SearchableModule(
      icon: Icons.playlist_add_check_rounded,
      title: 'loan_form'.tr(),
      subtitle: 'fast_reservation'.tr(),
      page: BookingFormPage(repository: repository),
    ),
    _SearchableModule(
      icon: Icons.file_download_outlined,
      title: 'download_docs'.tr(),
      subtitle: 'cloud_docs'.tr(),
      page: DownloadDocsPage(repository: repository),
    ),
    _SearchableModule(
      icon: Icons.view_timeline_outlined,
      title: 'room_schedule'.tr(),
      subtitle: 'multi_lab_schedule'.tr(),
      page: RoomSchedulePage(repository: repository),
    ),
    _SearchableModule(
      icon: Icons.location_city_outlined,
      title: 'sapras_campus'.tr(),
      subtitle: 'campus_facility_catalog'.tr(),
      page: SaprasFacilityPage(repository: repository),
    ),
  ];
}
