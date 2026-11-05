import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/admin_user.dart';
import '../models/admin_user_model.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AdminUsersPage> fetchUsers({
    required int page,
    String search = '',
    AdminUserFilter filter = AdminUserFilter.all,
  }) async {
    try {
      final response = await _dio.get(
        'v1/admin/users',
        queryParameters: {
          'page': page,
          if (search.isNotEmpty) 'search': search,
          if (filter == AdminUserFilter.superAdmin) 'role': 'super-admin',
          if (filter == AdminUserFilter.active) 'status': 'active',
          if (filter == AdminUserFilter.inactive) 'status': 'inactive',
        },
      );
      return adminUsersPageFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Daftar selalu ada kecuali server belum memuat fitur ini.
      throw _error(e, notFound: 'Admin Panel belum aktif di server.');
    }
  }

  Future<AdminUserDetail> fetchUser(String id) =>
      _detail(() => _dio.get('v1/admin/users/$id'));

  Future<AdminUserDetail> setSuperAdmin(String id, {required bool enabled}) =>
      _detail(() => _dio.put(
            'v1/admin/users/$id/super-admin',
            data: {'enabled': enabled},
          ));

  Future<AdminUserDetail> setActive(String id, {required bool active}) =>
      _detail(() => _dio.put(
            'v1/admin/users/$id/status',
            data: {'is_active': active},
          ));

  Future<AdminUserDetail> _detail(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data as Map<String, dynamic>;
      return AdminUserDetailModel.fromJson(
        body['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _error(e, notFound: 'Pengguna tidak ditemukan.');
    }
  }

  static AppException _error(DioException e, {required String notFound}) {
    final status = e.response?.statusCode;
    return switch (status) {
      403 => const ServerException('Anda tidak memiliki akses ke Admin Panel.'),
      404 => ServerException(notFound),
      422 => ServerException(_validationMessage(e)),
      429 => const ServerException(
          'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.'),
      null => const NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      _ => const ServerException('Terjadi kesalahan pada server. Coba lagi.'),
    };
  }

  /// Pesan validasi pertama dari server, sudah berbahasa Indonesia.
  static String _validationMessage(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['errors'] is Map) {
      final first = (body['errors'] as Map).values.firstOrNull;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    return 'Data tidak valid.';
  }
}
