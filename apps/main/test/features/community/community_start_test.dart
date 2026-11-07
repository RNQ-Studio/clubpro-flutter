import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/community_start_screen.dart';
import 'package:app_main/features/community/presentation/widgets/club_hero.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_community_repository.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this.fixed);

  final AuthState fixed;

  @override
  AuthState build() => fixed;

  @override
  Future<void> checkCurrentUser() async {}
}

const _me = User(id: 'u1', name: 'Rina Ayu Lestari', email: 'rina@gmail.com');

List<Override> _overrides(FakeCommunityRepository repository) => [
      authProvider.overrideWith(
        () => _FixedAuthNotifier(const AuthAuthenticated(_me)),
      ),
      communityRepositoryProvider.overrideWithValue(repository),
      activeCommunityStoreProvider
          .overrideWithValue(FakeActiveCommunityStore()),
    ];

Widget _startApp(FakeCommunityRepository repository) {
  final router = GoRouter(
    initialLocation: AppRoutes.communityStart,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
      GoRoute(
        path: AppRoutes.communityStart,
        builder: (_, __) => const CommunityStartScreen(),
      ),
      GoRoute(
        path: AppRoutes.communities,
        builder: (_, __) => Scaffold(
          appBar: AppBar(),
          body: const Text('HALAMAN KOMUNITAS'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: _overrides(repository),
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void main() {
  group('rute tab komunitas', () {
    test('nama tab ↔ indeks', () {
      expect(ClubTab.fromName(null), ClubTab.info);
      expect(ClubTab.fromName('anggota'), ClubTab.members);
      expect(ClubTab.fromName('galeri'), ClubTab.gallery);
      expect(ClubTab.fromName('kegiatan'), ClubTab.activities);
      expect(ClubTab.fromName('tidak-ada'), ClubTab.info);
    });

    test('lokasi: Info tanpa parameter, tab lain dengan ?tab=', () {
      expect(ClubTab.location('5', ClubTab.info), '/communities/5');
      expect(
        ClubTab.location('5', ClubTab.members),
        '/communities/5?tab=anggota',
      );
      expect(
        ClubTab.location('5', ClubTab.activities),
        '/communities/5?tab=kegiatan',
      );
      expect(
        ClubTab.location('5', ClubTab.gallery),
        '/communities/5?tab=galeri',
      );
    });
  });

  group('layar Gabung Komunitas', () {
    testWidgets('sapaan, pilihan cari/daftarkan, dan rekomendasi',
        (tester) async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('8', name: 'Gowes Bogor', membersCount: 140)],
      ]);
      await tester.pumpWidget(_startApp(repository));
      await tester.pumpAndSettle();

      expect(find.text('Gabung Komunitas'), findsOneWidget);
      expect(find.text('Satu langkah lagi, Rina!'), findsOneWidget);
      expect(find.text('Cari Komunitas'), findsOneWidget);
      expect(find.text('Daftarkan Komunitas Baru'), findsOneWidget);
      expect(find.text('Gowes Bogor'), findsOneWidget);
      expect(repository.listCalls.single.sort, CommunitySort.popular);
      // Langkah awal: tidak ada tombol kembali.
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('Nanti saja → Beranda', (tester) async {
      await tester.pumpWidget(_startApp(FakeCommunityRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community-start-skip')));
      await tester.pumpAndSettle();

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('cari komunitas lalu kembali ke langkah ini', (tester) async {
      await tester.pumpWidget(_startApp(FakeCommunityRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community-start-find')));
      await tester.pumpAndSettle();
      expect(find.text('HALAMAN KOMUNITAS'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Gabung Komunitas'), findsOneWidget);
    });

    testWidgets('sudah tergabung di komunitas → langsung Beranda',
        (tester) async {
      await tester.pumpWidget(_startApp(FakeCommunityRepository(
        joined: [testCommunity('1', myRole: CommunityRole.member)],
      )));
      await tester.pumpAndSettle();

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('hanya permintaan menunggu: tetap di langkah ini',
        (tester) async {
      await tester.pumpWidget(_startApp(FakeCommunityRepository(
        joined: [
          testCommunity(
            '1',
            myRole: CommunityRole.member,
            myStatus: CommunityMembershipStatus.pending,
          ),
        ],
      )));
      await tester.pumpAndSettle();

      expect(find.text('Gabung Komunitas'), findsOneWidget);
      expect(find.text('Menunggu persetujuan pengurus'), findsOneWidget);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      tester.view.physicalSize = const Size(640, 1280);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_startApp(FakeCommunityRepository(pages: [
        [
          for (var i = 0; i < 5; i++)
            testCommunity(
              '$i',
              name: 'Komunitas Dengan Nama Yang Cukup Panjang $i',
              membersCount: 1200 - i,
            ),
        ],
      ])));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('rute app', () {
    /// Langsung ke [location], tanpa melewati splash beranimasi.
    Future<void> pumpAppRouter(
      WidgetTester tester,
      FakeCommunityRepository repository,
      String location,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.7;
      addTearDown(tester.view.reset);
      appRouter.go(location);
      await tester.pumpWidget(ProviderScope(
        overrides: _overrides(repository),
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
        ),
      ));
    }

    testWidgets('Lengkapi Data Diri → langkah Gabung Komunitas',
        (tester) async {
      await pumpAppRouter(
        tester,
        FakeCommunityRepository(),
        AppRoutes.profileSetup,
      );
      await tester.pumpAndSettle();
      expect(find.text('Lengkapi Data Diri'), findsOneWidget);

      await tester.tap(find.byKey(const Key('skip-profile-setup')));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityStartScreen), findsOneWidget);
    });

    testWidgets('?tab= membuka tab itu di halaman komunitas', (tester) async {
      await pumpAppRouter(
        tester,
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          activities: CommunityActivities(upcoming: [
            testActivity(
              'a1',
              title: 'Latihan Malam',
              startsAt: DateTime.now().add(const Duration(days: 2)),
            ),
          ]),
        ),
        ClubTab.location('1', ClubTab.activities),
      );
      await tester.pumpAndSettle();

      final tabs = DefaultTabController.of(
        tester.element(find.byType(TabBarView)),
      );
      expect(tabs.index, ClubTab.activities);
      expect(find.text('Latihan Malam'), findsWidgets);
    });
  });
}
