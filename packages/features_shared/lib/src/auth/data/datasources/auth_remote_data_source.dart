import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return _withProfile(_data(response));
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Login failed');
    }
  }

  /// Tukar ID token Google dengan token backend, lalu ambil profil.
  Future<({UserModel user, bool isNewUser})> loginWithGoogle(
    String idToken,
  ) async {
    try {
      final response = await _dio.post(
        'v1/auth/google',
        data: {'id_token': idToken},
      );
      final tokens = _data(response);
      return (
        user: await _withProfile(tokens),
        isNewUser: tokens['is_new_user'] == true,
      );
    } on DioException catch (e) {
      throw _googleLoginError(e);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'v1/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return _withProfile(_data(response));
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Register failed');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('v1/auth/me');
      // Token digabung di lapisan repository.
      return UserModel.fromJson(_data(response));
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Failed to fetch profile');
    }
  }

  /// Simpan sebagian data diri: hanya kunci di [fields] yang dikirim.
  Future<UserModel> updateProfile(Map<String, Object?> fields) async {
    try {
      final response = await _dio.put('v1/auth/me', data: fields);
      return UserModel.fromJson(_data(response));
    } on DioException catch (e) {
      throw _validationError(e) ??
          e.error ??
          ServerException(e.message ?? 'Update profile failed');
    }
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('v1/auth/avatar', data: formData);
      return UserModel.fromJson(_data(response));
    } on DioException catch (e) {
      throw _validationError(e) ??
          e.error ??
          ServerException(e.message ?? 'Upload avatar failed');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('v1/auth/logout');
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Logout failed');
    }
  }

  /// Ambil `/me` dengan access token yang baru diterbitkan.
  Future<UserModel> _withProfile(Map<String, dynamic> tokens) async {
    final token = tokens['access_token'] as String;
    final profileResponse = await _dio.get(
      'v1/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return UserModel.fromJson(_data(profileResponse)).copyWith(
      token: token,
      refreshToken: tokens['refresh_token'] as String?,
    );
  }

  static Map<String, dynamic> _data(Response<dynamic> response) =>
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  static Object _googleLoginError(DioException e) {
    final status = e.response?.statusCode;
    return switch (status) {
      401 => const ServerException(
          'Akun Google tidak dapat diverifikasi. Silakan coba lagi.'),
      403 => const ServerException(
          'Akun Anda dinonaktifkan. Hubungi pengurus club.'),
      429 => const ServerException(
          'Terlalu banyak percobaan masuk. Coba lagi beberapa saat lagi.'),
      503 => const ServerException(
          'Login Google belum diaktifkan di server. Hubungi pengurus club.'),
      _ => e.error ?? ServerException(e.message ?? 'Login Google gagal'),
    };
  }

  /// Pesan validasi pertama dari server (422) agar bisa ditampilkan apa adanya.
  static ServerException? _validationError(DioException e) {
    if (e.response?.statusCode != 422) return null;
    final body = e.response?.data;
    if (body is! Map) return null;
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return ServerException(first.first.toString());
      }
    }
    return ServerException((body['message'] ?? 'Data tidak valid').toString());
  }
}
