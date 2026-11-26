import 'dart:async';
import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/training/presentation/training_providers.dart';
import 'package:app_main/features/training/presentation/training_screen.dart';
import '../training/fake_training_repository.dart';
import 'package:app_main/features/home/presentation/widgets/lobby_links.dart';
import 'package:app_main/features/home/presentation/widgets/member_lobby_card.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/marketplace/presentation/market_product_screen.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_screen.dart';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/marketplace/presentation/market_product_form_screen.dart';
import 'package:app_main/features/achievements/presentation/achievement_screens.dart';
import 'package:app_main/features/achievements/presentation/member_ads_screens.dart';
import 'package:app_main/features/achievements/presentation/achievements_providers.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_providers.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../community/fake_community_repository.dart';
import '../marketplace/fake_marketplace_repository.dart';
import '../money_movement/movement_screens_test.dart' show visibleTap;
import 'fake_achievements_repository.dart';

class AchievementAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthAuthenticated(User(
      id: '1',
      name: 'Akun uji',
      email: 'uji@anaklangit.manahpro.web.id',
      roles: ['super-admin']));
}

class MemberAchievementAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthAuthenticated(
      User(id: '1', name: 'Akun uji', email: 'uji@anaklangit.manahpro.web.id'));
}

Widget achievementsApp(Widget screen, FakeAchievements repo,
        {double scale = 1,
        bool admin = true,
        FakeMarketplace? market,
        bool watchAds = false}) =>
    ProviderScope(
        overrides: [
          achievementsRepositoryProvider.overrideWithValue(repo),
          trainingRepositoryProvider.overrideWithValue(FakeTraining()),
          walletSummaryProvider.overrideWith(
              (ref) async => const WalletSummary(available: 100000)),
          authProvider.overrideWith(
              admin ? AchievementAuth.new : MemberAchievementAuth.new),
          communityRepositoryProvider.overrideWithValue(FakeCommunityRepository(
              joined: [
                testCommunity('2', name: 'Komunitas Olahraga Anak Langit')
              ])),
          marketplaceRepositoryProvider
              .overrideWithValue(market ?? FakeMarketplace()),
          communityImagePickerProvider
              .overrideWithValue(FakeCommunityImagePicker())
        ],
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => Consumer(builder: (c, ref, _) {
                  if (watchAds) ref.watch(memberAdsProvider());
                  return MediaQuery(
                      data: MediaQuery.of(c)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!);
                }),
            routerConfig: GoRouter(initialLocation: '/screen', routes: [
              GoRoute(path: '/screen', builder: (_, s) => screen),
              GoRoute(
                  path: AppRoutes.rankings,
                  builder: (_, s) => RankingScreen(
                      key: ValueKey(s.uri.toString()),
                      communityId: s.uri.queryParameters['community'],
                      initialPeriod: s.uri.queryParameters['period'] ?? 'month',
                      initialMonth: s.uri.queryParameters['month'],
                      initialAsOf: s.uri.queryParameters['as_of'],
                      initialGender: s.uri.queryParameters['gender'],
                      initialAgeGroup: s.uri.queryParameters['age_group'])),
              GoRoute(
                  path: AppRoutes.myMarketProducts,
                  builder: (_, s) => const MarketplaceScreen(mine: true)),
              GoRoute(
                  path: AppRoutes.myAchievements,
                  builder: (_, s) => const MyAchievementsScreen()),
              GoRoute(
                  path: '/communities/:id/achievements',
                  builder: (_, s) => CommunityAchievementsScreen(
                      communityId: s.pathParameters['id']!)),
              GoRoute(
                  path: AppRoutes.memberAds,
                  builder: (_, s) => MemberAdsScreen(
                      communityId: s.uri.queryParameters['community'])),
              GoRoute(
                  path: AppRoutes.myAds,
                  builder: (_, s) => const MemberAdsScreen(mine: true)),
              GoRoute(
                  path: AppRoutes.newAd,
                  builder: (_, s) => const MemberAdFormScreen()),
              GoRoute(
                  path: '/advertisements/:id/edit',
                  builder: (_, s) =>
                      MemberAdFormScreen(id: s.pathParameters['id'])),
              GoRoute(
                  path: '/explore/products/:id',
                  builder: (_, s) =>
                      MarketProductScreen(id: s.pathParameters['id']!)),
              GoRoute(
                  path: '/explore/sellers/:id',
                  builder: (_, s) =>
                      Scaffold(body: Text('Lapak ${s.pathParameters['id']}')))
            ])));
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('main lobby ranking and advertisements reach populated services',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const Scaffold(body: SingleChildScrollView(child: PublicLobbyLinks())),
        r));
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('home-community-rankings')));
    expect(find.text('Ranking komunitas'), findsOneWidget);
    expect(r.queries.last['scope'], 'communities');
    expect(find.text('999.999.999\npoin'), findsOneWidget);
    await visibleTap(t, find.byType(BackButton));
    await visibleTap(t, find.byKey(const Key('home-public-ads')));
    expect(find.text(adFixture.title), findsOneWidget);
    expect(r.queries.last['mine'], false);
  });
  testWidgets(
      'community lobby opens real recorder, records and corrects source',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const Scaffold(
            body: SingleChildScrollView(
                child: CommunityLobbyLinks(communityId: '2', canRecord: true))),
        r));
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('community-record-achievement')));
    await visibleTap(t, find.text('Anggota penerima poin'));
    await visibleTap(t, find.text('Atlet Fixture').last);
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nama kegiatan/lomba dan hasil'),
        'Lomba lintas anggota');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi bukti / nomor hasil'),
        'HASIL/LOBI/003');
    await visibleTap(t, find.byKey(const Key('achievement-create')));
    expect(r.requests.last['member_id'], 3);
    expect(r.saveCalls, 1);
    await visibleTap(t, find.text('Koreksi prestasi'));
    await t.enterText(
        find.widgetWithText(TextField, 'Alasan koreksi minimal 10 karakter'),
        'Hasil lomba telah dikoreksi');
    await visibleTap(t, find.text('Koreksi dan batalkan poin'));
    expect(r.correctCalls, 1);
  });
  testWidgets('member lobby points and ads reach own server-backed flows',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const Scaffold(body: SingleChildScrollView(child: MemberLobbyCard())),
        r));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Poin prestasi'));
    expect(find.text('Prestasi saya'), findsOneWidget);
    expect(find.textContaining('HASIL/2026/11/001'), findsOneWidget);
    await visibleTap(t, find.byType(BackButton));
    await visibleTap(t, find.byKey(const Key('member-lobby-ads')));
    expect(find.text('Iklan saya'), findsOneWidget);
    await visibleTap(t, find.text('Kelola iklan'));
    await t.enterText(
        find.byKey(const Key('ad-title')), 'Iklan dari lobi anggota');
    await visibleTap(t, find.byKey(const Key('ad-save')));
    expect(r.requests.last['title'], 'Iklan dari lobi anggota');
  });

  testWidgets('central age rule save refreshes retained public ranking',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(Consumer(builder: (context, ref, _) {
      ref.watch(rankingsProvider());
      return const AchievementRulesScreen();
    }), r));
    await t.pumpAndSettle();
    final before = r.queries.length;
    await t.enterText(find.widgetWithText(TextFormField, 'Alasan perubahan'),
        'Perubahan batas usia operasional');
    await visibleTap(t, find.text('Simpan versi baru'));
    expect(r.queries.length, greaterThan(before));
  });
  testWidgets(
      'product deactivation refreshes retained advertisement eligibility',
      (t) async {
    final r = FakeAchievements();
    final market = FakeMarketplace()
      ..value = const MarketProduct(
          id: 'product-1',
          name: 'Produk Fixture',
          description: 'Deskripsi produk fixture',
          price: 75000,
          stock: 3,
          version: 2,
          sellerId: '2',
          sellerName: 'Penjual Fixture',
          communityId: '2',
          communityName: 'Komunitas Fixture',
          photoAssetId: 'asset-synthetic');
    await t.pumpWidget(achievementsApp(
        const MarketProductFormScreen(id: 'product-1'), r,
        market: market, watchAds: true));
    await t.pumpAndSettle();
    final before = r.queries.length;
    await visibleTap(t, find.byType(SwitchListTile));
    await visibleTap(t, find.text('Simpan barang'));
    expect(r.queries.length, greaterThan(before));
  });
  testWidgets('final package purchase refreshes retained own point summary',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        Consumer(
            builder: (context, ref, _) => Scaffold(
                    body: Column(children: [
                  Text(
                      'SUM ${ref.watch(myAchievementsProvider()).value?.totalPoints}'),
                  const Expanded(child: TrainingScreen(communityId: '1'))
                ]))),
        r));
    await t.pumpAndSettle();
    expect(find.text('SUM 999999999'), findsOneWidget);
    r.totalPoints = 1000000000;
    await visibleTap(t, find.byKey(const Key('training-buy-7')));
    await visibleTap(t, find.byKey(const Key('training-buy-confirm')));
    expect(find.text('SUM 1000000000'), findsOneWidget);
    expect(r.mineCalls, greaterThan(1));
  });
  testWidgets('ranking route back restores period and categories from URI',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(const RankingScreen(), r));
    await t.pumpAndSettle();
    final router = GoRouter.of(t.element(find.byType(RankingScreen)));
    router.go(
        '/explore/rankings?community=2&period=month&month=2026-10&gender=female&age_group=19_35');
    await t.pumpAndSettle();
    router.push(
        '/explore/rankings?community=2&period=all&as_of=2026-11-26&gender=male&age_group=unknown');
    await t.pumpAndSettle();
    expect(r.queries.last['period'], 'all');
    expect(r.queries.last['gender'], 'male');
    router.pop();
    await t.pumpAndSettle();
    expect(find.text('Perempuan'), findsOneWidget);
    expect(t.widget<TextField>(find.byType(TextField).first).controller!.text,
        '2026-10');
    await visibleTap(t, find.byTooltip('Muat ulang'));
    expect(r.queries.last['period'], 'month');
    expect(r.queries.last['month'], '2026-10');
    expect(r.queries.last['gender'], 'female');
    expect(r.queries.last['age_group'], '19_35');
  });
  testWidgets('new member search clears hidden previous recipient before award',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const CommunityAchievementsScreen(communityId: '2'), r));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Anggota penerima poin'));
    await visibleTap(t, find.text('Atlet Fixture').last);
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nama kegiatan/lomba dan hasil'),
        'Lomba fixture');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi bukti / nomor hasil'),
        'HASIL/004');
    await t.enterText(
        find.widgetWithText(TextField, 'Cari anggota aktif'), 'Anggota lain');
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('achievement-create')));
    expect(r.saveCalls, 0);
    expect(find.text('Pilih anggota.'), findsOneWidget);
  });
  testWidgets('ranking calls filters, keeps category on URL and paging',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const RankingScreen(
            communityId: '2',
            initialMonth: '2026-11',
            initialGender: 'female',
            initialAgeGroup: '19_35'),
        r));
    await t.pumpAndSettle();
    expect(find.text('999.999.999\npoin'), findsOneWidget);
    expect(r.queries.last['community'], '2');
    expect(r.queries.last['gender'], 'female');
    await visibleTap(t, find.byTooltip('Halaman berikutnya'));
    expect(r.queries.last['page'], 2);
    expect(r.queries.last['age_group'], '19_35');
  });
  testWidgets('ranking error retry and empty', (t) async {
    final r = FakeAchievements()
      ..error = const NetworkException('Koneksi terputus');
    await t.pumpWidget(achievementsApp(const RankingScreen(), r));
    await t.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsWidgets);
    r.error = null;
    r.empty = true;
    await visibleTap(t, find.text('Coba Lagi').last);
    expect(find.text('Belum ada poin sah untuk filter ini.'), findsOneWidget);
  });
  testWidgets('points show independent total and provenance', (t) async {
    await t.pumpWidget(
        achievementsApp(const MyAchievementsScreen(), FakeAchievements()));
    await t.pumpAndSettle();
    expect(find.text('999.999.999 poin'), findsOneWidget);
    expect(find.textContaining('HASIL/2026/11/001'), findsOneWidget);
    expect(find.textContaining('tidak dapat dicairkan'), findsOneWidget);
  });
  testWidgets('global settings hidden for community member no rules request',
      (t) async {
    final r = FakeAchievements()..gate = Completer();
    await t.pumpWidget(
        achievementsApp(const AchievementRulesScreen(), r, admin: false));
    await t.pumpAndSettle();
    expect(find.text('Khusus pengelola aplikasi.'), findsOneWidget);
  });
  testWidgets('rules validation, prospective version and double submit lock',
      (t) async {
    final r = FakeAchievements()..saveGate = Completer();
    await t.pumpWidget(achievementsApp(const AchievementRulesScreen(), r));
    await t.pumpAndSettle();
    expect(find.text('Versi 2'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextFormField, 'Alasan perubahan'),
        'Perubahan poin yang dapat diaudit');
    await visibleTap(t, find.text('Simpan versi baru'));
    await t.pump();
    expect(r.ruleCalls, 1);
    expect(r.requests.single['expected_version'], 2);
    expect(find.text('Menyimpan…'), findsOneWidget);
    r.saveGate!.complete();
    await t.pumpAndSettle();
    expect(find.textContaining('Event lama tetap'), findsOneWidget);
  });
  testWidgets('community recorder chooses actual member, posts stable key once',
      (t) async {
    final r = FakeAchievements()..saveGate = Completer();
    await t.pumpWidget(achievementsApp(
        const CommunityAchievementsScreen(communityId: '2'), r));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Anggota penerima poin'));
    await visibleTap(t, find.text('Atlet Fixture').last);
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nama kegiatan/lomba dan hasil'),
        'Lomba persahabatan');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi bukti / nomor hasil'),
        'HASIL/2026/11/002');
    await visibleTap(t, find.byKey(const Key('achievement-create')));
    expect(r.saveCalls, 1);
    expect(r.requests.single['member_id'], 3);
    expect(r.requests.single['idempotency_key'], isNotEmpty);
    expect(r.requests.single.containsKey('points'), false);
    r.saveGate!.complete();
    await t.pumpAndSettle();
    expect(find.textContaining('Ranking diperbarui'), findsOneWidget);
  });
  testWidgets(
      'community correction audit reason sent only to authorized action',
      (t) async {
    final r = FakeAchievements();
    await t.pumpWidget(achievementsApp(
        const CommunityAchievementsScreen(communityId: '2'), r));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Koreksi prestasi'));
    await t.enterText(
        find.widgetWithText(TextField, 'Alasan koreksi minimal 10 karakter'),
        'Koreksi hasil yang telah diperiksa');
    await visibleTap(t, find.text('Koreksi dan batalkan poin'));
    expect(r.correctCalls, 1);
    expect(r.requests.single['expected_version'], 1);
  });
  testWidgets(
      'correction history exposes original and correction actor and timestamps',
      (t) async {
    final r = FakeAchievements()
      ..canManage = false
      ..row = const AchievementRow(
          id: 'event-1',
          name: 'Atlet · Lomba fixture',
          points: 0,
          type: 'champion',
          status: 'corrected',
          actor: 'Pelatih Fixture',
          createdAt: '2026-11-26T01:00:00Z',
          occurredAt: '2026-11-25T00:00:00Z',
          correctedBy: 'Pendiri Fixture',
          correctedAt: '2026-11-26T02:00:00Z',
          correctionReason: 'Hasil kegiatan dibatalkan');
    await t.pumpWidget(achievementsApp(
        const CommunityAchievementsScreen(communityId: '2'), r));
    await t.pumpAndSettle();
    expect(
        find.textContaining(
            'Dicatat 26/11/2026 08:00 WIB oleh Pelatih Fixture'),
        findsOneWidget);
    expect(
        find.textContaining(
            'Koreksi 26/11/2026 09:00 WIB oleh Pendiri Fixture'),
        findsOneWidget);
    expect(find.text('Koreksi prestasi'), findsNothing);
  });
  testWidgets('readonly recorder cannot create or correct', (t) async {
    final r = FakeAchievements()
      ..canManage = false
      ..canCorrect = false;
    await t.pumpWidget(achievementsApp(
        const CommunityAchievementsScreen(communityId: '2'), r));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('achievement-create')), findsNothing);
    expect(find.text('Koreksi prestasi'), findsNothing);
  });
  testWidgets('public ad target reaches actual product route', (t) async {
    await t.pumpWidget(
        achievementsApp(const MemberAdsScreen(), FakeAchievements()));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Lihat produk'));
    expect(find.text('Raket komunitas pilihan'), findsWidgets);
    expect(find.textContaining('75.000'), findsWidgets);
  });
  testWidgets('own ad editor loads snapshot and saves version under lock',
      (t) async {
    final r = FakeAchievements()..saveGate = Completer();
    await t
        .pumpWidget(achievementsApp(const MemberAdFormScreen(id: 'ad-1'), r));
    await t.pumpAndSettle();
    expect(find.text(adFixture.title), findsOneWidget);
    await t.enterText(find.byKey(const Key('ad-title')), 'Iklan terbaru');
    await visibleTap(t, find.byKey(const Key('ad-save')));
    expect(r.saveCalls, 1);
    expect(r.requests.single['expected_version'], 2);
    expect(r.requests.single['target_product_id'], 'product-1');
    r.saveGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('Iklan saya'), findsOneWidget);
  });
  testWidgets('ad remove target can save informational advertising', (t) async {
    final r = FakeAchievements();
    await t
        .pumpWidget(achievementsApp(const MemberAdFormScreen(id: 'ad-1'), r));
    await t.pumpAndSettle();
    await visibleTap(t, find.byType(DropdownButtonFormField<String>).last);
    await visibleTap(t, find.text('Informasi / arahkan ke lapak').last);
    await visibleTap(t, find.byKey(const Key('ad-save')));
    expect(r.requests.single['target_product_id'], null);
  });
  testWidgets('ad delete awaits explicit product dialog then passes version',
      (t) async {
    final r = FakeAchievements();
    await t
        .pumpWidget(achievementsApp(const MemberAdFormScreen(id: 'ad-1'), r));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Hapus iklan'));
    await visibleTap(t, find.widgetWithText(FilledButton, 'Hapus iklan'));
    expect(r.deleteCalls, 1);
    expect(r.requests.single['expected_version'], 2);
  });
  for (final screen in [
    const RankingScreen(),
    const MyAchievementsScreen(),
    const AchievementRulesScreen(),
    const CommunityAchievementsScreen(communityId: '2'),
    const MemberAdsScreen(),
    const MemberAdFormScreen(id: 'ad-1')
  ]) {
    testWidgets('${screen.runtimeType} narrow large text keyboard no overflow',
        (t) async {
      t.view.physicalSize = const Size(500, 900);
      t.view.devicePixelRatio = 1;
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(t.view.reset);
      await t
          .pumpWidget(achievementsApp(screen, FakeAchievements(), scale: 1.5));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView).first, const Offset(0, -1600));
      await t.pumpAndSettle();
      expect(t.takeException(), null);
    });
  }
}
