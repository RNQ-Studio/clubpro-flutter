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
}
