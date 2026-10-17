import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_notifier.dart';

/// Satu halaman onboarding. App menyediakan isinya lewat [OnboardingScreen.pages].
class OnboardingPage {
  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  /// Pengganti ikon bundar (mis. logo app) bila diisi.
  final Widget? illustration;
}

/// Premium onboarding screen with a PageView, dot indicator and CTA button.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.pages = defaultPages,
    this.completeLocation = '/',
  });

  final List<OnboardingPage> pages;

  /// Tujuan setelah "Mulai Sekarang" / "Lewati".
  final String completeLocation;

  static const defaultPages = [
    OnboardingPage(
      icon: Icons.bolt_rounded,
      title: 'Cepat & Efisien',
      description: 'Arsitektur modern dengan Riverpod, Go Router, dan Drift '
          'untuk pengalaman pengembangan yang cepat dan andal.',
      color: Color(0xFF18181B),
    ),
    OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Aman & Terpercaya',
      description: 'Autentikasi biometrik, auto-refresh token, dan penyimpanan '
          'terenkripsi untuk menjaga data pengguna tetap aman.',
      color: Color(0xFF27272A),
    ),
    OnboardingPage(
      icon: Icons.palette_rounded,
      title: 'Siap Produksi',
      description:
          'Multi-flavor, lokalisasi, tema dinamis, dan push notification '
          'sudah tersedia — langsung mulai membangun fitur Anda.',
      color: Color(0xFF3F3F46),
    ),
  ];

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> get _pages => widget.pages;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) context.go(widget.completeLocation);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Lewati'),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageWidget(page: page);
                },
              ),
            ),

            // Dot indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: AppConstants.animationNormal,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: isLastPage
                      ? _completeOnboarding
                      : () => _pageController.nextPage(
                            duration: AppConstants.animationNormal,
                            curve: Curves.easeInOut,
                          ),
                  child: Text(
                    isLastPage ? 'Mulai Sekarang' : 'Selanjutnya',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageWidget extends StatelessWidget {
  const _OnboardingPageWidget({required this.page});

  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final illustration = page.illustration ??
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: page.color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(page.icon, size: 72, color: page.color),
        );

    // Layar pendek / teks besar: ilustrasi mengecil dan konten bisa digulir.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: constraints.maxHeight * 0.38,
                ),
                child: FittedBox(fit: BoxFit.scaleDown, child: illustration),
              ),
              const SizedBox(height: 32),
              Text(
                page.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                page.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
