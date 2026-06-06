import 'package:flutter/material.dart';

import 'widgets/dashboard_shell.dart';

class AslabDashboardPage extends StatelessWidget {
  const AslabDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Dashboard Aslab',
      subtitle: 'Validasi peminjaman dan pantau kondisi inventaris.',
      stats: [
        DashboardStat(label: 'Pending', value: '8'),
        DashboardStat(label: 'Aktif', value: '4'),
        DashboardStat(label: 'Laporan', value: '3'),
      ],
      actions: [
        DashboardAction(
          icon: Icons.fact_check_outlined,
          title: 'Validasi Pengajuan',
          description: 'Setujui atau tolak permintaan mahasiswa.',
        ),
        DashboardAction(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan QR',
          description: 'Verifikasi pengambilan dan pengembalian alat.',
        ),
        DashboardAction(
          icon: Icons.build_outlined,
          title: 'Cek Kerusakan',
          description: 'Tinjau laporan perawatan yang masuk.',
        ),
      ],
    );
  }
}
