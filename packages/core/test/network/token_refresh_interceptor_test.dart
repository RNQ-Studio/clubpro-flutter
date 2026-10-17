import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/src/network/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements StorageService {
  final values = <String, String>{};

  @override
  Future<void> init() async {}

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();
}

/// Adapter palsu: [handler] menerima request dan mengembalikan (status, body).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final (int, Object) Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _MemoryStorage storage;
  late int logouts;

  setUp(() {
    storage = _MemoryStorage();
    logouts = 0;
  });

  Dio buildDio(_FakeAdapter adapter) {
    final dio =
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter;
    final plain =
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter;
    dio.interceptors.addAll([
      AuthInterceptor(storage),
      TokenRefreshInterceptor(
        dio: dio,
        storage: storage,
        plainDio: plain,
        onLogout: () async => logouts++,
      ),
    ]);
    return dio;
  }

  test('401 → refresh ke v1/auth/refresh (body) → simpan token → ulangi',
      () async {
    storage.values[AppConstants.keyAuthToken] = 'old-access';
    storage.values[AppConstants.keyRefreshToken] = 'old-refresh';

    final adapter = _FakeAdapter((o) {
      if (o.path == 'v1/auth/refresh') {
        expect(o.data, {'refresh_token': 'old-refresh'});
        return (
          200,
          {
            'success': true,
            'data': {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh'
            },
          }
        );
      }
      final auth = o.headers['Authorization'];
      return auth == 'Bearer new-access'
          ? (
              200,
              {
                'success': true,
                'data': {'ok': true}
              }
            )
          : (401, {'success': false, 'message': 'Unauthenticated.'});
    });

    final response = await buildDio(adapter).get('v1/auth/me');

    expect(response.statusCode, 200);
    expect(storage.values[AppConstants.keyAuthToken], 'new-access');
    expect(storage.values[AppConstants.keyRefreshToken], 'new-refresh');
    expect(adapter.requests.map((r) => r.path),
        ['v1/auth/me', 'v1/auth/refresh', 'v1/auth/me']);
    expect(logouts, 0);
  });

  test('401 dari endpoint kredensial tidak memicu refresh', () async {
    storage.values[AppConstants.keyRefreshToken] = 'refresh';
    final adapter = _FakeAdapter(
      (o) => (401, {'success': false, 'message': 'Invalid Google token.'}),
    );

    await expectLater(
      buildDio(adapter).post('v1/auth/google', data: {'id_token': 'x'}),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(adapter.requests.map((r) => r.path), ['v1/auth/google']);
    expect(logouts, 0);
  });

  test('tanpa refresh token → logout', () async {
    storage.values[AppConstants.keyAuthToken] = 'old-access';
    final adapter = _FakeAdapter((o) => (401, {'message': 'Unauthenticated.'}));

    await expectLater(
        buildDio(adapter).get('v1/auth/me'), throwsA(isA<DioException>()));
    expect(logouts, 1);
  });

  test('refresh ditolak → logout, tanpa mengulang request', () async {
    storage.values[AppConstants.keyAuthToken] = 'old-access';
    storage.values[AppConstants.keyRefreshToken] = 'expired-refresh';
    final adapter = _FakeAdapter((o) => (401, {'message': 'Unauthenticated.'}));

    await expectLater(
        buildDio(adapter).get('v1/auth/me'), throwsA(isA<DioException>()));
    expect(
        adapter.requests.map((r) => r.path), ['v1/auth/me', 'v1/auth/refresh']);
    expect(logouts, 1);
  });

  test('token baru pun ditolak → logout, tidak berputar', () async {
    storage.values[AppConstants.keyAuthToken] = 'old-access';
    storage.values[AppConstants.keyRefreshToken] = 'refresh';
    final adapter = _FakeAdapter((o) => o.path == 'v1/auth/refresh'
        ? (
            200,
            {
              'data': {'access_token': 'new-access', 'refresh_token': 'r2'}
            }
          )
        : (401, {'message': 'Unauthenticated.'}));

    await expectLater(
        buildDio(adapter).get('v1/auth/me'), throwsA(isA<DioException>()));
    expect(adapter.requests.length, 3);
    expect(logouts, 1);
  });
}
