import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_auth_repository.dart';

const _user = User(id: '7', name: 'Rina', email: 'rina@gmail.com');

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

class _FakeGoogle extends GoogleSignInService {
  _FakeGoogle(this._result) : super(serverClientId: 'web-client');
  final Object _result;
  int signOuts = 0;

  @override
  Future<String> obtainIdToken() async {
    if (_result is String) return _result;
    throw _result;
  }

  @override
  Future<void> signOut() async => signOuts++;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final (int, Object) Function(RequestOptions) handler;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final (status, body) = handler(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  int googleCalls = 0;

  @override
  AuthState build() => _state;

  @override
  Future<void> loginWithGoogle() async => googleCalls++;
}

void main() {
  setUpAll(() => registerFallbackValue(<String, Object?>{}));

  group('AuthNotifier.loginWithGoogle', () {
    late MockAuthRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = MockAuthRepository();
      container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    });
    tearDown(() => container.dispose());

    test('berhasil → AuthAuthenticated', () async {
      when(() => repo.loginWithGoogle()).thenAnswer((_) async => _user);

      await container.read(authProvider.notifier).loginWithGoogle();

      final state = container.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user, _user);
    });

    test('dibatalkan → kembali belum login tanpa error', () async {
      when(() => repo.loginWithGoogle())
          .thenThrow(const GoogleSignInCancelled());

      await container.read(authProvider.notifier).loginWithGoogle();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
    });

    test('gagal → AuthError dengan pesan', () async {
      when(() => repo.loginWithGoogle()).thenThrow(
          const ServerException('Login Google belum diaktifkan di server.'));

      await container.read(authProvider.notifier).loginWithGoogle();

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message,
          'Login Google belum diaktifkan di server.');
    });

    test('sessionExpired → hapus sesi lokal & belum login', () async {
      when(() => repo.loginWithGoogle()).thenAnswer((_) async => _user);
      when(() => repo.clearSession()).thenAnswer((_) async {});
      await container.read(authProvider.notifier).loginWithGoogle();

      await container.read(authProvider.notifier).sessionExpired();

      expect(container.read(authProvider), isA<AuthUnauthenticated>());
      verify(() => repo.clearSession()).called(1);
    });
  });

  group('AuthRepositoryImpl.loginWithGoogle', () {
    late _MemoryStorage storage;

    AuthRepositoryImpl buildRepo(
      (int, Object) Function(RequestOptions) handler,
      GoogleSignInService google,
    ) {
      final dio =
          Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
            ..httpClientAdapter = _Adapter(handler);
      return AuthRepositoryImpl(
        remote: AuthRemoteDataSource(dio),
        local: AuthLocalDataSource(storage),
        google: google,
      );
    }

    setUp(() => storage = _MemoryStorage());

    test('menukar ID token, menyimpan access & refresh token', () async {
      String? sentIdToken;
      final repo = buildRepo((o) {
        if (o.path == 'v1/auth/google') {
          sentIdToken = (o.data as Map)['id_token'] as String;
          return (
            200,
            {
              'data': {
                'access_token': 'acc',
                'refresh_token': 'ref',
                'is_new_user': true,
              }
            }
          );
        }
        expect(o.headers['Authorization'], 'Bearer acc');
        return (
          200,
          {
            'data': {'id': 7, 'name': 'Rina', 'email': 'rina@gmail.com'}
          }
        );
      }, _FakeGoogle('google-id-token'));

      final user = await repo.loginWithGoogle();

      expect(sentIdToken, 'google-id-token');
      expect(user.email, 'rina@gmail.com');
      expect(storage.values[AppConstants.keyAuthToken], 'acc');
      expect(storage.values[AppConstants.keyRefreshToken], 'ref');
    });

    test('server belum dikonfigurasi (503) → pesan bahasa Indonesia', () async {
      final repo = buildRepo(
        (o) => (503, {'message': 'Google sign-in is not configured.'}),
        _FakeGoogle('token'),
      );

      expect(
        repo.loginWithGoogle,
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('belum diaktifkan'))),
      );
    });

    test('logout & clearSession menghapus refresh token dan sign-out Google',
        () async {
      final google = _FakeGoogle('token');
      final repo = buildRepo((o) => (200, {'data': null}), google);
      storage.values[AppConstants.keyRefreshToken] = 'ref';

      await repo.clearSession();

      expect(storage.values.containsKey(AppConstants.keyRefreshToken), isFalse);
      expect(google.signOuts, 1);
    });
  });

  test('GoogleSignInService tanpa serverClientId → belum dikonfigurasi',
      () async {
    final service = GoogleSignInService(serverClientId: null);

    expect(service.isConfigured, isFalse);
    expect(
      service.obtainIdToken,
      throwsA(isA<ServerException>().having(
          (e) => e.message, 'message', contains('belum dikonfigurasi'))),
    );
  });

  group('requireAuthRedirect & GoogleLoginScreen', () {
    Widget app(AuthState state, {_FixedAuthNotifier? notifier}) {
      final router = GoRouter(
        initialLocation: '/',
        redirect: requireAuthRedirect,
        routes: [
          GoRoute(path: '/', builder: (_, __) => const Text('BERANDA')),
          GoRoute(
            path: '/login',
            builder: (_, __) => const GoogleLoginScreen(
              title: 'Anak Langit Archery',
              subtitle: 'Masuk untuk mengakses jadwal latihan.',
            ),
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          authProvider
              .overrideWith(() => notifier ?? _FixedAuthNotifier(state)),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('belum login di rute terlindungi → halaman login Google',
        (tester) async {
      await tester.pumpWidget(app(const AuthUnauthenticated()));
      await tester.pumpAndSettle();

      expect(find.text('BERANDA'), findsNothing);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.text('Anak Langit Archery'), findsOneWidget);
    });

    testWidgets('sudah login → tetap di rute', (tester) async {
      await tester.pumpWidget(app(const AuthAuthenticated(_user)));
      await tester.pumpAndSettle();

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('sesi masih diperiksa → tidak dialihkan', (tester) async {
      await tester.pumpWidget(app(const AuthLoading()));
      await tester.pump();

      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('tombol memanggil loginWithGoogle; error tampil di halaman',
        (tester) async {
      final notifier =
          _FixedAuthNotifier(const AuthError('Akun Anda dinonaktifkan.'));
      await tester
          .pumpWidget(app(const AuthUnauthenticated(), notifier: notifier));
      await tester.pumpAndSettle();

      expect(find.text('Akun Anda dinonaktifkan.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('google-sign-in-button')));
      expect(notifier.googleCalls, 1);
    });
  });
}
