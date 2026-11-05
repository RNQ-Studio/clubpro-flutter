import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/community.dart';
import '../../domain/entities/community_draft.dart';
import '../models/community_model.dart';

class CommunityRemoteDataSource {
  const CommunityRemoteDataSource(this._dio);

  /// Foto yang tidak jadi dipakai dibersihkan server sesudah tenggat ini.
  static const _retention = Duration(days: 1);

  final Dio _dio;

  Future<CommunitiesPage> fetchCommunities({
    required int page,
    String search = '',
    String? type,
  }) =>
      _guard(() async {
        final response = await _dio.get(
          'v1/communities',
          queryParameters: {
            'page': page,
            if (search.isNotEmpty) 'search': search,
            if (type != null) 'type': type,
          },
        );
        return communitiesPageFromJson(response.data as Map<String, dynamic>);
      });

  Future<List<Community>> fetchMine() => _guard(() async {
        final response = await _dio.get('v1/communities/mine');
        return [
          for (final item in _data(response) as List<dynamic>)
            CommunityModel.fromJson(item as Map<String, dynamic>),
        ];
      });

  Future<CommunityDetail> fetchCommunity(String id) => _guard(
        () async {
          final response = await _dio.get('v1/communities/$id');
          return CommunityDetailModel.fromJson(
            _data(response) as Map<String, dynamic>,
          );
        },
        notFound: 'Komunitas tidak ditemukan.',
      );

  Future<List<CommunityTypeOption>> fetchTypes() => _guard(() async {
        final response = await _dio.get('v1/community-types');
        return [
          for (final item in _data(response) as List<dynamic>)
            communityTypeFromJson(item as Map<String, dynamic>),
        ];
      });

  Future<List<RegionProvince>> fetchRegions() => _guard(() async {
        final response = await _dio.get('v1/regions/indonesia');
        return [
          for (final item in _data(response) as List<dynamic>)
            regionProvinceFromJson(item as Map<String, dynamic>),
        ];
      });

  /// Dikirim sebagai byte: path `XFile` di web hanya URL blob.
  Future<String> uploadImage(
    CommunityImage image, {
    required String category,
  }) =>
      _guard(() async {
        final type = image.mimeType.split('/');
        final response = await _dio.post(
          'v1/assets/upload',
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              image.bytes,
              filename: image.filename,
              contentType: DioMediaType(type.first, type.last),
            ),
            'type': category,
            'retain_until':
                DateTime.now().toUtc().add(_retention).toIso8601String(),
          }),
        );
        return (_data(response) as Map<String, dynamic>)['id'] as String;
      });

  Future<CommunityDetail> submit(Map<String, Object?> payload) =>
      _guard(() async {
        final response = await _dio.post('v1/communities', data: payload);
        return CommunityDetailModel.fromJson(
          _data(response) as Map<String, dynamic>,
        );
      });

  Future<List<Community>> fetchJoined() => _guard(() async {
        final response = await _dio.get('v1/communities/joined');
        return [
          for (final item in _data(response) as List<dynamic>)
            CommunityModel.fromJson(item as Map<String, dynamic>),
        ];
      });

  Future<void> join(String id) =>
      _guard(() => _dio.post('v1/communities/$id/join'));

  Future<void> leave(String id) =>
      _guard(() => _dio.post('v1/communities/$id/leave'));

  Future<CommunityMembersPage> fetchMembers(
    String id, {
    required int page,
    bool pending = false,
  }) =>
      _guard(() async {
        final response = await _dio.get(
          'v1/communities/$id/members',
          queryParameters: {
            'page': page,
            if (pending) 'status': 'pending',
          },
        );
        return communityMembersPageFromJson(
          response.data as Map<String, dynamic>,
        );
      });

  Future<void> approveMember(String id, String memberId) =>
      _guard(() => _dio.post('v1/communities/$id/members/$memberId/approve'));

  Future<void> setMemberRole(
    String id,
    String memberId,
    CommunityRole role,
  ) =>
      _guard(() => _dio.put(
            'v1/communities/$id/members/$memberId/role',
            data: {'role': role.apiValue},
          ));

  Future<void> removeMember(String id, String memberId) =>
      _guard(() => _dio.delete('v1/communities/$id/members/$memberId'));

  Future<CommunityActivities> fetchActivities(String id) => _guard(() async {
        final response = await _dio.get('v1/communities/$id/activities');
        return communityActivitiesFromJson(
          _data(response) as Map<String, dynamic>,
        );
      });

  Future<void> createActivity(String id, Map<String, Object?> payload) =>
      _guard(() => _dio.post('v1/communities/$id/activities', data: payload));

  Future<void> updateActivity(
    String id,
    String activityId,
    Map<String, Object?> payload,
  ) =>
      _guard(() => _dio.put(
            'v1/communities/$id/activities/$activityId',
            data: payload,
          ));

  Future<void> deleteActivity(String id, String activityId) =>
      _guard(() => _dio.delete('v1/communities/$id/activities/$activityId'));

  Future<void> addPhoto(String id, String assetId) => _guard(
        () => _dio.post(
          'v1/communities/$id/photos',
          data: {'asset_id': assetId},
        ),
      );

  Future<void> removePhoto(String id, String assetId) =>
      _guard(() => _dio.delete('v1/communities/$id/photos/$assetId'));

  Future<CommunityMemberProfile> fetchMemberProfile(String userId) => _guard(
        () async {
          final response = await _dio.get('v1/members/$userId');
          return communityMemberProfileFromJson(
            _data(response) as Map<String, dynamic>,
          );
        },
        notFound: 'Profil anggota ini tidak tersedia.',
      );

  static Object? _data(Response<dynamic> response) =>
      (response.data as Map<String, dynamic>)['data'];

  static Future<T> _guard<T>(
    Future<T> Function() request, {
    String notFound = 'Fitur Komunitas belum aktif di server.',
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _error(e, notFound);
    }
  }

  static Exception _error(DioException e, String notFound) {
    final status = e.response?.statusCode;
    return switch (status) {
      403 =>
        const ServerException('Anda tidak punya akses untuk tindakan ini.'),
      404 => ServerException(notFound),
      413 => const ServerException(
          'Foto terlalu besar untuk server. Pilih foto yang lebih kecil.'),
      422 => _validationError(e),
      429 => const ServerException(
          'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.'),
      null => const NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      _ => const ServerException('Terjadi kesalahan pada server. Coba lagi.'),
    };
  }

  /// Isian pertama yang ditolak server, pesannya sudah berbahasa Indonesia.
  static Exception _validationError(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.entries.first;
        final messages = first.value;
        if (messages is List && messages.isNotEmpty) {
          // Galat per elemen ("photo_asset_ids.0") milik isian induknya.
          final field = first.key.toString().split('.').first;
          return CommunityFieldException(field, messages.first.toString());
        }
      }
    }
    return const ServerException('Data tidak valid.');
  }
}
