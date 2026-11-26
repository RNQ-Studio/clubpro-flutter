import 'package:app_main/app.dart';
import 'package:app_main/config/main_config.dart';
import 'package:app_main/features/achievements/presentation/achievement_screens.dart';
import 'package:app_main/features/achievements/presentation/achievements_providers.dart';
import 'package:app_main/features/achievements/presentation/member_ads_screens.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/community_detail_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_form_screen.dart';
import 'package:app_main/features/directory/presentation/directory_providers.dart';
import 'package:app_main/features/directory/presentation/directory_screen.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import 'package:app_main/features/finance/presentation/billing_screen.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/finance/presentation/topup_screen.dart';
import 'package:app_main/features/finance/presentation/wallet_screen.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_providers.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_screen.dart';
import 'package:app_main/features/member_card/domain/entities/member_card.dart';
import 'package:app_main/features/member_card/domain/repositories/member_card_repository.dart';
import 'package:app_main/features/member_card/presentation/member_card_providers.dart';
import 'package:app_main/features/member_card/presentation/screens/member_card_screen.dart';
import 'package:app_main/features/money_movement/presentation/money_movement_providers.dart';
import 'package:app_main/features/money_movement/presentation/payouts_screen.dart';
import 'package:app_main/features/training/presentation/training_providers.dart';
import 'package:app_main/features/training/presentation/training_screen.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'features/achievements/fake_achievements_repository.dart';
import 'features/community/fake_community_repository.dart';
import 'features/directory/s02_screens_test.dart' show FixedAuth, FakeDirectory;
import 'features/dues/fake_dues_repository.dart';
import 'features/finance/finance_screens_test.dart'
    show FakeFinance, billingFixture;
import 'features/marketplace/fake_marketplace_repository.dart';
import 'features/money_movement/fake_movement_repository.dart';
import 'features/training/fake_training_repository.dart';

class _Database extends Mock implements AppDatabase {}

class _Cards implements MemberCardRepository {
  bool expired = false;
  final calls = <String>[];
  @override
  Future<MemberCard> getCard(String id) async {
    calls.add(id);
    return MemberCard(
        memberNumber: 'S07-KTA-001',
        name: 'Atlet Journey',
        roleLabel: 'Anggota',
        community: testCommunity(id),
        validity: MemberCardValidity(
            status:
                expired ? MemberCardStatus.expired : MemberCardStatus.active,
            validUntil: DateTime(2026, 12, 31)));
  }
}

Widget _application(
        {required MarketStorage storage,
        required CommunityRole role,
        required FakeCommunityRepository communities,
        required FakeFinance finance,
        required FakeAchievements points,
        required FakeTraining training,
        required FakeMarketplace market,
        required _Cards cards}) =>
    ProviderScope(overrides: [
      authProvider.overrideWith(() => FixedAuth(const AuthAuthenticated(User(
          id: 'journey',
          name: 'Atlet Journey',
          email: 'journey@anaklangit.manahpro.web.id',
          pinEnabled: true,
          completion:
              ProfileCompletion(completed: 12, total: 12, missing: []))))),
      communityRepositoryProvider.overrideWithValue(communities),
      financeRepositoryProvider.overrideWithValue(finance),
      duesRepositoryProvider.overrideWithValue(FakeDuesRepository()),
      achievementsRepositoryProvider.overrideWithValue(points),
      trainingRepositoryProvider.overrideWithValue(training),
      marketplaceRepositoryProvider.overrideWithValue(market),
      moneyMovementRepositoryProvider.overrideWithValue(FakeMovement()),
      memberCardRepositoryProvider.overrideWithValue(cards),
      directoryRepositoryProvider.overrideWithValue(FakeDirectory()),
      homePromotionsProvider
          .overrideWith((ref) async => const HomePromotions()),
      settingsRepositoryProvider
          .overrideWith((ref) async => SettingsRepositoryImpl(storage)),
    ], child: App(storage: storage, database: _Database()));

Future<void> _tap(WidgetTester t, String key) async {
  final target = find.byKey(Key(key));
  for (var i = 0; i < 24 && target.evaluate().isEmpty; i++) {
    await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await t.pumpAndSettle();
  }
  expect(target, findsOneWidget, reason: 'CTA $key must be reachable');
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  for (var i = 0; i < 12 && target.hitTestable().evaluate().isEmpty; i++) {
    final dy = t.getCenter(target).dy;
    await t.drag(
        find.byType(Scrollable).first, Offset(0, dy > 600 ? -250 : 250));
    await t.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await t.tap(target);
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    AppConfig.instance = MainConfig();
    PackageInfo.setMockInitialValues(
        appName: 'CEO',
        packageName: 'fixture',
        version: '1',
        buildNumber: '1',
        buildSignature: '');
  });
  final cases =
      <({String key, Type destination, String evidence, CommunityRole role})>[
    (
      key: 'member-lobby-points',
      destination: MyAchievementsScreen,
      evidence: '999.999.999 poin',
      role: CommunityRole.member
    ),
    (
      key: 'member-lobby-ads',
      destination: MemberAdsScreen,
      evidence: adFixture.title,
      role: CommunityRole.member
    ),
    (
      key: 'member-lobby-card',
      destination: MemberCardScreen,
      evidence: 'S07-KTA-001',
      role: CommunityRole.member
    ),
    (
      key: 'member-lobby-dues',
      destination: BillingScreen,
      evidence: 'Siapkan perpanjangan',
      role: CommunityRole.member
    ),
    (
      key: 'member-lobby-packages',
      destination: TrainingScreen,
      evidence: 'Komunitas Fixture',
      role: CommunityRole.coach
    ),
    (
      key: 'member-lobby-topup',
      destination: TopupScreen,
      evidence: 'Top up',
      role: CommunityRole.member
    ),
    (
      key: 'member-lobby-payouts',
      destination: PayoutsScreen,
      evidence: 'Pencairan',
      role: CommunityRole.member
    ),
    (
      key: 'home-wallet',
      destination: WalletScreen,
      evidence: 'Saldo uang digital',
      role: CommunityRole.member
    ),
    (
      key: 'home-public-directory',
      destination: DirectoryScreen,
      evidence: 'Komunitas Uji',
      role: CommunityRole.member
    ),
    (
      key: 'home-public-members',
      destination: DirectoryScreen,
      evidence: 'Anggota · Komunitas Uji',
      role: CommunityRole.officer
    ),
    (
      key: 'home-community-rankings',
      destination: RankingScreen,
      evidence: rowFixture.name,
      role: CommunityRole.member
    ),
    (
      key: 'home-public-ads',
      destination: MemberAdsScreen,
      evidence: adFixture.title,
      role: CommunityRole.member
    ),
    (
      key: 'market-entry-main',
      destination: MarketplaceScreen,
      evidence: marketProductFixture.name,
      role: CommunityRole.member
    ),
    (
      key: 'market-entry-mine',
      destination: MarketplaceScreen,
      evidence: marketProductFixture.name,
      role: CommunityRole.member
    ),
    (
      key: 'community-member-rankings',
      destination: RankingScreen,
      evidence: rowFixture.name,
      role: CommunityRole.admin
    ),
    (
      key: 'community-member-ads',
      destination: MemberAdsScreen,
      evidence: adFixture.title,
      role: CommunityRole.member
    ),
    (
      key: 'market-entry-community',
      destination: MarketplaceScreen,
      evidence: marketProductFixture.name,
      role: CommunityRole.member
    ),
    (
      key: 'community-record-achievement',
      destination: CommunityAchievementsScreen,
      evidence: 'Referensi: HASIL/2026/11/001',
      role: CommunityRole.creator
    ),
    (
      key: 'home-club-card',
      destination: CommunityDetailScreen,
      evidence: 'Pemanah Nusantara',
      role: CommunityRole.member
    ),
  ];
  testWidgets(
      'actual App expired community retains billing and KTA, hides recording',
      (t) async {
    t.view.physicalSize = const Size(500, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final base = testDetail(id: '2', myRole: CommunityRole.creator);
    final detail = CommunityDetail(
        id: base.id,
        name: base.name,
        shortName: base.shortName,
        type: base.type,
        typeLabel: base.typeLabel,
        status: base.status,
        cityName: base.cityName,
        provinceName: base.provinceName,
        description: base.description,
        address: base.address,
        contactName: base.contactName,
        contactPhone: base.contactPhone,
        myRole: CommunityRole.creator,
        isMember: true,
        canManage: true,
        entitlementActive: false,
        platformActive: false);
    final communities = FakeCommunityRepository(
        joined: [testCommunity('2', myRole: CommunityRole.creator)],
        detail: detail);
    final finance = FakeFinance()..billingValue = billingFixture();
    final cards = _Cards()..expired = true;
    appRouter.go('/');
    await t.pumpWidget(_application(
        storage: MarketStorage(),
        role: CommunityRole.creator,
        communities: communities,
        finance: finance,
        points: FakeAchievements(),
        training: FakeTraining(),
        market: FakeMarketplace(),
        cards: cards));
    await t.pumpAndSettle();
    expect(
        find.textContaining('Keanggotaan atau langganan komunitas tidak aktif'),
        findsOneWidget);
    expect(find.byKey(const Key('community-record-achievement')), findsNothing);
    await _tap(t, 'member-lobby-dues');
    expect(find.byType(BillingScreen), findsOneWidget);
    expect(find.textContaining('150.000'), findsWidgets);
    appRouter.pop();
    await t.pumpAndSettle();
    await _tap(t, 'member-lobby-card');
    expect(find.byType(MemberCardScreen), findsOneWidget);
    expect(find.text('S07-KTA-001'), findsOneWidget);
    final container =
        ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
    expect(container.read(memberCardProvider('2')).requireValue.validity.status,
        MemberCardStatus.expired);
    expect(cards.calls, contains('2'));
    expect(t.takeException(), null);
    await t.pumpWidget(const SizedBox.shrink());
  });
  for (final c in cases) {
    testWidgets(
        'actual App ${c.role.apiValue}: ${c.key} loads real destination',
        (t) async {
      t.view.physicalSize = const Size(500, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final communities = FakeCommunityRepository(
          joined: [testCommunity('2', myRole: c.role)],
          detail: testDetail(id: '2', myRole: c.role),
          members: [testMember('3', name: 'Atlet Journey')]);
      final finance = FakeFinance()
        ..billingValue = billingFixture(active: true, amount: 0);
      final points = FakeAchievements(),
          training = FakeTraining(),
          market = FakeMarketplace(),
          cards = _Cards();
      appRouter.go('/');
      await t.pumpWidget(_application(
          storage: MarketStorage(),
          role: c.role,
          communities: communities,
          finance: finance,
          points: points,
          training: training,
          market: market,
          cards: cards));
      await t.pumpAndSettle();
      await _tap(t, c.key);
      expect(find.byType(c.destination), findsOneWidget);
      expect(find.textContaining(c.evidence), findsWidgets);
      if (c.destination == MemberCardScreen) expect(cards.calls, contains('2'));
      if (c.destination == TrainingScreen) {
        expect(training.loads, greaterThan(0));
      }
      if (c.destination == MarketplaceScreen) {
        expect(market.queries, isNotEmpty);
      }
      if (c.destination == RankingScreen) expect(points.queries, isNotEmpty);
      if (c.key == 'home-public-directory') {
        await _tap(t, 'lobby-create-community');
        expect(find.byType(CommunityFormScreen), findsOneWidget);
        expect(find.byType(TextFormField), findsWidgets);
      }
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
