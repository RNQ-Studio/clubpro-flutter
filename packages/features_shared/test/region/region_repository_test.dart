import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

({RegionRepositoryImpl repository, _Adapter adapter}) _repository(
  ResponseBody Function(RequestOptions options) respond,
) {
  final adapter = _Adapter(respond);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (repository: RegionRepositoryImpl(dio), adapter: adapter);
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  test('wilayah Indonesia lengkap dari respons server sungguhan', () async {
    // Direkam dari GET v1/regions/indonesia (Kepmendagri 2025).
    final fixture =
        File('test/region/fixtures/regions.json').readAsStringSync();
    final (:repository, :adapter) = _repository((_) => _json(200, fixture));

    final regions = await repository.getIndonesia();

    expect(adapter.request!.path, 'v1/regions/indonesia');
    expect(regions, hasLength(38));
    expect(regions.expand((p) => p.cities), hasLength(514));
    final jabar = regions.byCode('32')!;
    expect(jabar.name, 'Jawa Barat');
    expect(jabar.city('32.73')?.name, 'Kota Bandung');
    expect(jabar.city('35.78'), isNull);
    expect(regions.map((p) => p.name), contains('Papua Pegunungan'));
  });

  test('provinsi & kota sama bila kodenya sama', () {
    const a = RegionCity(code: '32.73', name: 'Kota Bandung');
    const b = RegionCity(code: '32.73', name: 'KOTA BANDUNG');
    const jabar = RegionProvince(code: '32', name: 'Jawa Barat', cities: [a]);

    expect(a, b);
    expect(jabar, const RegionProvince(code: '32', name: 'x', cities: []));
    expect(<RegionProvince>[jabar].byCode('35'), isNull);
  });

  test('tanpa koneksi → pesan jaringan', () async {
    final (:repository, adapter: _) = _repository(
      (o) => throw DioException.connectionError(
          requestOptions: o, reason: 'offline'),
    );

    expect(
      repository.getIndonesia,
      throwsA(isA<NetworkException>()
          .having((e) => e.message, 'message', contains('koneksi'))),
    );
  });

  test('server galat → pesan gagal memuat wilayah', () async {
    final (:repository, adapter: _) =
        _repository((_) => _json(500, '{"message":"boom"}'));

    expect(
      repository.getIndonesia,
      throwsA(isA<ServerException>()
          .having((e) => e.message, 'message', contains('daftar wilayah'))),
    );
  });
}
