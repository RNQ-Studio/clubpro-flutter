import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _complete = ProfileCompletion(completed: 5, total: 5, missing: []);

const _bandung = MemberRegion(
  provinceCode: '32',
  provinceName: 'Jawa Barat',
  cityCode: '32.73',
  cityName: 'Kota Bandung',
);
const _surabaya = MemberRegion(
  provinceCode: '35',
  provinceName: 'Jawa Timur',
  cityCode: '35.78',
  cityName: 'Kota Surabaya',
);

const _regions = [
  RegionProvince(code: '32', name: 'Jawa Barat', cities: [
    RegionCity(code: '32.73', name: 'Kota Bandung'),
    RegionCity(code: '32.05', name: 'Kabupaten Garut'),
  ]),
  RegionProvince(code: '35', name: 'Jawa Timur', cities: [
    RegionCity(code: '35.78', name: 'Kota Surabaya'),
  ]),
];

class _FakeRegions implements RegionRepository {
  Exception? error;

  @override
  Future<List<RegionProvince>> getIndonesia() async {
    final failure = error;
    if (failure != null) throw failure;
    return _regions;
  }
}

User _user({
  String name = 'Rina Ayu',
  MemberGender? gender,
  String? phone,
  MemberRegion? domicile,
  MemberRegion? nikRegion,
  bool nikSameAsDomicile = false,
  ProfileCompletion? completion,
}) =>
    User(
      id: '7',
      name: name,
      email: 'rina@gmail.com',
      gender: gender,
      phone: phone,
      domicile: domicile,
      nikRegion: nikRegion,
      nikSameAsDomicile: nikSameAsDomicile,
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

  @override
  Future<void> logout() async => state = const AuthUnauthenticated();
}

Widget _host(Widget child, _ProfileAuthNotifier notifier,
    {RegionRepository? regions}) {
  final router = GoRouter(
    initialLocation: '/screen',
    routes: [
      GoRoute(path: '/screen', builder: (_, __) => child),
      GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
      GoRoute(
          path: AppRoutes.editProfile, builder: (_, __) => const Text('EDIT')),
      GoRoute(
          path: AppRoutes.settings, builder: (_, __) => const Text('SETTINGS')),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => notifier),
      regionRepositoryProvider.overrideWithValue(regions ?? _FakeRegions()),
    ],
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
  await tester.pumpAndSettle();
}

/// Pilih satu butir dropdown lewat UI, seperti pengguna.
Future<void> _choose(WidgetTester tester, String fieldKey, String label) async {
  await _tap(tester, find.byKey(Key(fieldKey)));
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  group('UserModel & ProfileCompletion', () {
    test('membaca data diri, wilayah, dan profile_completion dari API', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Rina',
        'email': 'rina@gmail.com',
        'gender': 'female',
        'phone': '081234567890',
        'domicile_province_code': '32',
        'domicile_province_name': 'Jawa Barat',
        'domicile_city_code': '32.73',
        'domicile_city_name': 'Kota Bandung',
        'nik_province_code': '32',
        'nik_province_name': 'Jawa Barat',
        'nik_city_code': '32.73',
        'nik_city_name': 'Kota Bandung',
        'nik_same_as_domicile': true,
        'profile_completion': {
          'is_complete': true,
          'completed': 5,
          'total': 5,
          'percent': 100,
          'missing': [],
        },
      });

      expect(user.gender, MemberGender.female);
      expect(user.domicile?.label, 'Kota Bandung, Jawa Barat');
      expect(user.nikRegion?.cityCode, '32.73');
      expect(user.nikSameAsDomicile, isTrue);
      expect(user.completion.isComplete, isTrue);

      // Cache lokal: bentuk JSON sama → hasil baca ulang identik.
      final again = UserModel.fromJson(user.toJson());
      expect(again.domicile?.label, 'Kota Bandung, Jawa Barat');
      expect(again.nikRegion?.provinceCode, '32');
      expect(again.nikSameAsDomicile, isTrue);
      expect(again.completion.completed, 5);
    });

    test('wilayah belum lengkap (tanpa kota) dianggap belum diisi', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Rina',
        'email': 'rina@gmail.com',
        'domicile_province_code': '32',
        'domicile_province_name': 'Jawa Barat',
        'domicile_city_code': null,
      });

      expect(user.domicile, isNull);
      expect(user.nikSameAsDomicile, isFalse);
    });

    test('server lama masih menghitung isian lama → dihitung lokal', () {
      final user = UserModel.fromJson({
        'id': 7,
        'name': 'Rina',
        'email': 'rina@gmail.com',
        'gender': 'female',
        'phone': '081234567890',
        'birth_date': '2001-04-12',
        'blood_type': 'AB',
        'emergency_contact_name': 'Ibu',
        'profile_completion': {
          'is_complete': false,
          'completed': 7,
          'total': 10,
          'percent': 70,
          'missing': [
            {'key': 'avatar', 'label': 'Foto profil'},
            {'key': 'address', 'label': 'Alamat'},
          ],
        },
      });

      expect(user.completion.total, ProfileField.all.length);
      expect(user.completion.completed, 3); // nama, jenis kelamin, WhatsApp
      expect(user.completion.missing.map((f) => f.key),
          ['domicile', 'nik_region']);
      expect(user.toJson().keys, isNot(contains('blood_type')));
      expect(user.toJson().keys, isNot(contains('emergency_contact_name')));
    });

    test('lima isian kelengkapan, tanpa foto, lahir, alamat, kesehatan', () {
      expect(ProfileField.all.map((f) => f.key),
          ['name', 'gender', 'phone', 'domicile', 'nik_region']);
      expect(ProfileField.all.map((f) => f.label), [
        'Nama lengkap',
        'Jenis kelamin',
        'Nomor WhatsApp',
        'Provinsi & kota domisili',
        'Provinsi & kota sesuai NIK',
      ]);
    });

    test('tanpa profile_completion dari server → dihitung lokal', () {
      final partial = _user(gender: MemberGender.male, phone: '0812');
      expect(partial.completion.completed, 3);
      expect(partial.completion.isComplete, isFalse);

      final full = _user(
        gender: MemberGender.male,
        phone: '0812',
        domicile: _bandung,
        nikRegion: _bandung,
      );
      expect(full.completion.isComplete, isTrue);
    });
  });

  group('MemberProfileForm', () {
    Future<MemberProfileFormState> pumpForm(WidgetTester tester, User user,
        {RegionRepository? regions}) async {
      _tallScreen(tester);
      final key = GlobalKey<MemberProfileFormState>();
      await tester.pumpWidget(_host(
        Scaffold(
          body: SingleChildScrollView(
            child: MemberProfileForm(key: key, user: user),
          ),
        ),
        _ProfileAuthNotifier(user),
        regions: regions,
      ));
      await tester.pumpAndSettle();
      return key.currentState!;
    }

    testWidgets('hanya isian yang diminta; tanpa foto, lahir, kesehatan',
        (tester) async {
      await pumpForm(tester, _user());

      for (final label in [
        'Nama lengkap',
        'Jenis kelamin',
        'Nomor WhatsApp',
        'Domisili',
        'Sesuai NIK (KTP)',
        'Sama dengan domisili',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.text('Provinsi'), findsNWidgets(2));
      expect(find.text('Kota/Kabupaten'), findsNWidgets(2));
      for (final gone in [
        'Foto profil',
        'Tempat lahir',
        'Tanggal lahir',
        'Alamat',
        'Golongan darah',
        'Nama kontak darurat',
        'Nomor kontak darurat',
        'Kesehatan & Kontak Darurat',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      expect(find.byType(ProfileAvatarPicker), findsNothing);
    });

    testWidgets('tanpa perubahan → tidak ada yang dikirim', (tester) async {
      final form = await pumpForm(
        tester,
        _user(phone: '081234567890', domicile: _bandung, nikRegion: _surabaya),
      );
      expect(form.changes(), isEmpty);
    });

    testWidgets('nama, jenis kelamin, WhatsApp: hanya yang berubah dikirim',
        (tester) async {
      final form = await pumpForm(tester, _user(phone: '081111111111'));

      await tester.enterText(
          find.byKey(const Key('field-phone')), '0812-3456 7890');
      await _tap(tester, find.text('Perempuan'));

      expect(form.changes(), {'phone': '081234567890', 'gender': 'female'});

      await tester.enterText(find.byKey(const Key('field-phone')), '');
      expect(form.changes()['phone'], isNull);
      expect(form.changes().containsKey('phone'), isTrue);
    });

    testWidgets('domisili & NIK dipilih dari dropdown, dikirim berpasangan',
        (tester) async {
      final form = await pumpForm(tester, _user());

      await _choose(tester, 'field-domicile-province', 'Jawa Barat');
      await _choose(tester, 'field-domicile-city-32', 'Kabupaten Garut');
      await _choose(tester, 'field-nik-province', 'Jawa Timur');
      await _choose(tester, 'field-nik-city-35', 'Kota Surabaya');

      expect(form.validate(), isTrue);
      expect(form.changes(), {
        'domicile_province_code': '32',
        'domicile_city_code': '32.05',
        'nik_province_code': '35',
        'nik_city_code': '35.78',
      });
    });

    testWidgets(
        'kota hanya dari provinsi terpilih; ganti provinsi = kota ulang',
        (tester) async {
      final form = await pumpForm(tester, _user(domicile: _bandung));

      await _choose(tester, 'field-domicile-province', 'Jawa Timur');
      await _tap(tester, find.byKey(const Key('field-domicile-city-35')));
      expect(find.text('Kota Surabaya'), findsWidgets);
      expect(find.text('Kabupaten Garut'), findsNothing);
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      // Kota belum dipilih → tidak lolos validasi.
      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pilih kota/kabupaten domisili'), findsOneWidget);
    });

    testWidgets('kota terkunci sebelum provinsi dipilih', (tester) async {
      await pumpForm(tester, _user());

      final city = tester.widget<DropdownMenu<RegionCity>>(find.descendant(
        of: find.byKey(const Key('field-domicile-city-kosong')),
        matching: find.byType(DropdownMenu<RegionCity>),
      ));
      expect(city.enabled, isFalse);
      expect(find.text('Pilih provinsi terlebih dahulu'), findsWidgets);
    });

    testWidgets('"sama dengan domisili" menyembunyikan dropdown NIK',
        (tester) async {
      final form = await pumpForm(tester, _user(nikRegion: _surabaya));

      await _choose(tester, 'field-domicile-province', 'Jawa Barat');
      await _choose(tester, 'field-domicile-city-32', 'Kota Bandung');
      await _tap(tester, find.byKey(const Key('field-nik-same')));

      expect(find.byKey(const Key('field-nik-province')), findsNothing);
      expect(find.text('Kota Bandung, Jawa Barat'), findsOneWidget);
      // Wilayah NIK tidak dikirim: server menyalin domisili.
      expect(form.changes(), {
        'domicile_province_code': '32',
        'domicile_city_code': '32.73',
        'nik_same_as_domicile': true,
      });
    });

    testWidgets('berhenti "sama dengan domisili" → NIK bisa dipilih lagi',
        (tester) async {
      final form = await pumpForm(
        tester,
        _user(domicile: _bandung, nikRegion: _bandung, nikSameAsDomicile: true),
      );
      expect(find.byKey(const Key('field-nik-province')), findsNothing);

      await _tap(tester, find.byKey(const Key('field-nik-same')));
      await _choose(tester, 'field-nik-province', 'Jawa Timur');
      await _choose(tester, 'field-nik-city-35', 'Kota Surabaya');

      expect(form.changes(), {
        'nik_same_as_domicile': false,
        'nik_province_code': '35',
        'nik_city_code': '35.78',
      });
    });

    testWidgets('daftar wilayah gagal dimuat → pesan & coba lagi',
        (tester) async {
      final regions = _FakeRegions()
        ..error = const NetworkException('Tidak dapat terhubung ke server.');
      await pumpForm(tester, _user(), regions: regions);

      expect(find.byKey(const Key('field-domicile-error')), findsOneWidget);
      expect(find.text('Tidak dapat terhubung ke server.'), findsWidgets);

      regions.error = null;
      await _tap(tester, find.text('Coba Lagi').first);
      expect(find.byKey(const Key('field-domicile-province')), findsOneWidget);
    });

    testWidgets('nama wajib & nomor WhatsApp harus valid', (tester) async {
      final form = await pumpForm(tester, _user());

      await tester.enterText(find.byKey(const Key('field-name')), '  ');
      await tester.enterText(find.byKey(const Key('field-phone')), '12');
      await tester.pump();

      expect(form.validate(), isFalse);
      await tester.pump();
      expect(find.text('Nama tidak boleh kosong'), findsOneWidget);
      expect(find.text('Nomor tidak valid (8–15 angka)'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    Future<_ProfileAuthNotifier> pumpProfile(
        WidgetTester tester, User user) async {
      _tallScreen(tester);
      final notifier = _ProfileAuthNotifier(user);
      await tester.pumpWidget(_host(const ProfileScreen(), notifier));
      await tester.pumpAndSettle();
      return notifier;
    }

    testWidgets('belum lengkap → status, petunjuk, dan tombol Lengkapi',
        (tester) async {
      await pumpProfile(tester, _user());

      expect(find.byKey(const Key('profile-incomplete')), findsOneWidget);
      expect(find.text('Belum lengkap'), findsOneWidget);
      // Persentase cukup sekali, di kartu petunjuk.
      expect(find.text('Profil 20% lengkap'), findsOneWidget);
      expect(find.byKey(const Key('profile-incomplete-hint')), findsOneWidget);
      expect(find.byKey(const Key('profile-verified')), findsNothing);
      expect(find.text('Belum diisi'), findsNWidgets(4));

      await _tap(tester, find.text('Lengkapi Profil'));
      expect(find.text('EDIT'), findsOneWidget);
    });

    testWidgets('lengkap → penanda terverifikasi, data diri tampil',
        (tester) async {
      await pumpProfile(
        tester,
        _user(
          gender: MemberGender.female,
          phone: '081234567890',
          domicile: _bandung,
          nikRegion: _surabaya,
          completion: _complete,
        ),
      );

      expect(find.byKey(const Key('profile-verified')), findsOneWidget);
      expect(find.text('Profil lengkap'), findsOneWidget);
      expect(find.text('Lengkapi Profil'), findsNothing);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Kota Bandung, Jawa Barat'), findsOneWidget);
      expect(find.text('Kota Surabaya, Jawa Timur'), findsOneWidget);
      expect(find.text('Belum diisi'), findsNothing);
    });

    testWidgets('wilayah NIK sama dengan domisili ditandai', (tester) async {
      await pumpProfile(
        tester,
        _user(domicile: _bandung, nikRegion: _bandung, nikSameAsDomicile: true),
      );

      expect(find.text('Kota Bandung, Jawa Barat · sama dengan domisili'),
          findsOneWidget);
    });

    testWidgets('tanpa kesehatan & kontak darurat', (tester) async {
      await pumpProfile(tester, _user(completion: _complete));

      for (final gone in [
        'Kesehatan & Kontak Darurat',
        'Golongan darah',
        'Kontak darurat',
        'Tempat, tanggal lahir',
        'Alamat',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('Ubah membuka form data diri', (tester) async {
      await pumpProfile(tester, _user(completion: _complete));

      await _tap(tester, find.byKey(const Key('profile-edit')));
      expect(find.text('EDIT'), findsOneWidget);
    });

    testWidgets('Pengaturan membuka halaman pengaturan', (tester) async {
      await pumpProfile(tester, _user(completion: _complete));

      expect(find.text('Tema, bahasa, dan login biometrik'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('profile-settings')));
      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('Keluar minta konfirmasi; Batal tidak keluar', (tester) async {
      final notifier = await pumpProfile(tester, _user(completion: _complete));

      await _tap(tester, find.byKey(const Key('logout')));
      expect(find.text('Keluar dari akun?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(notifier.state, isA<AuthAuthenticated>());

      await _tap(tester, find.byKey(const Key('logout')));
      await tester.tap(find.byKey(const Key('logout-confirm')));
      // Sesudah keluar layar menunggu router (indikator berputar terus).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(notifier.state, isA<AuthUnauthenticated>());
    });

    testWidgets('layar lebar: isi tidak melebar', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(const ProfileScreen(),
          _ProfileAuthNotifier(_user(completion: _complete))));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(const Key('logout'))).width,
          lessThanOrEqualTo(ProfileScreen.maxWidth));
      expect(tester.takeException(), isNull);
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
