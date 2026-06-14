import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';
import 'booking_form_page.dart';
import 'check_reservation_page.dart';
import 'settings_page.dart';
import 'widgets/glass_app_bar.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GlassAppBar(title: 'Notifikasi Real-Time'),
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: repository.watchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return const Center(
                child: Text('Belum ada notifikasi realtime.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () async {
                    await repository.markNotificationRead(notification.id);
                    if (!context.mounted) return;
                    _openTarget(context, notification);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openTarget(BuildContext context, AppNotification notification) {
    if (notification.targetType == 'booking') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckReservationPage(
            repository: repository,
            initialQuery: notification.targetId,
          ),
        ),
      );
      return;
    }
    if (notification.targetType == 'profile') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SettingsPage(repository: repository)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingFormPage(repository: repository),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _kindColor(notification.kind);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_kindIcon(notification.kind), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.electricBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime createdAt) {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString();
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  static Color _kindColor(String kind) {
    return switch (kind) {
      'booking_status' => AppTheme.emerald,
      'booking_created' => AppTheme.electricBlue,
      'profile_update' => AppTheme.vibrantPurple,
      'maintenance_report' => AppTheme.richBronze,
      'feedback' => AppTheme.deepTeal,
      _ => AppTheme.muted,
    };
  }

  static IconData _kindIcon(String kind) {
    return switch (kind) {
      'booking_status' => Icons.verified_user_outlined,
      'booking_created' => Icons.receipt_long_outlined,
      'profile_update' => Icons.person_outline,
      'maintenance_report' => Icons.build_circle_outlined,
      'feedback' => Icons.star_outline_rounded,
      _ => Icons.notifications_outlined,
    };
  }
}
