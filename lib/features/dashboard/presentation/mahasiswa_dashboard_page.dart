import 'package:flutter/material.dart';

import 'widgets/dashboard_shell.dart';

class MahasiswaDashboardPage extends StatelessWidget {
  const MahasiswaDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      title: 'Dashboard Mahasiswa',
      subtitle: 'Pantau peminjaman, jadwal, dan laporan lab.',
      stats: [
        DashboardStat(label: 'Pengajuan', value: '2'),
        DashboardStat(label: 'Aktif', value: '1'),
        DashboardStat(label: 'Skor', value: '100'),
      ],
      actions: [
        DashboardAction(
          icon: Icons.inventory_2_outlined,
          title: 'Inventaris',
          description: 'Cek alat yang tersedia untuk dipinjam.',
        ),
        DashboardAction(
          icon: Icons.event_available_outlined,
          title: 'Ajukan Peminjaman',
          description: 'Buat permintaan alat atau ruang lab.',
        ),
        DashboardAction(
          icon: Icons.report_problem_outlined,
          title: 'Lapor Kerusakan',
          description: 'Kirim laporan kondisi alat atau fasilitas.',
        ),
      ],
    );
  }
}
