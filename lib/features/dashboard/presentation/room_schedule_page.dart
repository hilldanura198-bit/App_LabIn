import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class RoomSchedulePage extends StatefulWidget {
  const RoomSchedulePage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<RoomSchedulePage> createState() => _RoomSchedulePageState();
}

class _RoomSchedulePageState extends State<RoomSchedulePage> {
  late Future<List<LabRoom>> _roomsFuture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _roomsFuture = widget.repository.fetchLaboratories();
  }

  void _refresh() {
    setState(() {
      _roomsFuture = widget.repository.fetchLaboratories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Atur Ketersediaan Ruangan Lab'),
      body: SafeArea(
        child: FutureBuilder<List<LabRoom>>(
          future: _roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rooms = snapshot.data!
                .where((room) => room.status.isNotEmpty)
                .toList();
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
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
                                    'Kontrol Operasional Ruangan',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Gunakan switch untuk membuka atau menutup akses ruangan lab secara cepat.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...rooms.map(
                            (room) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoomControlCard(
                                room: room,
                                repository: widget.repository,
                                isBusy: _loading,
                                onChanged: () {
                                  setState(() => _loading = true);
                                  _refresh();
                                  setState(() => _loading = false);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoomControlCard extends StatelessWidget {
  const _RoomControlCard({
    required this.room,
    required this.repository,
    required this.onChanged,
    required this.isBusy,
  });

  final LabRoom room;
  final DashboardRepository repository;
  final VoidCallback onChanged;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isOpen = room.status == 'aktif';
    final statusColor = isOpen ? AppTheme.emerald : AppTheme.richBronze;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isOpen ? Icons.meeting_room_outlined : Icons.lock_outline,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.location,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Switch.adaptive(
                  value: isOpen,
                  onChanged: isBusy
                      ? null
                      : (value) async {
                          await repository.updateLaboratoryStatus(
                            laboratoryId: room.id,
                            isOpen: value,
                          );
                          onChanged();
                        },
                ),
                Text(
                  isOpen ? 'Buka Lab' : 'Tutup Lab',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
