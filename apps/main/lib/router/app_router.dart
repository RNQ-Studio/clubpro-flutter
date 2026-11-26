import '../features/marketplace/presentation/marketplace_screen.dart';
import '../features/marketplace/presentation/market_product_screen.dart';
import '../features/marketplace/presentation/market_product_form_screen.dart';
import '../features/marketplace/presentation/market_checkout_screen.dart';
import '../features/marketplace/presentation/market_orders_screen.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
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
import '../features/dues/presentation/screens/dues_payments_screen.dart';
import '../features/dues/presentation/screens/dues_screen.dart';
import '../features/finance/presentation/billing_screen.dart';
import '../features/finance/presentation/billing_management_screen.dart';
import '../features/finance/presentation/wallet_screen.dart';
import '../features/money_movement/presentation/bank_account_screen.dart';
import '../features/money_movement/presentation/payouts_screen.dart';
import '../features/money_movement/presentation/payout_request_screen.dart';
import '../features/money_movement/presentation/payout_detail_screen.dart';
import '../features/money_movement/presentation/transfer_screen.dart';
import '../features/finance/presentation/topup_screen.dart';
import '../features/finance/presentation/receipt_screen.dart';
import '../features/finance/presentation/billing_notices_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/training/presentation/training_screen.dart';
import '../features/training/presentation/training_settings_screen.dart';
import '../features/training/presentation/training_session_screen.dart';
import '../features/training/presentation/training_report_screen.dart';
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
    GoRoute(
      path: AppRoutes.authCheck,
      builder: (context, state) => const _SessionCheckScreen(),
    ),
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
        path: AppRoutes.marketProducts,
        builder: (_, s) =>
            MarketplaceScreen(communityId: s.uri.queryParameters['community'])),
    GoRoute(
        path: '/explore/products/:id',
        builder: (_, s) => MarketProductScreen(id: s.pathParameters['id']!)),
    GoRoute(
        path: '/explore/sellers/:id',
        builder: (_, s) =>
            MarketplaceScreen(sellerId: s.pathParameters['id']!)),
    GoRoute(
        path: AppRoutes.myMarketProducts,
        builder: (_, s) => const MarketplaceScreen(mine: true)),
    GoRoute(
        path: AppRoutes.newMarketProduct,
        builder: (_, s) => const MarketProductFormScreen()),
    GoRoute(
        path: '/marketplace/my-products/:id/edit',
        builder: (_, s) =>
            MarketProductFormScreen(id: s.pathParameters['id']!)),
    GoRoute(
        path: '/marketplace/checkout/:id',
        builder: (_, s) => MarketCheckoutScreen(id: s.pathParameters['id']!)),
    GoRoute(
        path: AppRoutes.marketOrders,
        builder: (_, s) => const MarketOrdersScreen()),
    GoRoute(
        path: '/marketplace/orders/:id',
        builder: (_, s) => MarketOrderScreen(id: s.pathParameters['id']!)),
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

    GoRoute(
        path: AppRoutes.notifications,
        redirect: (context, state) => AppRoutes.billingNotices),
    GoRoute(
        path: AppRoutes.billingNotices,
        builder: (context, state) => const BillingNoticesScreen()),
    GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => WalletScreen(
            scope: state.uri.queryParameters['scope'] ?? 'identity',
            communityId: state.uri.queryParameters['community']),
        routes: [
          GoRoute(
              path: 'bank-account',
              builder: (_, state) => const PrimaryBankScreen()),
          GoRoute(
              path: 'payouts',
              builder: (_, state) => PayoutsScreen(
                  communityId: state.uri.queryParameters['community'],
                  manage: state.uri.queryParameters['manage'] == '1'),
              routes: [
                GoRoute(
                    path: 'new',
                    builder: (_, state) => PayoutRequestScreen(
                        communityId: state.uri.queryParameters['community'])),
                GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        PayoutDetailScreen(id: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                          path: 'parts/:partId/proof',
                          builder: (_, state) => PayoutProofRouteScreen(
                              id: state.pathParameters['id']!,
                              partId: state.pathParameters['partId']!)),
                      GoRoute(
                          path: 'parts/:partId/fragments/:fragmentId',
                          builder: (_, state) => PayoutProofRouteScreen(
                              id: state.pathParameters['id']!,
                              partId: state.pathParameters['partId']!,
                              fragmentId: state.pathParameters['fragmentId']!)),
                    ]),
              ]),
          GoRoute(
              path: 'transfers',
              builder: (_, state) => const TransferHistoryScreen(),
              routes: [
                GoRoute(
                    path: 'new',
                    builder: (_, state) => TransferScreen(
                        communityId: state.uri.queryParameters['community'])),
              ]),
          GoRoute(
              path: 'topup',
              builder: (context, state) => TopupScreen(
                  communityId: state.uri.queryParameters['community'],
                  scope: state.uri.queryParameters['scope'],
                  targetMemberId: state.uri.queryParameters['member'])),
          GoRoute(
              path: 'receipts',
              builder: (context, state) => ReceiptScreen(
                  communityId: state.uri.queryParameters['community'],
                  manage: state.uri.queryParameters['manage'] == '1')),
          GoRoute(
              path: 'transactions/:transactionId',
              builder: (context, state) => WalletTransactionScreen(
                  id: state.pathParameters['transactionId']!,
                  scope: state.uri.queryParameters['scope'] ?? 'identity',
                  communityId: state.uri.queryParameters['community'])),
        ]),

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
              builder: (context, state) => BillingAccessGate(
                  communityId: state.pathParameters['id']!,
                  child: CommunityDetailScreen(
                    communityId: state.pathParameters['id']!,
                    initialTab:
                        ClubTab.fromName(state.uri.queryParameters['tab']),
                  )),
              routes: [
                GoRoute(
                    path: 'training',
                    builder: (_, state) => TrainingScreen(
                        communityId: state.pathParameters['id']!),
                    routes: [
                      GoRoute(
                          path: 'settings',
                          builder: (_, state) => TrainingSettingsScreen(
                              communityId: state.pathParameters['id']!)),
                      GoRoute(
                          path: 'locations/new',
                          builder: (_, state) => TrainingLocationScreen(
                              communityId: state.pathParameters['id']!)),
                      GoRoute(
                          path: 'locations/:locationId',
                          builder: (_, state) => TrainingLocationScreen(
                              communityId: state.pathParameters['id']!,
                              locationId: state.pathParameters['locationId']!)),
                      GoRoute(
                          path: 'sessions/new',
                          builder: (_, state) => TrainingSessionScreen(
                              communityId: state.pathParameters['id']!)),
                      GoRoute(
                          path: 'report',
                          builder: (_, state) => TrainingReportScreen(
                              communityId: state.pathParameters['id']!)),
                    ]),
                GoRoute(
                    path: 'billing',
                    builder: (context, state) => BillingScreen(
                        communityId: state.pathParameters['id']!,
                        scope: state.uri.queryParameters['scope'] ?? 'member',
                        targetMemberId: state.uri.queryParameters['member']),
                    routes: [
                      GoRoute(
                          path: 'settings',
                          builder: (context, state) => BillingSettingsScreen(
                              communityId: state.pathParameters['id']!)),
                      GoRoute(
                          path: 'inactive',
                          builder: (context, state) => LifecycleScreen(
                              communityId: state.pathParameters['id']!)),
                    ]),
                GoRoute(
                  path: 'card',
                  builder: (context, state) => MemberCardScreen(
                      communityId: state.pathParameters['id']!),
                ),
                GoRoute(
                  path: 'dues',
                  builder: (context, state) =>
                      BillingScreen(communityId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                        path: 'calendar',
                        builder: (context, state) => DuesScreen(
                            communityId: state.pathParameters['id']!)),
                    GoRoute(
                      path: 'pay',
                      builder: (context, state) => BillingScreen(
                        communityId: state.pathParameters['id']!,
                      ),
                    ),
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => BillingSettingsScreen(
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
                            readOnly: true,
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

String? safeLoginReturn(String? value) => decodeLoginReturn(value);

String loginDestination(BuildContext context, User user) =>
    safeLoginReturn(GoRouterState.of(context).uri.queryParameters['from']) ??
    afterLoginLocation(user);
String? clubAuthRedirect(BuildContext context, GoRouterState state) {
  final auth = ProviderScope.containerOf(context).read(authProvider);
  final path = state.uri.path;
  final rawReturn = state.uri.queryParameters['from'];
  final legacyReturn = safeLoginReturn(rawReturn);
  if (path.startsWith('/login') &&
      legacyReturn != null &&
      rawReturn != encodeLoginReturn(legacyReturn)) {
    return state.uri.replace(queryParameters: {
      ...state.uri.queryParameters,
      'from': encodeLoginReturn(legacyReturn),
    }).toString();
  }
  final public = path == '/splash' ||
      path == '/onboarding' ||
      path.startsWith('/explore') ||
      path.startsWith('/login');
  final checking = path == AppRoutes.authCheck;
  if (auth is AuthInitial || auth is AuthLoading) {
    return public || checking
        ? null
        : '${AppRoutes.authCheck}?from=${encodeLoginReturn(state.uri.toString())}';
  }
  if (checking) {
    final destination = safeLoginReturn(state.uri.queryParameters['from']);
    return auth is AuthAuthenticated
        ? destination ?? afterLoginLocation(auth.user)
        : '/login${destination == null ? '' : '?from=${encodeLoginReturn(destination)}'}';
  }
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
      : '/login?from=${encodeLoginReturn(state.uri.toString())}';
}

/// Private routes never mount their consumers until session restoration settles.
class _SessionCheckScreen extends ConsumerStatefulWidget {
  const _SessionCheckScreen();
  @override
  ConsumerState<_SessionCheckScreen> createState() =>
      _SessionCheckScreenState();
}

class _SessionCheckScreenState extends ConsumerState<_SessionCheckScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GoRouter.of(context).refresh();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider) is AuthInitial) {
        ref.read(authProvider.notifier).checkCurrentUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memeriksa sesi…'),
            ]),
          ),
        ),
      );
}
