import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:app_main/features/admin/domain/entities/admin_banner.dart';
import 'package:app_main/features/admin/domain/entities/admin_community.dart';
import 'package:app_main/features/admin/presentation/admin_banner_providers.dart';
import 'package:app_main/features/admin/presentation/admin_community_providers.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:app_main/features/admin/presentation/screens/admin_banner_form_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_banners_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../community/fake_community_repository.dart';
import 'fake_admin_repository.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
String _fixture(String name) =>
    File('test/features/admin/fixtures/$name.json').readAsStringSync();

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int status;
  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

({AdminRemoteDataSource source, _FakeAdapter adapter}) _source(
  int status,
  String body,
) {
  final adapter = _FakeAdapter(status, body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: AdminRemoteDataSource(dio), adapter: adapter);
}

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

const _input = AdminBannerInput(
  title: '  Latihan Bersama ',
  subtitle: '',
  linkUrl: '/profile',
  isActive: true,
);

const _nusantara = AdminBannerCommunity(id: '5', name: 'Panahan Nusantara');

List<AdminBanner> _threeBanners() => [
      adminBanner(
        '1',
        title: 'Latihan Bersama',
        subtitle: 'Setiap akhir pekan',
        linkUrl: '/communities/5',
        linkCommunity: _nusantara,
      ),
      adminBanner('2', title: '', linkUrl: AppRoutes.profile),
      adminBanner(
        '3',
        title: 'Kejuaraan',
        status: AdminBannerStatus.inactive,
        imageUrl: null,
      ),
    ];

class _Harness {
  _Harness({
    List<AdminBanner>? banners,
    this.location = AppRoutes.adminBanners,
    this.auth = const AuthAuthenticated(_owner),
  }) : admin = FakeAdminRepository(
          banners: banners ?? _threeBanners(),
          communityPages: [
            [
              adminCommunity(
                '5',
                name: 'Panahan Nusantara',
                status: CommunityStatus.approved,
              ),
              adminCommunity(
                '6',
                name: 'Fotografi Bandung',
                status: CommunityStatus.approved,
              ),
            ],
          ],
        );

  final FakeAdminRepository admin;
  final communities = FakeCommunityRepository();
  final picker = FakeCommunityImagePicker();
  final String location;
  final AuthState auth;

  Widget app() {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
        GoRoute(
          path: AppRoutes.adminPanel,
          builder: (_, __) => const AdminPanelScreen(),
          routes: [
            GoRoute(
              path: 'banners',
              builder: (_, __) => const AdminBannersScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const AdminBannerFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminBannerFormScreen(
                    bannerId: state.pathParameters['id'],
                  ),
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
        adminRepositoryProvider.overrideWithValue(admin),
        communityRepositoryProvider.overrideWithValue(communities),
        communityImagePickerProvider.overrideWithValue(picker),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }
}

void _size(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<_Harness> _open(
  WidgetTester tester, {
  List<AdminBanner>? banners,
  String location = AppRoutes.adminBanners,
  AuthState auth = const AuthAuthenticated(_owner),
  double width = 420,
}) async {
  _size(tester, width, 1000);
  final harness = _Harness(banners: banners, location: location, auth: auth);
  await tester.pumpWidget(harness.app());
  await tester.pumpAndSettle();
  return harness;
}

Finder _rowTitles() => find.descendant(
      of: find.byKey(const Key('admin-banner-list')),
      matching: find.byWidgetPredicate(
        (w) => w is InkWell && '${w.key}'.contains('admin-banner-'),
      ),
    );

List<String> _rowOrder(WidgetTester tester) => [
      for (final row in tester.widgetList<InkWell>(_rowTitles()))
        '${(row.key! as ValueKey<String>).value}'
            .replaceFirst('admin-banner-', ''),
    ];

Future<void> _chooseLink(WidgetTester tester, AdminBannerLinkType type) async {
  await tester.ensureVisible(find.byKey(const Key('admin-banner-link-type')));
  await tester.tap(find.byKey(const Key('admin-banner-link-type')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(type.label).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('admin-banner-save')));
  await tester.pumpAndSettle();
}

void main() {
  group('tujuan ketuk', () {
    test('tautan tersimpan dikenali kembali', () {
      expect(AdminBannerLinkType.of(null), AdminBannerLinkType.none);
      expect(AdminBannerLinkType.of(''), AdminBannerLinkType.none);
      expect(AdminBannerLinkType.of('/communities'),
          AdminBannerLinkType.communities);
      expect(AdminBannerLinkType.of('/communities/new'),
          AdminBannerLinkType.createCommunity);
      expect(AdminBannerLinkType.of('/communities/12'),
          AdminBannerLinkType.community);
      expect(AdminBannerLinkType.of('/profile'), AdminBannerLinkType.profile);
      expect(AdminBannerLinkType.of('https://anaklangit.manahpro.web.id'),
          AdminBannerLinkType.external);
      expect(AdminBannerLinkType.communityId('/communities/12'), '12');
      expect(AdminBannerLinkType.communityId('/communities/0'), isNull);
      expect(AdminBannerLinkType.communityId('/communities/12/x'), isNull);
    });

    test('tujuan tetap menjadi rute app', () {
      expect(AdminBannerLinkType.communities.fixedLink, AppRoutes.communities);
      expect(AdminBannerLinkType.createCommunity.fixedLink,
          AppRoutes.createCommunity);
      expect(AdminBannerLinkType.profile.fixedLink, AppRoutes.profile);
      expect(AdminBannerLinkType.none.fixedLink, isNull);
    });

    test('label baris daftar', () {
      final banners = _threeBanners();
      expect(banners[0].linkLabel, 'Panahan Nusantara');
      expect(banners[1].linkLabel, 'Profil Saya');
      expect(banners[2].linkLabel, 'Tidak membuka apa pun');
      expect(adminBanner('9', linkUrl: '/communities/9').linkLabel,
          'Komunitas tidak ditemukan');
      expect(
        adminBanner('9', linkUrl: 'https://anaklangit.manahpro.web.id')
            .linkLabel,
        'https://anaklangit.manahpro.web.id',
      );
    });
  });

  test('isian: teks dirapikan, kosong jadi null, kolom teks selalu dikirim',
      () {
    expect(_input.toPayload(), {
      'title': 'Latihan Bersama',
      'subtitle': null,
      'link_url': '/profile',
      'is_active': true,
    });
    expect(
      const AdminBannerInput(
        title: '',
        subtitle: ' Akhir pekan ',
        linkUrl: null,
        isActive: false,
        imageAssetId: 'aset-1',
      ).toPayload(),
      {
        'title': null,
        'subtitle': 'Akhir pekan',
        'link_url': null,
        'is_active': false,
        'image_asset_id': 'aset-1',
      },
    );
  });

  test('banner tayang di luar batas Beranda ditandai', () {
    final banners = [
      for (var i = 0; i < 12; i++)
        adminBanner(
          '$i',
          status: i == 1 ? AdminBannerStatus.inactive : AdminBannerStatus.live,
        ),
    ];
    final state = AdminBannersState(
      banners: banners,
      summary: const AdminBannerSummary(total: 12, live: 11, maxVisible: 10),
    );
    expect(state.overLimitIds, {'11'});
  });

  group('kontrak dengan respons server sungguhan', () {
    test('daftar banner', () async {
      final result =
          await _source(200, _fixture('admin_banners')).source.fetchBanners();

      expect(result.summary.total, 3);
      expect(result.summary.live, 1);
      expect(result.summary.maxVisible, 10);
      expect(result.banners.map((b) => b.status), [
        AdminBannerStatus.live,
        AdminBannerStatus.inactive,
        AdminBannerStatus.scheduled,
      ]);

      final first = result.banners.first;
      expect(first.id, '1');
      expect(first.title, 'Latihan Bersama');
      expect(first.subtitle, 'Setiap akhir pekan');
      expect(first.imageUrl, startsWith('https://'));
      expect(first.linkType, AdminBannerLinkType.community);
      expect(first.linkCommunity?.name, 'Panahan Nusantara');
      expect(first.isActive, isTrue);

      // Foto bertulisan: tanpa judul, tanpa tujuan.
      expect(result.banners[1].title, '');
      expect(result.banners[1].linkType, AdminBannerLinkType.none);

      final scheduled = result.banners[2];
      expect(scheduled.linkType, AdminBannerLinkType.external);
      expect(scheduled.startsAt, isNotNull);
      expect(scheduled.endsAt, isNotNull);
    });

    test('ringkasan Admin Panel memuat banner; server lama tanpa banner',
        () async {
      final summary = await _source(200, _fixture('admin_summary_with_banners'))
          .source
          .fetchSummary();
      expect(summary.banners?.total, 3);
      expect(summary.banners?.live, 1);

      final old =
          await _source(200, _fixture('admin_summary')).source.fetchSummary();
      expect(old.banners, isNull);
      expect(old.totalUsers, 2);
    });

    test('tambah, ubah, urutkan, hapus memakai alamat dan isian server',
        () async {
      final created = _source(201, _fixture('admin_banner_saved'));
      final banner = await created.source.createBanner(
        const AdminBannerInput(
          title: 'Latihan Bersama',
          subtitle: '',
          linkUrl: '/profile',
          isActive: true,
          imageAssetId: 'aset-1',
        ),
      );
      expect(created.adapter.request!.method, 'POST');
      expect(created.adapter.request!.path, 'v1/admin/banners');
      expect(created.adapter.request!.data, {
        'title': 'Latihan Bersama',
        'subtitle': null,
        'link_url': '/profile',
        'is_active': true,
        'image_asset_id': 'aset-1',
      });
      expect(banner.linkType, AdminBannerLinkType.profile);

      final updated = _source(200, _fixture('admin_banner_saved'));
      await updated.source.updateBanner('1', _input);
      expect(updated.adapter.request!.method, 'PUT');
      expect(updated.adapter.request!.path, 'v1/admin/banners/1');
      expect(
        (updated.adapter.request!.data as Map).containsKey('image_asset_id'),
        isFalse,
      );

      final reordered = _source(200, _fixture('admin_banners'));
      await reordered.source.reorderBanners(['3', '1', '2']);
      expect(reordered.adapter.request!.method, 'PUT');
      expect(reordered.adapter.request!.path, 'v1/admin/banners/order');
      expect(reordered.adapter.request!.data, {
        'ids': [3, 1, 2],
      });

      final deleted = _source(
        200,
        jsonEncode({'success': true, 'message': 'Banner dihapus'}),
      );
      await deleted.source.deleteBanner('3');
      expect(deleted.adapter.request!.method, 'DELETE');
      expect(deleted.adapter.request!.path, 'v1/admin/banners/3');
    });

    test('pesan galat', () async {
      await expectLater(
        _source(422, _fixture('admin_banner_invalid')).source.createBanner(
              _input,
            ),
        throwsA(isA<ServerException>().having(
            (e) => e.message, 'message', 'Halaman tujuan tidak dikenal.')),
      );
      await expectLater(
        _source(409, '{"success":false}').source.reorderBanners(['1']),
        throwsA(isA<AdminConflictException>().having((e) => e.message,
            'message', contains('Daftar banner sudah berubah'))),
      );
      await expectLater(
        _source(404, '{}').source.updateBanner('9', _input),
        throwsA(isA<ServerException>().having(
            (e) => e.message, 'message', contains('Banner tidak ditemukan'))),
      );
      await expectLater(
        _source(404, '{}').source.fetchBanners(),
        throwsA(isA<ServerException>().having((e) => e.message, 'message',
            'Kelola Banner belum aktif di server.')),
      );
    });
  });

  group('notifier', () {
    late FakeAdminRepository repository;
    late ProviderContainer container;
    late int homeLoads;

    setUp(() {
      repository = FakeAdminRepository(banners: _threeBanners());
      homeLoads = 0;
      container = ProviderContainer(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repository),
          homeBannersProvider.overrideWith((ref) async {
            homeLoads++;
            return const <HomeBanner>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      container.listen(adminBannersProvider, (_, __) {});
      container.listen(homeBannersProvider, (_, __) {});
      container.listen(adminSummaryProvider, (_, __) {});
    });

    List<String> order() => [
          for (final b
              in container.read(adminBannersProvider).requireValue.banners)
            b.id,
        ];

    Future<void> ready() async {
      await container.read(adminBannersProvider.future);
      await container.read(homeBannersProvider.future);
      await container.read(adminSummaryProvider.future);
    }

    test('memindah langsung tampil, lalu tersimpan dan Beranda disegarkan',
        () async {
      await ready();
      repository.reorderGate = Completer();

      final moving = container.read(adminBannersProvider.notifier).move(2, 0);
      expect(order(), ['3', '1', '2']);
      expect(container.read(adminBannersProvider).requireValue.isSavingOrder,
          isTrue);

      // Gerakan kedua selama menyimpan diabaikan.
      await container.read(adminBannersProvider.notifier).move(0, 1);
      expect(order(), ['3', '1', '2']);

      repository.reorderGate!.complete();
      await moving;
      await container.read(homeBannersProvider.future);
      await container.read(adminSummaryProvider.future);

      expect(repository.bannerOrders, [
        ['3', '1', '2'],
      ]);
      expect(order(), ['3', '1', '2']);
      expect(container.read(adminBannersProvider).requireValue.isSavingOrder,
          isFalse);
      expect(homeLoads, 2);
      expect(repository.summaryLoads, 2);
    });

    test('gagal menyimpan urutan: kembali seperti semula', () async {
      await ready();
      repository.bannerActionError = const NetworkException('Tidak terhubung');

      await expectLater(
        container.read(adminBannersProvider.notifier).move(0, 2),
        throwsA(isA<NetworkException>()),
      );
      expect(order(), ['1', '2', '3']);
      expect(homeLoads, 1);
    });

    test('daftar basi: kembali, lalu memuat yang terbaru', () async {
      await ready();
      repository.bannerActionError =
          const AdminConflictException('Daftar banner sudah berubah.');
      repository.banners = [..._threeBanners(), adminBanner('4')];

      await expectLater(
        container.read(adminBannersProvider.notifier).move(0, 2),
        throwsA(isA<AdminConflictException>()),
      );
      expect(order(), ['1', '2', '3', '4']);
    });

    test('menyimpan dan menghapus menyegarkan daftar dan Beranda', () async {
      await ready();

      await container.read(adminBannersProvider.notifier).save(_input);
      expect(order(), ['1', '2', '3', '101']);
      await container.read(homeBannersProvider.future);
      expect(homeLoads, 2);

      await container.read(adminBannersProvider.notifier).delete('2');
      expect(order(), ['1', '3', '101']);
      await container.read(homeBannersProvider.future);
      expect(homeLoads, 3);
    });
  });

  group('Admin Panel', () {
    testWidgets('menu Kelola Banner dengan ringkasannya', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminPanel);

      final card = find.byKey(const Key('admin-menu-banners'));
      expect(card, findsOneWidget);
      expect(find.text('4 banner · 3 tayang'), findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('Kelola Banner'), findsOneWidget);
      expect(harness.admin.bannerLoads, 1);
    });

    testWidgets('desktop: tiga menu tanpa overflow', (tester) async {
      await _open(tester, location: AppRoutes.adminPanel, width: 1280);

      expect(find.byKey(const Key('admin-menu-banners')), findsOneWidget);
      expect(tester.takeException(), isNull);
      final users = tester.getRect(find.byKey(const Key('admin-menu-users')));
      final banners =
          tester.getRect(find.byKey(const Key('admin-menu-banners')));
      expect(banners.top, greaterThan(users.bottom));
      expect(banners.width, closeTo(users.width, 1));
    });
  });

  group('daftar banner', () {
    testWidgets('urutan, status, dan tujuan tiap banner', (tester) async {
      await _open(tester);

      expect(_rowOrder(tester), ['1', '2', '3']);
      expect(find.text('3 banner · 2 tayang di Beranda'), findsOneWidget);
      expect(find.text('Latihan Bersama'), findsOneWidget);
      expect(find.text('Tanpa judul'), findsOneWidget);
      expect(find.text('Panahan Nusantara'), findsOneWidget);
      expect(find.text('Profil Saya'), findsOneWidget);
      expect(find.text('Tayang'), findsNWidgets(2));
      expect(find.text('Nonaktif'), findsOneWidget);
      expect(find.byKey(const Key('admin-banner-limit')), findsNothing);
    });

    testWidgets('lebih dari batas Beranda: diberi tahu', (tester) async {
      await _open(tester, banners: [
        for (var i = 1; i <= 11; i++) adminBanner('$i', title: 'Banner $i'),
      ]);

      expect(find.byKey(const Key('admin-banner-limit')), findsOneWidget);
      expect(
          find.textContaining('hanya menampilkan 10 banner'), findsOneWidget);
    });

    testWidgets('seret mengubah urutan dan tersimpan', (tester) async {
      final harness = await _open(tester);

      final handle = find.byKey(const Key('admin-banner-handle-1'));
      final rowHeight =
          tester.getSize(find.byKey(const Key('admin-banner-1'))).height;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(Offset(0, rowHeight / 3));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(harness.admin.bannerOrders, [
        ['2', '3', '1'],
      ]);
      expect(_rowOrder(tester), ['2', '3', '1']);
    });

    testWidgets('gagal menyimpan urutan: pesan tampil, urutan kembali',
        (tester) async {
      final harness = await _open(tester);
      harness.admin.bannerActionError =
          const NetworkException('Tidak dapat terhubung ke server.');

      final handle = find.byKey(const Key('admin-banner-handle-1'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
      expect(_rowOrder(tester), ['1', '2', '3']);
    });

    testWidgets('kosong: ajakan menambah banner', (tester) async {
      await _open(tester, banners: []);

      expect(find.text('Belum ada banner'), findsOneWidget);
      await tester.tap(find.byKey(const Key('admin-banner-add')));
      await tester.pumpAndSettle();
      expect(find.text('Tambah Banner'), findsWidgets);
      expect(find.byKey(const Key('admin-banner-photo-placeholder')),
          findsOneWidget);
    });

    testWidgets('gagal dimuat: bisa dicoba lagi', (tester) async {
      _size(tester, 420, 1000);
      final harness = _Harness();
      harness.admin.bannersError =
          const ServerException('Kelola Banner belum aktif di server.');
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(find.text('Kelola Banner belum aktif di server.'), findsOneWidget);
      harness.admin.bannersError = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(_rowOrder(tester), ['1', '2', '3']);
    });

    testWidgets('bukan super admin: tidak memuat apa pun', (tester) async {
      final harness = await _open(
        tester,
        auth: const AuthAuthenticated(
          User(id: '9', name: 'Budi', email: 'budi@gmail.com'),
        ),
      );

      expect(find.text('Halaman ini khusus super admin'), findsOneWidget);
      expect(harness.admin.bannerLoads, 0);
    });
  });

  group('tambah banner', () {
    testWidgets('foto wajib; tersimpan dengan foto, teks, dan tujuan',
        (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBannerNew);

      await _save(tester);
      expect(find.text('Lampirkan foto banner.'), findsOneWidget);
      expect(harness.admin.bannerSaves, isEmpty);
      expect(harness.communities.uploads, isEmpty);

      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();
      expect(find.text('Lampirkan foto banner.'), findsNothing);
      expect(find.byKey(const Key('admin-banner-preview')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('admin-banner-title')), 'Latihan Bersama');
      await tester.pump();
      // Pratinjau mengikuti isian.
      expect(
        find.descendant(
          of: find.byKey(const Key('admin-banner-preview')),
          matching: find.text('Latihan Bersama'),
        ),
        findsOneWidget,
      );

      await _chooseLink(tester, AdminBannerLinkType.profile);
      await _save(tester);

      expect(harness.communities.uploads, ['banner:foto-1-0.png']);
      final saved = harness.admin.bannerSaves.single;
      expect(saved.id, isNull);
      expect(saved.input.toPayload(), {
        'title': 'Latihan Bersama',
        'subtitle': null,
        'link_url': '/profile',
        'is_active': true,
        'image_asset_id': 'aset-foto-1-0.png',
      });
      expect(find.text('Banner ditambahkan'), findsOneWidget);
      // Kembali ke daftar yang sudah memuat banner baru.
      expect(_rowOrder(tester), ['1', '2', '3', '101']);
    });

    testWidgets('tautan luar harus lengkap', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBannerNew);
      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();

      await _chooseLink(tester, AdminBannerLinkType.external);
      await tester.enterText(find.byKey(const Key('admin-banner-url')),
          'anaklangit.manahpro.web.id');
      await _save(tester);
      expect(find.text('Masukkan tautan lengkap, diawali https://'),
          findsOneWidget);
      expect(harness.admin.bannerSaves, isEmpty);

      await tester.enterText(find.byKey(const Key('admin-banner-url')),
          ' https://anaklangit.manahpro.web.id/info ');
      await _save(tester);
      expect(harness.admin.bannerSaves.single.input.linkUrl,
          'https://anaklangit.manahpro.web.id/info');
    });

    testWidgets('komunitas tujuan dipilih dari yang terverifikasi',
        (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBannerNew);
      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();

      await _chooseLink(tester, AdminBannerLinkType.community);
      await _save(tester);
      expect(find.text('Pilih komunitas tujuan.'), findsOneWidget);
      expect(harness.admin.bannerSaves, isEmpty);

      await tester
          .ensureVisible(find.byKey(const Key('admin-banner-community')));
      await tester.tap(find.byKey(const Key('admin-banner-community')));
      await tester.pumpAndSettle();
      expect(harness.admin.communityCalls.last.filter,
          AdminCommunityFilter.approved);

      await tester.enterText(
          find.byKey(const Key('admin-banner-community-search')), 'foto');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(harness.admin.communityCalls.last.search, 'foto');

      await tester.tap(find.byKey(const Key('admin-banner-community-6')));
      await tester.pumpAndSettle();
      expect(find.text('Fotografi Bandung'), findsOneWidget);
      expect(find.text('Pilih komunitas tujuan.'), findsNothing);

      await _save(tester);
      expect(harness.admin.bannerSaves.single.input.linkUrl, '/communities/6');
    });

    testWidgets('gagal menyimpan: foto tidak diunggah ulang', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBannerNew);
      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();
      harness.admin.bannerActionError =
          const ServerException('Halaman tujuan tidak dikenal.');

      await _save(tester);
      expect(find.text('Halaman tujuan tidak dikenal.'), findsOneWidget);
      expect(find.byKey(const Key('admin-banner-save')), findsOneWidget);

      await _save(tester);
      expect(harness.communities.uploads, hasLength(1));
      expect(harness.admin.bannerSaves, hasLength(2));
      expect(harness.admin.bannerSaves.last.input.imageAssetId,
          'aset-foto-1-0.png');
      expect(find.text('Banner ditambahkan'), findsOneWidget);
    });

    testWidgets('tombol simpan tidak mengirim dua kali', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBannerNew);
      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();

      harness.admin.saveGate = Completer();
      final save = find.byKey(const Key('admin-banner-save'));
      await tester.tap(save);
      await tester.pump();

      expect(find.text('Menyimpan...'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);
      await tester.tap(save, warnIfMissed: false);
      await tester.pump();

      harness.admin.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(harness.admin.bannerSaves, hasLength(1));
    });

    testWidgets('desktop: form tidak melebar, tanpa overflow', (tester) async {
      await _open(tester, location: AppRoutes.adminBannerNew, width: 1280);

      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byKey(const Key('admin-banner-title')));
      expect(field.width, lessThanOrEqualTo(640));
    });
  });

  group('ubah banner', () {
    testWidgets('isian terisi; simpan tanpa mengganti foto', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBanner('1'));

      expect(find.text('Ubah Banner'), findsOneWidget);
      expect(find.text('Setiap akhir pekan'), findsWidgets);
      expect(find.text('Panahan Nusantara'), findsOneWidget);
      expect(find.text('Ganti Foto'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('admin-banner-title')), 'Latihan Rutin');
      await tester.ensureVisible(find.byKey(const Key('admin-banner-active')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-banner-active')));
      await _save(tester);

      final saved = harness.admin.bannerSaves.single;
      expect(saved.id, '1');
      expect(saved.input.toPayload(), {
        'title': 'Latihan Rutin',
        'subtitle': 'Setiap akhir pekan',
        'link_url': '/communities/5',
        'is_active': false,
      });
      expect(harness.communities.uploads, isEmpty);
      expect(find.text('Banner tersimpan'), findsOneWidget);
    });

    testWidgets('mengganti foto mengunggah foto baru', (tester) async {
      final harness = await _open(tester, location: AppRoutes.adminBanner('2'));

      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();
      await _save(tester);

      expect(harness.communities.uploads, ['banner:foto-1-0.png']);
      expect(harness.admin.bannerSaves.single.input.imageAssetId,
          'aset-foto-1-0.png');
      expect(harness.admin.bannerSaves.single.input.linkUrl, '/profile');
    });

    testWidgets('komunitas tujuan yang terhapus harus dipilih ulang',
        (tester) async {
      final harness = await _open(
        tester,
        banners: [adminBanner('1', linkUrl: '/communities/9')],
        location: AppRoutes.adminBanner('1'),
      );

      await _save(tester);
      expect(find.text('Pilih komunitas tujuan.'), findsOneWidget);
      expect(harness.admin.bannerSaves, isEmpty);
    });

    testWidgets('jadwal dari back-office diberitahukan', (tester) async {
      await _open(
        tester,
        banners: [
          adminBanner(
            '1',
            status: AdminBannerStatus.scheduled,
            startsAt: DateTime(2026, 11, 8, 9),
          ),
        ],
        location: AppRoutes.adminBanner('1'),
      );

      expect(find.textContaining('Jadwal tayang dari back-office'),
          findsOneWidget);
    });

    testWidgets('hapus setelah konfirmasi; batal tidak menghapus',
        (tester) async {
      final harness = await _open(tester);
      await tester.tap(find.byKey(const Key('admin-banner-2')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin-banner-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(harness.admin.bannerDeletes, isEmpty);

      await tester.tap(find.byKey(const Key('admin-banner-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-banner-delete-confirm')));
      await tester.pumpAndSettle();

      expect(harness.admin.bannerDeletes, ['2']);
      expect(find.text('Banner dihapus'), findsOneWidget);
      expect(_rowOrder(tester), ['1', '3']);
    });

    testWidgets('banner yang tidak ada', (tester) async {
      await _open(tester, location: AppRoutes.adminBanner('99'));

      expect(find.text('Banner tidak ditemukan. Mungkin sudah dihapus.'),
          findsOneWidget);
    });
  });
}
