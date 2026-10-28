// Merender screenshot layar utama app (ukuran ponsel 360×780 dp) dengan font
// Roboto & Material Icons asli dari SDK Flutter — untuk review visual tanpa
// perangkat. Tidak ikut `melos run test` (berada di tool/).
//
//   RENDER_DIR=/tmp/shots flutter test tool/render_screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/branding/club_brand.dart';
import 'package:app_main/branding/club_logo.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/shell/main_shell.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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

const _partial = User(
  id: '1',
  name: 'Rina Ayu Lestari',
  email: 'rina.ayu@gmail.com',
  gender: MemberGender.female,
  bloodType: BloodType.o,
  phone: '081234567890',
);

final _complete = User(
  id: '1',
  name: 'Rina Ayu Lestari',
  email: 'rina.ayu@gmail.com',
  gender: MemberGender.female,
  birthPlace: 'Bandung',
  birthDate: DateTime(2001, 4, 12),
  phone: '081234567890',
  address: 'Jl. Merdeka No. 10, Bandung',
  bloodType: BloodType.o,
  emergencyContactName: 'Ibu Sari',
  emergencyContactPhone: '081298765432',
  completion: const ProfileCompletion(completed: 10, total: 10, missing: []),
);

Future<void> _loadFonts() async {
  final sdk =
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final dir = '$sdk/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('MaterialIcons-Regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

void main() {
  final outDir = Platform.environment['RENDER_DIR'] ?? 'build/screens';
  final boundaryKey = GlobalKey();

  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget app, {
    Future<void> Function()? before,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: app));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    if (before != null) await before();
    // Gambar aset (logo) di-decode di luar fake async; tunggu, lalu gambar ulang.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump();

    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(outDir).createSync(recursive: true);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Widget material(Widget home, AuthState auth) => ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: home,
        ),
      );

  Widget shell(User user, {String location = '/'}) {
    final router = GoRouter(
      initialLocation: location,
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
                  builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider
            .overrideWith(() => _FixedAuthNotifier(AuthAuthenticated(user))),
        homeBannersProvider.overrideWith((ref) async => defaultHomeBanners),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }

  testWidgets('01-onboarding', (tester) async {
    await shoot(
      tester,
      '01-onboarding',
      material(const OnboardingScreen(pages: ClubBrand.onboardingPages),
          const AuthUnauthenticated()),
    );
  });

  testWidgets('02-onboarding-iuran', (tester) async {
    await shoot(
      tester,
      '02-onboarding-iuran',
      material(const OnboardingScreen(pages: ClubBrand.onboardingPages),
          const AuthUnauthenticated()),
      before: () async {
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Selanjutnya'));
          await tester.pumpAndSettle();
        }
      },
    );
  });

  testWidgets('03-login', (tester) async {
    await shoot(
      tester,
      '03-login',
      material(
        const GoogleLoginScreen(
          title: ClubBrand.name,
          subtitle: ClubBrand.loginSubtitle,
          logo: ClubLogo(size: 112),
        ),
        const AuthUnauthenticated(),
      ),
    );
  });

  testWidgets('04-setup', (tester) async {
    await shoot(
        tester,
        '04-setup',
        material(
            const ProfileSetupScreen(), const AuthAuthenticated(_partial)));
  });

  testWidgets('05-beranda', (tester) async {
    await shoot(tester, '05-beranda', shell(_partial));
  });

  testWidgets('06-segera-hadir', (tester) async {
    await shoot(tester, '06-segera-hadir', shell(_partial), before: () async {
      await tester.tap(find.byKey(const Key('home-menu-member-card')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('07-profil-belum-lengkap', (tester) async {
    await shoot(tester, '07-profil-belum-lengkap',
        shell(_partial, location: AppRoutes.profile));
  });

  testWidgets('08-profil-lengkap', (tester) async {
    await shoot(tester, '08-profil-lengkap',
        shell(_complete, location: AppRoutes.profile));
  });
}
