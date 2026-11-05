import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:app_main/features/admin/domain/entities/admin_community.dart';
import 'package:app_main/features/admin/presentation/admin_community_providers.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:app_main/features/admin/presentation/screens/admin_communities_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_community_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart' hide Community;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
const _member = User(id: '9', name: 'Budi', email: 'budi@gmail.com');

Widget _app(
  FakeAdminRepository repository, {
  String location = AppRoutes.adminPanel,
  AuthState auth = const AuthAuthenticated(_owner),
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
                builder: (_, __) => const Text('DATA PENGGUNA'),
              ),
            ],
          ),
          GoRoute(
            path: 'communities',
            builder: (_, __) => const AdminCommunitiesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => AdminCommunityDetailScreen(
                  communityId: state.pathParameters['id']!,
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
  group('kontrak dengan respons server sungguhan', () {
    test('ringkasan panel', () async {
      final summary =
          await _source(200, _fixture('admin_summary')).source.fetchSummary();

      expect(summary.totalUsers, 2);
      expect(summary.communities.pending, 1);
      expect(summary.communities.total, 2);
    });

    test('daftar komunitas', () async {
      final page = await _source(200, _fixture('admin_communities'))
          .source
          .fetchCommunities(page: 1);

      expect(page.communities, hasLength(2));
      expect(page.summary.approved, 1);
      final first = page.communities.first;
      expect(first.status, CommunityStatus.pending);
      expect(first.submitter?.name, 'Budi Santoso');
      expect(first.submitter?.email, 'budi.santoso@gmail.com');
      expect(first.createdAt, isNotNull);
      expect(first.location, 'Kota Bandung, Jawa Barat');
    });

    test('detail untuk diperiksa', () async {
      final detail = await _source(200, _fixture('admin_community_detail'))
          .source
          .fetchCommunity('2');

      expect(detail.status, CommunityStatus.pending);
      expect(detail.address, isNotEmpty);
      expect(detail.contactName, 'Rina Ayu');
      expect(detail.photoUrls, hasLength(1));
      expect(detail.reviewer, isNull);
      expect(detail.reviewedAt, isNull);
    });

    test('hasil penolakan', () async {
      final detail = await _source(200, _fixture('admin_community_rejected'))
          .source
          .reviewCommunity(
            '2',
            status: CommunityStatus.rejected,
            expected: CommunityStatus.pending,
            note: 'Foto kegiatan belum jelas.',
          );

      expect(detail.status, CommunityStatus.rejected);
      expect(detail.reviewNote, 'Foto kegiatan belum jelas.');
      expect(detail.reviewer?.name, 'Budi Santoso');
      expect(detail.reviewedAt, isNotNull);
    });
  });

  test('saringan menjadi parameter server', () async {
    final fake = _source(200, _fixture('admin_communities'));

    await fake.source.fetchCommunities(
      page: 2,
      search: 'rina',
      filter: AdminCommunityFilter.pending,
    );

    expect(fake.adapter.request!.path, 'v1/admin/communities');
    expect(fake.adapter.request!.queryParameters,
        {'page': 2, 'search': 'rina', 'status': 'pending'});
  });

  test('verifikasi mengirim status yang sedang dilihat', () async {
    final fake = _source(200, _fixture('admin_community_detail'));

    await fake.source.reviewCommunity(
      '2',
      status: CommunityStatus.approved,
      expected: CommunityStatus.pending,
    );

    expect(fake.adapter.request!.method, 'PUT');
    expect(fake.adapter.request!.path, 'v1/admin/communities/2/review');
    expect(fake.adapter.request!.data,
        {'status': 'approved', 'expected_status': 'pending'});
  });

  test('409 menandai keputusan super admin lain', () async {
    await expectLater(
      _source(409, '{}').source.reviewCommunity(
            '2',
            status: CommunityStatus.approved,
            expected: CommunityStatus.pending,
          ),
      throwsA(isA<AdminConflictException>()),
    );
  });

  test('404 pada daftar = server belum memuat fitur ini', () async {
    await expectLater(
      _source(404, '{}').source.fetchCommunities(page: 1),
      throwsA(isA<ServerException>().having((e) => e.message, 'message',
          'Kelola Komunitas belum aktif di server.')),
    );
  });

  test('422 meneruskan pesan server', () async {
    await expectLater(
      _source(
        422,
        jsonEncode({
          'errors': {
            'note': ['Tulis alasan penolakan.'],
          },
        }),
      ).source.reviewCommunity(
            '2',
            status: CommunityStatus.rejected,
            expected: CommunityStatus.pending,
          ),
      throwsA(isA<ServerException>()
          .having((e) => e.message, 'message', 'Tulis alasan penolakan.')),
    );
  });

  test('ringkasan berpindah saat status berubah', () {
    final moved = adminCommunitySummary.moved(
      CommunityStatus.pending,
      CommunityStatus.approved,
    );

    expect(moved.pending, adminCommunitySummary.pending - 1);
    expect(moved.approved, adminCommunitySummary.approved + 1);
    expect(moved.rejected, adminCommunitySummary.rejected);
    expect(moved.total, adminCommunitySummary.total);
  });

  group('status daftar', () {
    ProviderContainer container(FakeAdminRepository repository) {
      final container = ProviderContainer(overrides: [
        adminRepositoryProvider.overrideWithValue(repository),
      ]);
      addTearDown(container.dispose);
      container.listen(adminCommunitiesProvider, (_, __) {});
      return container;
    }

    test('muat berikutnya tanpa duplikat', () async {
      final repository = FakeAdminRepository(communityPages: [
        [adminCommunity('3'), adminCommunity('2')],
        [adminCommunity('2'), adminCommunity('1')],
      ]);
      final c = container(repository);
      await c.read(adminCommunitiesProvider.future);

      await c.read(adminCommunitiesProvider.notifier).loadMore();

      expect(
        c
            .read(adminCommunitiesProvider)
            .requireValue
            .communities
            .map((e) => e.id),
        ['3', '2', '1'],
      );
    });

    test('hasil verifikasi memperbarui baris dan ringkasan', () async {
      final repository = FakeAdminRepository(
        communityPages: [
          [adminCommunity('5')],
        ],
        community: adminCommunityDetail(),
      );
      final c = container(repository);
      await c.read(adminCommunitiesProvider.future);
      final provider = adminCommunityDetailProvider('5');
      c.listen(provider, (_, __) {});
      await c.read(provider.future);

      await c.read(provider.notifier).review(status: CommunityStatus.approved);

      final state = c.read(adminCommunitiesProvider).requireValue;
      expect(state.communities.single.status, CommunityStatus.approved);
      expect(state.summary.pending, adminCommunitySummary.pending - 1);
      expect(repository.reviews.single.expected, CommunityStatus.pending);
    });

    test('baris yang tidak lagi cocok saringan keluar dari daftar', () async {
      final repository = FakeAdminRepository(
        communityPages: [
          [adminCommunity('5'), adminCommunity('4')],
        ],
      );
      final c = container(repository);
      await c.read(adminCommunitiesProvider.future);
      final notifier = c.read(adminCommunitiesProvider.notifier);
      await notifier.setFilter(AdminCommunityFilter.pending);

      notifier.applyUpdate(
        adminCommunity('5', status: CommunityStatus.approved),
      );

      expect(
        c.read(adminCommunitiesProvider).requireValue.communities.single.id,
        '4',
      );
    });

    test('keputusan super admin lain: pesan diteruskan, data dimuat ulang',
        () async {
      final repository = FakeAdminRepository(
        community: adminCommunityDetail(),
        reviewError: const AdminConflictException('Sudah berubah.'),
      );
      final c = container(repository);
      final provider = adminCommunityDetailProvider('5');
      c.listen(provider, (_, __) {});
      await c.read(provider.future);

      repository.community =
          adminCommunityDetail(status: CommunityStatus.approved);
      await expectLater(
        c.read(provider.notifier).review(status: CommunityStatus.rejected),
        throwsA(isA<AdminConflictException>()),
      );

      expect((await c.read(provider.future)).status, CommunityStatus.approved);
    });
  });

  group('menu Admin Panel', () {
    testWidgets('memuat Kelola User dan Kelola Komunitas dengan angkanya',
        (tester) async {
      await tester.pumpWidget(_app(FakeAdminRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Kelola User'), findsOneWidget);
      expect(find.text('Kelola Komunitas'), findsOneWidget);
      expect(find.text('128 pengguna'), findsOneWidget);
      expect(find.text('12 komunitas'), findsOneWidget);
      expect(find.text('3 menunggu verifikasi'), findsOneWidget);
      // Daftar user tidak lagi langsung tampil di halaman ini.
      expect(find.byKey(const Key('admin-search')), findsNothing);
    });

    testWidgets('anggota biasa ditolak tanpa memanggil API', (tester) async {
      final repository = FakeAdminRepository();
      await tester.pumpWidget(
        _app(repository, auth: const AuthAuthenticated(_member)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halaman ini khusus super admin'), findsOneWidget);
      expect(find.text('Kelola User'), findsNothing);
      expect(repository.summaryLoads, 0);
    });

    testWidgets('tautan langsung Kelola Komunitas juga ditolak',
        (tester) async {
      final repository = FakeAdminRepository(
        community: adminCommunityDetail(),
      );
      await tester.pumpWidget(_app(
        repository,
        location: AppRoutes.adminCommunity('5'),
        auth: const AuthAuthenticated(_member),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Halaman ini khusus super admin'), findsOneWidget);
      expect(find.text('Jl. Merdeka No. 10, Sumur Bandung'), findsNothing);
    });

    testWidgets('jumlah gagal dimuat tidak menghalangi menu', (tester) async {
      await tester.pumpWidget(_app(FakeAdminRepository(
        summaryError: const ServerException('Gagal'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('Kelola Komunitas'), findsOneWidget);
      expect(find.textContaining('menunggu verifikasi'), findsNothing);
    });

    testWidgets('tidak ada pengajuan: tanpa penanda', (tester) async {
      final repository = _NoPendingRepository();
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining('menunggu verifikasi'), findsNothing);
    });

    testWidgets('Kelola User membuka daftar pengguna yang dipindahkan',
        (tester) async {
      await tester.pumpWidget(_app(FakeAdminRepository(pages: [
        [adminUser('2', name: 'Budi', email: 'budi@gmail.com')],
      ])));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin-menu-users')));
      await tester.pumpAndSettle();

      expect(find.text('budi@gmail.com'), findsOneWidget);
      expect(find.byKey(const Key('admin-search')), findsOneWidget);
    });

    testWidgets('Kelola Komunitas membuka daftar komunitas', (tester) async {
      await tester.pumpWidget(_app(FakeAdminRepository(communityPages: [
        [adminCommunity('5')],
      ])));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin-menu-communities')));
      await tester.pumpAndSettle();

      expect(find.text('Pemanah Nusantara'), findsOneWidget);
    });

    testWidgets('tautan langsung tetap punya jalan kembali', (tester) async {
      await tester.pumpWidget(_app(FakeAdminRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('layar lebar berdampingan, sempit bertumpuk tanpa overflow',
        (tester) async {
      _size(tester, 1280, 800);
      await tester.pumpWidget(_app(FakeAdminRepository()));
      await tester.pumpAndSettle();

      final users =
          tester.getTopLeft(find.byKey(const Key('admin-menu-users')));
      final communities =
          tester.getTopLeft(find.byKey(const Key('admin-menu-communities')));
      expect(communities.dx, greaterThan(users.dx));
      expect(communities.dy, users.dy);

      await tester.pumpWidget(const SizedBox.shrink());
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(FakeAdminRepository()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Kelola Komunitas', () {
    FakeAdminRepository filled() => FakeAdminRepository(communityPages: [
          [
            adminCommunity(
              '5',
              name: 'Fotografer Priangan',
              createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
            ),
            adminCommunity('4',
                name: 'Sepak Bola Solo', status: CommunityStatus.approved),
            adminCommunity('3',
                name: 'Komunitas Ditolak', status: CommunityStatus.rejected),
          ],
        ], community: adminCommunityDetail());

    Future<void> open(
        WidgetTester tester, FakeAdminRepository repository) async {
      _size(tester, 500, 1000);
      await tester.pumpWidget(
        _app(repository, location: AppRoutes.adminCommunities),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('urutan dari server dipertahankan dan status terlihat',
        (tester) async {
      await open(tester, filled());

      final y = [
        'Fotografer Priangan',
        'Sepak Bola Solo',
        'Komunitas Ditolak',
      ].map((name) => tester.getTopLeft(find.text(name)).dy).toList();
      expect(y, orderedEquals([...y]..sort()));

      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsWidgets);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(
        find.text('Diajukan Rina Ayu · 12 menit lalu'),
        findsOneWidget,
      );
    });

    testWidgets('saringan menampilkan jumlah dan memanggil server',
        (tester) async {
      final repository = filled();
      await open(tester, repository);

      expect(find.text('Semua (12)'), findsOneWidget);
      expect(find.text('Menunggu (3)'), findsOneWidget);
      expect(find.text('Terverifikasi (8)'), findsOneWidget);
      expect(find.text('Ditolak (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('admin-community-filter-pending')));
      await tester.pumpAndSettle();

      expect(
          repository.communityCalls.last.filter, AdminCommunityFilter.pending);
    });

    testWidgets('pencarian menunggu pengguna selesai mengetik', (tester) async {
      final repository = filled();
      await open(tester, repository);

      final field = find.byKey(const Key('admin-community-search'));
      await tester.enterText(field, 'ri');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(field, 'rina');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(repository.communityCalls.map((c) => c.search), ['', 'rina']);
    });

    testWidgets('kosong dan gagal punya tampilan sendiri', (tester) async {
      final repository = FakeAdminRepository(
        error: const ServerException('Kelola Komunitas belum aktif di server.'),
      );
      await open(tester, repository);

      expect(
        find.text('Kelola Komunitas belum aktif di server.'),
        findsOneWidget,
      );

      repository.error = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(
          find.text('Belum ada komunitas pada saringan ini'), findsOneWidget);
    });

    testWidgets('halaman berikutnya dimuat walau tidak perlu digulir',
        (tester) async {
      _size(tester, 1280, 2000);
      await tester.pumpWidget(_app(
        FakeAdminRepository(communityPages: [
          [adminCommunity('2', name: 'Satu')],
          [adminCommunity('1', name: 'Dua')],
        ]),
        location: AppRoutes.adminCommunities,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dua'), findsOneWidget);
    });

    testWidgets('pengaju terhapus tidak merusak baris', (tester) async {
      await open(
        tester,
        FakeAdminRepository(communityPages: [
          [
            const AdminCommunity(
              id: '1',
              name: 'Yatim',
              shortName: 'Y',
              type: 'panahan',
              typeLabel: 'Panahan',
              status: CommunityStatus.pending,
              cityName: 'Kota Bandung',
              provinceName: 'Jawa Barat',
            ),
          ],
        ]),
      );

      expect(find.textContaining('Akun terhapus'), findsOneWidget);
    });

    testWidgets('mengetuk baris membuka data lengkap', (tester) async {
      await open(tester, filled());

      await tester.tap(find.byKey(const Key('admin-community-5')));
      await tester.pumpAndSettle();

      expect(find.text('Verifikasi Komunitas'), findsOneWidget);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(
        filled(),
        location: AppRoutes.adminCommunities,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('verifikasi', () {
    Future<void> open(
      WidgetTester tester,
      FakeAdminRepository repository, {
      double width = 500,
      double height = 1500,
    }) async {
      _size(tester, width, height);
      await tester.pumpWidget(
        _app(repository, location: AppRoutes.adminCommunity('5')),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan seluruh data pengajuan', (tester) async {
      await open(
          tester, FakeAdminRepository(community: adminCommunityDetail()));

      for (final text in [
        'Pemanah Nusantara',
        'PN · Panahan',
        'Menunggu Verifikasi',
        'Foto Lampiran (2)',
        'Komunitas pecinta panahan tradisional yang rutin berlatih setiap '
            'akhir pekan di Bandung.',
        'Jawa Barat',
        'Kota Bandung',
        'Jl. Merdeka No. 10, Sumur Bandung',
        'Budi Santoso',
        '081234567890',
        'pengurus@gmail.com',
        'Rina Ayu',
        'rina.ayu@gmail.com',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('foto lampiran bisa dibuka penuh dan digeser', (tester) async {
      await open(
          tester, FakeAdminRepository(community: adminCommunityDetail()));

      await tester.tap(find.byKey(const Key('community-photo-thumb-0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('community-photo-viewer')), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byTooltip('Foto sebelumnya'), findsNothing);

      await tester.tap(find.byTooltip('Foto berikutnya'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byTooltip('Foto berikutnya'), findsNothing);

      await tester.tap(find.byTooltip('Tutup'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('community-photo-viewer')), findsNothing);
    });

    testWidgets('menyetujui butuh konfirmasi lalu tersimpan', (tester) async {
      final repository = FakeAdminRepository(community: adminCommunityDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-approve')));
      await tester.pumpAndSettle();
      expect(find.text('Setujui komunitas ini?'), findsOneWidget);
      expect(repository.reviews, isEmpty);

      await tester.tap(find.byKey(const Key('admin-approve-confirm')));
      await tester.pumpAndSettle();

      expect(repository.reviews.single, (
        status: CommunityStatus.approved,
        expected: CommunityStatus.pending,
        note: null,
      ));
      expect(find.text('Komunitas disetujui'), findsOneWidget);
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Pemilik'), findsOneWidget);
    });

    testWidgets('batal menyetujui tidak mengubah apa pun', (tester) async {
      final repository = FakeAdminRepository(community: adminCommunityDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(repository.reviews, isEmpty);
    });

    testWidgets('menolak wajib beralasan', (tester) async {
      final repository = FakeAdminRepository(community: adminCommunityDetail());
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-reject')));
      await tester.pumpAndSettle();

      FilledButton confirm() => tester.widget<FilledButton>(
            find.byKey(const Key('admin-reject-confirm')),
          );
      expect(confirm().onPressed, isNull);

      final note = find.byKey(const Key('admin-reject-note'));
      await tester.enterText(note, '   a  ');
      await tester.pump();
      expect(confirm().onPressed, isNull);

      await tester.enterText(note, 'Foto kegiatan belum jelas.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin-reject-confirm')));
      await tester.pumpAndSettle();

      expect(repository.reviews.single, (
        status: CommunityStatus.rejected,
        expected: CommunityStatus.pending,
        note: 'Foto kegiatan belum jelas.',
      ));
      expect(find.text('Komunitas ditolak'), findsOneWidget);
      expect(find.text('Foto kegiatan belum jelas.'), findsOneWidget);
    });

    testWidgets('tindakan mengikuti status', (tester) async {
      await open(
        tester,
        FakeAdminRepository(
          community: adminCommunityDetail(status: CommunityStatus.approved),
        ),
      );

      expect(find.byKey(const Key('admin-approve')), findsNothing);
      expect(find.text('Cabut Verifikasi'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await open(
        tester,
        FakeAdminRepository(
          community: adminCommunityDetail(status: CommunityStatus.rejected),
        ),
      );

      expect(find.byKey(const Key('admin-approve')), findsOneWidget);
      expect(find.byKey(const Key('admin-reject')), findsNothing);
    });

    testWidgets('verifikasi yang salah bisa dicabut dengan alasan',
        (tester) async {
      final repository = FakeAdminRepository(
        community: adminCommunityDetail(status: CommunityStatus.approved),
      );
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-reject')));
      await tester.pumpAndSettle();
      expect(find.text('Cabut verifikasi?'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('admin-reject-note')),
        'Ternyata komunitas fiktif.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('admin-reject-confirm')));
      await tester.pumpAndSettle();

      expect(repository.reviews.single.expected, CommunityStatus.approved);
      expect(find.text('Verifikasi dicabut'), findsOneWidget);
    });

    testWidgets('keputusan super admin lain: pesan tampil dan data terbaru',
        (tester) async {
      final repository = FakeAdminRepository(
        community: adminCommunityDetail(),
        reviewError: const AdminConflictException(
          'Status komunitas sudah berubah. Data terbaru sudah dimuat.',
        ),
      );
      await open(tester, repository);
      repository.community =
          adminCommunityDetail(status: CommunityStatus.approved);

      await tester.tap(find.byKey(const Key('admin-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-approve-confirm')));
      await tester.pumpAndSettle();

      expect(
        find.text('Status komunitas sudah berubah. Data terbaru sudah dimuat.'),
        findsOneWidget,
      );
      expect(find.text('Terverifikasi'), findsOneWidget);
      expect(find.text('Cabut Verifikasi'), findsOneWidget);
    });

    testWidgets('gagal menyimpan: pesan tampil dan tombol kembali aktif',
        (tester) async {
      final repository = FakeAdminRepository(
        community: adminCommunityDetail(),
        reviewError: const NetworkException('Tidak dapat terhubung.'),
      );
      await open(tester, repository);

      await tester.tap(find.byKey(const Key('admin-approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-approve-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('Tidak dapat terhubung.'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi'), findsOneWidget);
      final approve = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('admin-approve')),
      );
      expect(approve.onPressed, isNotNull);
    });

    testWidgets('hasil verifikasi menyebut siapa, kapan, dan alasannya',
        (tester) async {
      await open(
        tester,
        FakeAdminRepository(
          community: adminCommunityDetail(
            status: CommunityStatus.rejected,
            reviewNote: 'Foto kegiatan belum jelas.',
            reviewedAt: DateTime(2026, 11, 5, 14, 30),
            reviewer: const AdminCommunityPerson(id: '1', name: 'Pemilik'),
          ),
        ),
      );

      expect(find.text('Hasil Verifikasi'), findsOneWidget);
      expect(find.text('Pemilik'), findsOneWidget);
      expect(find.text('Foto kegiatan belum jelas.'), findsOneWidget);
    });

    testWidgets('pengaju bisa dibuka di Kelola User', (tester) async {
      await open(
          tester, FakeAdminRepository(community: adminCommunityDetail()));

      await tester.tap(find.byKey(const Key('admin-open-submitter')));
      await tester.pumpAndSettle();

      expect(find.text('DATA PENGGUNA'), findsOneWidget);
    });

    testWidgets('komunitas tidak ditemukan bisa dicoba lagi', (tester) async {
      await open(
        tester,
        FakeAdminRepository(
          error: const ServerException('Komunitas tidak ditemukan.'),
        ),
      );

      expect(find.text('Komunitas tidak ditemukan.'), findsOneWidget);
      expect(find.byKey(const Key('admin-approve')), findsNothing);
    });

    testWidgets('layar lebar dua kolom tanpa overflow', (tester) async {
      await open(
        tester,
        FakeAdminRepository(community: adminCommunityDetail()),
        width: 1280,
        height: 900,
      );

      final photos = tester.getTopLeft(find.text('Foto Lampiran (2)'));
      final location = tester.getTopLeft(find.text('Lokasi'));
      expect(location.dx, greaterThan(photos.dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(_app(
        FakeAdminRepository(community: adminCommunityDetail()),
        location: AppRoutes.adminCommunity('5'),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

class _NoPendingRepository extends FakeAdminRepository {
  @override
  Future<AdminPanelSummary> getSummary() async => const AdminPanelSummary(
        totalUsers: 5,
        communities: AdminCommunitySummary(
          total: 2,
          pending: 0,
          approved: 2,
          rejected: 0,
        ),
      );
}
