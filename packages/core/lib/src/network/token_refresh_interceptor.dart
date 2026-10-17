import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

/// Intercepts 401 responses and transparently refreshes the access token.
///
/// Uses [QueuedInterceptor] so that concurrent 401 errors are queued and only
/// a single refresh request is issued. Subsequent queued requests are retried
/// with the new token.
///
/// Kontrak backend (clubpro-laravel): `POST v1/auth/refresh` dengan body
/// `{refresh_token}` → envelope `{data: {access_token, refresh_token}}`.
class TokenRefreshInterceptor extends QueuedInterceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required StorageService storage,
    this.refreshEndpoint = 'v1/auth/refresh',
    this.onLogout,
    Dio? plainDio,
  })  : _dio = dio,
        _storage = storage,
        _plainDio = plainDio;

  final Dio _dio;
  final StorageService _storage;
  final String refreshEndpoint;
  final Future<void> Function()? onLogout;

  /// Dio tanpa interceptor untuk refresh & pengulangan. Mengulang lewat [_dio]
  /// di dalam QueuedInterceptor bisa deadlock bila ulangan itu gagal lagi.
  Dio? _plainDio;

  Dio get _plain => _plainDio ??= Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        headers: {'Accept': 'application/json'},
      ));

  /// Endpoint yang 401-nya berarti kredensial salah, bukan token kedaluwarsa.
  static const _credentialEndpoints = [
    'auth/login',
    'auth/google',
    'auth/register',
    'auth/refresh',
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    if (err.response?.statusCode != 401 ||
        _credentialEndpoints.any(path.contains)) {
      return handler.next(err);
    }

    try {
      // Permintaan antre yang gagal dengan token lama: token sudah diperbarui
      // oleh refresh sebelumnya → cukup ulangi tanpa refresh kedua.
      final currentToken = await _storage.read(AppConstants.keyAuthToken);
      final usedHeader = err.requestOptions.headers['Authorization'];
      if (currentToken != null && usedHeader != 'Bearer $currentToken') {
        return await _retry(err.requestOptions, currentToken, handler);
      }

      // 1. Read the refresh token from secure storage.
      final refreshToken = await _storage.read(AppConstants.keyRefreshToken);
      if (refreshToken == null) {
        await _forceLogout();
        return handler.next(err);
      }

      // 2. Use a separate Dio instance (no interceptors) to avoid loops.
      final response = await _plain.post(
        refreshEndpoint,
        data: {'refresh_token': refreshToken},
      );

      // 3. Persist the new tokens.
      final body = response.data as Map<String, dynamic>;
      final tokens = (body['data'] as Map<String, dynamic>?) ?? body;
      final newAccessToken = tokens['access_token'] as String;
      final newRefreshToken = tokens['refresh_token'] as String?;

      await _storage.write(AppConstants.keyAuthToken, newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(AppConstants.keyRefreshToken, newRefreshToken);
      }

      // 4. Retry the original request with the new access token.
      return await _retry(err.requestOptions, newAccessToken, handler);
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      await _forceLogout();
      return handler.next(err);
    }
  }

  Future<void> _retry(
    RequestOptions options,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    options.headers['Authorization'] = 'Bearer $token';
    try {
      handler.resolve(await _plain.fetch(options));
    } on DioException catch (retryError) {
      // Token baru pun ditolak → sesi memang tidak sah lagi.
      if (retryError.response?.statusCode == 401) await _forceLogout();
      handler.next(retryError);
    }
  }

  Future<void> _forceLogout() async {
    try {
      await onLogout?.call();
    } catch (_) {
      // Swallow errors during logout to avoid masking the original error.
    }
  }
}
