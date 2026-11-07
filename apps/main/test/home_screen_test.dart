import 'dart:async';

import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/widgets/club_hero.dart';
import 'package:app_main/features/home/data/banner_remote_data_source.dart';
import 'package:app_main/features/home/domain/app_refresher.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/features/home/presentation/widgets/home_app_version.dart';
import 'package:app_main/features/home/presentation/widgets/home_banner_slider.dart';
import 'package:app_main/features/home/presentation/widgets/home_club_card.dart';
import 'package:app_main/features/home/presentation/widgets/home_club_sections.dart';
import 'package:app_main/features/home/presentation/widgets/home_user_header.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'features/community/fake_community_repository.dart';

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

  final Future<List<HomeBanner>> Function() _fetch;

  @override
  Future<List<HomeBanner>> fetchBanners() => _fetch();
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

Widget _app({
  User user = _incompleteUser,
  List<HomeBanner> banners = _banners,
  Future<List<HomeBanner>>? loadingBanners,
  AppRefresher? refresher,
  FakeCommunityRepository? communities,
  FakeActiveCommunityStore? store,
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
      homeBannersProvider
          .overrideWith((ref) => loadingBanners ?? Future.value(banners)),
      appRefresherProvider.overrideWithValue(refresher),
      communityRepositoryProvider
          .overrideWithValue(communities ?? FakeCommunityRepository()),
      activeCommunityStoreProvider
          .overrideWithValue(store ?? FakeActiveCommunityStore()),
    ],
    child: MaterialApp.router(
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
  testWidgets('Beranda anggota: info user, komunitas aktif, banner, menu',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(communities: _member()));
    await tester.pumpAndSettle();

    // Info singkat user: foto (inisial bila tanpa foto), nama, email.
    expect(find.text('Rina Ayu'), findsOneWidget);
    expect(find.text('rina@gmail.com'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);

    // Komunitas aktif di bawah info user, banner di bawahnya, lalu menu.
    expect(find.text('Pemanah Nusantara'), findsOneWidget);
    expect(find.text('Masuk sebagai anggota'), findsOneWidget);
    expect(find.text('24 anggota'), findsOneWidget);
    final header = tester.getRect(find.byType(HomeUserHeader));
    final card = tester.getRect(find.byType(HomeClubCard));
    final banner = tester.getRect(find.byKey(const Key('home-banner-slider')));
    final menu = tester.getTopLeft(find.text('Menu Komunitas')).dy;
    expect(header.bottom, lessThanOrEqualTo(card.top));
    expect(card.bottom, lessThanOrEqualTo(banner.top));
    expect(banner.bottom, lessThanOrEqualTo(menu));

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
        'Kartu Anggota',
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

    testWidgets('pilihan cari/daftarkan di atas banner', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(communities: popular()));
      await tester.pumpAndSettle();

      final create =
          tester.getRect(find.byKey(const Key('community-start-create')));
      // Terlihat tanpa menggulir.
      expect(create.bottom, lessThan(tester.view.physicalSize.height / 2.7));
      await _scrollToEnd(tester);
      expect(find.byKey(const Key('home-banner-slider')), findsOneWidget);
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

  testWidgets('banner bergeser otomatis', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    final pageView = find.byKey(const Key('home-banner-slider'));
    expect(tester.widget<PageView>(pageView).controller!.page, 0);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
        tester.widget<PageView>(pageView).controller!.page, closeTo(1, 0.01));
  });

  testWidgets('banner bertujuan halaman app: terbuka lalu kembali ke Beranda',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(communities: _member(), banners: const [
      HomeBanner(id: '1', title: 'Klub Pilihan', linkUrl: '/communities/5'),
    ]));
    await tester.pump();

    await tester.tap(find.text('Klub Pilihan'));
    await tester.pumpAndSettle();
    expect(find.text('KLUB 5'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeUserHeader), findsOneWidget);
  });

  testWidgets('banner foto bertulisan: tanpa teks dan gradasi di atasnya',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(banners: const [
      HomeBanner(id: '1', title: ''),
      HomeBanner(id: '2', title: 'Pendaftaran Dibuka'),
    ]));
    await tester.pump();

    final cards = find.byType(HomeBannerCard);
    expect(
      find.descendant(of: cards.first, matching: find.byType(Text)),
      findsNothing,
    );
    expect(
      find.descendant(of: cards.first, matching: find.byType(DecoratedBox)),
      findsOneWidget, // latar warna saja
    );
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

  group('banner hanya dari Admin Panel', () {
    ProviderContainer container(Future<List<HomeBanner>> Function() fetch) {
      final c = ProviderContainer(overrides: [
        bannerRemoteDataSourceProvider
            .overrideWithValue(_FakeBannerSource(fetch)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('banner dari server dipakai apa adanya', () async {
      final banners = await container(() async => _banners)
          .read(homeBannersProvider.future);
      expect(banners.map((b) => b.id), ['1', '2']);
    });

    test('server tanpa banner atau gagal → kosong, tanpa banner bawaan',
        () async {
      expect(
        await container(() async => const []).read(homeBannersProvider.future),
        isEmpty,
      );
      expect(
        await container(() => throw const NetworkException('offline'))
            .read(homeBannersProvider.future),
        isEmpty,
      );
    });

    testWidgets('belum ada banner: bagiannya tidak tampil', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(banners: const [], communities: _member()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-banner-slider')), findsNothing);
      expect(find.byType(HomeBannerCard), findsNothing);
      expect(find.textContaining('Selamat datang di CEO'), findsNothing);
      // Menu langsung di bawah kartu komunitas, tanpa celah bekas banner.
      final gap = tester.getTopLeft(find.text('Menu Komunitas')).dy -
          tester.getBottomLeft(find.byType(HomeClubCard)).dy;
      expect(gap, lessThanOrEqualTo(24));
    });

    testWidgets('saat memuat: tidak ada kotak pemuat banner', (tester) async {
      _phoneScreen(tester);
      await tester.pumpWidget(_app(
        loadingBanners: Completer<List<HomeBanner>>().future,
        communities: _member(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-banner-slider')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Menu Komunitas'), findsOneWidget);
    });
  });

  test('salam mengikuti jam', () {
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 7)), 'Selamat pagi');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 12)), 'Selamat siang');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 16)), 'Selamat sore');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 21)), 'Selamat malam');
  });
}
