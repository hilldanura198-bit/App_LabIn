import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.bottom,
    this.leading,
    this.showProfileAvatar = false,
    this.onProfilePressed,
  });

  final String title;
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
    return AppBar(
      leading: leading,
      title: Text(title, textAlign: TextAlign.center),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: foreground,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).scaffoldBackgroundColor.withValues(alpha: 0.74),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.electricBlue.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        ...actions,
        if (showProfileAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
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
                      color: AppTheme.vibrantPurple.withValues(alpha: 0.26),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
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
          )
        else
          const SizedBox(width: 8),
      ],
      bottom: bottom,
    );
  }
}
