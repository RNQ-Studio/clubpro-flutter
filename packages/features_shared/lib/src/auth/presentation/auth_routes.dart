import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/presentation/splash_screen.dart';
import 'login_screen.dart';

const authLoginPath = '/login';

/// Rute publik (splash, onboarding, login). App bisa mengganti tiap layar
/// lewat builder, mis. untuk branding atau alur wajib-login.
/// [withOnboarding] `false` = `/onboarding` dialihkan ke halaman login (pasang
/// juga `SplashScreen.showOnboarding: false`).
List<GoRoute> buildAuthRoutes({
  Widget Function()? splash,
  Widget Function()? onboarding,
  Widget Function()? login,
  bool withOnboarding = true,
}) =>
    [
      GoRoute(
        path: '/splash',
        builder: (context, state) => splash?.call() ?? const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        redirect: withOnboarding ? null : (_, __) => authLoginPath,
        builder: (context, state) =>
            onboarding?.call() ?? const OnboardingScreen(),
      ),
      GoRoute(
        path: authLoginPath,
        builder: (context, state) => login?.call() ?? const LoginScreen(),
      ),
    ];

final List<GoRoute> authRoutes = buildAuthRoutes();
