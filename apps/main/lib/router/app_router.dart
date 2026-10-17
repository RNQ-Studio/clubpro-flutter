import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';

import '../branding/club_brand.dart';
import '../branding/club_logo.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_route.dart';
import '../features/profile/presentation/profile_route.dart';
import '../features/ui_gallery/screens/ui_gallery_home_screen.dart';
import '../features/quotes/presentation/screens/quotes_screen.dart';
import '../features/quotes/presentation/screens/quote_form_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: authRedirect,
  observers: [AppNavigatorObserver()],
  routes: [
    ...buildAuthRoutes(
      splash: () => const SplashScreen(
        title: ClubBrand.name,
        tagline: ClubBrand.tagline,
        logo: ClubLogo(size: 80),
      ),
      onboarding: () =>
          const OnboardingScreen(pages: ClubBrand.onboardingPages),
    ),
    settingsRoute,
    profileRoute,
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/ui-gallery',
      builder: (context, state) => const UiGalleryHomeScreen(),
    ),

    // Quotes management
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
