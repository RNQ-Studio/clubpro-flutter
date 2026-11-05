import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/communities_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_detail_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_form_screen.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_community_repository.dart';

Widget _app(
  FakeCommunityRepository repository, {
  String location = AppRoutes.communities,
  FakeCommunityImagePicker? picker,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.communities,
        builder: (_, __) => const CommunitiesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (_, __) => const CommunityFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => CommunityDetailScreen(
              communityId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      communityRepositoryProvider.overrideWithValue(repository),
      communityImagePickerProvider
          .overrideWithValue(picker ?? FakeCommunityImagePicker()),
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

Finder _field(String name) => find.byKey(Key('community-field-$name'));

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('community-next')));
  await tester.pumpAndSettle();
}

/// Pilih satu butir dropdown lewat UI, seperti pengguna.
Future<void> _choose(WidgetTester tester, Finder field, String label) async {
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _fillIdentity(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('community-logo')));
  await tester.pumpAndSettle();
  await tester.enterText(_field('name'), 'Pemanah Nusantara');
  await tester.enterText(_field('short_name'), 'PN');
  await tester.tap(find.byKey(const Key('community-type-panahan')));
  await tester.pumpAndSettle();
}

Future<void> _fillLocation(WidgetTester tester) async {
  await _choose(
      tester, find.byKey(const Key('community-province')), 'Jawa Barat');
  await _choose(
      tester, find.byKey(const Key('community-city-32')), 'Kota Bandung');
  await tester.enterText(_field('address'), 'Jl. Merdeka No. 10, Bandung');
}

Future<void> _fillContact(WidgetTester tester) async {
  await tester.enterText(_field('contact_name'), 'Rina Ayu');
  await tester.enterText(_field('contact_phone'), '0812 3456 7890');
}

Future<void> _fillStory(WidgetTester tester) async {
  await tester.enterText(
    _field('description'),
    'Komunitas pecinta panahan yang rutin berlatih setiap akhir pekan.',
  );
  await tester.tap(find.byKey(const Key('community-add-photo')));
  await tester.pumpAndSettle();
}

Future<void> _toReview(WidgetTester tester) async {
  await _fillIdentity(tester);
  await _next(tester);
  await _fillLocation(tester);
  await _next(tester);
  await _fillContact(tester);
  await _next(tester);
  await _fillStory(tester);
  await _next(tester);
}

void main() {
  group('daftar', () {
    testWidgets('kosong: mengajak mendaftarkan komunitas', (tester) async {
      await tester.pumpWidget(_app(FakeCommunityRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada komunitas terverifikasi'), findsOneWidget);
      expect(find.text('Daftarkan Komunitas'), findsOneWidget);
    });

    testWidgets('menampilkan komunitas dan saringan jenis', (tester) async {
      await tester.pumpWidget(_app(FakeCommunityRepository(pages: [
        [testCommunity('1'), testCommunity('2', name: 'Sepak Bola Solo')],
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Pemanah Nusantara'), findsOneWidget);
      expect(find.text('Sepak Bola Solo'), findsOneWidget);
      expect(find.text('Kota Bandung, Jawa Barat'), findsNWidgets(2));
      expect(find.byKey(const Key('community-filter-semua')), findsOneWidget);
      expect(find.byKey(const Key('community-filter-fashion')), findsOneWidget);
    });

    testWidgets('pengajuan sendiri tampil terpisah dengan statusnya',
        (tester) async {
      await tester.pumpWidget(_app(FakeCommunityRepository(mine: [
        testCommunity('5',
            name: 'Masih Menunggu', status: CommunityStatus.pending),
        testCommunity('6', name: 'Sudah Tampil'),
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Masih Menunggu'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      // Yang sudah disetujui ada di daftar umum, tidak perlu ditampilkan lagi.
      expect(find.text('Sudah Tampil'), findsNothing);
    });

    testWidgets('pencarian menunggu pengguna selesai mengetik', (tester) async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1')],
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('community-search'));
      await tester.enterText(field, 'ba');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(field, 'bandung');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repository.listCalls.map((c) => c.search), ['', 'bandung']);
    });

    testWidgets('saring jenis memanggil server', (tester) async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1')],
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community-filter-panahan')));
      await tester.pumpAndSettle();

      expect(repository.listCalls.last.type, 'panahan');
    });

    testWidgets('hasil pencarian kosong beda dengan belum ada komunitas',
        (tester) async {
      final repository = FakeCommunityRepository(pages: [
        [testCommunity('1')],
      ]);
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      repository.pages = const [[]];
      await tester.enterText(find.byKey(const Key('community-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Tidak ada komunitas yang cocok'), findsOneWidget);
      expect(find.byKey(const Key('community-search')), findsOneWidget);
    });

    testWidgets('server belum memuat fitur: pesan jelas dan bisa dicoba lagi',
        (tester) async {
      final repository = FakeCommunityRepository(
        pages: [
          [testCommunity('1')],
        ],
        error: const ServerException('Fitur Komunitas belum aktif di server.'),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(
          find.text('Fitur Komunitas belum aktif di server.'), findsOneWidget);

      repository.error = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Pemanah Nusantara'), findsOneWidget);
    });

    testWidgets('halaman berikutnya dimuat walau tidak perlu digulir',
        (tester) async {
      _size(tester, 1280, 2000);
      await tester.pumpWidget(_app(FakeCommunityRepository(pages: [
        [testCommunity('1', name: 'Satu')],
        [testCommunity('2', name: 'Dua')],
      ])));
      await tester.pumpAndSettle();

      expect(find.text('Dua'), findsOneWidget);
    });

    testWidgets('mengetuk kartu membuka detail', (tester) async {
      final repository = FakeCommunityRepository(
        pages: [
          [testCommunity('1')],
        ],
        detail: testDetail(),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community-1')));
      await tester.pumpAndSettle();

      expect(find.text('Detail Komunitas'), findsOneWidget);
    });

    testWidgets('tombol membuka form', (tester) async {
      await tester.pumpWidget(_app(FakeCommunityRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('community-create')));
      await tester.pumpAndSettle();

      expect(find.text('Kenalkan komunitas Anda'), findsOneWidget);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(FakeCommunityRepository(
        pages: [
          [
            testCommunity('1',
                name: 'Nama Komunitas Yang Panjang Sekali Di Sini')
          ],
        ],
        mine: [testCommunity('2', status: CommunityStatus.pending)],
      )));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('detail', () {
    testWidgets('memuat isi lengkap dan kontak', (tester) async {
      await tester.pumpWidget(_app(
        FakeCommunityRepository(detail: testDetail()),
        location: AppRoutes.community('1'),
      ));
      await tester.pumpAndSettle();

      for (final text in [
        'Pemanah Nusantara',
        'Panahan',
        'Kota Bandung, Jawa Barat',
        'Jl. Merdeka No. 10, Sumur Bandung',
        'Rina Ayu',
        '081234567890',
        'pengurus@gmail.com',
        'WhatsApp',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.textContaining('Menunggu verifikasi'), findsNothing);
    });

    testWidgets('pengajuan sendiri menjelaskan statusnya', (tester) async {
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(status: CommunityStatus.pending, email: null),
        ),
        location: AppRoutes.community('1'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Belum tampil di publik'), findsOneWidget);
      expect(find.text('Email'), findsNothing);
    });

    testWidgets('tidak ditemukan bisa dicoba lagi', (tester) async {
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          error: const ServerException('Komunitas tidak ditemukan.'),
        ),
        location: AppRoutes.community('9'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Komunitas tidak ditemukan.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('form', () {
    Future<FakeCommunityRepository> open(
      WidgetTester tester, {
      double width = 500,
      double height = 1100,
      FakeCommunityRepository? repository,
      FakeCommunityImagePicker? picker,
    }) async {
      _size(tester, width, height);
      final fake = repository ?? FakeCommunityRepository();
      await tester.pumpWidget(_app(
        fake,
        location: AppRoutes.createCommunity,
        picker: picker,
      ));
      await tester.pumpAndSettle();
      return fake;
    }

    testWidgets('isi langkah mulai tepat di bawah header', (tester) async {
      await open(tester, width: 500, height: 1100);
      final narrow = tester.getTopLeft(find.text('Kenalkan komunitas Anda')).dy;
      expect(narrow, lessThan(180));

      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester, width: 1280, height: 900);
      final wide = tester.getTopLeft(find.text('Kenalkan komunitas Anda')).dy;
      expect(wide, lessThan(180));
    });

    testWidgets('garis langkah berada di tengah lingkaran penanda',
        (tester) async {
      await open(tester);

      final dot = tester.getCenter(
        find.byKey(const Key('community-step-dot-location')),
      );
      final line = tester.getCenter(
        find.byKey(const Key('community-step-line-location')),
      );
      expect(line.dy, closeTo(dot.dy, 1));
    });

    testWidgets('alur lengkap: isi, tinjau, kirim, menunggu verifikasi',
        (tester) async {
      final repository = await open(tester);

      await _toReview(tester);

      expect(find.text('Periksa sekali lagi sebelum dikirim'), findsOneWidget);
      expect(find.text('Jawa Barat'), findsOneWidget);
      expect(find.text('Kota Bandung'), findsOneWidget);
      expect(find.text('Kirim Pengajuan'), findsOneWidget);

      await _next(tester);

      expect(find.text('Pengajuan Terkirim!'), findsOneWidget);
      expect(find.textContaining('menunggu verifikasi super admin'),
          findsOneWidget);
      expect(find.text('Verifikasi super admin'), findsOneWidget);

      final sent = repository.submitted.single.toPayload();
      expect(sent['name'], 'Pemanah Nusantara');
      expect(sent['short_name'], 'PN');
      expect(sent['type'], 'panahan');
      expect(sent['province_code'], '32');
      expect(sent['city_code'], '32.73');
      expect(sent['contact_phone'], '081234567890');
      expect((sent['photo_asset_ids'] as List), hasLength(2));
    });

    testWidgets('sesudah terkirim kembali ke daftar dengan statusnya',
        (tester) async {
      final repository = await open(tester);
      await _toReview(tester);
      repository.mine = [
        testCommunity('1', status: CommunityStatus.pending),
      ];
      await _next(tester);

      await tester.tap(find.byKey(const Key('community-submitted-done')));
      await tester.pumpAndSettle();

      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
    });

    testWidgets(
        'langkah tidak terlewati tanpa isian, galat tampil di tempatnya',
        (tester) async {
      await open(tester);

      expect(find.text('Nama komunitas wajib diisi'), findsNothing);

      await _next(tester);

      expect(find.text('Kenalkan komunitas Anda'), findsOneWidget);
      expect(find.text('Pilih foto profil komunitas'), findsOneWidget);
      expect(find.text('Nama komunitas wajib diisi'), findsOneWidget);
      expect(find.text('Nama pendek wajib diisi'), findsOneWidget);
      expect(find.text('Pilih jenis komunitas'), findsOneWidget);

      await tester.enterText(_field('name'), 'Pemanah');
      await tester.pump();
      expect(find.text('Nama komunitas wajib diisi'), findsNothing);
    });

    testWidgets('semua contoh jenis tampil; Lainnya meminta jenisnya',
        (tester) async {
      await open(tester);

      for (final label in ['Panahan', 'Fashion', 'Sepak Bola', 'Lainnya']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(_field('type_other'), findsNothing);

      await tester.tap(find.byKey(const Key('community-type-lainnya')));
      await tester.pumpAndSettle();

      expect(_field('type_other'), findsOneWidget);
    });

    testWidgets('kota terkunci sebelum provinsi dipilih', (tester) async {
      await open(tester);
      await _fillIdentity(tester);
      await _next(tester);

      expect(find.text('Provinsi'), findsWidgets);
      final city = tester.widget<DropdownMenu<RegionCity>>(
        find.descendant(
          of: find.byKey(const Key('community-city-kosong')),
          matching: find.byType(DropdownMenu<RegionCity>),
        ),
      );
      expect(city.enabled, isFalse);
      expect(find.text('Pilih provinsi terlebih dahulu'), findsWidgets);
    });

    testWidgets('pilihan kota hanya dari provinsi terpilih', (tester) async {
      await open(tester);
      await _fillIdentity(tester);
      await _next(tester);
      await _choose(
          tester, find.byKey(const Key('community-province')), 'Jawa Timur');

      await tester.tap(find.byKey(const Key('community-city-35')));
      await tester.pumpAndSettle();

      expect(find.text('Kota Surabaya'), findsWidgets);
      expect(find.text('Kota Bandung'), findsNothing);
    });

    testWidgets('mengganti provinsi mengosongkan kota yang sudah dipilih',
        (tester) async {
      final repository = await open(tester);
      await _fillIdentity(tester);
      await _next(tester);
      await _fillLocation(tester);

      await _choose(
          tester, find.byKey(const Key('community-province')), 'Jawa Timur');
      await _next(tester);

      expect(find.text('Pilih kota/kabupaten'), findsOneWidget);
      expect(find.text('Di mana komunitas Anda berada?'), findsOneWidget);
      expect(repository.submitted, isEmpty);
    });

    testWidgets('provinsi bisa dicari dengan mengetik', (tester) async {
      await open(tester);
      await _fillIdentity(tester);
      await _next(tester);

      final field = find.descendant(
        of: find.byKey(const Key('community-province')),
        matching: find.byType(TextField),
      );
      await tester.tap(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, 'timur');
      await tester.pumpAndSettle();

      expect(find.text('Jawa Timur'), findsWidgets);
      expect(find.text('Jawa Barat'), findsNothing);
    });

    testWidgets('data wilayah gagal dimuat bisa dicoba lagi', (tester) async {
      final repository = FakeCommunityRepository(
        regionsError:
            const NetworkException('Tidak dapat terhubung ke server.'),
      );
      await open(tester, repository: repository);
      await _fillIdentity(tester);
      await _next(tester);

      expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);

      repository.regionsError = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('community-province')), findsOneWidget);
    });

    testWidgets('kembali ke langkah sebelumnya mempertahankan isian',
        (tester) async {
      await open(tester);
      await _fillIdentity(tester);
      await _next(tester);

      await tester.tap(find.byKey(const Key('community-back')));
      await tester.pumpAndSettle();

      expect(find.text('Pemanah Nusantara'), findsWidgets);
    });

    testWidgets('Ubah di ringkasan membuka langkahnya', (tester) async {
      await open(tester);
      await _toReview(tester);

      await tester.tap(find.byKey(const Key('community-review-edit-contact')));
      await tester.pumpAndSettle();

      expect(find.text('Siapa yang bisa dihubungi?'), findsOneWidget);
    });

    testWidgets('foto bisa ditambah dan dihapus', (tester) async {
      await open(tester);
      await _fillIdentity(tester);
      await _next(tester);
      await _fillLocation(tester);
      await _next(tester);
      await _fillContact(tester);
      await _next(tester);

      await tester.tap(find.byKey(const Key('community-add-photo')));
      await tester.pumpAndSettle();
      expect(find.text('2/${CommunityDraft.maxPhotos}'), findsOneWidget);

      await tester.tap(find.byTooltip('Hapus foto').first);
      await tester.pumpAndSettle();
      expect(find.text('1/${CommunityDraft.maxPhotos}'), findsOneWidget);
    });

    testWidgets('foto yang tidak bisa dipakai menampilkan pesan',
        (tester) async {
      await open(
        tester,
        picker: FakeCommunityImagePicker(
          error: const CommunityImageException(
              'Format foto harus JPG, PNG, atau WebP.'),
        ),
      );

      await tester.tap(find.byKey(const Key('community-logo')));
      await tester.pumpAndSettle();

      expect(
          find.text('Format foto harus JPG, PNG, atau WebP.'), findsOneWidget);
    });

    testWidgets('gagal terkirim: pesan tampil, isian utuh, bisa dikirim lagi',
        (tester) async {
      final repository = await open(tester);
      await _toReview(tester);
      repository.submitError = const NetworkException(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );

      await _next(tester);

      expect(find.byKey(const Key('community-form-error')), findsOneWidget);
      expect(find.text('Kirim Pengajuan'), findsOneWidget);

      await _next(tester);

      expect(find.text('Pengajuan Terkirim!'), findsOneWidget);
    });

    testWidgets('ditolak server: kembali ke isian yang salah', (tester) async {
      final repository = await open(tester);
      await _toReview(tester);
      repository.submitError = const CommunityFieldException(
        'name',
        'Komunitas ini sudah Anda ajukan dan sedang menunggu verifikasi.',
      );

      await _next(tester);

      expect(find.text('Kenalkan komunitas Anda'), findsOneWidget);
      expect(
        find.text(
            'Komunitas ini sudah Anda ajukan dan sedang menunggu verifikasi.'),
        findsOneWidget,
      );
    });

    testWidgets('form kosong bisa langsung ditutup', (tester) async {
      await open(tester);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();

      expect(find.text('Tinggalkan form?'), findsNothing);
      expect(find.text('Komunitas'), findsOneWidget);
    });

    testWidgets('form terisi meminta konfirmasi sebelum ditutup',
        (tester) async {
      await open(tester);
      await tester.enterText(_field('name'), 'Pemanah');
      await tester.pump();

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Tinggalkan form?'), findsOneWidget);

      await tester.tap(find.text('Lanjut Mengisi'));
      await tester.pumpAndSettle();
      expect(find.text('Kenalkan komunitas Anda'), findsOneWidget);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tinggalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Kenalkan komunitas Anda'), findsNothing);
    });

    testWidgets('layar lebar menampilkan pratinjau yang ikut berubah',
        (tester) async {
      await open(tester, width: 1280, height: 900);

      expect(find.text('Pratinjau'), findsOneWidget);
      expect(find.text('Nama komunitas Anda'), findsOneWidget);

      await tester.enterText(_field('name'), 'Pemanah Nusantara');
      await tester.pump();

      expect(find.text('Nama komunitas Anda'), findsNothing);
      expect(find.text('Pemanah Nusantara'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layar sempit tanpa panel pratinjau, ada di langkah Tinjau',
        (tester) async {
      await open(tester, width: 500);
      expect(find.text('Pratinjau'), findsNothing);

      await _toReview(tester);

      expect(find.text('Pemanah Nusantara'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('layar sempit + teks besar tanpa overflow di semua langkah',
        (tester) async {
      await open(tester, width: 360, height: 1400);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _toReview(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
