import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({this.completed = false});

  bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted() async => completed = true;
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

const _user = User(id: '1', name: 'Rina', email: 'rina@example.com');

Widget _app({
  required Widget Function() splash,
  required _FakeOnboardingRepository repo,
  AuthState auth = const AuthUnauthenticated(),
  Widget Function()? onboarding,
}) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      ...buildAuthRoutes(splash: splash, onboarding: onboarding),
      GoRoute(path: '/', builder: (_, __) => const Text('HOME')),
    ],
  );
  return ProviderScope(
    overrides: [
      onboardingRepositoryProvider.overrideWith((ref) async => repo),
      authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void main() {
  const pages = [
    OnboardingPage(
      icon: Icons.event_available_rounded,
      title: 'Jadwal Latihan',
      description: 'Lihat jadwal latihan.',
      color: Colors.blue,
    ),
    OnboardingPage(
      icon: Icons.emoji_events_rounded,
      title: 'Catat Prestasi',
      description: 'Simpan hasil lomba.',
      color: Colors.orange,
    ),
  ];

  group('OnboardingScreen', () {
    testWidgets('menampilkan halaman dari app dan maju ke halaman berikutnya',
        (tester) async {
      final repo = _FakeOnboardingRepository();
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club'),
        onboarding: () => const OnboardingScreen(pages: pages),
        repo: repo,
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Latihan'), findsOneWidget);
      expect(find.text('Selanjutnya'), findsOneWidget);

      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Catat Prestasi'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);
    });

    testWidgets('selesai menyimpan status dan menuju completeLocation',
        (tester) async {
      final repo = _FakeOnboardingRepository();
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club'),
        onboarding: () =>
            const OnboardingScreen(pages: pages, completeLocation: '/login'),
        repo: repo,
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(repo.completed, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('SplashScreen', () {
    testWidgets('belum onboarding → /onboarding', (tester) async {
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club', requireLogin: true),
        repo: _FakeOnboardingRepository(),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('wajib login & belum login → /login', (tester) async {
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club', requireLogin: true),
        repo: _FakeOnboardingRepository(completed: true),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('wajib login & sudah login → /', (tester) async {
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club', requireLogin: true),
        repo: _FakeOnboardingRepository(completed: true),
        auth: const AuthAuthenticated(_user),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('tanpa wajib login → / walau belum login', (tester) async {
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(title: 'Club'),
        repo: _FakeOnboardingRepository(completed: true),
      ));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('menampilkan judul, tagline, dan logo dari app',
        (tester) async {
      await tester.pumpWidget(_app(
        splash: () => const SplashScreen(
          title: 'Anak Langit Archery',
          tagline: 'Aplikasi Anggota Club Panahan',
          logo: Icon(Icons.sports_score, key: Key('logo')),
        ),
        repo: _FakeOnboardingRepository(completed: true),
      ));
      await tester.pump();

      expect(find.text('Anak Langit Archery'), findsOneWidget);
      expect(find.text('Aplikasi Anggota Club Panahan'), findsOneWidget);
      expect(find.byKey(const Key('logo')), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}
