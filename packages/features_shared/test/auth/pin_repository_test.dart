import 'dart:typed_data';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _Storage implements StorageService {
  final values = <String, String>{};
  @override
  Future<void> init() async {}
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

void main() {
  test('PIN login exchanges tokens, loads exact account and persists securely',
      () async {
    final storage = _Storage();
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      paths.add(o.path);
      if (o.path.endsWith('/login')) {
        expect(o.data,
            {'identifier': 'wali@anaklangit.manahpro.web.id', 'pin': '123456'});
        h.resolve(Response(requestOptions: o, data: {
          'data': {'access_token': 'new-token', 'refresh_token': 'new-refresh'}
        }));
      } else {
        expect(o.headers['Authorization'], 'Bearer new-token');
        h.resolve(Response(requestOptions: o, data: {
          'data': {
            'id': 2,
            'name': 'Wali',
            'email': 'wali@anaklangit.manahpro.web.id',
            'pin_enabled': true,
            'birth_date': '1990-02-10'
          }
        }));
      }
    }));
    final repo = PinRepositoryImpl(dio, AuthLocalDataSource(storage));
    final user = await repo.login('wali@anaklangit.manahpro.web.id', '123456');
    expect(user.id, '2');
    expect(user.birthDate, '1990-02-10');
    expect(user.pinEnabled, true);
    expect(storage.values[AppConstants.keyAuthToken], 'new-token');
    expect(storage.values[AppConstants.keyRefreshToken], 'new-refresh');
    expect(paths, ['v1/auth/pin/login', 'v1/auth/me']);
    expect(storage.values.values.any((v) => v.contains('123456')), false);
  });
  test(
      'PIN current/reset validation shows Indonesian server errors, not generic',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (o, h) => h.reject(DioException(
            requestOptions: o,
            response: Response(requestOptions: o, statusCode: 422, data: {
              'message': 'The given data was invalid.',
              'errors': {
                'code': ['Kode verifikasi tidak valid.']
              }
            })))));
    final repo = PinRepositoryImpl(dio, AuthLocalDataSource(_Storage()));
    await expectLater(
        repo.reset('uji', 'salah', '123456'),
        throwsA(predicate(
            (e) => e.toString().contains('Kode verifikasi tidak valid.'))));
    await expectLater(
        repo.save('123456', currentPin: '000000'),
        throwsA(predicate(
            (e) => e.toString().contains('Kode verifikasi tidak valid.'))));
  });
  test('avatar upload uses bytes even XFile has no native path', () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      expect(o.path, 'v1/auth/avatar');
      final form = o.data as FormData;
      expect(form.files.single.key, 'avatar');
      expect(form.files.single.value.filename, 'avatar.png');
      expect(form.files.single.value.length, 4);
      h.resolve(Response(requestOptions: o, data: {
        'data': {
          'id': 1,
          'name': 'Uji',
          'email': 'uji@anaklangit.manahpro.web.id'
        }
      }));
    }));
    await AuthRemoteDataSource(dio).uploadAvatar(XFile.fromData(
        Uint8List.fromList([1, 2, 3, 4]),
        name: 'avatar.png',
        mimeType: 'image/png'));
  });
  test('PIN generic server failures are translated to Indonesian', () async {
    for (final status in [403, 503]) {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
          onRequest: (o, h) => h.reject(DioException(
              requestOptions: o,
              response: Response(
                  requestOptions: o,
                  statusCode: status,
                  data: {'message': 'Service unavailable.'})))));
      final repo = PinRepositoryImpl(dio, AuthLocalDataSource(_Storage()));
      final expected = status == 403
          ? 'Akun ini tidak dapat digunakan. Hubungi pengelola.'
          : 'Layanan PIN sedang mengalami kendala. Silakan coba lagi.';
      await expectLater(
          repo.recover('uji@anaklangit.manahpro.web.id'),
          throwsA(isA<ServerException>()
              .having((e) => e.toString(), 'message', contains(expected))));
    }
  });
  test(
      'PIN recovery capabilities and explicit password/Google methods match API',
      () async {
    final storage = _Storage();
    final dio = Dio();
    final requests = <RequestOptions>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      requests.add(o);
      if (o.method == 'GET') {
        expect(o.path, 'v1/auth/pin/options');
        h.resolve(Response(requestOptions: o, data: {
          'success': true,
          'data': {
            'pin_length': 6,
            'email_recovery_available': false,
            'account_recovery_available': true,
            'in_app_invitations': true
          }
        }));
      } else {
        expect(o.path, 'v1/auth/pin');
        h.resolve(
            Response(requestOptions: o, data: {'success': true, 'data': null}));
      }
    }));
    final repo = PinRepositoryImpl(dio, AuthLocalDataSource(storage));
    expect(await repo.emailRecoveryAvailable(), false);
    await repo.save('123456',
        currentPassword: 'account-password-test',
        verificationMethod: 'password');
    expect(requests.last.data, {
      'pin': '123456',
      'pin_confirmation': '123456',
      'current_password': 'account-password-test',
      'verification_method': 'password'
    });
    await repo.save('654321', verificationMethod: 'google');
    expect(requests.last.data, {
      'pin': '654321',
      'pin_confirmation': '654321',
      'verification_method': 'google'
    });
    expect(storage.values, isEmpty);
    final user = UserModel.fromJson({
      'id': 1,
      'name': 'Google Uji',
      'email': 'google@anaklangit.manahpro.web.id',
      'pin_enabled': true,
      'pin_google_reauthenticated': true
    });
    expect(user.pinGoogleReauthenticated, true);
    expect(user.copyWith(token: 'new-token').pinGoogleReauthenticated, true);
    expect(UserModel.fromJson(user.toJson()).pinGoogleReauthenticated, true);
  });
}
