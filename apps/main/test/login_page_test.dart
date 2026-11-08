import 'dart:async';

import 'package:app_main/branding/club_login.dart';
import 'package:app_main/features/home/domain/app_refresher.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  int googleCalls = 0;

  @override
  AuthState build() => _state;

  @override
  Future<void> checkCurrentUser() async {}

  @override
  Future<void> loginWithGoogle() async => googleCalls++;
}

class _FakeRefresher implements AppRefresher {
  _FakeRefresher({this.error, this.gate});

  final Exception? error;
  final Completer<void>? gate;
  int calls = 0;

  @override
  Future<void> refresh() async {
    calls++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
  }
}

/// Teks yang boleh tampil di halaman awal sebelum login.
const _allowedTexts = {
  'CEO',
  'COMMUNITY E-COMMERCE OPERATOR',
  'Masuk dengan Google',
  'v1.0.0+86',
  'Perbarui Aplikasi',
};

Widget _page({
  AuthState auth = const AuthUnauthenticated(),
  AppRefresher? refresher,
  _FixedAuthNotifier? notifier,
}) =>
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => notifier ?? _FixedAuthNotifier(auth)),
        appRefresherProvider.overrideWithValue(refresher),
      ],
      // Tema app terang: halaman login tetap gelap hitam-emas.
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ClubLoginPage(),
      ),
    );

void _screen(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'app_main',
      packageName: 'app_main',
      version: '1.0.0',
      buildNumber: '86',
      buildSignature: '',
    );
  });

  testWidgets('clean: hanya nama app, kepanjangannya, tombol masuk, dan versi',
      (tester) async {
    _screen(tester, const Size(390, 844));
    await tester.pumpWidget(_page(refresher: _FakeRefresher()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-brand-name')), findsOneWidget);
    expect(find.text('CEO'), findsOneWidget);
    expect(find.text('COMMUNITY E-COMMERCE OPERATOR'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);

    final texts = {
      for (final text in tester.widgetList<Text>(find.byType(Text)))
        text.data ?? text.textSpan?.toPlainText() ?? '',
    };
    expect(texts.difference(_allowedTexts), isEmpty);
    expect(find.textContaining('Masuk untuk'), findsNothing);
    expect(find.textContaining('Belum punya akun'), findsNothing);
    expect(find.textContaining('kartu anggota'), findsNothing);

    // Urutan: logo → nama → kepanjangan → tombol masuk → versi.
    double top(Finder f) => tester.getTopLeft(f).dy;
    final name = find.byKey(const Key('login-brand-name'));
    final tagline = find.byKey(const Key('login-brand-tagline'));
    final google = find.byKey(const Key('google-sign-in-button'));
    final version = find.byKey(const Key('home-app-version'));
    expect(top(find.byType(Image).first), lessThan(top(name)));
    expect(top(name), lessThan(top(tagline)));
    expect(top(tagline), lessThan(top(google)));
    expect(top(google), lessThan(top(version)));
    // Huruf nama di tengah layar: kotak teks memuat jarak sesudah huruf
    // terakhir (12), yang tidak terlihat.
    final box = tester.getRect(name);
    expect(box.left + (box.width - 12) / 2, closeTo(195, 1));
  });

  testWidgets('nama app terlihat penuh sejak frame pertama, tanpa animasi',
      (tester) async {
    // Bila frame tertahan (perangkat lambat, Chrome headless saat smoke),
    // animasi masuk yang mulai dari transparan membuat nama tak terlihat.
    _screen(tester, const Size(390, 844));
    await tester.pumpWidget(_page());

    for (final key in ['login-brand-name', 'login-brand-tagline']) {
      final hidden = find.ancestor(
        of: find.byKey(Key(key)),
        matching: find.byWidgetPredicate(
          (w) =>
              (w is Opacity && w.opacity < 1) ||
              (w is FadeTransition && w.opacity.value < 1),
        ),
      );
      expect(hidden, findsNothing, reason: key);
    }
  });

  testWidgets('selalu gelap hitam-emas walau tema app terang', (tester) async {
    _screen(tester, const Size(390, 844));
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(GoogleLoginScreen));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.byType(ClubLoginBackdrop), findsOneWidget);
    expect(
      tester.getSize(find.byType(ClubLoginBackdrop)),
      const Size(390, 844),
    );
  });

  testWidgets('tombol masuk tetap berfungsi', (tester) async {
    _screen(tester, const Size(390, 844));
    final notifier = _FixedAuthNotifier(const AuthUnauthenticated());
    await tester.pumpWidget(_page(notifier: notifier));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('google-sign-in-button')));
    await tester.pump();
    expect(notifier.googleCalls, 1);
  });

  testWidgets('galat masuk tampil di atas tombol', (tester) async {
    _screen(tester, const Size(390, 844));
    await tester.pumpWidget(
      _page(auth: const AuthError('Login Google dibatalkan.')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Login Google dibatalkan.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Login Google dibatalkan.')).dy,
      lessThan(
          tester.getTopLeft(find.byKey(const Key('google-sign-in-button'))).dy),
    );
  });

  group('perbarui paksa ke versi web terbaru', () {
    Finder button() => find.byKey(const Key('home-refresh-app'));

    testWidgets('memuat versi terbaru; tombol nonaktif selama proses',
        (tester) async {
      _screen(tester, const Size(390, 844));
      final refresher = _FakeRefresher(gate: Completer());
      await tester.pumpWidget(_page(refresher: refresher));
      await tester.pumpAndSettle();

      expect(find.text('v1.0.0+86'), findsOneWidget);
      await tester.tap(button());
      await tester.pump();
      expect(refresher.calls, 1);
      expect(find.text('Memperbarui...'), findsOneWidget);
      expect(tester.widget<TextButton>(button()).onPressed, isNull);

      refresher.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('gagal (offline): pesan tampil, tombol aktif lagi',
        (tester) async {
      _screen(tester, const Size(390, 844));
      final refresher = _FakeRefresher(error: Exception('offline'));
      await tester.pumpWidget(_page(refresher: refresher));
      await tester.pumpAndSettle();

      await tester.tap(button());
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Gagal mengambil versi terbaru'), findsOneWidget);
      expect(tester.widget<TextButton>(button()).onPressed, isNotNull);
    });

    testWidgets('bukan web: tombol tidak tampil', (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_page());
      await tester.pumpAndSettle();

      expect(button(), findsNothing);
      expect(find.text('v1.0.0+86'), findsOneWidget);
    });
  });

  for (final (label, size, scale) in [
    ('ponsel kecil + teks besar', const Size(360, 640), 1.3),
    ('ponsel', const Size(390, 844), 1.0),
    ('desktop', const Size(1280, 800), 1.0),
  ]) {
    testWidgets('tanpa overflow: $label', (tester) async {
      _screen(tester, size, textScale: scale);
      await tester.pumpWidget(_page(refresher: _FakeRefresher()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final google =
          tester.getRect(find.byKey(const Key('google-sign-in-button')));
      expect(google.center.dx, closeTo(size.width / 2, 1));
    });
  }

  group('rute app', () {
    Future<void> pump(WidgetTester tester, String location) async {
      _screen(tester, const Size(390, 844));
      appRouter.go(location);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _FixedAuthNotifier(const AuthUnauthenticated()),
          ),
          appRefresherProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: appRouter,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
        ),
      ));
    }

    testWidgets('splash langsung ke login, tanpa slide onboarding',
        (tester) async {
      await pump(tester, '/splash');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(ClubLoginPage), findsOneWidget);
    });

    testWidgets('alamat /onboarding lama dialihkan ke login', (tester) async {
      await pump(tester, '/onboarding');
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(ClubLoginPage), findsOneWidget);
    });
  });
}
