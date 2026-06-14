import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/data/auth_repository.dart';
import '../bloc/dashboard_bloc.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'widgets/glass_app_bar.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(
            DashboardRepository(context.read<AuthRepository>().client),
          )..add(
            const DashboardStarted(inventoryStream: true, bookingStream: true),
          ),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Admin',
        showProfileAvatar: true,
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.isLoading && state.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingCount = state.bookings
              .where((booking) => booking.status == 'pending')
              .length;
          final approvedCount = state.bookings
              .where((booking) => booking.statusLabel == 'Approved')
              .length;
          final criticalCount = state.criticalInventories.length;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DashboardBloc>().add(
                const DashboardStarted(
                  inventoryStream: true,
                  bookingStream: true,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _AdminStatCard(
                      label: 'Pengajuan Pending',
                      value: '$pendingCount',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFFFB020),
                    ),
                    _AdminStatCard(
                      label: 'Disetujui',
                      value: '$approvedCount',
                      icon: Icons.verified_rounded,
                      color: AppTheme.emerald,
                    ),
                    _AdminStatCard(
                      label: 'Stok Kritis',
                      value: '$criticalCount',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.vibrantPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Dashboard Utama Admin',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau semua transaksi real-time, stok lab, dan jalur approval Aslab/Kalab dari satu panel.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _BookingQueue(bookings: state.bookings),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 760
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 480
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.22),
                AppTheme.electricBlue.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BookingQueue extends StatelessWidget {
  const _BookingQueue({required this.bookings});

  final List<LabBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final recentBookings = bookings.take(8).toList();
    if (recentBookings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'Belum ada transaksi peminjaman yang masuk.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Antrian Transaksi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...recentBookings.map(
              (booking) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: booking.statusColor.withValues(alpha: 0.18),
                  child: Icon(
                    _statusIcon(booking.status),
                    color: booking.statusColor,
                  ),
                ),
                title: Text(
                  booking.reservationNo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${booking.labId} • ${booking.statusLabel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Chip(
                  label: Text(booking.statusLabel),
                  backgroundColor: booking.statusColor.withValues(alpha: 0.16),
                  side: BorderSide(color: booking.statusColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'approved_aslab':
      case 'approved_kalab':
        return Icons.verified_user_rounded;
      case 'active':
        return Icons.directions_run_rounded;
      case 'returned':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
