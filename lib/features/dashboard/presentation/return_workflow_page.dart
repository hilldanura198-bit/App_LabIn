import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class ReturnWorkflowPage extends StatelessWidget {
  const ReturnWorkflowPage({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });

  final DashboardRepository repository;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? const GlassAppBar(title: 'Pengembalian Alat') : null,
      body: SafeArea(
        child: StreamBuilder<List<LabBooking>>(
          stream: repository.watchReturnableBookings(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final bookings = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (bookings.isEmpty)
                          const _EmptyReturnQueue()
                        else
                          ...bookings.map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReturnBookingCard(
                                booking: booking,
                                repository: repository,
                              ),
                            ),
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

class _ReturnBookingCard extends StatelessWidget {
  const _ReturnBookingCard({required this.booking, required this.repository});

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    final schedule = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(booking.tanggalPinjam);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openChecklist(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.deepTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_return_rounded,
                  color: AppTheme.deepTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.borrowerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${booking.reservationNo} | $schedule',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openChecklist(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ReturnChecklistSheet(booking: booking, repository: repository),
    );
  }
}

class _ReturnChecklistSheet extends StatefulWidget {
  const _ReturnChecklistSheet({
    required this.booking,
    required this.repository,
  });

  final LabBooking booking;
  final DashboardRepository repository;

  @override
  State<_ReturnChecklistSheet> createState() => _ReturnChecklistSheetState();
}

class _ReturnChecklistSheetState extends State<_ReturnChecklistSheet> {
  final Map<String, TextEditingController> _controllers = {};
  String _condition = 'bagus';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.booking.itemsSnapshot) {
      final key = item.inventoryId ?? item.name;
      _controllers[key] = TextEditingController(text: '${item.quantity}');
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Validasi Pengembalian',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...widget.booking.itemsSnapshot.map((item) {
              final key = item.inventoryId ?? item.name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _controllers[key],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: item.name,
                    helperText:
                        'Harus sama dengan kuantitas pinjam: ${item.quantity}',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
              );
            }),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: const InputDecoration(
                labelText: 'Kondisi fisik',
                prefixIcon: Icon(Icons.health_and_safety_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'bagus', child: Text('Bagus')),
                DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _condition = value ?? 'bagus'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Pengembalian'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final quantities = <String, int>{};
    for (final item in widget.booking.itemsSnapshot) {
      final inventoryId = item.inventoryId;
      if (inventoryId == null || inventoryId.isEmpty) continue;
      quantities[inventoryId] =
          int.tryParse(_controllers[inventoryId]?.text ?? '') ?? 0;
    }
    try {
      setState(() => _submitting = true);
      await widget.repository.confirmReturnChecklist(
        bookingId: widget.booking.id,
        returnedQuantities: quantities,
        condition: _condition,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengembalian berhasil dikonfirmasi.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}

class _EmptyReturnQueue extends StatelessWidget {
  const _EmptyReturnQueue();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 44),
            const SizedBox(height: 10),
            Text(
              'Belum ada peminjaman aktif untuk dikembalikan.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
