import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/community/data/datasources/community_remote_data_source.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_community_repository.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
String _fixture(String name) =>
    File('test/features/community/fixtures/$name.json').readAsStringSync();

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

({CommunityRemoteDataSource source, _FakeAdapter adapter}) _source(
  int status,
  String body,
) {
  final adapter = _FakeAdapter(status, body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: CommunityRemoteDataSource(dio), adapter: adapter);
}

void main() {
  group('kontrak dengan respons server sungguhan', () {
    test('daftar komunitas', () async {
      final page = await _source(200, _fixture('community_list'))
          .source
          .fetchCommunities(page: 1);

      final community = page.communities.single;
      expect(community.name, 'Pemanah Nusantara');
      expect(community.shortName, 'PN');
      expect(community.type, 'panahan');
      expect(community.typeLabel, 'Panahan');
      expect(community.status, CommunityStatus.approved);
      expect(community.location, 'Kota Bandung, Jawa Barat');
      expect(community.logoUrl, contains('/api/v1/assets/'));
      expect(community.createdAt, isNotNull);
      expect(page.lastPage, 1);
    });

    test('pengajuan saya', () async {
      final mine =
          await _source(200, _fixture('community_mine')).source.fetchMine();

      expect(mine.single.status, CommunityStatus.pending);
    });

    test('detail komunitas', () async {
      final detail = await _source(200, _fixture('community_detail'))
          .source
          .fetchCommunity('1');

      expect(detail.address, 'Jl. Merdeka No. 10, Sumur Bandung');
      expect(detail.contactName, 'Rina Ayu');
      expect(detail.contactPhone, '081234567890');
      expect(detail.contactEmail, 'rina.ayu@gmail.com');
      expect(detail.photoUrls, hasLength(2));
    });

    test('jenis komunitas', () async {
      final types =
          await _source(200, _fixture('community_types')).source.fetchTypes();

      expect(types.map((t) => t.label),
          containsAll(['Panahan', 'Fashion', 'Sepak Bola', 'Lainnya']));
      expect(types.last.value, CommunityTypeOption.other);
    });

    test('wilayah Indonesia lengkap', () async {
      final regions =
          await _source(200, _fixture('regions')).source.fetchRegions();

      expect(regions, hasLength(38));
      expect(regions.expand((p) => p.cities), hasLength(514));
      final jabar = regions.firstWhere((p) => p.name == 'Jawa Barat');
      expect(jabar.cities.map((c) => c.name), contains('Kota Bandung'));
      expect(regions.map((p) => p.name), contains('Papua Pegunungan'));
    });
  });

  test('pencarian dan saringan menjadi parameter server', () async {
    final fake = _source(200, _fixture('community_list'));

    await fake.source
        .fetchCommunities(page: 2, search: 'rina', type: 'fashion');

    expect(fake.adapter.request!.path, 'v1/communities');
    expect(fake.adapter.request!.queryParameters,
        {'page': 2, 'search': 'rina', 'type': 'fashion'});
  });

  test('foto diunggah sebagai byte dengan batas simpan sementara', () async {
    final fake = _source(
      201,
      jsonEncode({
        'data': {'id': 'aset-1'},
      }),
    );

    final id = await fake.source
        .uploadImage(testImage('logo.png'), category: 'community-logo');

    expect(id, 'aset-1');
    final request = fake.adapter.request!;
    expect(request.path, 'v1/assets/upload');
    final form = request.data as FormData;
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'logo.png');
    expect(form.files.single.value.contentType.toString(), 'image/png');
    final fields = Map.fromEntries(form.fields);
    expect(fields['type'], 'community-logo');
    expect(
      DateTime.parse(fields['retain_until']!).isAfter(DateTime.now()),
      isTrue,
    );
  });

  test('pengajuan mengirim isian yang diharapkan server', () async {
    final fake = _source(201, _fixture('community_detail'));

    await fake.source.submit({'name': 'Pemanah'});

    expect(fake.adapter.request!.method, 'POST');
    expect(fake.adapter.request!.path, 'v1/communities');
    expect(fake.adapter.request!.data, {'name': 'Pemanah'});
  });

  group('pesan galat', () {
    Future<Object?> failure(int status, [String body = '{}']) async {
      try {
        await _source(status, body).source.fetchCommunities(page: 1);
      } catch (e) {
        return e;
      }
      return null;
    }

    test('404 = server belum memuat fitur ini', () async {
      expect((await failure(404)).toString(),
          'Fitur Komunitas belum aktif di server.');
    });

    test('404 pada detail = komunitas tidak ada', () async {
      await expectLater(
        _source(404, '{}').source.fetchCommunity('9'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'Komunitas tidak ditemukan.')),
      );
    });

    test('413 = foto terlalu besar', () async {
      expect((await failure(413)).toString(), contains('terlalu besar'));
    });

    test('500 tidak membocorkan pesan teknis', () async {
      expect((await failure(500)).toString(),
          'Terjadi kesalahan pada server. Coba lagi.');
    });

    test('422 membawa isian dan pesan server', () async {
      await expectLater(
        _source(
          422,
          jsonEncode({
            'errors': {
              'name': ['Komunitas ini sudah Anda ajukan.'],
            },
          }),
        ).source.submit({}),
        throwsA(isA<CommunityFieldException>()
            .having((e) => e.field, 'field', 'name')
            .having((e) => e.message, 'message',
                'Komunitas ini sudah Anda ajukan.')),
      );
    });

    test('422 per elemen menunjuk isian induknya', () async {
      await expectLater(
        _source(
          422,
          jsonEncode({
            'errors': {
              'photo_asset_ids.1': ['Foto tidak valid.'],
            },
          }),
        ).source.submit({}),
        throwsA(isA<CommunityFieldException>()
            .having((e) => e.field, 'field', 'photo_asset_ids')),
      );
    });
  });

  group('klub', () {
    test('komunitas saya membawa peran dan jumlah anggota', () async {
      final joined =
          await _source(200, _fixture('community_joined')).source.fetchJoined();

      expect(joined, isNotEmpty);
      expect(joined.first.name, 'Pemanah Nusantara');
      expect(joined.first.myRole, CommunityRole.admin);
      expect(joined.first.membersCount, greaterThan(0));
    });

    test('detail membawa keanggotaan pengguna dan galeri', () async {
      final detail = await _source(200, _fixture('community_detail'))
          .source
          .fetchCommunity('1');

      expect(detail.isMember, isTrue);
      expect(detail.isJoinPending, isFalse);
      expect(detail.canManage, isTrue);
      expect(detail.myRole, CommunityRole.admin);
      expect(detail.photos, isNotEmpty);
      expect(detail.photos.first.url, startsWith('https://'));
      expect(detail.photos.first.id, isNotEmpty);
    });

    test('detail lama tanpa field baru tetap terbaca', () async {
      final json =
          jsonDecode(_fixture('community_detail')) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      for (final key in [
        'can_manage',
        'my_role',
        'my_status',
        'members_count',
        'photos',
        'upcoming_activities_count',
        'pending_members_count',
      ]) {
        data.remove(key);
      }

      final detail =
          await _source(200, jsonEncode(json)).source.fetchCommunity('1');

      expect(detail.isMember, isFalse);
      expect(detail.canManage, isFalse);
      expect(detail.photos, isEmpty);
    });

    test('anggota: peran, urutan server, dan halaman', () async {
      final fake = _source(200, _fixture('community_members'));
      final page = await fake.source.fetchMembers('1', page: 2);

      expect(page.members.first.role, CommunityRole.creator);
      expect(page.members.first.userId, isNotEmpty);
      expect(page.members.first.joinedAt, isNotNull);
      expect(page.lastPage, 1);
      expect(fake.adapter.request!.path, 'v1/communities/1/members');
      expect(fake.adapter.request!.queryParameters, {'page': 2});
    });

    test('permintaan bergabung memakai saringan status', () async {
      final fake = _source(200, _fixture('community_requests'));
      final page = await fake.source.fetchMembers('1', page: 1, pending: true);

      expect(page.members.single.requestedAt, isNotNull);
      expect(page.members.single.joinedAt, isNull);
      expect(fake.adapter.request!.queryParameters['status'], 'pending');
    });

    test('mengubah peran mengirim nilai API', () async {
      final fake = _source(200, '{"success":true,"data":{}}');
      await fake.source.setMemberRole('1', '5', CommunityRole.admin);

      expect(fake.adapter.request!.method, 'PUT');
      expect(fake.adapter.request!.path, 'v1/communities/1/members/5/role');
      expect(fake.adapter.request!.data, {'role': 'admin'});
    });

    test('kegiatan terbagi akan datang dan selesai, waktu tetap UTC', () async {
      final activities = await _source(200, _fixture('community_activities'))
          .source
          .fetchActivities('1');

      expect(activities.upcoming.first.title, 'Latihan Bersama Akhir Pekan');
      expect(
        activities.upcoming.first.startsAt,
        DateTime.utc(2026, 11, 12, 2),
      );
      expect(activities.past.single.location, isNull);
    });

    test('isian kegiatan dikirim dalam UTC, isian kosong menjadi null', () {
      final payload = CommunityActivityInput(
        title: '  Kopdar  ',
        startsAt: DateTime.utc(2026, 11, 12, 2),
        location: '   ',
      ).toPayload();

      expect(payload['title'], 'Kopdar');
      expect(payload['starts_at'], '2026-11-12T02:00:00.000Z');
      expect(payload['location'], isNull);
      expect(payload['description'], isNull);
    });

    test('profil anggota hanya berisi data umum', () async {
      final profile = await _source(200, _fixture('member_profile'))
          .source
          .fetchMemberProfile('3');

      expect(profile.name, 'Rina Ayu');
      expect(profile.communities.single.role, CommunityRole.admin);
      expect(
        _fixture('member_profile'),
        isNot(anyOf(contains('phone'), contains('email'), contains('address'))),
      );
    });

    test('profil di luar komunitas bersama: pesan jelas', () async {
      await expectLater(
        _source(404, '{"success":false,"message":"Not found"}')
            .source
            .fetchMemberProfile('9'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.toString(),
            'pesan',
            contains('Profil anggota ini tidak tersedia'),
          ),
        ),
      );
    });

    test('ditolak server: pesan akses', () async {
      await expectLater(
        _source(403, '{"success":false,"message":"This action"}')
            .source
            .approveMember('1', '5'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.toString(),
            'pesan',
            contains('tidak punya akses'),
          ),
        ),
      );
    });

    test('aturan yang dilanggar: pesan dari server tampil apa adanya',
        () async {
      await expectLater(
        _source(
          422,
          '{"success":false,"message":"Data tidak valid",'
          '"errors":{"member":["Creator tidak bisa dikeluarkan."]}}',
        ).source.removeMember('1', '5'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'pesan',
            'Creator tidak bisa dikeluarkan.',
          ),
        ),
      );
    });
  });
}
