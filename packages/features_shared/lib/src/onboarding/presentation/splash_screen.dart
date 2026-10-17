import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import 'onboarding_notifier.dart';

/// Premium splash screen with animated fade-in branding.
///
/// After 2 seconds navigates to:
/// - `/onboarding` — if the user has not completed onboarding yet.
/// - `/login`      — if [requireLogin] and the user has not logged in.
/// - `/`           — otherwise.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.title,
    this.tagline = 'Build something great',
    this.logo,
    this.requireLogin = false,
  });

  /// Nama yang ditampilkan; null = nama app dari platform.
  final String? title;
  final String tagline;

  /// Pengganti logo aset bawaan.
  final Widget? logo;

  /// `true` = pengguna yang belum login diarahkan ke `/login`, bukan `/`.
  final bool requireLogin;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  String _appName = 'Starter App';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();

    _loadAppName();

    Future.delayed(const Duration(seconds: 2), _checkNavigation);
  }

  Future<void> _loadAppName() async {
    if (widget.title != null) {
      _appName = widget.title!;
      return;
    }
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          // Fallback to title case of folder if blank
          _appName = info.appName.isNotEmpty ? info.appName : 'Starter App';
        });
      }
    } catch (_) {}
  }

  Future<void> _checkNavigation() async {
    if (!mounted) return;

    // Tunggu status onboarding benar-benar terbaca (bukan nilai sementara).
    bool hasOnboarded;
    try {
      hasOnboarded = await ref.read(onboardingProvider.future);
    } catch (_) {
      hasOnboarded = false;
    }
    if (!mounted) return;

    if (!hasOnboarded) {
      context.go('/onboarding');
      return;
    }

    if (!widget.requireLogin) {
      context.go('/');
      return;
    }

    final auth = await _resolvedAuthState();
    if (!mounted) return;
    context.go(auth is AuthAuthenticated ? '/' : '/login');
  }

  /// Status auth setelah pengecekan sesi selesai (bukan Initial/Loading).
  Future<AuthState> _resolvedAuthState() async {
    bool settled(AuthState s) => s is! AuthInitial && s is! AuthLoading;

    final current = ref.read(authProvider);
    if (settled(current)) return current;

    final completer = Completer<AuthState>();
    final sub = ref.listenManual<AuthState>(authProvider, (_, next) {
      if (settled(next) && !completer.isCompleted) completer.complete(next);
    });
    try {
      // Router tetap mengalihkan /login → / bila sesi selesai dipulihkan belakangan.
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => ref.read(authProvider),
      );
    } finally {
      sub.close();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menjaga provider onboarding (autoDispose) tetap hidup sampai dibaca.
    ref.watch(onboardingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: widget.logo ??
                          Image.asset(
                            'packages/features_shared/assets/logo.png',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.tagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
