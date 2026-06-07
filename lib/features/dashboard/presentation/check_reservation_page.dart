import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_repository.dart';

class CheckReservationPage extends StatefulWidget {
  const CheckReservationPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<CheckReservationPage> createState() => _CheckReservationPageState();
}

class _CheckReservationPageState extends State<CheckReservationPage> {
  final _controller = TextEditingController();
  String _reservationNo = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cek Status Reservasi')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Lacak Reservasi',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan nomor reservasi format PMJ-XXXXX.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Nomor Reservasi',
                              hintText: 'PMJ-ABCDE',
                              prefixIcon: Icon(
                                Icons.confirmation_number_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => setState(
                              () => _reservationNo = _controller.text.trim(),
                            ),
                            icon: const Icon(Icons.search_rounded),
                            label: const Text('Cek Status'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_reservationNo.isNotEmpty)
                    StreamBuilder(
                      stream: widget.repository.watchReservation(
                        _reservationNo,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _StatusCard(
                            title: 'Gagal membaca reservasi',
                            subtitle: snapshot.error.toString(),
                            color: AppTheme.sepia,
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final bookings = snapshot.data!;
                        if (bookings.isEmpty) {
                          return const _StatusCard(
                            title: 'Reservasi tidak ditemukan',
                            subtitle:
                                'Periksa kembali nomor PMJ yang dimasukkan.',
                            color: AppTheme.richBronze,
                          );
                        }
                        final booking = bookings.first;
                        return _StatusCard(
                          title: booking.reservationNo,
                          subtitle: 'Status saat ini: ${booking.status}',
                          color: AppTheme.richBronze,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.circle, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
