import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../branding/club_brand.dart';
import '../branding/club_logo.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/quotes/presentation/screens/quote_form_screen.dart';
import '../features/quotes/presentation/screens/quotes_screen.dart';
import '../features/settings/presentation/settings_route.dart';
import '../features/ui_gallery/screens/ui_gallery_home_screen.dart';
import '../shell/main_shell.dart';

/// Sesudah login: data diri belum lengkap → form data diri, selain itu Beranda.
String afterLoginLocation(User user) =>
    user.completion.isComplete ? '/' : AppRoutes.profileSetup;

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  // Semua halaman selain splash/onboarding/login wajib login.
  redirect: requireAuthRedirectWith(afterLogin: afterLoginLocation),
  observers: [AppNavigatorObserver()],
  routes: [
    ...buildAuthRoutes(
      splash: () => const SplashScreen(
        title: ClubBrand.name,
        tagline: ClubBrand.tagline,
        logo: ClubLogo(size: 80),
        requireLogin: true,
      ),
      onboarding: () => const OnboardingScreen(
        pages: ClubBrand.onboardingPages,
        completeLocation: '/login',
      ),
      login: () => GoogleLoginScreen(
        title: ClubBrand.name,
        subtitle: ClubBrand.loginSubtitle,
        logo: const ClubLogo(size: 112),
        onLoggedIn: (context, state) =>
            context.go(afterLoginLocation(state.user)),
      ),
    ),

    // Halaman utama: navigasi bawah Beranda & Profil.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),

    // Layar penuh di atas navigasi bawah.
    GoRoute(
      path: AppRoutes.profileSetup,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    settingsRoute,

    // Contoh bawaan starter (tidak ditautkan dari menu club).
    GoRoute(
      path: '/ui-gallery',
      builder: (context, state) => const UiGalleryHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.quotes,
      builder: (context, state) => const QuotesScreen(),
    ),
    GoRoute(
      path: AppRoutes.createQuote,
      builder: (context, state) => const QuoteFormScreen(),
    ),
    GoRoute(
      path: '${AppRoutes.editQuote}/:localId',
      builder: (context, state) {
        final localId = int.parse(state.pathParameters['localId']!);
        return QuoteFormScreen(localId: localId);
      },
    ),
  ],
);
