import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_models.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, this.booking, this.status})
    : assert(booking != null || status != null);

  final LabBooking? booking;
  final String? status;

  static const _steps = [
    ('pending', 'status_pending'),
    ('approved_aslab', 'status_approved_aslab'),
    ('approved_kalab', 'status_approved_kalab'),
    ('active', 'status_active'),
    ('returned', 'status_returned'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStatus = booking?.status ?? status ?? 'pending';
    final currentIndex = _steps.indexWhere((step) => step.$1 == currentStatus);
    final doneIndex = currentStatus == 'approved_kalab'
        ? _steps.length - 1
        : currentIndex;
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
                  'timeline_title'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'timeline_subtitle'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 14),
            ...List.generate(_steps.length, (index) {
              final done = doneIndex >= index;
              final stepStatus = _steps[index].$2.tr();
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
                  Expanded(
                    child: Padding(
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
                          if (booking != null && done && index == currentIndex)
                            Text(
                              booking!.reservationNo,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (booking != null && _canRenderQr(currentStatus)) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showQrDialog(context, booking!),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text('view_qr_scan'.tr()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canRenderQr(String status) {
    return switch (status) {
      'approved_kalab' || 'active' || 'returned' || 'late' => true,
      _ => false,
    };
  }

  Future<void> _showQrDialog(BuildContext context, LabBooking booking) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricBlue.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'qr_scan_title'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: AppTheme.vibrantPurple,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.reservationNo,
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: QrImageView(
                      data: booking.id,
                      version: QrVersions.auto,
                      size: 224,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.cyberGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text('scan_qr_code'.tr()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
