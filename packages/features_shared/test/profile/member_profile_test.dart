import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _complete = ProfileCompletion(completed: 12, total: 12, missing: []);

User _user({
  String name = 'Rina Ayu',
  MemberGender? gender,
  DateTime? birthDate,
  String? phone,
  String? address,
  DateTime? archeryStartedAt,
  BowType? bowType,
  ProfileCompletion? completion,
}) =>
    User(
      id: '7',
      name: name,
      email: 'rina@gmail.com',
      gender: gender,
      birthDate: birthDate,
      phone: phone,
      address: address,
      archeryStartedAt: archeryStartedAt,
      bowType: bowType,
      completion: completion,
    );

class _ProfileAuthNotifier extends AuthNotifier {
  _ProfileAuthNotifier(this._user);
  final User _user;
  final saved = <Map<String, Object?>>[];

  @override
  AuthState build() => AuthAuthenticated(_user);

  @override
  Future<void> updateProfile(Map<String, Object?> fields) async {
    saved.add(fields);
  }
}

Widget _host(Widget child, _ProfileAuthNotifier notifier,
    {List<RouteBase> extraRoutes = const []}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, __) => child),
      GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
      GoRoute(
          path: AppRoutes.editProfile, builder: (_, __) => const Text('EDIT')),
      ...extraRoutes,
    ],
  );
  return ProviderScope(
    overrides: [authProvider.overrideWith(() => notifier)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

/// Layar ponsel tinggi agar seluruh form/profil ikut dibangun & bisa diketuk.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 5400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  group('UserModel & ProfileCompletion', () {
    test('membaca data diri dan profile_completion dari API', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Rina',
        'email': 'rina@gmail.com',
        'gender': 'female',
        'birth_place': 'Bandung',
        'birth_date': '2001-04-12',
        'archery_started_at': '2019-07-01',
        'bow_type': 'recurve',
        'blood_type': 'AB',
        'profile_completion': {
          'is_complete': false,
          'completed': 7,
          'total': 12,
          'percent': 58,
          'missing': [
            {'key': 'avatar', 'label': 'Foto profil'},
          ],
        },
      });

      expect(user.gender, MemberGender.female);
      expect(user.birthDate, DateTime(2001, 4, 12));
      expect(user.archeryStartedAt, DateTime(2019, 7));
      expect(user.bowType, BowType.recurve);
      expect(user.bloodType, BloodType.ab);
      expect(user.completion.percent, 58);
      expect(user.completion.missing.single.label, 'Foto profil');

      // Cache lokal: bentuk JSON sama → hasil baca ulang identik.
      final again = UserModel.fromJson(user.toJson());
      expect(again.birthDate, user.birthDate);
      expect(again.bloodType, BloodType.ab);
      expect(again.completion.completed, 7);
    });

    test('tanpa profile_completion dari server → dihitung lokal', () {
      final partial = _user(gender: MemberGender.male, phone: '0812');
      expect(partial.completion.completed, 3); // nama, jenis kelamin, HP
      expect(partial.completion.isComplete, isFalse);
      expect(partial.completion.missing.map((f) => f.key), contains('avatar'));
      expect(partial.completion.total, ProfileField.all.length);
    });

    test('tanggal Indonesia', () {
      expect(AppDateUtils.longDateId(DateTime(2001, 4, 12)), '12 April 2001');
      expect(AppDateUtils.monthYearId(DateTime(2019, 7)), 'Juli 2019');
      expect(AppDateUtils.isoDate(DateTime(2019, 7, 1)), '2019-07-01');
    });
  });

  group('MemberProfileForm', () {
    Future<MemberProfileFormState> pumpForm(
        WidgetTester tester, User user) async {
      _tallScreen(tester);
      final key = GlobalKey<MemberProfileFormState>();
      await tester.pumpWidget(_host(
        Scaffold(
          body: SingleChildScrollView(
            child: MemberProfileForm(key: key, user: user),
          ),
        ),
        _ProfileAuthNotifier(user),
      ));
      await tester.pumpAndSettle();
      return key.currentState!;
    }

    testWidgets('tanpa perubahan → tidak ada yang dikirim', (tester) async {
      final form = await pumpForm(tester, _user(address: 'Jl. Merdeka'));
      expect(form.changes(), isEmpty);
    });

    testWidgets('hanya isian berubah; pengosongan → null; HP dinormalkan',
        (tester) async {
      final form = await pumpForm(
          tester, _user(address: 'Jl. Merdeka', bowType: BowType.compound));

      await tester.enterText(
          find.byKey(const Key('field-phone')), '0812-3456 7890');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Jl. Merdeka'), '');
      await _tap(tester, find.text('Perempuan'));
      await _tap(tester, find.text('Compound')); // ketuk lagi = kosongkan

      expect(form.changes(), {
        'phone': '081234567890',
        'address': null,
        'gender': 'female',
        'bow_type': null,
      });
    });

    testWidgets('nama wajib & nomor HP harus valid', (tester) async {
      final form = await pumpForm(tester, _user());

      await tester.enterText(find.byKey(const Key('field-name')), '  ');
      await tester.enterText(find.byKey(const Key('field-phone')), '12');
      await tester.pump();

      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
      expect(find.text('Nomor tidak valid (8–15 angka)'), findsOneWidget);
    });

    testWidgets('mulai panahan sebelum tanggal lahir ditolak', (tester) async {
      final form = await pumpForm(
        tester,
        _user(
          birthDate: DateTime(2005, 1, 1),
          archeryStartedAt: DateTime(2004, 6),
        ),
      );

      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('Tidak boleh sebelum tanggal lahir'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('belum lengkap → petunjuk + daftar isian + tombol Lengkapi',
        (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(
          _host(const ProfileScreen(), _ProfileAuthNotifier(_user())));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-incomplete-hint')), findsOneWidget);
      expect(find.textContaining('% lengkap'), findsOneWidget);
      expect(find.text('Foto profil'), findsOneWidget);
      expect(find.byKey(const Key('profile-complete-badge')), findsNothing);
      expect(find.byKey(const Key('profile-verified-icon')), findsNothing);
      expect(find.text('Belum diisi'), findsWidgets);

      await _tap(tester, find.text('Lengkapi Profil'));
      await tester.pumpAndSettle();
      expect(find.text('EDIT'), findsOneWidget);
    });

    testWidgets('lengkap → penanda apresiasi & ikon terverifikasi',
        (tester) async {
      _tallScreen(tester);
      await tester.pumpWidget(_host(
        const ProfileScreen(),
        _ProfileAuthNotifier(_user(
          gender: MemberGender.female,
          birthDate: DateTime(2001, 4, 12),
          archeryStartedAt: DateTime(2019, 7),
          bowType: BowType.recurve,
          completion: _complete,
        )),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-complete-badge')), findsOneWidget);
      expect(find.text('Profil Lengkap'), findsOneWidget);
      expect(find.byKey(const Key('profile-verified-icon')), findsOneWidget);
      expect(find.text('Lengkapi Profil'), findsNothing);
      expect(find.textContaining('Juli 2019'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
    });
  });

  group('ProfileSetupScreen', () {
    testWidgets('simpan sebagian lalu ke Beranda', (tester) async {
      _tallScreen(tester);
      final notifier = _ProfileAuthNotifier(_user());
      await tester.pumpWidget(_host(const ProfileSetupScreen(), notifier));
      await tester.pumpAndSettle();

      expect(find.text('Lengkapi Data Diri'), findsOneWidget);
      await _tap(tester, find.text('Laki-laki'));
      await tester.tap(find.byKey(const Key('save-profile')));
      await tester.pumpAndSettle();

      expect(notifier.saved, [
        {'gender': 'male'},
      ]);
      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('"Nanti saja" ke Beranda tanpa menyimpan', (tester) async {
      final notifier = _ProfileAuthNotifier(_user());
      await tester.pumpWidget(_host(const ProfileSetupScreen(), notifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('skip-profile-setup')));
      await tester.pumpAndSettle();

      expect(notifier.saved, isEmpty);
      expect(find.text('BERANDA'), findsOneWidget);
    });
  });

  group('requireAuthRedirectWith(afterLogin)', () {
    Future<void> pumpAt(WidgetTester tester, User user) async {
      String after(User u) =>
          u.completion.isComplete ? '/' : AppRoutes.profileSetup;
      final router = GoRouter(
        initialLocation: '/login',
        redirect: requireAuthRedirectWith(afterLogin: after),
        routes: [
          GoRoute(path: '/login', builder: (_, __) => const Text('LOGIN')),
          GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
          GoRoute(
              path: AppRoutes.profileSetup,
              builder: (_, __) => const Text('SETUP')),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _ProfileAuthNotifier(user))
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('profil belum lengkap → form data diri', (tester) async {
      await pumpAt(tester, _user());
      expect(find.text('SETUP'), findsOneWidget);
    });

    testWidgets('profil lengkap → Beranda', (tester) async {
      await pumpAt(tester, _user(completion: _complete));
      expect(find.text('BERANDA'), findsOneWidget);
    });
  });
}
