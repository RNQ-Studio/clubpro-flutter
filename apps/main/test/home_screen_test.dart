import 'dart:async';

import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/widgets/club_hero.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import 'package:app_main/features/home/data/banner_remote_data_source.dart';
import 'package:app_main/features/home/domain/app_refresher.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/domain/entities/promotion_action.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/features/home/presentation/widgets/home_app_version.dart';
import 'package:app_main/features/home/presentation/widgets/home_club_card.dart';
import 'package:app_main/features/home/presentation/widgets/home_club_sections.dart';
import 'package:app_main/features/home/presentation/widgets/home_user_header.dart';
import 'package:app_main/features/home/presentation/widgets/promotion_popup.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'features/community/fake_community_repository.dart';
import 'features/dues/fake_dues_repository.dart';
import 'features/home/fake_promotion_popup_store.dart';

class _FakeRefresher implements AppRefresher {
  _FakeRefresher({this.error});

  final Exception? error;
  int calls = 0;

  @override
  Future<void> refresh() async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
  }
}

class _FakeBannerSource implements BannerRemoteDataSource {
  _FakeBannerSource(this._fetch);

  final Future<HomePromotions> Function() _fetch;

  @override
  Future<HomePromotions> fetchPromotions() => _fetch();
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> checkCurrentUser() async {}
}

const _incompleteUser =
    User(id: '1', name: 'Rina Ayu', email: 'rina@gmail.com');
const _completeUser = User(
  id: '1',
  name: 'Rina Ayu',
  email: 'rina@gmail.com',
  completion: ProfileCompletion(completed: 12, total: 12, missing: []),
);

const _superAdmin = User(
  id: '1',
  name: 'Rina Ayu',
  email: 'rina@gmail.com',
  roles: [User.superAdminRole],
);

const _banners = [
  HomeBanner(id: '1', title: 'Latihan Bersama Akhir Pekan'),
  HomeBanner(id: '2', title: 'Pendaftaran Kejuaraan Dibuka'),
];

/// Tanpa promosi bawaan: popup menutupi Beranda.
Widget _app({
  User user = _incompleteUser,
  List<HomeBanner> promotions = const [],
  int intervalHours = 24,
  Future<HomePromotions>? loadingPromotions,
  FakePromotionPopupStore? popupStore,
  AppRefresher? refresher,
  FakeCommunityRepository? communities,
  FakeActiveCommunityStore? store,
  FakeDuesRepository? dues,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'communities',
            builder: (_, __) => Scaffold(
              appBar: AppBar(),
              body: const Text('HALAMAN KOMUNITAS'),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => Scaffold(
                  appBar: AppBar(),
                  body: const Text('HALAMAN DAFTARKAN'),
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => Scaffold(
                  appBar: AppBar(),
                  body: Text(
                    'KLUB ${state.pathParameters['id']}'
                    '${state.uri.queryParameters['tab'] == null ? '' : ' tab=${state.uri.queryParameters['tab']}'}',
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'card',
                    builder: (_, state) => Scaffold(
                      appBar: AppBar(),
                      body: Text('KARTU ${state.pathParameters['id']}'),
                    ),
                  ),
                  GoRoute(
                    path: 'dues',
                    builder: (_, state) => Scaffold(
                      appBar: AppBar(),
                      body: Text('IURAN ${state.pathParameters['id']}'),
                    ),
                    routes: [
                      for (final page in [
                        'pay',
                        'payments',
                        'members',
                        'settings',
                      ])
                        GoRoute(
                          path: page,
                          builder: (_, state) => Scaffold(
                            appBar: AppBar(),
                            body: Text(
                              'IURAN ${state.pathParameters['id']} $page',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => Scaffold(
              appBar: AppBar(),
              body: const Text('HALAMAN PROFIL'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (_, __) => const Text('HALAMAN ADMIN'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider
          .overrideWith(() => _FixedAuthNotifier(AuthAuthenticated(user))),
      homePromotionsProvider.overrideWith(
        (ref) =>
            loadingPromotions ??
            Future.value(HomePromotions(
              banners: promotions,
              intervalHours: intervalHours,
            )),
      ),
      promotionPopupStoreProvider
          .overrideWithValue(popupStore ?? FakePromotionPopupStore()),
      appRefresherProvider.overrideWithValue(refresher),
      communityRepositoryProvider
          .overrideWithValue(communities ?? FakeCommunityRepository()),
      activeCommunityStoreProvider
          .overrideWithValue(store ?? FakeActiveCommunityStore()),
      duesRepositoryProvider.overrideWithValue(
        dues ?? FakeDuesRepository(overview: notConfigured),
      ),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

/// Anggota satu komunitas: Beranda langsung membuka komunitas itu.
FakeCommunityRepository _member({
  CommunityRole role = CommunityRole.member,
  CommunityStatus status = CommunityStatus.approved,
  int pendingMembersCount = 0,
  CommunityActivities activities = const CommunityActivities(),
  bool duesConfigured = false,
  int pendingDuesPaymentsCount = 0,
}) =>
    FakeCommunityRepository(
      joined: [
        testCommunity('1', myRole: role, status: status, membersCount: 24),
      ],
      detail: testDetail(
        myRole: role,
        status: status,
        membersCount: 24,
        pendingMembersCount: pendingMembersCount,
        upcomingActivitiesCount: activities.upcoming.length,
        duesConfigured: duesConfigured,
        pendingDuesPaymentsCount: pendingDuesPaymentsCount,
      ),
      activities: activities,
    );

final _clubs = [
  testCommunity(
    '1',
    name: 'Pemanah Nusantara',
    myRole: CommunityRole.creator,
    membersCount: 24,
  ),
  testCommunity(
    '2',
    name: 'Futsal Bandung',
    myRole: CommunityRole.admin,
    membersCount: 12,
  ),
  testCommunity(
    '3',
    name: 'Gowes Bogor',
    myRole: CommunityRole.member,
    membersCount: 40,
  ),
];

FakeCommunityRepository _manyClubs() => FakeCommunityRepository(
      joined: _clubs,
      detail: testDetail(myRole: CommunityRole.member),
    );

const _day = Duration(days: 1);

/// Isi Beranda dibangun bertahap; gulir ke dasar agar semua bagiannya dibuat.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -4000));
  await tester.pumpAndSettle();
}

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Beranda anggota: info user, komunitas aktif, menu',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(communities: _member()));
    await tester.pumpAndSettle();

    // Info singkat user: foto (inisial bila tanpa foto), nama, email.
    expect(find.text('Rina Ayu'), findsOneWidget);
    expect(find.text('rina@gmail.com'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);

    // Komunitas aktif di bawah info user, lalu menu; banner tidak lagi di sini.
    expect(find.text('Pemanah Nusantara'), findsOneWidget);
    expect(find.text('Masuk sebagai anggota'), findsOneWidget);
    expect(find.text('24 anggota'), findsOneWidget);
    final header = tester.getRect(find.byType(HomeUserHeader));
    final card = tester.getRect(find.byType(HomeClubCard));
    final menu = tester.getTopLeft(find.text('Menu Komunitas')).dy;
    expect(header.bottom, lessThanOrEqualTo(card.top));
    expect(card.bottom, lessThanOrEqualTo(menu));
    expect(find.byKey(const Key('home-banner-slider')), findsNothing);

    for (final (tab, label, _, _) in HomeClubMenu.items) {
      expect(
        find.descendant(
          of: find.byKey(Key('home-club-menu-$tab')),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
    }
    expect(HomeClubMenu.items.map((i) => i.$2),
        ['Info', 'Anggota', 'Kegiatan', 'Galeri']);
    // Kartu Anggota paling depan.
    expect(
      find.descendant(
        of: find.byKey(const Key('home-club-menu-card')),
        matching: find.text('Kartu Anggota'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('home-club-menu-card'))).dx,
      lessThan(tester
          .getTopLeft(find.byKey(Key('home-club-menu-${ClubTab.info}')))
          .dx),
    );
    // Anggota biasa tidak melihat sisi pengelola, dan tidak bisa ganti
    // komunitas karena hanya ikut satu.
    expect(find.byKey(const Key('home-manager-panel')), findsNothing);
    expect(find.byKey(const Key('home-club-switch')), findsNothing);
  });

  testWidgets('tidak ada lagi menu "Segera hadir"', (tester) async {
    _phoneScreen(tester);
    for (final communities in [
      _member(),
      _manyClubs(),
      FakeCommunityRepository(),
    ]) {
      await tester.pumpWidget(_app(communities: communities));
      await tester.pumpAndSettle();

      for (final label in [
        'Menu Utama',
        'Absensi',
        'Iuran Bulanan',
        'Top-up Saldo',
        'Riwayat Transaksi',
        'Pengumuman',
        'Segera hadir',
      ]) {
        expect(find.text(label), findsNothing, reason: label);
      }
    }
  });

  group('menu komunitas', () {
    for (final (tab, label, query) in [
      (ClubTab.info, 'Info', ''),
      (ClubTab.members, 'Anggota', ' tab=anggota'),
      (ClubTab.activities, 'Kegiatan', ' tab=kegiatan'),
      (ClubTab.gallery, 'Galeri', ' tab=galeri'),
    ]) {
      testWidgets('$label membuka tabnya di halaman komunitas lalu kembali',
          (tester) async {
        _phoneScreen(tester);
        await tester.pumpWidget(_app(communities: _member()));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(Key('home-club-menu-$tab')));
        await tester.pumpAndSettle();
        expect(find.text('KLUB 1$query'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(HomeClubCard), findsOneWidget);
      });
    }

    testWidgets('Kartu Anggota membuka kartu komunitas aktif lalu kembali',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: _member()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-club-menu-card')));
      await tester.pumpAndSettle();
      expect(find.text('KARTU 1'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeClubCard), findsOneWidget);
    });

    testWidgets('lima menu muat di ponsel kecil dengan teks besar',
        (tester) async {
      tester.view.physicalSize = const Size(320, 700) * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(communities: _member()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home-club-menu-card')), findsOneWidget);
    });

    testWidgets('kartu komunitas membuka halaman komunitasnya', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: _member()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-club-card')));
      await tester.pumpAndSettle();

      expect(find.text('KLUB 1'), findsOneWidget);
    });
  });

  group('sisi pengelola', () {
    testWidgets('creator: panel Kelola Komunitas dengan permintaan menunggu',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(
          role: CommunityRole.creator,
          pendingMembersCount: 2,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Masuk sebagai creator'), findsOneWidget);
      expect(find.text('Kelola Komunitas'), findsOneWidget);
      expect(find.text('Anda Creator di komunitas ini'), findsOneWidget);
      expect(find.text('2 menunggu persetujuan'), findsOneWidget);
      expect(find.text('Belum ada kegiatan terjadwal'), findsOneWidget);
      expect(find.text('Belum ada foto'), findsOneWidget);
      final badge = tester
          .widget<Badge>(find.byKey(const Key('home-club-requests-badge')));
      expect(badge.isLabelVisible, isTrue);

      await tester.ensureVisible(find.byKey(const Key('home-manage-requests')));
      await tester.tap(find.byKey(const Key('home-manage-requests')));
      await tester.pumpAndSettle();
      expect(find.text('KLUB 1 tab=anggota'), findsOneWidget);
    });

    testWidgets('admin: panel ikut tampil; kegiatan & galeri ke tabnya',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(
          role: CommunityRole.admin,
          activities: CommunityActivities(upcoming: [
            testActivity('a1', startsAt: DateTime.now().add(_day)),
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Anda Admin di komunitas ini'), findsOneWidget);
      expect(find.text('Tidak ada yang menunggu'), findsOneWidget);
      expect(find.text('1 kegiatan mendatang'), findsOneWidget);
      expect(
        tester
            .widget<Badge>(find.byKey(const Key('home-club-requests-badge')))
            .isLabelVisible,
        isFalse,
      );

      for (final (key, location) in [
        ('home-manage-activities', 'KLUB 1 tab=kegiatan'),
        ('home-manage-gallery', 'KLUB 1 tab=galeri'),
      ]) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.text(location), findsOneWidget, reason: key);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('anggota biasa: tanpa panel walau server mengirim angka',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(pendingMembersCount: 5),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Komunitas'), findsNothing);
      expect(
        tester
            .widget<Badge>(find.byKey(const Key('home-club-requests-badge')))
            .isLabelVisible,
        isFalse,
      );
    });

    testWidgets('pengajuan belum diverifikasi: status di kartu dan panel',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(
          role: CommunityRole.creator,
          status: CommunityStatus.pending,
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(HomeClubCard),
          matching: find.text('Menunggu Verifikasi'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('home-manager-notice')), findsOneWidget);
      expect(find.textContaining('belum bisa ditemukan'), findsOneWidget);
    });
  });

  group('iuran', () {
    testWidgets('iuran saya: tunggakan dan tombol Bayar', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(duesConfigured: true),
        dues: FakeDuesRepository(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Iuran Saya'), findsOneWidget);
      expect(find.text('Menunggak 3 bulan'), findsOneWidget);
      expect(find.text('2 bulan menunggu verifikasi'), findsOneWidget);
      // Tepat di bawah kartu komunitas.
      expect(
        tester.getTopLeft(find.byKey(const Key('home-dues-card'))).dy,
        greaterThan(tester.getBottomLeft(find.byType(HomeClubCard)).dy),
      );

      await tester.tap(find.byKey(const Key('home-dues-pay')));
      await tester.pumpAndSettle();
      expect(find.text('IURAN 1 pay'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-dues-card')));
      await tester.pumpAndSettle();
      expect(find.text('IURAN 1'), findsOneWidget);
    });

    testWidgets('iuran belum diatur atau gagal dimuat: kartu tidak tampil',
        (tester) async {
      _phoneScreen(tester);
      // Server tetap mengirim data anggota walau iuran belum diatur.
      await tester.pumpWidget(_app(
        communities: _member(),
        dues: FakeDuesRepository(overview: overviewWith(configured: false)),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-dues-card')), findsNothing);

      await tester.pumpWidget(_app(
        communities: _member(),
        dues: FakeDuesRepository()
          ..overviewError = const NetworkException('offline'),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-dues-card')), findsNothing);
      expect(find.text('offline'), findsNothing);
    });

    testWidgets('pengelola: verifikasi, kalender, dan pengaturan iuran',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(
          role: CommunityRole.admin,
          duesConfigured: true,
          pendingDuesPaymentsCount: 2,
        ),
        dues: FakeDuesRepository(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 bukti transfer menunggu'), findsOneWidget);
      for (final (key, page) in [
        ('home-manage-dues-payments', 'IURAN 1 payments'),
        ('home-manage-dues-calendar', 'IURAN 1 members'),
        ('home-manage-dues-settings', 'IURAN 1 settings'),
      ]) {
        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.text(page), findsOneWidget, reason: key);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('pengelola, iuran belum diatur: ajakan mengatur saja',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(role: CommunityRole.creator),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-manage-dues-payments')), findsNothing);
      expect(find.byKey(const Key('home-manage-dues-calendar')), findsNothing);
      expect(find.textContaining('Belum diatur'), findsOneWidget);
    });

    testWidgets('anggota biasa: tanpa baris kelola iuran', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _member(duesConfigured: true),
        dues: FakeDuesRepository(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-manage-dues-settings')), findsNothing);
      expect(find.byKey(const Key('home-dues-card')), findsOneWidget);
    });
  });

  group('kegiatan mendatang', () {
    testWidgets('paling banyak tiga, terdekat dulu; Lihat semua ke tabnya',
        (tester) async {
      _phoneScreen(tester);
      final now = DateTime.now();
      await tester.pumpWidget(_app(
        communities: _member(
          activities: CommunityActivities(upcoming: [
            for (var i = 1; i <= 4; i++)
              testActivity('a$i',
                  title: 'Kegiatan $i', startsAt: now.add(_day * i)),
          ]),
        ),
      ));
      await tester.pumpAndSettle();

      for (var i = 1; i <= 3; i++) {
        expect(find.text('Kegiatan $i'), findsOneWidget);
      }
      expect(find.text('Kegiatan 4'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('home-activities-all')));
      await tester.tap(find.byKey(const Key('home-activities-all')));
      await tester.pumpAndSettle();
      expect(find.text('KLUB 1 tab=kegiatan'), findsOneWidget);
    });

    testWidgets('belum ada kegiatan', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: _member()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada kegiatan terjadwal.'), findsOneWidget);
    });
  });

  group('beberapa komunitas', () {
    testWidgets('belum memilih: tanya masuk sebagai anggota komunitas mana',
        (tester) async {
      _phoneScreen(tester);
      final store = FakeActiveCommunityStore();
      await tester.pumpWidget(_app(communities: _manyClubs(), store: store));
      await tester.pumpAndSettle();

      expect(
          find.text('Masuk sebagai anggota komunitas mana?'), findsOneWidget);
      expect(find.byType(HomeClubCard), findsNothing);
      expect(find.text('Menu Komunitas'), findsNothing);
      for (final name in [
        'Pemanah Nusantara',
        'Futsal Bandung',
        'Gowes Bogor'
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      // Peran ditandai per komunitas.
      expect(find.text('Creator'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);

      await tester.tap(find.byKey(const Key('home-club-option-2')));
      await tester.pumpAndSettle();

      expect(find.byType(HomeClubCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(HomeClubCard),
          matching: find.text('Futsal Bandung'),
        ),
        findsOneWidget,
      );
      expect(find.text('Masuk sebagai anggota komunitas mana?'), findsNothing);
      expect(store.saved, {'1': '2'});
    });

    testWidgets('pilihan terakhir dipakai lagi saat membuka app',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _manyClubs(),
        store: FakeActiveCommunityStore({'1': '3'}),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Masuk sebagai anggota komunitas mana?'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HomeClubCard),
          matching: find.text('Gowes Bogor'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('ganti komunitas lewat lembar pilihan, lalu diingat',
        (tester) async {
      _phoneScreen(tester);
      final store = FakeActiveCommunityStore({'1': '3'});
      await tester.pumpWidget(_app(communities: _manyClubs(), store: store));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-club-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Ganti Komunitas'), findsOneWidget);
      expect(find.byKey(const Key('home-switcher-find')), findsOneWidget);
      expect(find.byKey(const Key('home-switcher-create')), findsOneWidget);
      // Yang sedang aktif ditandai.
      expect(
        find.descendant(
          of: find.byKey(const Key('home-club-option-3')),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('home-club-option-1')));
      await tester.pumpAndSettle();

      expect(find.text('Ganti Komunitas'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(HomeClubCard),
          matching: find.text('Pemanah Nusantara'),
        ),
        findsOneWidget,
      );
      expect(store.saved, {'1': '1'});
    });

    testWidgets('lembar pilihan: cari komunitas lain', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: _manyClubs(),
        store: FakeActiveCommunityStore({'1': '3'}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home-club-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-switcher-find')));
      await tester.pumpAndSettle();

      expect(find.text('HALAMAN KOMUNITAS'), findsOneWidget);
    });
  });

  group('belum tergabung', () {
    FakeCommunityRepository popular({List<Community> joined = const []}) =>
        FakeCommunityRepository(
          joined: joined,
          pages: [
            [
              testCommunity('8', name: 'Gowes Bogor', membersCount: 140),
              testCommunity('9', name: 'Futsal Bandung', membersCount: 75),
            ],
          ],
        );

    testWidgets('cari atau daftarkan, dengan rekomendasi terpopuler',
        (tester) async {
      _phoneScreen(tester);
      final repository = popular();
      await tester.pumpWidget(_app(communities: repository));
      await tester.pumpAndSettle();

      expect(find.text('Mulai bersama komunitas'), findsOneWidget);
      expect(find.text('Cari Komunitas'), findsOneWidget);
      expect(find.text('Daftarkan Komunitas Baru'), findsOneWidget);
      expect(find.text('Rekomendasi Komunitas'), findsOneWidget);
      expect(find.text('Paling banyak anggotanya'), findsOneWidget);
      expect(find.text('140'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Gowes Bogor')).dy,
        lessThan(tester.getTopLeft(find.text('Futsal Bandung')).dy),
      );
      expect(repository.listCalls.single.sort, CommunitySort.popular);
      expect(find.byType(HomeClubCard), findsNothing);
    });

    testWidgets('pilihan cari/daftarkan terlihat tanpa menggulir',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: popular()));
      await tester.pumpAndSettle();

      final create =
          tester.getRect(find.byKey(const Key('community-start-create')));
      expect(create.bottom, lessThan(tester.view.physicalSize.height / 2.7));
    });

    for (final (key, page) in [
      ('community-start-find', 'HALAMAN KOMUNITAS'),
      ('community-start-create', 'HALAMAN DAFTARKAN'),
      ('community-recommended-8', 'KLUB 8'),
      ('community-recommended-all', 'HALAMAN KOMUNITAS'),
    ]) {
      testWidgets('$key membuka $page lalu bisa kembali', (tester) async {
        _phoneScreen(tester);
        await tester.pumpWidget(_app(communities: popular()));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(Key(key)));
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.text(page), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Mulai bersama komunitas'), findsOneWidget);
      });
    }

    testWidgets('permintaan bergabung yang menunggu ikut tampil',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        communities: popular(joined: [
          testCommunity(
            '9',
            name: 'Futsal Bandung',
            myRole: CommunityRole.member,
            myStatus: CommunityMembershipStatus.pending,
          ),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Menunggu persetujuan pengurus'), findsOneWidget);
      expect(
          find.byKey(const Key('community-start-request-9')), findsOneWidget);
      // Rekomendasi yang sudah diminta ditandai, bukan angka anggotanya.
      expect(
        find.descendant(
          of: find.byKey(const Key('community-recommended-9')),
          matching: find.text('Menunggu'),
        ),
        findsOneWidget,
      );
      expect(find.text('75'), findsNothing);
      expect(find.byType(HomeClubCard), findsNothing);
    });

    testWidgets('rekomendasi gagal dimuat: coba lagi', (tester) async {
      _phoneScreen(tester);
      final repository = popular()..error = const NetworkException('offline');
      await tester.pumpWidget(_app(communities: repository));
      await tester.pumpAndSettle();

      expect(find.text('Rekomendasi gagal dimuat.'), findsOneWidget);
      expect(find.text('Cari Komunitas'), findsOneWidget);

      repository.error = null;
      await tester
          .ensureVisible(find.byKey(const Key('community-recommended-retry')));
      await tester.tap(find.byKey(const Key('community-recommended-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Gowes Bogor'), findsOneWidget);
    });

    testWidgets('belum ada komunitas terverifikasi', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum ada komunitas terverifikasi'),
          findsOneWidget);
    });
  });

  group('memuat & gagal', () {
    testWidgets('selama dimuat: tempat kartu, tanpa pemutar', (tester) async {
      _phoneScreen(tester);
      final repository = _member()..joinedGate = Completer();
      await tester.pumpWidget(_app(communities: repository));
      await tester.pump();

      expect(find.byKey(const Key('home-club-loading')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(HomeUserHeader), findsOneWidget);

      repository.joinedGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-club-loading')), findsNothing);
      expect(find.byType(HomeClubCard), findsOneWidget);
    });

    testWidgets('gagal dimuat: Beranda utuh, coba lagi memuat ulang',
        (tester) async {
      _phoneScreen(tester);
      final repository = _member()
        ..joinedError = const ServerException('Server sibuk.');
      await tester.pumpWidget(_app(communities: repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-club-error')), findsOneWidget);
      expect(find.byType(HomeUserHeader), findsOneWidget);
      expect(find.text('Server sibuk.'), findsNothing);

      repository.joinedError = null;
      await tester.tap(find.byKey(const Key('home-club-retry')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeClubCard), findsOneWidget);
    });

    testWidgets('tarik untuk menyegarkan memuat ulang komunitas',
        (tester) async {
      _phoneScreen(tester);
      final repository = _member();
      await tester.pumpWidget(_app(communities: repository));
      await tester.pumpAndSettle();
      expect(repository.joinedCalls, 1);

      repository.joined = [
        testCommunity('1', name: 'Nama Baru', myRole: CommunityRole.member),
      ];
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.joinedCalls, 2);
      expect(find.text('Nama Baru'), findsOneWidget);
    });
  });

  group('tanpa overflow', () {
    for (final (name, communities, store) in [
      (
        'pengelola',
        () => _member(role: CommunityRole.creator, pendingMembersCount: 12),
        null,
      ),
      ('pilihan komunitas', _manyClubs, null),
      ('ganti komunitas', _manyClubs, {'1': '1'}),
      ('belum tergabung', FakeCommunityRepository.new, null),
    ]) {
      testWidgets('$name: layar sempit + teks besar', (tester) async {
        tester.view.physicalSize = const Size(640, 1280); // 320×640 dp
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(_app(
          communities: communities(),
          store: FakeActiveCommunityStore(store),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('layar lebar: isi tidak melar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(communities: _member()));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(HomeClubCard)).width,
        lessThanOrEqualTo(HomeScreen.maxContentWidth),
      );
      expect(tester.getCenter(find.byType(HomeClubCard)).dx, 640);
    });
  });

  group('popup Paid Promotion', () {
    const whatsapp = HomeBanner(
      id: 'wa',
      title: '',
      linkUrl: 'https://wa.me/6281234567890?text=Halo',
      buttonLabel: 'Chat Sekarang',
    );
    const site = HomeBanner(
      id: 'web',
      title: 'Promo Busur',
      linkUrl: 'https://anaklangit.manahpro.web.id/promo',
    );
    const plain = HomeBanner(id: 'plain', title: 'Ayo Istirahat');

    Finder popup() => find.byKey(const Key('promotion-popup'));
    PageController slider(WidgetTester tester) => tester
        .widget<PageView>(find.byKey(const Key('promotion-slider')))
        .controller!;

    testWidgets(
        'pertama kali: tampil besar & portrait, tombol tutup di kanan atas, '
        'tercatat per akun', (tester) async {
      _phoneScreen(tester);
      final store = FakePromotionPopupStore();
      await tester.pumpWidget(_app(
        communities: _member(),
        promotions: const [whatsapp, site],
        popupStore: store,
      ));
      await tester.pumpAndSettle();

      expect(popup(), findsOneWidget);
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      final image = tester.getRect(find.byKey(const Key('promotion-slider')));
      final whole = tester.getRect(popup());
      expect(image.width / image.height, closeTo(2 / 3, 0.01));
      expect(whole.height, lessThanOrEqualTo(screen.height * 0.8 + 0.5));
      // Selebar mungkin di ponsel: ±90% lebar layar.
      expect(image.width, closeTo(screen.width * 0.9, 1));
      expect(whole.center.dx, closeTo(screen.width / 2, 1));

      final close = tester.getRect(find.byKey(const Key('promotion-close')));
      expect(image.contains(close.center), isTrue);
      expect(image.right - close.right, lessThan(24));
      expect(close.top - image.top, lessThan(24));

      // Tombol di bawah gambar, sesuai slide pertama.
      final button = tester.getRect(find.byKey(const Key('promotion-button')));
      expect(button.top, greaterThan(image.bottom));
      expect(find.text('Chat Sekarang'), findsOneWidget);

      expect(store.marks.map((m) => m.$1), ['1']);

      await tester.tap(find.byKey(const Key('promotion-close')));
      await tester.pumpAndSettle();
      expect(popup(), findsNothing);
      expect(find.byType(HomeClubCard), findsOneWidget);
    });

    testWidgets('ketuk di luar popup menutupnya', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(promotions: const [plain]));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(6, 6));
      await tester.pumpAndSettle();
      expect(popup(), findsNothing);
    });

    testWidgets('desktop: tidak melebihi 80% tinggi layar', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(promotions: const [whatsapp, site]));
      await tester.pumpAndSettle();

      final image = tester.getRect(find.byKey(const Key('promotion-slider')));
      final whole = tester.getRect(popup());
      expect(whole.height, closeTo(640, 1));
      expect(image.width / image.height, closeTo(2 / 3, 0.01));
      expect(image.width, lessThanOrEqualTo(PromotionPopup.maxWidth));
    });

    for (final (label, ago, hours, shows) in [
      ('baru 23 jam dari 24 jam: tidak tampil', 23, 24, false),
      ('sudah 25 jam dari 24 jam: tampil lagi', 25, 24, true),
      ('jeda 6 jam, sudah 7 jam: tampil lagi', 7, 6, true),
      ('jeda 72 jam, baru 30 jam: tidak tampil', 30, 72, false),
    ]) {
      testWidgets(label, (tester) async {
        _phoneScreen(tester);
        final store = FakePromotionPopupStore(
          {'1': DateTime.now().subtract(Duration(hours: ago))},
        );
        await tester.pumpWidget(_app(
          promotions: const [plain],
          intervalHours: hours,
          popupStore: store,
        ));
        await tester.pumpAndSettle();

        expect(popup(), shows ? findsOneWidget : findsNothing);
        expect(store.marks, hasLength(shows ? 1 : 0));
      });
    }

    testWidgets('akun lain di perangkat yang sama punya hitungan sendiri',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        promotions: const [plain],
        popupStore: FakePromotionPopupStore({'2': DateTime.now()}),
      ));
      await tester.pumpAndSettle();

      expect(popup(), findsOneWidget);
    });

    testWidgets('promosi selesai dimuat belakangan: popup tampil saat itu',
        (tester) async {
      _phoneScreen(tester);
      final loading = Completer<HomePromotions>();
      await tester.pumpWidget(_app(
        communities: _member(),
        loadingPromotions: loading.future,
      ));
      await tester.pumpAndSettle();
      expect(popup(), findsNothing);
      expect(find.byType(HomeClubCard), findsOneWidget);

      loading.complete(const HomePromotions(banners: [plain]));
      await tester.pumpAndSettle();
      expect(popup(), findsOneWidget);
    });

    testWidgets('app kembali ke depan sesudah jedanya lewat: tampil lagi',
        (tester) async {
      _phoneScreen(tester);
      final store = FakePromotionPopupStore(
        {'1': DateTime.now().subtract(const Duration(hours: 1))},
      );
      await tester
          .pumpWidget(_app(promotions: const [plain], popupStore: store));
      await tester.pumpAndSettle();
      expect(popup(), findsNothing);

      store.shown['1'] = DateTime.now().subtract(const Duration(hours: 25));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(popup(), findsOneWidget);
    });

    testWidgets('tarik untuk menyegarkan sesudah jedanya lewat: tampil lagi',
        (tester) async {
      _phoneScreen(tester);
      final store = FakePromotionPopupStore(
        {'1': DateTime.now().subtract(const Duration(hours: 1))},
      );
      await tester.pumpWidget(_app(
        communities: _member(),
        promotions: const [plain],
        popupStore: store,
      ));
      await tester.pumpAndSettle();
      expect(popup(), findsNothing);

      store.shown['1'] = DateTime.now().subtract(const Duration(hours: 25));
      await tester.fling(
          find.byType(ListView).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(popup(), findsOneWidget);
    });

    testWidgets('tombol WhatsApp membuka chat lalu popup tertutup',
        (tester) async {
      _phoneScreen(tester);
      final launcher = FakeUrlLauncher.install();
      await tester.pumpWidget(_app(promotions: const [whatsapp]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat Sekarang'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://wa.me/6281234567890?text=Halo']);
      expect(popup(), findsNothing);
    });

    testWidgets('ketuk gambar menjalankan aksi yang sama', (tester) async {
      _phoneScreen(tester);
      final launcher = FakeUrlLauncher.install();
      await tester.pumpWidget(_app(promotions: const [site]));
      await tester.pumpAndSettle();

      // Data lama tanpa label: label bawaan sesuai aksi.
      expect(find.text('Kunjungi Situs'), findsOneWidget);
      await tester.tap(find.byKey(const Key('promotion-slide-web')));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://anaklangit.manahpro.web.id/promo']);
    });

    testWidgets('tautan tidak bisa dibuka: diberi tahu', (tester) async {
      _phoneScreen(tester);
      FakeUrlLauncher.install(canOpen: false);
      await tester.pumpWidget(_app(promotions: const [site]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('promotion-button')));
      await tester.pumpAndSettle();

      expect(find.text('Tautan tidak dapat dibuka'), findsOneWidget);
    });

    testWidgets('tombol halaman app: terbuka lalu kembali ke Beranda',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: _member(), promotions: const [
        HomeBanner(
          id: '1',
          title: 'Klub Pilihan',
          linkUrl: '/communities/5',
          buttonLabel: 'Lihat Klub',
        ),
      ]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lihat Klub'));
      await tester.pumpAndSettle();
      expect(find.text('KLUB 5'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(HomeClubCard), findsOneWidget);
      expect(popup(), findsNothing);
    });

    testWidgets('tanpa aksi: tanpa tombol, ketuk gambar tidak menutupnya',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(promotions: const [plain]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('promotion-button')), findsNothing);
      expect(find.byKey(const Key('promotion-dot-0')), findsNothing);
      await tester.tap(find.byKey(const Key('promotion-slide-plain')));
      await tester.pumpAndSettle();
      expect(popup(), findsOneWidget);
    });

    testWidgets('geser otomatis tiap 5 detik; titik & tombol ikut slide',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(promotions: const [whatsapp, site, plain]));
      await tester.pumpAndSettle();
      expect(slider(tester).page, 0);
      expect(find.text('Chat Sekarang'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(slider(tester).page, closeTo(1, 0.01));
      expect(find.text('Kunjungi Situs'), findsOneWidget);
      expect(find.text('Chat Sekarang'), findsNothing);

      final height = tester.getSize(popup()).height;
      await tester.tap(find.byKey(const Key('promotion-dot-2')));
      await tester.pumpAndSettle();
      expect(slider(tester).page, closeTo(2, 0.01));
      // Slide tanpa tombol: ruang tombol tetap, popup tidak melompat.
      expect(find.byKey(const Key('promotion-button')), findsNothing);
      expect(tester.getSize(popup()).height, height);
    });

    testWidgets('bisa digeser dengan mouse (web desktop)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(promotions: const [whatsapp, site]));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('promotion-slider')),
        const Offset(-300, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
      expect(slider(tester).page, closeTo(1, 0.01));
    });

    testWidgets('gambar bertulisan: tanpa teks dan gradasi di atasnya',
        (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(promotions: const [
        HomeBanner(id: '1', title: ''),
        HomeBanner(id: '2', title: 'Pendaftaran Dibuka'),
      ]));
      await tester.pumpAndSettle();

      final first = find.byKey(const Key('promotion-slide-1'));
      expect(find.descendant(of: first, matching: find.byType(Text)),
          findsNothing);
      expect(
        find.descendant(of: first, matching: find.byType(DecoratedBox)),
        findsOneWidget, // latar warna saja
      );
    });
  });

  testWidgets('tidak ada navigasi bawah', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Profil'), findsNothing);
  });

  testWidgets('foto profil membuka halaman Profil dan bisa kembali',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
    expect(find.text('HALAMAN PROFIL'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeUserHeader), findsOneWidget);
  });

  testWidgets('profil belum lengkap ditandai di foto', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(
      tester
          .widget<Badge>(find.byKey(const Key('home-profile-badge')))
          .isLabelVisible,
      isTrue,
    );
  });

  testWidgets('profil lengkap → tanpa penanda, ikon terverifikasi di header',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _completeUser));
    await tester.pump();

    expect(
      tester
          .widget<Badge>(find.byKey(const Key('home-profile-badge')))
          .isLabelVisible,
      isFalse,
    );
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  group('versi dan pembaruan', () {
    Finder refreshButton() => find.byKey(const Key('home-refresh-app'));

    const scrollToBottom = _scrollToEnd;

    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'app_main',
        packageName: 'app_main',
        version: '1.0.0',
        buildNumber: '72',
        buildSignature: '',
      );
    });

    test('format versi tanpa nama app', () async {
      expect(
        HomeAppVersion.label(await PackageInfo.fromPlatform()),
        'v1.0.0+72',
      );
    });

    testWidgets('tampil di Beranda', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      expect(find.text('v1.0.0+72'), findsOneWidget);
      expect(find.textContaining('app_main'), findsNothing);
      expect(find.textContaining('Versi'), findsNothing);
    });

    testWidgets('tanpa dukungan platform, tombol tidak tampil', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      expect(refreshButton(), findsNothing);
    });

    testWidgets('tombol memuat versi terbaru', (tester) async {
      _phoneScreen(tester);
      final refresher = _FakeRefresher();
      await tester.pumpWidget(_app(refresher: refresher));
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      expect(find.text('Perbarui Aplikasi'), findsOneWidget);

      await tester.tap(refreshButton());
      await tester.pump();

      expect(refresher.calls, 1);
    });

    testWidgets('gagal mengunduh: pesan tampil dan tombol kembali aktif',
        (tester) async {
      _phoneScreen(tester);
      final refresher = _FakeRefresher(error: Exception('offline'));
      await tester.pumpWidget(_app(refresher: refresher));
      await tester.pumpAndSettle();
      await scrollToBottom(tester);

      await tester.tap(refreshButton());
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Gagal mengambil versi terbaru'), findsOneWidget);
      // Tombol ada di dasar halaman, tertutup pesan sampai pesannya hilang.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(refreshButton());
      await tester.pump();
      expect(refresher.calls, 2);
    });
  });

  testWidgets('Admin Panel tidak tampil untuk anggota biasa', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _completeUser));
    await tester.pump();

    await _scrollToEnd(tester);
    expect(find.byKey(const Key('home-admin-panel')), findsNothing);
    expect(find.text('Admin Panel'), findsNothing);
  });

  testWidgets('peran admin & staff juga tidak melihat Admin Panel',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(
      user: const User(
        id: '1',
        name: 'Rina Ayu',
        email: 'rina@gmail.com',
        roles: ['admin', 'staff'],
      ),
    ));
    await tester.pump();

    await _scrollToEnd(tester);
    expect(find.byKey(const Key('home-admin-panel')), findsNothing);
  });

  testWidgets('super admin melihat Admin Panel dan bisa membukanya',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _superAdmin));
    await tester.pump();

    final card = find.byKey(const Key('home-admin-panel'));
    await _scrollToEnd(tester);
    expect(card, findsOneWidget);
    expect(find.text('Admin Panel'), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('HALAMAN ADMIN'), findsOneWidget);
  });

  group('promosi hanya dari Admin Panel', () {
    ProviderContainer container(Future<HomePromotions> Function() fetch) {
      final c = ProviderContainer(overrides: [
        bannerRemoteDataSourceProvider
            .overrideWithValue(_FakeBannerSource(fetch)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('promosi dari server dipakai apa adanya', () async {
      final promotions = await container(
        () async => const HomePromotions(banners: _banners, intervalHours: 6),
      ).read(homePromotionsProvider.future);
      expect(promotions.banners.map((b) => b.id), ['1', '2']);
      expect(promotions.intervalHours, 6);
    });

    test('server gagal → kosong, popup tidak tampil', () async {
      final promotions =
          await container(() => throw const NetworkException('offline'))
              .read(homePromotionsProvider.future);
      expect(promotions.banners, isEmpty);
      expect(promotions.isDue(null, DateTime.now()), isFalse);
    });

    testWidgets('belum ada promosi: tidak ada popup maupun banner di Beranda',
        (tester) async {
      _phoneScreen(tester);
      final store = FakePromotionPopupStore();
      await tester.pumpWidget(_app(communities: _member(), popupStore: store));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('promotion-popup')), findsNothing);
      expect(store.marks, isEmpty);
      // Menu langsung di bawah kartu komunitas, tanpa celah bekas banner.
      final gap = tester.getTopLeft(find.text('Menu Komunitas')).dy -
          tester.getBottomLeft(find.byType(HomeClubCard)).dy;
      expect(gap, lessThanOrEqualTo(24));
    });
  });

  group('aturan jeda & aksi promosi', () {
    final now = DateTime(2026, 11, 8, 12);
    const promotions = HomePromotions(
      banners: [HomeBanner(id: '1', title: '')],
      intervalHours: 24,
    );

    test('jeda dihitung dari terakhir tampil', () {
      expect(promotions.isDue(null, now), isTrue);
      expect(
        promotions.isDue(
            now.subtract(const Duration(hours: 23, minutes: 59)), now),
        isFalse,
      );
      expect(promotions.isDue(now.subtract(const Duration(hours: 24)), now),
          isTrue);
      // Jam perangkat dimundurkan: jangan tampil terus-menerus.
      expect(promotions.isDue(now.add(const Duration(hours: 2)), now), isFalse);
      expect(const HomePromotions().isDue(null, now), isFalse);
    });

    test('nomor WhatsApp dirapikan ke kode negara', () {
      for (final (input, expected) in [
        ('0812-3456-7890', '6281234567890'),
        ('+62 812 3456 7890', '6281234567890'),
        ('6281234567890', '6281234567890'),
        ('(0812) 3456.7890', '6281234567890'),
        ('+1 415 555 0100', '14155550100'),
        ('', null),
        ('0812', null),
        ('+0812345678', null),
        ('0812345678901234567', null),
        ('08123abc456', null),
      ]) {
        expect(PromotionAction.normalizeWhatsappNumber(input), expected,
            reason: input);
      }
    });

    test('tautan wa.me: pesan awal dikodekan dan terbaca kembali', () {
      const message = 'Halo, saya tertarik promo 50% & ingin tanya?';
      final link = PromotionAction.whatsappLink('6281234567890', message);
      expect(link, startsWith('https://wa.me/6281234567890?text=Halo%2C'));
      expect(link, isNot(contains(' ')));
      expect(link, isNot(contains('&')));
      expect(PromotionAction.whatsappNumber(link), '6281234567890');
      expect(PromotionAction.whatsappMessage(link), message);
      expect(PromotionAction.whatsappLink('6281234567890', '  '),
          'https://wa.me/6281234567890');
      expect(PromotionAction.formatWhatsappNumber('6281234567890'),
          '+62 812-3456-7890');
      expect(
          PromotionAction.formatWhatsappNumber('14155550100'), '+14155550100');
    });

    test('jenis aksi & label tombol', () {
      expect(
          PromotionActionKind.of('/communities'), PromotionActionKind.appPage);
      expect(PromotionActionKind.of('https://wa.me/6281234567890'),
          PromotionActionKind.whatsapp);
      expect(PromotionActionKind.of('https://WA.ME/6281234567890'),
          PromotionActionKind.whatsapp);
      expect(PromotionActionKind.of('https://anaklangit.manahpro.web.id'),
          PromotionActionKind.web);
      expect(PromotionActionKind.of('javascript:alert(1)'),
          PromotionActionKind.none);
      expect(PromotionActionKind.of(null), PromotionActionKind.none);

      expect(const HomeBanner(id: '1', title: '').button, isNull);
      expect(
        const HomeBanner(id: '1', title: '', buttonLabel: 'Beli').button,
        isNull,
      );
      expect(
        const HomeBanner(
                id: '1', title: '', linkUrl: '/profile', buttonLabel: '  ')
            .button,
        'Lihat Selengkapnya',
      );
      expect(
        const HomeBanner(
          id: '1',
          title: '',
          linkUrl: 'https://wa.me/6281234567890',
          buttonLabel: ' Chat Admin ',
        ).button,
        'Chat Admin',
      );
    });

    test('ukuran gambar: portrait terbesar dalam 80% tinggi & 90% lebar', () {
      final phone = PromotionPopup.imageSize(
        const Size(400, 889),
        hasButton: true,
        hasDots: true,
      );
      expect(phone.width, closeTo(360, 0.01));
      expect(phone.height, closeTo(540, 0.01));

      // Layar pendek: tinggi yang membatasi.
      final short = PromotionPopup.imageSize(
        const Size(400, 600),
        hasButton: true,
        hasDots: false,
      );
      expect(short.height, closeTo(600 * 0.8 - 66, 0.01));
      expect(short.width / short.height, closeTo(2 / 3, 0.001));

      final desktop = PromotionPopup.imageSize(
        const Size(1920, 1080),
        hasButton: false,
        hasDots: false,
      );
      expect(desktop.width, closeTo(460, 0.01));
      expect(desktop.height, closeTo(690, 0.01));
    });
  });

  test('salam mengikuti jam', () {
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 7)), 'Selamat pagi');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 12)), 'Selamat siang');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 16)), 'Selamat sore');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 21)), 'Selamat malam');
  });
}
