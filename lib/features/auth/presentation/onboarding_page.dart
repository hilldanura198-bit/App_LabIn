import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _backgroundImage =
      'https://images.unsplash.com/photo-1581093588401-fbb62a02f120'
      '?auto=format&fit=crop&w=1400&q=80';

  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _OnboardingSlideData(
      title: 'SIMLAB Terpadu',
      description:
          'Kelola aktivitas laboratorium, inventaris, dan reservasi ruangan dalam satu pengalaman mobile yang cepat.',
      icon: Icons.hub_outlined,
    ),
    _OnboardingSlideData(
      title: 'Reservasi Lebih Presisi',
      description:
          'Cek ketersediaan ruang dan alat secara real-time, lalu pantau approval tanpa alur manual yang melelahkan.',
      icon: Icons.event_available_outlined,
    ),
    _OnboardingSlideData(
      title: 'Dokumen & Riwayat Aman',
      description:
          'Simpan bukti peminjaman, timeline penggunaan, dan laporan kondisi aset dengan akses yang rapi.',
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          _BlurredLaboratoryBackground(imageUrl: _backgroundImage),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth >= 760
                    ? 520.0
                    : constraints.maxWidth;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandLockup(),
                          const Spacer(),
                          _GlassOnboardingPanel(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: constraints.maxHeight < 640
                                      ? 260
                                      : 330,
                                  child: PageView.builder(
                                    controller: _controller,
                                    itemCount: _slides.length,
                                    onPageChanged: (value) =>
                                        setState(() => _index = value),
                                    itemBuilder: (context, index) {
                                      return _OnboardingSlide(
                                        data: _slides[index],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _OnboardingDots(
                                  activeIndex: _index,
                                  length: _slides.length,
                                ),
                                const SizedBox(height: 24),
                                CyberGradientButton(
                                  onPressed: () {
                                    if (isLast) {
                                      widget.onFinished();
                                      return;
                                    }
                                    _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 320,
                                      ),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isLast ? 'Mulai Sekarang' : 'Lanjut',
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredLaboratoryBackground extends StatelessWidget {
  const _BlurredLaboratoryBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.cyberGradient),
              );
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.deepSpace.withValues(alpha: 0.72),
                AppTheme.electricBlue.withValues(alpha: 0.32),
                AppTheme.vibrantPurple.withValues(alpha: 0.48),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: AppTheme.cyberGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricBlue.withValues(alpha: 0.36),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.science_outlined,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'LabIN',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                color: Color(0x80000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
        Text(
          'Laboratory Intelligence System',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GlassOnboardingPanel extends StatelessWidget {
  const _GlassOnboardingPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.30),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 34,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
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
          width: activeIndex == index ? 30 : 9,
          height: 9,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: activeIndex == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});

  final _OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                gradient: AppTheme.cyberGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              ),
              child: Icon(data.icon, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 22),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.90),
                fontWeight: FontWeight.w500,
                height: 1.42,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
