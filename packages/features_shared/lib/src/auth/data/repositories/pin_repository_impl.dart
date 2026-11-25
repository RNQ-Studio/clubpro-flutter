import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/pin_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class PinRepositoryImpl implements PinRepository {
  const PinRepositoryImpl(this.dio, this.local);
  final Dio dio;
  final AuthLocalDataSource local;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      final body = e.response?.data;
      var message = body is Map ? body['message']?.toString() : null;
      if (body is Map && body['errors'] is Map) {
        final errors = (body['errors'] as Map).values;
        if (errors.isNotEmpty &&
            errors.first is List &&
            (errors.first as List).isNotEmpty) {
          message = (errors.first as List).first.toString();
        }
      }
      if (e.response?.statusCode == 401) {
        throw const ServerException('Pengenal akun atau PIN tidak sesuai.');
      }
      final translated = switch (e.response?.statusCode ?? 0) {
        429 => 'Terlalu banyak percobaan. Coba lagi setelah 15 menit.',
        403 => 'Akun ini tidak dapat digunakan. Hubungi pengelola.',
        404 => 'Layanan PIN belum tersedia. Silakan coba lagi.',
        >= 500 => 'Layanan PIN sedang mengalami kendala. Silakan coba lagi.',
        422 when message == null || message == 'The given data was invalid.' =>
          'Data tidak valid. Periksa isian Anda.',
        _ => message ?? 'Tidak dapat terhubung. Silakan coba lagi.',
      };
      throw ServerException(translated);
    }
  }

  @override
  Future<bool> emailRecoveryAvailable() => _guard(() async {
        final response = await dio.get('v1/auth/pin/options');
        return ((response.data as Map)['data']
                as Map)['email_recovery_available'] ==
            true;
      });
  @override
  Future<User> login(String identifier, String pin) => _guard(() async {
        final response = await dio.post('v1/auth/pin/login',
            data: {'identifier': identifier, 'pin': pin});
        final tokens = (response.data as Map)['data'] as Map;
        final token = tokens['access_token'] as String;
        final me = await dio.get('v1/auth/me',
            options: Options(
                headers: {'Authorization': 'Bearer $token'},
                extra: {'skipTokenRefresh': true}));
        final user = UserModel.fromJson(
                Map<String, dynamic>.from((me.data as Map)['data'] as Map))
            .copyWith(
                token: token, refreshToken: tokens['refresh_token'] as String?);
        await local.saveUser(user);
        return user;
      });
  @override
  Future<void> save(String pin,
          {String? currentPin,
          String? currentPassword,
          String? verificationMethod,
          bool useRecentGoogleAuth = false}) =>
      _guard(() async {
        await dio.put('v1/auth/pin', data: {
          'pin': pin,
          'pin_confirmation': pin,
          if (verificationMethod != null)
            'verification_method': verificationMethod,
          if (useRecentGoogleAuth) 'use_recent_google_auth': true,
          if (currentPin != null) 'current_pin': currentPin,
          if (currentPassword != null) 'current_password': currentPassword
        });
      });
  @override
  Future<void> recover(String identifier) => _guard(() async {
        await dio
            .post('v1/auth/pin/recovery', data: {'identifier': identifier});
      });
  @override
  Future<void> reset(String identifier, String code, String pin) =>
      _guard(() async {
        await dio.post('v1/auth/pin/reset', data: {
          'identifier': identifier,
          'code': code,
          'pin': pin,
          'pin_confirmation': pin
        });
        await local.clearUser();
      });
}
