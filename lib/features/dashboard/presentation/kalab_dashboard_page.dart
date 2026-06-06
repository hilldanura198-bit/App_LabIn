import 'package:flutter/material.dart';

import 'widgets/dashboard_shell.dart';

class KalabDashboardPage extends StatelessWidget {
  const KalabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Dashboard Kalab',
      subtitle: 'Kelola persetujuan akhir, lab, dan kepatuhan pengguna.',
      stats: [
        DashboardStat(label: 'Approval', value: '5'),
        DashboardStat(label: 'Lab Aktif', value: '6'),
        DashboardStat(label: 'Denda', value: '12'),
      ],
      actions: [
        DashboardAction(
          icon: Icons.verified_user_outlined,
          title: 'Approval Kalab',
          description: 'Tinjau pengajuan yang membutuhkan persetujuan akhir.',
        ),
        DashboardAction(
          icon: Icons.science_outlined,
          title: 'Manajemen Lab',
          description: 'Pantau status operasional laboratorium.',
        ),
        DashboardAction(
          icon: Icons.analytics_outlined,
          title: 'Kepatuhan',
          description: 'Lihat skor kepatuhan dan akumulasi denda.',
        ),
      ],
    );
  }
}
