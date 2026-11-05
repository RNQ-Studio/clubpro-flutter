import 'package:app_main/features/home/domain/app_refresher.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/features/home/presentation/widgets/home_app_version.dart';
import 'package:app_main/features/home/presentation/widgets/home_menu_grid.dart';
import 'package:app_main/features/home/presentation/widgets/home_user_header.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  AppRefresher? refresher,
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
      homeBannersProvider.overrideWith((ref) async => banners),
      appRefresherProvider.overrideWithValue(refresher),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void _phoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('Beranda: info user di atas, banner, lalu menu utama club',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    // Info singkat user: foto (inisial bila tanpa foto), nama, email.
    expect(find.text('Rina Ayu'), findsOneWidget);
    expect(find.text('rina@gmail.com'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);

    // Banner slider di bawah header.
    expect(find.byKey(const Key('home-banner-slider')), findsOneWidget);
    expect(find.text('Latihan Bersama Akhir Pekan'), findsOneWidget);
    final headerY =
        tester.getTopLeft(find.byKey(const Key('home-user-header'))).dy;
    final bannerY =
        tester.getTopLeft(find.byKey(const Key('home-banner-slider'))).dy;
    final menuY = tester.getTopLeft(find.text('Menu Utama')).dy;
    expect(headerY, lessThan(bannerY));
    expect(bannerY, lessThan(menuY));

    // Menu utama sesuai lingkup CEO.
    for (final menu in homeMenus) {
      expect(find.text(menu.label), findsOneWidget);
    }
    for (final label in [
      'Kartu Anggota',
      'Absensi',
      'Iuran Bulanan',
      'Top-up Saldo',
      'Riwayat Transaksi'
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
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

  testWidgets('menu yang belum tersedia menampilkan "Segera hadir"',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-menu-dues')));
    await tester.pumpAndSettle();

    expect(find.text('Segera hadir'), findsOneWidget);
    expect(find.textContaining('iuran bulanan'), findsOneWidget);
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
    expect(find.text('Menu Utama'), findsOneWidget);
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

  testWidgets('Komunitas menjadi kartu teratas Menu Utama dan bisa kembali',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    final card = find.byKey(const Key('home-community'));
    expect(card, findsOneWidget);
    final cardY = tester.getTopLeft(card).dy;
    expect(cardY, greaterThan(tester.getTopLeft(find.text('Menu Utama')).dy));
    expect(cardY, lessThan(tester.getTopLeft(find.byType(HomeMenuGrid)).dy));

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('HALAMAN KOMUNITAS'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Menu Utama'), findsOneWidget);
  });

  group('versi dan pembaruan', () {
    Finder refreshButton() => find.byKey(const Key('home-refresh-app'));

    Future<void> scrollToBottom(WidgetTester tester) async {
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
    }

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
      await tester.tap(refreshButton());
      await tester.pump();
      expect(refresher.calls, 2);
    });
  });

  testWidgets('Admin Panel tidak tampil untuk anggota biasa', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _completeUser));
    await tester.pump();

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

    expect(find.byKey(const Key('home-admin-panel')), findsNothing);
  });

  testWidgets('super admin melihat Admin Panel dan bisa membukanya',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _superAdmin));
    await tester.pump();

    final card = find.byKey(const Key('home-admin-panel'));
    expect(card, findsOneWidget);
    expect(find.text('Admin Panel'), findsOneWidget);
    expect(
      tester.getTopLeft(card).dy,
      greaterThan(tester.getTopLeft(find.text('Menu Utama')).dy),
    );

    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('HALAMAN ADMIN'), findsOneWidget);
  });

  testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360×640 dp
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('menu tanpa sisa istilah panahan & id unik', () {
    final copy = [for (final m in homeMenus) '${m.label} ${m.description}']
        .join(' ')
        .toLowerCase();
    for (final old in ['latihan', 'panah', 'busur', 'lomba', 'club']) {
      expect(copy, isNot(contains(old)), reason: old);
    }
    expect(homeMenus.map((m) => m.id).toSet(), hasLength(homeMenus.length));
  });

  test('banner bawaan tersedia bila server belum punya banner', () {
    expect(defaultHomeBanners, isNotEmpty);
    expect(defaultHomeBanners.first.title, contains('CEO'));
  });

  test('salam mengikuti jam', () {
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 7)), 'Selamat pagi');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 12)), 'Selamat siang');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 16)), 'Selamat sore');
    expect(HomeUserHeader.greeting(DateTime(2026, 1, 1, 21)), 'Selamat malam');
  });
}
