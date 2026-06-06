import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/busy_meter.dart';
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

class _MahasiswaDashboardView extends StatelessWidget {
  const _MahasiswaDashboardView();

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
        appBar: AppBar(
          title: const Text('LabIN Mahasiswa'),
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
          ],
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
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
                              _StockCalendar(state: state),
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
                                StatusTimeline(
                                  status: state.latestBooking!.status,
                                ),
                                const SizedBox(height: 16),
                              ],
                              BusyMeter(hours: state.busyHours),
                              const SizedBox(height: 16),
                              _MaintenanceReport(
                                inventories: state.inventories,
                              ),
                            ],
                          ),
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
    final stockColor = totalAvailable > 0 ? Colors.green : Colors.red;
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
                  color: inventory.isAvailable ? Colors.green : Colors.red,
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
