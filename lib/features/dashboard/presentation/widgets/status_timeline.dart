import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.status});

  final String status;

  static const _steps = [
    ('pending', 'Pending'),
    ('approved_aslab', 'Approved Aslab'),
    ('approved_kalab', 'Approved Kalab'),
    ('active', 'Active'),
    ('returned', 'Returned'),
  ];

  @override
  Widget build(BuildContext context) {
    final activeIndex = _steps.indexWhere((step) => step.$1 == status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timeline Peminjaman',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...List.generate(_steps.length, (index) {
              final done = activeIndex >= index;
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
                    child: Text(
                      _steps[index].$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: done ? FontWeight.w800 : FontWeight.w500,
                        color: done ? AppTheme.ink : AppTheme.muted,
                      ),
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
