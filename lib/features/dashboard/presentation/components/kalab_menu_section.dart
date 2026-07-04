import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_repository.dart';
import '../kalab_daily_report_page.dart';
import '../kalab_inventory_crud_page.dart';
import '../maintenance_list_page.dart';
import '../kalab_user_management_page.dart';
import '../room_schedule_page.dart';

class KalabMenuSection extends StatelessWidget {
  const KalabMenuSection({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    final campus = AppTheme.campusColorsOf(context);
    final actions = <_KalabMenuAction>[
      _KalabMenuAction(
        icon: Icons.inventory_2_outlined,
        title: 'CRUD Sarpras',
        subtitle: 'Kelola inventaris alat dan ruangan',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabInventoryCrudPage(repository: repository),
          ),
        ),
      ),
      _KalabMenuAction(
        icon: Icons.manage_accounts_outlined,
        title: 'Kontrol User',
        subtitle: 'Verifikasi dan pantau akun pengguna',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabUserManagementPage(repository: repository),
          ),
        ),
      ),
      _KalabMenuAction(
        icon: Icons.meeting_room_outlined,
        title: 'Jadwal Ruangan',
        subtitle: 'Cek penggunaan dan ketersediaan ruang',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RoomSchedulePage(repository: repository),
          ),
        ),
      ),
      _KalabMenuAction(
        icon: Icons.analytics_outlined,
        title: 'Laporan Peminjaman',
        subtitle: 'Ringkasan transaksi dan aktivitas lab',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => KalabDailyReportPage(repository: repository),
          ),
        ),
      ),
      _KalabMenuAction(
        icon: Icons.handyman_outlined,
        title: 'Laporan Maintenance',
        subtitle: 'Cek laporan kerusakan dan tindak lanjuti',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MaintenanceListPage(repository: repository),
          ),
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.campusGradientOf(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.dashboard_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: campus.gradient.createShader,
                        child: Text(
                          'Menu Kalab',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Akses cepat ke fitur inti pengelolaan laboratorium.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 620
                    ? 2
                    : 1;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: columns == 1 ? 3.8 : 2.6,
                  children: actions
                      .map(
                        (action) =>
                            _KalabMenuCard(action: action, campus: campus),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KalabMenuCard extends StatelessWidget {
  const _KalabMenuCard({required this.action, required this.campus});

  final _KalabMenuAction action;
  final CampusThemeExtension campus;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: campus.primary.withValues(alpha: 0.12)),
            color: campus.primary.withValues(alpha: 0.04),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.campusGradientOf(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: campus.gradient.createShader,
                      child: Text(
                        action.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: campus.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _KalabMenuAction {
  const _KalabMenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}
