import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'aslab_detail_pengajuan_page.dart';
import 'settings_page.dart';
import 'widgets/glass_app_bar.dart';
import 'widgets/room_stock_stream_banner.dart';
import 'widgets/scan_page.dart';

class AslabDashboardPage extends StatelessWidget {
  const AslabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(
            DashboardRepository(context.read<AuthRepository>().client),
          )..add(
            const DashboardStarted(inventoryStream: false, bookingStream: true),
          ),
      child: const _AslabDashboardView(),
    );
  }
}

class _AslabDashboardView extends StatefulWidget {
  const _AslabDashboardView();

  @override
  State<_AslabDashboardView> createState() => _AslabDashboardViewState();
}

class _AslabDashboardViewState extends State<_AslabDashboardView> {
  late Future<List<Map<String, dynamic>>> _pendingFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pendingFuture = _fetchPendingBookings();
  }

  Future<List<Map<String, dynamic>>> _fetchPendingBookings() async {
    final client = context.read<AuthRepository>().client;
    if (client == null) {
      throw Exception('Sistem backend belum dikonfigurasi.');
    }
    final rows = await client
        .from('bookings')
        .select('*, profiles(nama, nim_nip), laboratories(name)')
        .eq('status', 'pending')
        .order('tanggal_pinjam');
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  void _refreshPending() {
    setState(() {
      _pendingFuture = _fetchPendingBookings();
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
          title: '${AppBrand.name} Aslab',
          showProfileAvatar: true,
          onProfilePressed: () => _openSettings(context),
          actions: [
            HeaderActionButton(
              tooltip: 'Scan QR',
              onPressed: () => _scanQr(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final active = state.bookings
                .where(
                  (booking) =>
                      booking.status == 'approved_kalab' ||
                      booking.status == 'active',
                )
                .toList();
            final repository = DashboardRepository(
              context.read<AuthRepository>().client,
            );

            return SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth >= 900
                      ? 760.0
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
                              future: _pendingFuture,
                              builder: (context, snapshot) {
                                final pending =
                                    snapshot.data ??
                                    const <Map<String, dynamic>>[];
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _AslabHero(
                                      pendingCount: pending.length,
                                      activeCount: active.length,
                                    ),
                                    const SizedBox(height: 16),
                                    RoomStockStreamBanner(
                                      repository: repository,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Daftar Pengajuan Pending',
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
                                    else if (pending.isEmpty)
                                      const _InfoCard(
                                        'Tidak ada antrean pending.',
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: pending.length,
                                        itemBuilder: (context, index) {
                                          final booking = pending[index];
                                          return _ApprovalRequestCard(
                                            booking: booking,
                                            onTap: () => _openApprovalDetail(
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
                            _ScannerPrompt(onScan: () => _scanQr(context)),
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

  Future<void> _scanQr(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanPage(title: 'Scan QR Pass')),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final repository = DashboardRepository(
      context.read<AuthRepository>().client,
    );
    try {
      final booking = await repository.fetchBookingForQr(result);
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => _QrHandoverSheet(
          booking: booking,
          onConfirm: () async {
            await repository.confirmItemHandover(booking.id);
            if (!context.mounted) return;
            context.read<DashboardBloc>().add(
              const DashboardStarted(
                inventoryStream: false,
                bookingStream: true,
              ),
            );
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Serah terima barang berhasil dikonfirmasi.'),
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
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

  Future<void> _openApprovalDetail(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AslabDetailPengajuanPage(
          booking: booking,
          repository: DashboardRepository(
            context.read<AuthRepository>().client,
          ),
        ),
      ),
    );
    if (result != null && context.mounted) {
      _refreshPending();
      context.read<DashboardBloc>().add(
        const DashboardStarted(inventoryStream: false, bookingStream: true),
      );
    }
  }
}

class _QrHandoverSheet extends StatefulWidget {
  const _QrHandoverSheet({required this.booking, required this.onConfirm});

  final LabBooking booking;
  final Future<void> Function() onConfirm;

  @override
  State<_QrHandoverSheet> createState() => _QrHandoverSheetState();
}

class _QrHandoverSheetState extends State<_QrHandoverSheet> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bukti Pengambilan Barang',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _SheetInfoRow(
                label: 'Nama Peminjam',
                value: booking.borrowerName,
              ),
              _SheetInfoRow(
                label: 'NIM',
                value: booking.borrowerIdentity?.trim().isNotEmpty == true
                    ? booking.borrowerIdentity!
                    : '-',
              ),
              _SheetInfoRow(
                label: 'Nomor Reservasi',
                value: booking.reservationNo,
              ),
              const SizedBox(height: 12),
              Text(
                'Daftar Item',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              if (booking.itemsSnapshot.isEmpty)
                const Text('Tidak ada item tercatat.')
              else
                ...booking.itemsSnapshot.map(
                  (item) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(item.name),
                    trailing: Text(
                      'x${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _confirm,
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.handshake_outlined),
                label: const Text('Konfirmasi Serah Terima Barang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    try {
      setState(() => _submitting = true);
      await widget.onConfirm();
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _SheetInfoRow extends StatelessWidget {
  const _SheetInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AslabHero extends StatelessWidget {
  const _AslabHero({required this.pendingCount, required this.activeCount});

  final int pendingCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, size: 42),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingCount pending approval',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text('$activeCount tiket siap scan/check-out'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalRequestCard extends StatelessWidget {
  const _ApprovalRequestCard({required this.booking, required this.onTap});

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
    final items = _itemsFromBooking(booking);
    final itemCount = items.length;
    final itemLabel = itemCount == 0 ? 'Tidak ada barang' : '$itemCount barang';
    final borrowerName = _firstNotEmpty([
      profile['nama'],
      booking['borrower_name'],
      'Unknown',
    ]);
    final nim = _firstNotEmpty([profile['nim_nip'], '-']);
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
                      const _PendingBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM $nim',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CompactInfo(
                          icon: Icons.meeting_room_outlined,
                          label: 'Laboratorium',
                          value: labName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactInfo(
                          icon: Icons.event_note_outlined,
                          label: 'Tanggal',
                          value: date,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _CompactInfo(
                    icon: Icons.schedule_rounded,
                    label: 'Waktu',
                    value: '$start - $end | $itemLabel',
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

  static List<Object?> _itemsFromBooking(Map<String, dynamic> booking) {
    final value = booking['items'] ?? booking['items_snapshot'];
    if (value is List) return value;
    return const [];
  }

  static String _firstNotEmpty(List<Object?> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '-';
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB020).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFFB020).withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pending_actions_rounded,
            color: Color(0xFFB45309),
            size: 16,
          ),
          SizedBox(width: 5),
          Text(
            'Pending',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
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

class _ScannerPrompt extends StatelessWidget {
  const _ScannerPrompt({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QR Code Scanner Mode',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan QR mahasiswa untuk mengubah status Approved Kalab menjadi Active, atau Active menjadi Returned.',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Buka Scanner'),
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
