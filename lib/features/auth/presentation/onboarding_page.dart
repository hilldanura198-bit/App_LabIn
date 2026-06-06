import 'package:flutter/material.dart';

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
      title: 'Manajemen Inventaris Terpadu',
      description:
          'Pantau stok alat, kondisi aset, dan laporan kerusakan dalam satu ruang kerja yang rapi.',
      icon: Icons.inventory_2_outlined,
    ),
    _OnboardingSlideData(
      title: 'Peminjaman Alat & Ruangan Real-time',
      description:
          'Ajukan reservasi, cek ketersediaan, dan ikuti progres approval tanpa refresh manual.',
      icon: Icons.event_available_outlined,
    ),
    _OnboardingSlideData(
      title: 'Riwayat & Pelaporan Lengkap',
      description:
          'Unduh dokumen izin, lihat timeline, dan kirim bukti maintenance langsung dari kamera.',
      icon: Icons.assignment_turned_in_outlined,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth >= 760
                ? 520.0
                : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'LabIN',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.deepTeal,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: _slides.length,
                          onPageChanged: (value) =>
                              setState(() => _index = value),
                          itemBuilder: (context, index) {
                            return _OnboardingSlide(data: _slides[index]);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: _index == index ? 28 : 9,
                            height: 9,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _index == index
                                  ? AppTheme.deepTeal
                                  : const Color(0xFFCFE0DB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () {
                          if (isLast) {
                            widget.onFinished();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                        child: Text(isLast ? 'Mulai Sekarang' : 'Lanjut'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final artSize = constraints.maxHeight < 470 ? 180.0 : 250.0;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: artSize,
                  height: artSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F2),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(88),
                      topRight: Radius.circular(32),
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(88),
                    ),
                    border: Border.all(color: const Color(0xFFC9E8DE)),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 28,
                        top: 28,
                        child: Icon(
                          Icons.circle,
                          color: AppTheme.cleanCyan.withValues(alpha: 0.42),
                          size: 36,
                        ),
                      ),
                      Container(
                        width: artSize * 0.48,
                        height: artSize * 0.48,
                        decoration: BoxDecoration(
                          color: AppTheme.deepTeal,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Icon(
                          data.icon,
                          color: Colors.white,
                          size: artSize * 0.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
