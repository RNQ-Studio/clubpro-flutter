import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/features/home/presentation/widgets/home_menu_grid.dart';
import 'package:app_main/features/home/presentation/widgets/home_user_header.dart';
import 'package:app_main/shell/main_shell.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

const _banners = [
  HomeBanner(id: '1', title: 'Latihan Bersama Akhir Pekan'),
  HomeBanner(id: '2', title: 'Pendaftaran Kejuaraan Dibuka'),
];

Widget _app(
    {User user = _incompleteUser, List<HomeBanner> banners = _banners}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const Text('HALAMAN PROFIL')),
          ]),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider
          .overrideWith(() => _FixedAuthNotifier(AuthAuthenticated(user))),
      homeBannersProvider.overrideWith((ref) async => banners),
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

    // Menu utama operasional club.
    for (final menu in homeMenus) {
      expect(find.text(menu.label), findsOneWidget);
    }
    expect(find.text('Jadwal Latihan'), findsOneWidget);
    expect(find.text('Iuran Bulanan'), findsOneWidget);
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

  testWidgets('tab Profil & penanda profil belum lengkap', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(
      tester
          .widget<Badge>(find.byKey(const Key('profile-tab-badge')))
          .isLabelVisible,
      isTrue,
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('HALAMAN PROFIL'), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('Menu Utama'), findsOneWidget);
  });

  testWidgets('profil lengkap → tanpa penanda, ikon terverifikasi di header',
      (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app(user: _completeUser));
    await tester.pump();

    expect(
      tester
          .widget<Badge>(find.byKey(const Key('profile-tab-badge')))
          .isLabelVisible,
      isFalse,
    );
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });

  testWidgets('mengetuk header membuka tab Profil', (tester) async {
    _phoneScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pump();

    await tester.tap(find.byKey(const Key('home-user-header')));
    await tester.pumpAndSettle();
    expect(find.text('HALAMAN PROFIL'), findsOneWidget);
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
