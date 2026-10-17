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
      // 1. Post to login endpoint
      final response = await _dio.post(
        'v1/auth/login',
        data: {'email': email, 'password': password},
      );

      final responseData = response.data as Map<String, dynamic>;
      final tokensData = responseData['data'] as Map<String, dynamic>;
      final token = tokensData['access_token'] as String;

      // 2. Fetch the user profile from /v1/auth/me using this token manually
      final profileResponse = await _dio.get(
        'v1/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final profileData = profileResponse.data as Map<String, dynamic>;
      final userJson = profileData['data'] as Map<String, dynamic>;

      return UserModel(
        id: userJson['id'].toString(), // Safely convert integer ID to string
        name: userJson['name'] as String,
        email: userJson['email'] as String,
        phone: userJson['phone'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        roles: (userJson['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        token: token,
      );
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Login failed');
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Post to register endpoint
      final response = await _dio.post(
        'v1/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final responseData = response.data as Map<String, dynamic>;
      final tokensData = responseData['data'] as Map<String, dynamic>;
      final token = tokensData['access_token'] as String;

      // 2. Fetch the user profile from /v1/auth/me using this token manually
      final profileResponse = await _dio.get(
        'v1/auth/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final profileData = profileResponse.data as Map<String, dynamic>;
      final userJson = profileData['data'] as Map<String, dynamic>;

      return UserModel(
        id: userJson['id'].toString(), // Safely convert integer ID to string
        name: userJson['name'] as String,
        email: userJson['email'] as String,
        phone: userJson['phone'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        roles: (userJson['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        token: token,
      );
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Register failed');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('v1/auth/me');
      final responseData = response.data as Map<String, dynamic>;
      final userJson = responseData['data'] as Map<String, dynamic>;

      return UserModel(
        id: userJson['id'].toString(),
        name: userJson['name'] as String,
        email: userJson['email'] as String,
        phone: userJson['phone'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        roles: (userJson['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        token: null, // Token will be merged in repository layer
      );
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Failed to fetch profile');
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _dio.put(
        'v1/auth/me',
        data: {'name': name, 'email': email},
      );

      final responseData = response.data as Map<String, dynamic>;
      final userJson = responseData['data'] as Map<String, dynamic>;

      return UserModel(
        id: userJson['id'].toString(),
        name: userJson['name'] as String,
        email: userJson['email'] as String,
        phone: userJson['phone'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        roles: (userJson['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        token: null, // Token will be merged in repository layer
      );
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Update profile failed');
    }
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        'v1/auth/avatar',
        data: formData,
      );

      final responseData = response.data as Map<String, dynamic>;
      final userJson = responseData['data'] as Map<String, dynamic>;

      return UserModel(
        id: userJson['id'].toString(),
        name: userJson['name'] as String,
        email: userJson['email'] as String,
        phone: userJson['phone'] as String?,
        avatarUrl: userJson['avatar_url'] as String?,
        roles: (userJson['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        token: null, // Token will be merged in repository layer
      );
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Upload avatar failed');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('v1/auth/logout');
    } on DioException catch (e) {
      throw e.error ?? ServerException(e.message ?? 'Logout failed');
    }
  }
}
