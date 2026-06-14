import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_models.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, this.booking, this.status})
    : assert(booking != null || status != null);

  final LabBooking? booking;
  final String? status;

  static const _steps = [
    ('pending', 'Pending'),
    ('approved_aslab', 'Approved Aslab'),
    ('approved_kalab', 'Approved Kalab'),
    ('active', 'Active'),
    ('returned', 'Returned'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStatus = booking?.status ?? status ?? 'pending';
    final activeIndex = _steps.indexWhere((step) => step.$1 == currentStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline_outlined,
                  color: AppTheme.electricBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  'Timeline Peminjaman',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Status mengikuti perubahan real-time dari dashboard admin.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            ...List.generate(_steps.length, (index) {
              final done = activeIndex >= index;
              final stepStatus = _steps[index].$2;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.emerald
                              : AppTheme.richBronze.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: done
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      if (index != _steps.length - 1)
                        Container(
                          width: 2,
                          height: 30,
                          color: done
                              ? AppTheme.emerald
                              : AppTheme.richBronze.withValues(alpha: 0.18),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stepStatus,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: done
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: done ? AppTheme.ink : AppTheme.muted,
                              ),
                        ),
                        if (booking != null && done && index == activeIndex)
                          Text(
                            booking!.reservationNo,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
