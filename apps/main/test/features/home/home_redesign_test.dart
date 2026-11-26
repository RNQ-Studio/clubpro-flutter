import 'dart:async';

import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/achievements/presentation/achievements_providers.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../community/fake_community_repository.dart';
import '../dues/fake_dues_repository.dart';
import 'fake_promotion_popup_store.dart';

class _RedesignAuth extends AuthNotifier {
  _RedesignAuth(this.user);
  final User user;

  @override
  AuthState build() => AuthAuthenticated(user);

  @override
  Future<void> checkCurrentUser() async {}
}

const homeRedesignUser = User(
  id: 'home-redesign',
  name: 'Rina Ayu Lestari',
  email: 'rina@anaklangit.manahpro.web.id',
  completion: ProfileCompletion(completed: 12, total: 12, missing: []),
);

FakeCommunityRepository homeRedesignRepository({
  CommunityRole role = CommunityRole.member,
  CommunityRole? summaryRole,
  bool restricted = false,
  bool joined = true,
  bool? canManage,
}) =>
    FakeCommunityRepository(
      joined: joined
          ? [testCommunity('1', myRole: summaryRole ?? role, membersCount: 124)]
          : [],
      detail: CommunityDetail(
        id: '1',
        name: 'Pemanah Nusantara',
        shortName: 'PN',
        type: 'panahan',
        typeLabel: 'Panahan',
        status: CommunityStatus.approved,
        cityName: 'Kota Bandung',
        provinceName: 'Jawa Barat',
        description: 'Komunitas panahan tradisional di Bandung.',
        address: 'Lapangan Merdeka, Bandung',
        contactName: 'Pengurus Komunitas',
        contactPhone: '081234567890',
        myRole: role,
        isMember: true,
        canManage: canManage ?? role.canManage,
        membersCount: 124,
        entitlementActive: !restricted,
        platformActive: true,
        pendingMembersCount: 4,
        upcomingActivitiesCount: 1,
        duesConfigured: true,
        pendingDuesPaymentsCount: 2,
      ),
      activities: CommunityActivities(upcoming: [
        testActivity('home-practice',
            title: 'Latihan bersama akhir pekan',
            startsAt: DateTime(2026, 11, 29, 8),
            location: 'Lapangan Merdeka, Bandung'),
      ]),
    );

/// Shared, fully stubbed fixture for regression tests and screenshot renders.
Widget homeRedesignApp({
  FakeCommunityRepository? communities,
  User user = homeRedesignUser,
  double textScale = 1,
  bool dark = false,
  Future<WalletSummary> Function()? wallet,
  Future<AchievementPage> Function()? points,
  bool dues = false,
}) {
  final targets = {
    AppRoutes.profile,
    AppRoutes.wallet,
    AppRoutes.billingNotices,
    AppRoutes.topup,
    AppRoutes.payouts,
    AppRoutes.myAchievements,
    AppRoutes.myAds,
    AppRoutes.myMarketProducts,
    AppRoutes.marketProducts,
    AppRoutes.rankings,
    AppRoutes.memberAds,
    AppRoutes.adminPanel,
    AppRoutes.achievementRules,
    AppRoutes.communities,
    AppRoutes.createCommunity,
    '/explore',
    AppRoutes.community('1'),
    AppRoutes.communityCard('1'),
    AppRoutes.communityBilling('1'),
    AppRoutes.communityTraining('1'),
    AppRoutes.communityAchievements('1'),
    AppRoutes.communityDues('1'),
    AppRoutes.communityDuesPay('1'),
    AppRoutes.communityDuesPayments('1'),
    AppRoutes.communityDuesMembers('1'),
    AppRoutes.communityDuesSettings('1'),
  };
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    for (final target in targets)
      GoRoute(
        path: target,
        builder: (_, state) => Scaffold(
          appBar: AppBar(),
          body: Text('TARGET ${state.uri}'),
        ),
      ),
  ]);
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authProvider.overrideWith(() => _RedesignAuth(user)),
      communityRepositoryProvider
          .overrideWithValue(communities ?? homeRedesignRepository()),
      activeCommunityStoreProvider
          .overrideWithValue(FakeActiveCommunityStore()),
      homePromotionsProvider
          .overrideWith((ref) async => const HomePromotions()),
      promotionPopupStoreProvider.overrideWithValue(FakePromotionPopupStore()),
      appRefresherProvider.overrideWithValue(null),
      duesRepositoryProvider.overrideWithValue(FakeDuesRepository(
          overview: dues ? memberOverview() : notConfigured)),
      walletSummaryProvider.overrideWith((ref) =>
          wallet?.call() ??
          Future.value(const WalletSummary(available: 999999999))),
      myAchievementsProvider().overrideWith((ref) =>
          points?.call() ??
          Future.value(const AchievementPage([], totalPoints: 987654321))),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Future<void> homeRedesignScrollTo(WidgetTester tester, String key,
    {double delta = 300}) async {
  final finder = find.byKey(Key(key));
  final scrollable = find
      .descendant(
          of: find.byType(ListView).first, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> homeRedesignExpand(WidgetTester tester, String key) async {
  await homeRedesignScrollTo(tester, key);
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'CEO',
      packageName: 'clubpro.main',
      version: '1.0.0',
      buildNumber: '135',
      buildSignature: '',
    );
  });

  testWidgets('secondary menus stay grouped until users open a section',
      (tester) async {
    await tester.pumpWidget(homeRedesignApp());
    await tester.pumpAndSettle();
    for (final key in [
      'home-menu-community',
      'home-menu-finance',
      'home-menu-market',
      'home-menu-explore',
    ]) {
      await homeRedesignScrollTo(tester, key);
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    expect(find.byKey(const Key('market-entry-main')), findsNothing);
    expect(find.byKey(const Key('home-public-members')), findsNothing);
    await homeRedesignExpand(tester, 'home-menu-explore');
    expect(find.byKey(const Key('home-public-members')), findsOneWidget);
  });

  for (final (group, entry, destination) in [
    ('community', 'training-entry', AppRoutes.communityTraining('1')),
    (
      'community',
      'community-member-rankings',
      '${AppRoutes.rankings}?community=1'
    ),
    ('community', 'community-member-ads', '${AppRoutes.memberAds}?community=1'),
    (
      'community',
      'market-entry-community',
      AppRoutes.marketCatalogue(communityId: '1')
    ),
    ('community', 'home-more-find', AppRoutes.communities),
    ('community', 'home-more-create', AppRoutes.createCommunity),
    ('finance', 'member-lobby-topup', '${AppRoutes.topup}?community=1'),
    ('finance', 'member-lobby-payouts', AppRoutes.payouts),
    ('finance', 'finance-entry', AppRoutes.communityBilling('1')),
    ('market', 'market-entry-main', AppRoutes.marketProducts),
    ('market', 'market-entry-mine', AppRoutes.myMarketProducts),
    ('market', 'member-lobby-ads', AppRoutes.myAds),
    ('explore', 'home-public-directory', '/explore'),
    ('explore', 'home-public-members', '/explore?members=1'),
    ('explore', 'home-community-rankings', AppRoutes.rankings),
    ('explore', 'home-public-ads', AppRoutes.memberAds),
  ]) {
    testWidgets('$entry preserves its navigation context', (tester) async {
      await tester.pumpWidget(homeRedesignApp());
      await tester.pumpAndSettle();
      await homeRedesignExpand(tester, 'home-menu-$group');
      await homeRedesignScrollTo(tester, entry);
      await tester.tap(find.byKey(Key(entry)));
      await tester.pumpAndSettle();
      expect(find.text('TARGET $destination'), findsOneWidget);
    });
  }

  for (final role in CommunityRole.values) {
    testWidgets('${role.label} sees only authorized management menus',
        (tester) async {
      await tester.pumpWidget(
          homeRedesignApp(communities: homeRedesignRepository(role: role)));
      await tester.pumpAndSettle();
      if (role.canManage) {
        await homeRedesignScrollTo(tester, 'home-manage-expand');
      }
      expect(find.byKey(const Key('home-manage-expand')),
          role.canManage ? findsOneWidget : findsNothing);
      await homeRedesignExpand(tester, 'home-menu-community');
      expect(
          find.byKey(const Key('community-record-achievement')),
          role.canManage || role == CommunityRole.coach
              ? findsOneWidget
              : findsNothing);
      expect(find.byKey(const Key('home-admin-panel')), findsNothing);
      expect(find.byKey(const Key('member-lobby-point-rules')), findsNothing);
    });
  }

  testWidgets('detail authorization overrides a stale manager summary',
      (tester) async {
    await tester.pumpWidget(homeRedesignApp(
        communities: homeRedesignRepository(
            role: CommunityRole.member,
            summaryRole: CommunityRole.creator,
            canManage: false)));
    await tester.pumpAndSettle();
    await homeRedesignExpand(tester, 'home-menu-community');
    expect(find.byKey(const Key('home-manage-expand')), findsNothing);
    expect(find.byKey(const Key('community-record-achievement')), findsNothing);
  });

  testWidgets('creator platform subscription stays separate from member dues',
      (tester) async {
    await tester.pumpWidget(homeRedesignApp(
        communities: homeRedesignRepository(role: CommunityRole.creator)));
    await tester.pumpAndSettle();
    await homeRedesignExpand(tester, 'home-menu-finance');
    await homeRedesignScrollTo(tester, 'home-platform-billing');
    await tester.tap(find.byKey(const Key('home-platform-billing')));
    await tester.pumpAndSettle();
    expect(
        find.text('TARGET ${AppRoutes.communityBilling('1')}?scope=platform'),
        findsOneWidget);
  });

  for (final (entry, destination) in [
    ('member-lobby-balance', AppRoutes.wallet),
    ('member-lobby-points', AppRoutes.myAchievements),
  ]) {
    testWidgets('$entry opens the corresponding personal history',
        (tester) async {
      await tester.pumpWidget(homeRedesignApp());
      await tester.pumpAndSettle();
      await homeRedesignScrollTo(tester, entry);
      await tester.tap(find.byKey(Key(entry)));
      await tester.pumpAndSettle();
      expect(find.text('TARGET $destination'), findsOneWidget);
    });
  }

  for (final (entry, destination) in [
    ('home-admin-panel', AppRoutes.adminPanel),
    ('member-lobby-point-rules', AppRoutes.achievementRules),
  ]) {
    testWidgets('super admin can reach $entry', (tester) async {
      await tester.pumpWidget(homeRedesignApp(
          user: const User(
              id: 'central',
              name: 'Admin Pusat',
              email: 'admin@anaklangit.manahpro.web.id',
              roles: [User.superAdminRole])));
      await tester.pumpAndSettle();
      await homeRedesignScrollTo(tester, entry);
      await tester.tap(find.byKey(Key(entry)));
      await tester.pumpAndSettle();
      expect(find.text('TARGET $destination'), findsOneWidget);
    });
  }

  testWidgets('inactive membership keeps payment recovery accessible',
      (tester) async {
    await tester.pumpWidget(homeRedesignApp(
        communities: homeRedesignRepository(
            role: CommunityRole.creator, restricted: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-manage-expand')), findsNothing);
    expect(find.byKey(const Key('home-club-menu-card')), findsNothing);
    await homeRedesignExpand(tester, 'home-menu-community');
    expect(find.byKey(const Key('community-record-achievement')), findsNothing);
    await homeRedesignExpand(tester, 'home-menu-finance');
    await homeRedesignScrollTo(tester, 'finance-entry');
    await tester.tap(find.byKey(const Key('finance-entry')));
    await tester.pumpAndSettle();
    expect(
        find.text('TARGET ${AppRoutes.communityBilling('1')}'), findsOneWidget);
  });

  testWidgets('inactive creator opens platform renewal directly',
      (tester) async {
    await tester.pumpWidget(homeRedesignApp(
        communities: homeRedesignRepository(
            role: CommunityRole.creator, restricted: true)));
    await tester.pumpAndSettle();
    await homeRedesignScrollTo(tester, 'home-restricted-billing');
    await tester.tap(find.byKey(const Key('home-restricted-billing')));
    await tester.pumpAndSettle();
    expect(
        find.text('TARGET ${AppRoutes.communityBilling('1')}?scope=platform'),
        findsOneWidget);
  });

  testWidgets('changing active community resets expanded scoped menu links',
      (tester) async {
    final communities = homeRedesignRepository();
    communities.joined = [
      testCommunity('1', myRole: CommunityRole.member),
      testCommunity('2', name: 'Panahan Bandung', myRole: CommunityRole.member),
    ];
    await tester.pumpWidget(homeRedesignApp(communities: communities));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-club-option-1')));
    await tester.pumpAndSettle();
    await homeRedesignExpand(tester, 'home-menu-finance');
    await homeRedesignScrollTo(tester, 'member-lobby-topup');
    await tester.tap(find.byKey(const Key('member-lobby-topup')));
    await tester.pumpAndSettle();
    expect(find.text('TARGET ${AppRoutes.topup}?community=1'), findsOneWidget);
    GoRouter.of(
            tester.element(find.text('TARGET ${AppRoutes.topup}?community=1')))
        .pop();
    await tester.pumpAndSettle();
    await homeRedesignScrollTo(tester, 'home-club-switch', delta: -300);
    await tester.tap(find.byKey(const Key('home-club-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-club-option-2')));
    await tester.pumpAndSettle();
    await homeRedesignExpand(tester, 'home-menu-finance');
    await homeRedesignScrollTo(tester, 'member-lobby-topup');
    await tester.tap(find.byKey(const Key('member-lobby-topup')));
    await tester.pumpAndSettle();
    expect(find.text('TARGET ${AppRoutes.topup}?community=2'), findsOneWidget);
  });

  testWidgets('without a community finance and public exploration still work',
      (tester) async {
    await tester.pumpWidget(
        homeRedesignApp(communities: homeRedesignRepository(joined: false)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-menu-community')), findsNothing);
    expect(find.byKey(const Key('home-manage-expand')), findsNothing);
    await homeRedesignExpand(tester, 'home-menu-finance');
    await homeRedesignScrollTo(tester, 'member-lobby-topup');
    await tester.tap(find.byKey(const Key('member-lobby-topup')));
    await tester.pumpAndSettle();
    expect(find.text('TARGET ${AppRoutes.topup}'), findsOneWidget);
  });

  testWidgets('summary distinguishes loading, errors and actual zero values',
      (tester) async {
    final wallet = Completer<WalletSummary>();
    final points = Completer<AchievementPage>();
    var walletCalls = 0;
    var pointCalls = 0;
    await tester.pumpWidget(homeRedesignApp(
      wallet: () => walletCalls++ == 0
          ? wallet.future
          : Future.value(const WalletSummary(available: 0)),
      points: () => pointCalls++ == 0
          ? points.future
          : Future.value(const AchievementPage([], totalPoints: 0)),
    ));
    await tester.pumpAndSettle();
    await homeRedesignScrollTo(tester, 'home-menu-finance');
    expect(find.byKey(const Key('member-lobby-balance')), findsNothing);
    expect(find.byKey(const Key('member-lobby-points')), findsNothing);
    wallet.completeError(Exception('offline'));
    points.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('0 poin'), findsNothing);
    expect(find.textContaining('Coba lagi'), findsWidgets);
    for (final label in [
      'Saldo gagal dimuat · Coba lagi',
      'Poin gagal dimuat · Coba lagi',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.text('0 poin'), findsOneWidget);
    expect(walletCalls, 2);
    expect(pointCalls, 2);
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale) in [
    (const Size(320, 700), 1.5),
    (const Size(1280, 900), 1.0),
  ]) {
    testWidgets('overview and opened menus fit ${size.width}px at $scale',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(homeRedesignApp(
          textScale: scale,
          dues: true,
          communities: homeRedesignRepository(role: CommunityRole.creator)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final group in ['community', 'finance', 'market', 'explore']) {
        await homeRedesignExpand(tester, 'home-menu-$group');
        expect(tester.takeException(), isNull);
      }
    });
  }
}
