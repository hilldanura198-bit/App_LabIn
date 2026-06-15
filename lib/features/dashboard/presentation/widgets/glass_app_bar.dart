import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions = const [],
    this.bottom,
    this.leading,
    this.showProfileAvatar = false,
    this.onProfilePressed,
  });

  final String title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final bool showProfileAvatar;
  final VoidCallback? onProfilePressed;

  @override
  Size get preferredSize {
    return Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final hasTrailingControls = actions.isNotEmpty || showProfileAvatar;

    return AppBar(
      leading: leading,
      title: const SizedBox.shrink(),
      titleSpacing: 0,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: foreground,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
      actions: hasTrailingControls
          ? [
              SizedBox(
                width: MediaQuery.sizeOf(context).width,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ...actions,
                        if (showProfileAvatar)
                          IconButton(
                            tooltip: 'Profil',
                            onPressed: onProfilePressed,
                            icon: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.cyberGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.vibrantPurple.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ]
          : null,
      bottom: bottom,
    );
  }
}
