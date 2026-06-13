import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_models.dart';

class BusyMeter extends StatelessWidget {
  const BusyMeter({super.key, required this.hours});

  final List<BusyHour> hours;

  @override
  Widget build(BuildContext context) {
    final maxCount = hours.isEmpty
        ? 1
        : hours.map((hour) => hour.count).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lab Busy Meter',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (hours.isEmpty)
              Text(
                'Belum ada riwayat transaksi untuk prediksi jam sibuk.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
              )
            else
              ...hours.map(
                (hour) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 54, child: Text('${hour.hour}:00')),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: LinearProgressIndicator(
                            value: hour.count / maxCount,
                            minHeight: 14,
                            backgroundColor: AppTheme.richBronze.withValues(
                              alpha: 0.16,
                            ),
                            color: AppTheme.cleanCyan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${hour.count}x'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
