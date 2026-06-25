import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dashboard_repository.dart';

class RoomStockStreamBanner extends StatelessWidget {
  const RoomStockStreamBanner({super.key, required this.repository});

  final DashboardRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: repository.watchRoomStockTotal(),
      builder: (context, snapshot) {
        final totalAvailable = snapshot.data;
        final isAvailable = (totalAvailable ?? 0) > 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isAvailable
                ? AppTheme.campusGradientOf(context)
                : LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.outline,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            totalAvailable == null
                ? 'loading_room_stock'.tr()
                : 'rooms_stock_available'
                    .tr(namedArgs: {'count': '$totalAvailable'}),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}
