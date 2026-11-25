import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/directory/presentation/directory_screen.dart';
import '../features/directory/presentation/guardian_screen.dart';
import '../branding/club_brand.dart';
import '../branding/club_login.dart';
import '../branding/club_logo.dart';
import '../features/admin/presentation/screens/admin_banner_form_screen.dart';
import '../features/admin/presentation/screens/admin_banners_screen.dart';
import '../features/admin/presentation/screens/admin_communities_screen.dart';
import '../features/admin/presentation/screens/admin_community_detail_screen.dart';
import '../features/admin/presentation/screens/admin_panel_screen.dart';
import '../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/community/presentation/screens/communities_screen.dart';
import '../features/community/presentation/screens/community_detail_screen.dart';
import '../features/community/presentation/screens/community_form_screen.dart';
import '../features/community/presentation/screens/community_start_screen.dart';
import '../features/community/presentation/widgets/club_hero.dart';
import '../features/community/presentation/screens/member_profile_screen.dart';
import '../features/dues/presentation/screens/dues_members_screen.dart';
import '../features/dues/presentation/screens/dues_pay_screen.dart';
import '../features/dues/presentation/screens/dues_payments_screen.dart';
import '../features/dues/presentation/screens/dues_screen.dart';
import '../features/dues/presentation/screens/dues_settings_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/member_card/presentation/screens/member_card_screen.dart';
import '../features/quotes/presentation/screens/quote_form_screen.dart';
import '../features/quotes/presentation/screens/quotes_screen.dart';
import '../features/settings/presentation/settings_route.dart';
import '../features/ui_gallery/screens/ui_gallery_home_screen.dart';

/// Sesudah login: data diri belum lengkap → form data diri, selain itu Beranda.
String afterLoginLocation(User user) =>
    user.completion.isComplete ? '/' : AppRoutes.profileSetup;

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  // Semua halaman selain splash/onboarding/login wajib login.
  redirect: clubAuthRedirect,
  observers: [AppNavigatorObserver()],
  routes: [
    ...buildAuthRoutes(
      splash: () => const SplashScreen(
        title: ClubBrand.name,
        tagline: ClubBrand.tagline,
        logo: ClubLogo(size: 80),
        requireLogin: true,
        // Halaman awal cukup nama app; tanpa slide penjelasan fitur.
        showOnboarding: false,
      ),
      withOnboarding: false,
      login: () => ClubLoginPage(
        onLoggedIn: (context, state) =>
            context.go(loginDestination(context, state.user)),
      ),
    ),

    GoRoute(
        path: '/login/pin',
        builder: (context, state) => PinScreen(onLoggedIn: () {
              final auth =
                  ProviderScope.containerOf(context).read(authProvider);
              if (auth is AuthAuthenticated) {
                context.go(loginDestination(context, auth.user));
              }
            })),
    GoRoute(
        path: '/login/recovery',
        builder: (context, state) => const PinScreen(mode: PinMode.recovery)),
    GoRoute(
        path: '/login/password',
        builder: (context, state) => LoginScreen(onLoginSuccess: () {
              final auth =
                  ProviderScope.containerOf(context).read(authProvider);
              if (auth is AuthAuthenticated) {
                context.go(loginDestination(context, auth.user));
              }
            })),
    GoRoute(
        path: '/explore', builder: (context, state) => const DirectoryScreen()),
    GoRoute(
        path: '/explore/communities/:id',
        builder: (context, state) =>
            PublicCommunityScreen(id: state.pathParameters['id']!)),
    GoRoute(
        path: '/explore/communities/:id/members',
        builder: (context, state) =>
            DirectoryScreen(communityId: state.pathParameters['id']!)),
    GoRoute(
        path: '/account/pin',
        builder: (context, state) => const PinScreen(mode: PinMode.manage)),
    GoRoute(
        path: '/guardians',
        builder: (context, state) => const GuardianScreen()),
    GoRoute(
        path: '/guardians/dependents/:id',
        builder: (context, state) =>
            DependentScreen(id: state.pathParameters['id']!)),

    // Anak `/`: tombol kembali tetap ada walau halaman dimuat ulang.
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'members/:id',
          builder: (context, state) =>
              MemberProfileScreen(userId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: 'communities',
          builder: (context, state) => const CommunitiesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const CommunityFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => CommunityDetailScreen(
                communityId: state.pathParameters['id']!,
                initialTab: ClubTab.fromName(state.uri.queryParameters['tab']),
              ),
              routes: [
                GoRoute(
                  path: 'card',
                  builder: (context, state) => MemberCardScreen(
                      communityId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'dues',
                  builder: (context, state) =>
                      DuesScreen(communityId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                      path: 'pay',
                      builder: (context, state) => DuesPayScreen(
                        communityId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => DuesSettingsScreen(
                        communityId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'payments',
                      builder: (context, state) => DuesPaymentsScreen(
                        communityId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'members',
                      builder: (context, state) => DuesMembersScreen(
                        communityId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: ':userId',
                          builder: (context, state) => DuesMemberScreen(
                            communityId: state.pathParameters['id']!,
                            userId: state.pathParameters['userId']!,
                            initialYear: int.tryParse(
                              state.uri.queryParameters['year'] ?? '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.profileSetup,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          const ProfileSetupScreen(doneLocation: AppRoutes.communityStart),
    ),
    GoRoute(
      path: AppRoutes.communityStart,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CommunityStartScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    settingsRoute,

    // Khusus super admin: layar menolak selain itu, begitu juga API-nya.
    GoRoute(
      path: AppRoutes.adminPanel,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminPanelScreen(),
      routes: [
        GoRoute(
          path: 'users',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AdminUsersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) =>
                  AdminUserDetailScreen(userId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: 'communities',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AdminCommunitiesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => AdminCommunityDetailScreen(
                communityId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'banners',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AdminBannersScreen(),
          routes: [
            GoRoute(
              path: 'new',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => const AdminBannerFormScreen(),
            ),
            GoRoute(
              path: ':id',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) => AdminBannerFormScreen(
                bannerId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
    ),

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

String? safeLoginReturn(String? value) {
  if (value == null ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      value.startsWith('/login') ||
      Uri.tryParse(value)?.hasScheme == true) {
    return null;
  }
  return value;
}

String loginDestination(BuildContext context, User user) =>
    safeLoginReturn(GoRouterState.of(context).uri.queryParameters['from']) ??
    afterLoginLocation(user);
String? clubAuthRedirect(BuildContext context, GoRouterState state) {
  final auth = ProviderScope.containerOf(context).read(authProvider);
  if (auth is AuthInitial || auth is AuthLoading) return null;
  final path = state.uri.path;
  final public = path == '/splash' ||
      path == '/onboarding' ||
      path.startsWith('/explore') ||
      path.startsWith('/login');
  if (auth is AuthAuthenticated) {
    if ((path == '/login' ||
            path == '/login/pin' ||
            path == '/login/password') &&
        state.uri.queryParameters['reauth'] != '1') {
      return safeLoginReturn(state.uri.queryParameters['from']) ??
          afterLoginLocation(auth.user);
    }
    return null;
  }
  return public
      ? null
      : '/login?from=${Uri.encodeComponent(state.uri.toString())}';
}
