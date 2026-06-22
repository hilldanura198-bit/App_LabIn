import 'package:flutter/material.dart';

import '../../../core/brand.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingSlideData(
      headline: 'Inventaris lab dalam satu ruang digital.',
      description:
          'Pantau ruang, alat, dan status peminjaman dengan visual yang rapi dan mudah dipahami.',
      icon: Icons.inventory_2_outlined,
    ),
    _OnboardingSlideData(
      headline: 'Reservasi cepat, approval lebih jelas.',
      description:
          'Ajukan kebutuhan lab, cek ketersediaan, dan ikuti progres persetujuan secara real-time.',
      icon: Icons.event_available_outlined,
    ),
    _OnboardingSlideData(
      headline: 'Riwayat dan dokumen tertata aman.',
      description:
          'Simpan bukti peminjaman, timeline, dan catatan kondisi aset dalam alur yang terhubung.',
      icon: Icons.verified_user_outlined,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFEAF1FF), Color(0xFFF7F2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth >= 760
                  ? 500.0
                  : constraints.maxWidth;
              final compact = constraints.maxHeight < 700;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      compact ? 12 : 22,
                      22,
                      compact ? 16 : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandIntro(compact: compact),
                        SizedBox(height: compact ? 12 : 20),
                        Expanded(
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: _slides.length,
                            onPageChanged: (value) =>
                                setState(() => _index = value),
                            itemBuilder: (context, index) {
                              return _OnboardingSlide(
                                data: _slides[index],
                                index: index,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        _OnboardingDots(
                          activeIndex: _index,
                          length: _slides.length,
                        ),
                        SizedBox(height: compact ? 14 : 22),
                        CyberGradientButton(
                          onPressed: () {
                            if (isLast) {
                              widget.onFinished();
                              return;
                            }
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 330),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          borderRadius: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isLast ? 'Mulai Sekarang' : 'Lanjut'),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandIntro extends StatelessWidget {
  const _BrandIntro({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 64.0 : 78.0;
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 14 : 18,
        18,
        compact ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricBlue.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            padding: EdgeInsets.all(compact ? 8 : 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 22 : 26),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricBlue.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 16 : 20),
              child: Image.asset(
                'assets/images/labin.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            AppBrand.name,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? Theme.of(context).textTheme.headlineSmall
                        : Theme.of(context).textTheme.headlineMedium)
                    ?.copyWith(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            AppBrand.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.muted,
              fontWeight: FontWeight.w800,
              height: 1.38,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.headline,
    required this.description,
    required this.icon,
  });

  final String headline;
  final String description;
  final IconData icon;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data, required this.index});

  final _OnboardingSlideData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricBlue.withValues(alpha: 0.12),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxHeight < 390;
            final iconBox = tight ? 48.0 : 58.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _InventoryTechIllustration(activeIndex: index),
                  ),
                ),
                SizedBox(height: tight ? 12 : 18),
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cyberGradient,
                    borderRadius: BorderRadius.circular(tight ? 17 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.vibrantPurple.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: tight ? 25 : 30,
                  ),
                ),
                SizedBox(height: tight ? 12 : 18),
                Text(
                  data.headline,
                  textAlign: TextAlign.center,
                  style:
                      (tight
                              ? Theme.of(context).textTheme.titleMedium
                              : Theme.of(context).textTheme.titleLarge)
                          ?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w900,
                            height: 1.18,
                          ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  maxLines: tight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.48,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InventoryTechIllustration extends StatelessWidget {
  const _InventoryTechIllustration({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 48;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : availableWidth;
        final rawSize = availableWidth < availableHeight
            ? availableWidth
            : availableHeight;
        final size = rawSize.clamp(0.0, 250.0);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: size * 0.04,
                  child: Container(
                    width: size * 0.86,
                    height: size * 0.16,
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  top: size * 0.18,
                  left: size * 0.14,
                  right: size * 0.14,
                  bottom: size * 0.18,
                  child: Transform.rotate(
                    angle: -0.10,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFFFFF), Color(0xFFEAF2FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE1E9FF)),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepSpace.withValues(alpha: 0.10),
                            blurRadius: 28,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size * 0.28,
                  left: size * 0.25,
                  right: size * 0.25,
                  child: Column(
                    children: List.generate(
                      3,
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (col) => _InventoryCube(
                              color: _cubeColor(row, col, activeIndex),
                              small: row == 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: size * 0.08,
                  top: size * 0.20,
                  child: _FloatingBadge(
                    icon: Icons.qr_code_2_rounded,
                    color: AppTheme.vibrantPurple,
                  ),
                ),
                Positioned(
                  left: size * 0.08,
                  bottom: size * 0.24,
                  child: _FloatingBadge(
                    icon: Icons.wifi_tethering_rounded,
                    color: AppTheme.electricBlue,
                  ),
                ),
                Positioned(
                  right: size * 0.18,
                  bottom: size * 0.18,
                  child: Container(
                    width: size * 0.26,
                    height: size * 0.34,
                    decoration: BoxDecoration(
                      color: AppTheme.ink,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.deepSpace.withValues(alpha: 0.20),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.cyberGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _cubeColor(int row, int col, int activeIndex) {
    final colors = [
      AppTheme.electricBlue,
      AppTheme.vibrantPurple,
      const Color(0xFF22C55E),
    ];
    return colors[(row + col + activeIndex) % colors.length];
  }
}

class _InventoryCube extends StatelessWidget {
  const _InventoryCube({required this.color, required this.small});

  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 24.0 : 30.0;
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.82), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 25),
    );
  }
}

class _OnboardingDots extends StatelessWidget {
  const _OnboardingDots({required this.activeIndex, required this.length});

  final int activeIndex;
  final int length;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: activeIndex == index ? 32 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: activeIndex == index ? AppTheme.cyberGradient : null,
            color: activeIndex == index ? null : const Color(0xFFD6E0F7),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
