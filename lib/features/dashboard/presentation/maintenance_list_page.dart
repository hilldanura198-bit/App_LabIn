import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class MaintenanceListPage extends StatefulWidget {
  const MaintenanceListPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  State<MaintenanceListPage> createState() => _MaintenanceListPageState();
}

class _MaintenanceListPageState extends State<MaintenanceListPage> {
  late final Stream<List<MaintenanceReportEntry>> _maintenanceStream;

  @override
  void initState() {
    super.initState();
    _maintenanceStream = widget.repository.watchMaintenanceReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Laporan Maintenance',
        showProfileAvatar: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: _MaintenanceListContent(
                repository: widget.repository,
                maintenanceStream: _maintenanceStream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceListContent extends StatelessWidget {
  const _MaintenanceListContent({
    required this.repository,
    required this.maintenanceStream,
  });

  final DashboardRepository repository;
  final Stream<List<MaintenanceReportEntry>> maintenanceStream;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: StreamBuilder<List<MaintenanceReportEntry>>(
          stream: maintenanceStream,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? const <MaintenanceReportEntry>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  icon: Icons.build_circle_outlined,
                  title: 'Laporan Maintenance Mahasiswa',
                  subtitle:
                      'Klik salah satu kartu untuk mengecek detail dan mengambil tindakan.',
                ),
                const SizedBox(height: 12),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (rows.isEmpty)
                  const _EmptyStateCard(
                    title: 'Belum ada laporan maintenance.',
                    subtitle:
                        'Mahasiswa belum mengirim laporan kerusakan pada data ini.',
                  )
                else
                  SizedBox(
                    height: 580,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == rows.length - 1 ? 0 : 12,
                          ),
                          child: _MaintenanceReportTile(
                            row: row,
                            campus: campus,
                            onTap: () => _openMaintenanceDetail(
                              context,
                              repository,
                              row,
                            ),
                          ),
                        );
                      },
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

class _MaintenanceReportTile extends StatelessWidget {
  const _MaintenanceReportTile({
    required this.row,
    required this.campus,
    required this.onTap,
  });

  final MaintenanceReportEntry row;
  final CampusThemeExtension campus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _maintenanceStatusColor(row.statusLabel, campus);
    final imageUrl = row.photoUrl;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                campus.primary.withValues(alpha: 0.06),
                campus.secondary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: campus.primary.withValues(alpha: 0.12)),
          ),
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textWidth = (constraints.maxWidth - 124)
                  .clamp(0.0, 9999.0)
                  .toDouble();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MaintenancePreview(imageUrl: imageUrl),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: textWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.inventoryName ?? row.inventoryId,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          row.reporterName == null
                              ? 'Pelapor: -'
                              : 'Pelapor: ${row.reporterName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoChip(
                              icon: Icons.schedule_rounded,
                              label: row.statusLabel,
                            ),
                            _InfoChip(
                              icon: Icons.person_outline,
                              label: row.reporterIdentity ?? '-',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            'Tap untuk buka detail laporan',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: campus.secondary),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MaintenancePreview extends StatelessWidget {
  const _MaintenancePreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.build_circle_outlined),
    );
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: placeholder,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 192,
          memCacheHeight: 192,
          filterQuality: FilterQuality.low,
          placeholder: (context, url) => placeholder,
          errorWidget: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}

Future<void> _openMaintenanceDetail(
  BuildContext context,
  DashboardRepository repository,
  MaintenanceReportEntry row,
) async {
  final noteController = TextEditingController();
  final result = await showModalBottomSheet<_MaintenanceActionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _MaintenanceDetailSheet(
        row: row,
        noteController: noteController,
        onApprove: () =>
            Navigator.of(sheetContext).pop(_MaintenanceActionResult.approve),
        onReject: () =>
            Navigator.of(sheetContext).pop(_MaintenanceActionResult.reject),
      );
    },
  );
  noteController.dispose();
  if (result == null || !context.mounted) {
    return;
  }
  try {
    if (result == _MaintenanceActionResult.approve) {
      await repository.acceptMaintenanceReport(row.id);
    } else {
      await repository.rejectMaintenanceReport(row.id);
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == _MaintenanceActionResult.approve
              ? 'Laporan maintenance diproses.'
              : 'Laporan maintenance ditolak.',
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

enum _MaintenanceActionResult { approve, reject }

class _MaintenanceDetailSheet extends StatelessWidget {
  const _MaintenanceDetailSheet({
    required this.row,
    required this.noteController,
    required this.onApprove,
    required this.onReject,
  });

  final MaintenanceReportEntry row;
  final TextEditingController noteController;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final campus = AppTheme.campusColorsOf(context);
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHandle(title: 'Detail Maintenance'),
              const SizedBox(height: 16),
              _MaintenancePreview(imageUrl: row.photoUrl),
              const SizedBox(height: 16),
              Text(
                row.inventoryName ?? row.inventoryId,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                row.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _DetailLine(
                icon: Icons.person_outline,
                label: 'Pelapor',
                value: row.reporterName ?? '-',
              ),
              _DetailLine(
                icon: Icons.badge_outlined,
                label: 'NIM',
                value: row.reporterIdentity ?? '-',
              ),
              _DetailLine(
                icon: Icons.schedule_rounded,
                label: 'Status',
                value: row.statusLabel,
              ),
              _DetailLine(
                icon: Icons.event_outlined,
                label: 'Dibuat',
                value: DateFormat('dd MMM yyyy HH:mm').format(row.createdAt),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Kalab',
                  hintText: 'Opsional, jelaskan tindak lanjut maintenance...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Ditolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.campusGradientOf(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                        ),
                        onPressed: onApprove,
                        icon: const Icon(Icons.done_rounded),
                        label: const Text('Diproses'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Status dan keterangan akan diteruskan ke mahasiswa melalui notifikasi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: campus.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppTheme.campusGradientOf(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: campus.primary.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 5,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

Color _maintenanceStatusColor(String status, CampusThemeExtension campus) {
  return switch (status.toLowerCase()) {
    'pending' => const Color(0xFFF59E0B),
    'diproses' => const Color(0xFF3B82F6),
    'selesai' => const Color(0xFF10B981),
    'ditolak' => const Color(0xFFEF4444),
    _ => campus.primary,
  };
}
