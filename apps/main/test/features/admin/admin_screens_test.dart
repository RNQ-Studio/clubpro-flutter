import 'package:app_main/features/admin/domain/entities/admin_user.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:app_main/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_admin_repository.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

const _owner = User(
  id: '1',
  name: 'Pemilik',
  email: 'pemilik@gmail.com',
  roles: [User.superAdminRole],
);
const _member = User(id: '9', name: 'Budi', email: 'budi@gmail.com');

Widget _app(
  FakeAdminRepository repository, {
  AuthState auth = const AuthAuthenticated(_owner),
  String location = AppRoutes.adminUsers,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (_, __) => const AdminPanelScreen(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (_, __) => const AdminUsersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    AdminUserDetailScreen(userId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
      adminRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void _size(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('gerbang akses', () {
    testWidgets('anggota biasa ditolak tanpa memanggil API', (tester) async {
      final repository = FakeAdminRepository();
      await tester.pumpWidget(
        _app(repository, auth: const AuthAuthenticated(_member)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halaman ini khusus super admin'), findsOneWidget);
      expect(repository.calls, isEmpty);

      await tester.tap(find.text('Kembali ke Beranda'));
      await tester.pumpAndSettle();
      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('detail lewat tautan langsung juga ditolak', (tester) async {
      final repository = FakeAdminRepository(detail: adminDetail());
      await tester.pumpWidget(_app(
        repository,
        auth: const AuthAuthenticated(_member),
        location: AppRoutes.adminUser('7'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Halaman ini khusus super admin'), findsOneWidget);
      expect(find.text('rina.ayu@gmail.com'), findsNothing);
    });

    testWidgets('selagi sesi diperiksa belum memanggil API', (tester) async {
      final repository = FakeAdminRepository();
      await tester.pumpWidget(_app(repository, auth: const AuthInitial()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.calls, isEmpty);
    });
  });

  group('daftar pengguna', () {
    FakeAdminRepository filled() => FakeAdminRepository(pages: [
          [
            adminUser(
              '1',
              name: 'Pemilik',
              email: 'pemilik@gmail.com',
              isSuperAdmin: true,
              lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
              device: adminDevices.first,
            ),
            adminUser('2',
                name: 'Budi', email: 'budi@gmail.com', isActive: false),
          ],
        ]);

    testWidgets('menampilkan ringkasan, data, peran, dan status',
        (tester) async {
      _size(tester, 500, 900);
      await tester.pumpWidget(_app(filled()));
      await tester.pumpAndSettle();

      expect(find.text('128'), findsOneWidget);
      expect(find.text('Total Pengguna'), findsOneWidget);
      expect(find.text('pemilik@gmail.com'), findsOneWidget);
      expect(find.text('Akses 5 menit lalu'), findsOneWidget);
      expect(find.textContaining('Chrome 130'), findsOneWidget);
      expect(find.text('Bekasi, West Java, Indonesia'), findsOneWidget);
      expect(find.text('Akses Belum tercatat'), findsOneWidget);
      expect(find.text('IP Geolocation by DB-IP'), findsOneWidget);
    });

    testWidgets('kolom di layar lebar, isi dibatasi lebarnya', (tester) async {
      _size(tester, 1280, 800);
      await tester.pumpWidget(_app(filled()));
      await tester.pumpAndSettle();

      expect(find.text('Terakhir Akses'), findsOneWidget);
      expect(find.text('Perangkat'), findsOneWidget);
      final row = tester.getSize(find.byKey(const Key('admin-user-1')));
      expect(row.width, lessThanOrEqualTo(1040));
      expect(tester.takeException(), isNull);

      // Judul kolom sejajar dengan isinya.
      expect(
        tester.getTopLeft(find.text('Perangkat')).dx,
        tester.getTopLeft(find.byKey(const Key('admin-device-cell'))).dx,
      );
      expect(
        tester.getTopLeft(find.text('Lokasi')).dx,
        tester.getTopLeft(find.text('Bekasi, West Java, Indonesia')).dx,
      );
    });

    testWidgets('pencarian menunggu pengguna selesai mengetik', (tester) async {
      final repository = filled();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('admin-search'));
      await tester.enterText(field, 'bu');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(field, 'budi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repository.calls.map((call) => call.search), ['', 'budi']);

      await tester.tap(find.byTooltip('Hapus pencarian'));
      await tester.pumpAndSettle();
      expect(repository.calls.last.search, '');
    });

    testWidgets('saringan memanggil server dan terpilih', (tester) async {
      final repository = filled();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin-filter-superAdmin')));
      await tester.pumpAndSettle();

      expect(repository.calls.last.filter, AdminUserFilter.superAdmin);
      expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const Key('admin-filter-superAdmin')))
            .selected,
        isTrue,
      );
    });

    testWidgets('kosong saat mencari', (tester) async {
      final repository = filled();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      repository.pages = const [[]];
      await tester.enterText(find.byKey(const Key('admin-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(
        find.text('Tidak ada pengguna yang cocok dengan pencarian'),
        findsOneWidget,
      );
      // Kolom pencarian tetap ada untuk memperbaiki kata kunci.
      expect(find.byKey(const Key('admin-search')), findsOneWidget);
    });

    testWidgets('gagal memuat bisa dicoba lagi', (tester) async {
      final repository = filled()
        ..error = const ServerException('Admin Panel belum aktif di server.');
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('Admin Panel belum aktif di server.'), findsOneWidget);

      repository.error = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('pemilik@gmail.com'), findsOneWidget);
    });

    testWidgets('halaman berikutnya dimuat walau tidak perlu digulir',
        (tester) async {
      _size(tester, 1280, 2000);
      final repository = FakeAdminRepository(pages: [
        [adminUser('1', email: 'satu@gmail.com')],
        [adminUser('2', email: 'dua@gmail.com')],
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.text('dua@gmail.com'), findsOneWidget);
    });

    testWidgets('mengetuk baris membuka detail', (tester) async {
      final repository = filled()..detail = adminDetail(id: '2', name: 'Budi');
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin-user-2')));
      await tester.pumpAndSettle();

      expect(find.text('Detail Pengguna'), findsOneWidget);
    });

    testWidgets('tombol kembali menuju menu Admin Panel', (tester) async {
      await tester.pumpWidget(_app(filled()));
      await tester.pumpAndSettle();

      expect(find.text('Kelola User'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Admin Panel'), findsOneWidget);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(filled()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('detail pengguna', () {
    Future<void> open(
      WidgetTester tester,
      FakeAdminRepository repository, {
      String id = '7',
    }) async {
      _size(tester, 500, 1600);
      await tester.pumpWidget(
        _app(repository, location: AppRoutes.adminUser(id)),
      );
      await tester.pumpAndSettle();
    }

    SwitchListTile tile(WidgetTester tester, String key) =>
        tester.widget<SwitchListTile>(find.byKey(Key(key)));

    testWidgets('menampilkan semua data yang diminta', (tester) async {
      await open(tester, FakeAdminRepository(detail: adminDetail()));

      for (final text in [
        'Rina Ayu Lestari',
        'rina.ayu@gmail.com',
        'Terakhir akses',
        'Terakhir login',
        'Terdaftar',
        'Google',
        'Perangkat & Lokasi (2)',
        'Chrome 130 · Android 14 · SM-S918B',
        'Bekasi, West Java, Indonesia',
        '180.244.128.1',
        'Safari 17 · macOS',
        'Jakarta, Indonesia',
        '081234567890',
        'Perempuan',
        'Nomor WhatsApp',
        'Kota Bandung, Jawa Barat',
        'Kota Bandung, Jawa Barat · sama dengan domisili',
        '5 dari 5 isian',
        'IP Geolocation by DB-IP',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final gone in [
        'Tempat, tanggal lahir',
        'Alamat',
        'Golongan darah',
        'Kontak darurat',
      ]) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
    });

    testWidgets('data aktivitas lama tertulis belum tercatat', (tester) async {
      await open(
        tester,
        FakeAdminRepository(
          detail: const AdminUserDetail(
            id: '7',
            name: 'Rina',
            email: 'rina@gmail.com',
          ),
        ),
      );

      expect(find.text('Belum tercatat'), findsNWidgets(4));
      expect(find.text('Perangkat & Lokasi (0)'), findsOneWidget);
    });

    testWidgets('memberi super admin butuh konfirmasi', (tester) async {
      final repository = FakeAdminRepository(detail: adminDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-super-admin-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Berikan akses super admin?'), findsOneWidget);
      expect(repository.actions, isEmpty);

      await tester.tap(find.text('Berikan Akses'));
      await tester.pumpAndSettle();

      expect(repository.actions, ['super-admin:7:true']);
      expect(find.text('Akses super admin diberikan'), findsOneWidget);
      expect(tile(tester, 'admin-super-admin-switch').value, isTrue);
    });

    testWidgets('batal di konfirmasi tidak mengubah apa pun', (tester) async {
      final repository = FakeAdminRepository(detail: adminDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-super-admin-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(repository.actions, isEmpty);
      expect(tile(tester, 'admin-super-admin-switch').value, isFalse);
    });

    testWidgets('menolak dari server tampil dan sakelar kembali',
        (tester) async {
      final repository = FakeAdminRepository(
        detail: adminDetail(),
        actionError: const ServerException('Ditolak oleh server.'),
      );
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-super-admin-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Berikan Akses'));
      await tester.pumpAndSettle();

      expect(find.text('Ditolak oleh server.'), findsOneWidget);
      expect(tile(tester, 'admin-super-admin-switch').value, isFalse);
      expect(tile(tester, 'admin-super-admin-switch').onChanged, isNotNull);
    });

    testWidgets('menonaktifkan akun menjelaskan akibatnya', (tester) async {
      final repository = FakeAdminRepository(detail: adminDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-active-switch')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('keluar dari semua perangkat'), findsOneWidget);

      await tester.tap(find.text('Nonaktifkan'));
      await tester.pumpAndSettle();

      expect(repository.actions, ['status:7:false']);
    });

    testWidgets('akun sendiri tidak bisa dicabut atau dinonaktifkan',
        (tester) async {
      await open(
        tester,
        FakeAdminRepository(detail: adminDetail(id: '1', isSuperAdmin: true)),
        id: '1',
      );

      expect(tile(tester, 'admin-super-admin-switch').onChanged, isNull);
      expect(tile(tester, 'admin-active-switch').onChanged, isNull);
      expect(find.text('Anda tidak bisa mencabut akses Anda sendiri'),
          findsOneWidget);
    });

    testWidgets('email belum terverifikasi tidak bisa diberi akses',
        (tester) async {
      await open(
        tester,
        FakeAdminRepository(detail: adminDetail(emailVerified: false)),
      );

      expect(tile(tester, 'admin-super-admin-switch').onChanged, isNull);
      expect(find.textContaining('Email belum terverifikasi'), findsOneWidget);
    });

    testWidgets('akun nonaktif harus diaktifkan dulu', (tester) async {
      await open(
        tester,
        FakeAdminRepository(detail: adminDetail(isActive: false)),
      );

      expect(tile(tester, 'admin-super-admin-switch').onChanged, isNull);
      expect(tile(tester, 'admin-active-switch').onChanged, isNotNull);
    });

    testWidgets('pengguna tidak ditemukan bisa dicoba lagi', (tester) async {
      final repository = FakeAdminRepository(
        detail: adminDetail(),
        error: const ServerException('Pengguna tidak ditemukan.'),
      );
      await open(tester, repository);

      expect(find.text('Pengguna tidak ditemukan.'), findsOneWidget);

      repository.error = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Rina Ayu Lestari'), findsOneWidget);
    });

    testWidgets('dua kolom di layar lebar tanpa overflow', (tester) async {
      _size(tester, 1280, 1000);
      await tester.pumpWidget(_app(
        FakeAdminRepository(detail: adminDetail()),
        location: AppRoutes.adminUser('7'),
      ));
      await tester.pumpAndSettle();

      final akses = tester.getTopLeft(find.text('Akses'));
      final perangkat = tester.getTopLeft(find.text('Perangkat & Lokasi (2)'));
      expect(perangkat.dx, greaterThan(akses.dx));
      expect(perangkat.dy, akses.dy);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(
        FakeAdminRepository(detail: adminDetail()),
        location: AppRoutes.adminUser('7'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
