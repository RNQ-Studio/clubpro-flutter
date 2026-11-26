import 'dart:async';
import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/achievements/presentation/achievements_providers.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/directory/presentation/directory_providers.dart';
import 'package:app_main/features/directory/presentation/directory_screen.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/home/presentation/widgets/lobby_links.dart';
import 'package:app_main/features/home/presentation/widgets/member_lobby_card.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../community/fake_community_repository.dart';
import '../directory/s02_screens_test.dart' show FixedAuth, FakeDirectory;

const lobbyUser = User(
    id: 's07-lobby',
    name: 'Anggota Uji',
    email: 'uji@anaklangit.manahpro.web.id');

Widget lobbyApp(Widget child,
    {bool guest = false,
    bool admin = false,
    Completer<WalletSummary>? wallet,
    Completer<AchievementPage>? points,
    double scale = 1}) {
  final auth = guest
      ? const AuthUnauthenticated()
      : AuthAuthenticated(admin
          ? const User(
              id: 'super',
              name: 'Pusat',
              email: 'pusat@anaklangit.manahpro.web.id',
              roles: [User.superAdminRole])
          : lobbyUser);
  final router = GoRouter(routes: [
    GoRoute(
        path: '/',
        builder: (_, __) => (child is DirectoryScreen ||
                child is PublicCommunityScreen)
            ? child
            : Scaffold(
                body: SingleChildScrollView(
                    child: Center(
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 760),
                            child: child))))),
    for (final path in [
      AppRoutes.wallet,
      AppRoutes.myAchievements,
      AppRoutes.myAds,
      AppRoutes.payouts,
      AppRoutes.topup,
      AppRoutes.achievementRules,
      AppRoutes.rankings,
      AppRoutes.memberAds,
      '/explore',
      '/login',
      AppRoutes.createCommunity,
      AppRoutes.communityCard('2'),
      AppRoutes.communityBilling('2'),
      AppRoutes.communityTraining('2')
    ])
      GoRoute(
          path: path,
          builder: (_, s) =>
              Scaffold(appBar: AppBar(), body: Text('DEST ${s.uri}'))),
  ]);
  return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => FixedAuth(auth)),
        walletSummaryProvider.overrideWith((ref) =>
            wallet?.future ??
            Future.value(const WalletSummary(available: 999999999))),
        myAchievementsProvider().overrideWith((ref) =>
            points?.future ??
            Future.value(const AchievementPage([], totalPoints: 987654321))),
        directoryRepositoryProvider.overrideWithValue(FakeDirectory()),
      ],
      child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: w!)));
}

void main() {
  testWidgets(
      'own lobby separates actual points and rupiah and role visibility',
      (t) async {
    await t
        .pumpWidget(lobbyApp(MemberLobbyCard(community: testCommunity('2'))));
    await t.pumpAndSettle();
    expect(find.text('987.654.321 poin'), findsOneWidget);
    expect(find.byKey(const Key('member-lobby-balance')), findsOneWidget);
    expect(find.byKey(const Key('member-lobby-point-rules')), findsNothing);
    await t.ensureVisible(find.byKey(const Key('member-lobby-card')));
    await t.tap(find.byKey(const Key('member-lobby-card')));
    await t.pumpAndSettle();
    expect(find.text('DEST ${AppRoutes.communityCard('2')}'), findsOneWidget);
  });
  testWidgets('guest cannot mount own balance or achievement requests',
      (t) async {
    final w = Completer<WalletSummary>(), p = Completer<AchievementPage>();
    await t.pumpWidget(
        lobbyApp(const MemberLobbyCard(), guest: true, wallet: w, points: p));
    await t.pumpAndSettle();
    expect(find.text('Ruang anggota saya'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('large figures and text remain readable with keyboard at 320px',
      (t) async {
    t.view.physicalSize = const Size(320, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
        lobbyApp(MemberLobbyCard(community: testCommunity('2')), scale: 1.5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.pumpWidget(lobbyApp(const DirectoryScreen(initialMembers: true),
        guest: true, scale: 1.3));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byType(TextField), 300);
    t.view.viewInsets = const FakeViewPadding(bottom: 320);
    await t.enterText(find.byType(TextField), 'Nama panjang');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('loading and errors never invent zero money or points',
      (t) async {
    final w = Completer<WalletSummary>(), p = Completer<AchievementPage>();
    await t.pumpWidget(lobbyApp(const MemberLobbyCard(), wallet: w, points: p));
    await t.pump();
    expect(find.text('Memuat saldo…'), findsOneWidget);
    expect(find.text('Memuat poin…'), findsOneWidget);
    w.completeError(Exception('offline'));
    p.completeError(Exception('offline'));
    await t.pumpAndSettle();
    expect(find.text('Saldo gagal dimuat · Coba lagi'), findsOneWidget);
    expect(find.text('Poin gagal dimuat · Coba lagi'), findsOneWidget);
    expect(find.text('0 poin'), findsNothing);
  });
  testWidgets(
      'public member search opens exact member mode and approved origins',
      (t) async {
    await t.pumpWidget(
        lobbyApp(const DirectoryScreen(initialMembers: true), guest: true));
    await t.pumpAndSettle();
    expect(find.text('Cari nama anggota'), findsOneWidget);
    expect(find.text('Anggota · Komunitas Uji'), findsOneWidget);
    await t.tap(find.byKey(const Key('lobby-create-community')));
    await t.pumpAndSettle();
    final target = t.widget<Text>(find.textContaining('DEST /login')).data!;
    expect(
        decodeLoginReturn(
            Uri.parse(target.substring(5)).queryParameters['from']),
        AppRoutes.createCommunity);
  });
  testWidgets(
      'main lobby keeps member search route distinct from community search',
      (t) async {
    await t.pumpWidget(lobbyApp(const PublicLobbyLinks()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('home-public-members')));
    await t.pumpAndSettle();
    expect(find.text('DEST /explore?members=1'), findsOneWidget);
  });
  testWidgets('community mutations absent for ordinary members', (t) async {
    await t.pumpWidget(lobbyApp(const CommunityLobbyLinks(communityId: '2')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('community-record-achievement')), findsNothing);
    await t.tap(find.byKey(const Key('community-member-rankings')));
    await t.pumpAndSettle();
    expect(find.text('DEST ${AppRoutes.rankings}?community=2'), findsOneWidget);
  });
}
