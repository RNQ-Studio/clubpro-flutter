import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../domain/directory_repository.dart';

class DirectoryRepositoryImpl implements DirectoryRepository {
  const DirectoryRepositoryImpl(this.dio);
  final Dio dio;
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
      final status = e.response?.statusCode;
      final translated = switch (status ?? 0) {
        401 => 'Sesi berakhir. Silakan masuk kembali.',
        403 => 'Anda tidak berhak mengakses data ini.',
        404 => 'Data tidak ditemukan.',
        429 => 'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.',
        >= 500 => 'Server sedang mengalami kendala. Silakan coba lagi.',
        422 when message == null || message == 'The given data was invalid.' =>
          'Data tidak valid. Periksa isian Anda.',
        _ => message ?? 'Tidak dapat terhubung. Silakan coba lagi.',
      };
      throw ServerException(translated);
    }
  }

  Map<String, dynamic> _map(Object? data) =>
      Map<String, dynamic>.from(data as Map);
  dynamic _data(Response<dynamic> response) => (response.data as Map)['data'];
  DirectoryItem _community(Map<String, dynamic> j) => DirectoryItem(
      j['id'].toString(),
      j['name'] as String,
      '${j['city_name'] ?? ''} · ${j['type_label'] ?? ''}',
      description: j['description'] as String? ?? '');
  @override
  Future<DirectoryPage> search(
          {required bool members,
          String search = '',
          String? communityId,
          String? role,
          int page = 1}) =>
      _guard(() async {
        final response = await dio.get(
            'v1/public/${members ? 'members' : 'communities'}',
            queryParameters: {
              'search': search,
              'page': page,
              if (communityId != null) 'community_id': communityId,
              if (role != null) 'role': role
            });
        final body = _map(response.data);
        final pagination = _map(_map(body['meta'])['pagination']);
        return DirectoryPage([
          for (final raw in body['data'] as List)
            if (members) _member(_map(raw)) else _community(_map(raw))
        ], pagination['current_page'] as int, pagination['last_page'] as int);
      });
  DirectoryItem _member(Map<String, dynamic> j) {
    final c = _map(j['community']);
    return DirectoryItem(j['id'].toString(), j['name'] as String,
        '${j['role_label']} · ${c['name']}',
        communityId: c['id'].toString(),
        role: j['role'] as String,
        membershipId: j['membership_id'].toString());
  }

  @override
  Future<List<Map<String, dynamic>>> internalMembers(String communityId,
          {String search = '',
          String? role,
          String status = 'active',
          int page = 1}) =>
      _guard(() async => [
            for (final raw in _data(await dio
                .get('v1/communities/$communityId/members', queryParameters: {
              'search': search,
              'page': page,
              'status': status,
              if (role != null) 'role': role
            })) as List)
              _map(raw)
          ]);
  @override
  Future<DirectoryItem> community(String id) => _guard(() async =>
      _community(_map(_data(await dio.get('v1/public/communities/$id')))));
  @override
  Future<Map<String, dynamic>> createMember(
          String communityId, Map<String, Object?> fields) =>
      _guard(() async => _map(_data(await dio
          .post('v1/communities/$communityId/manual-members', data: fields))));
  @override
  Future<Map<String, dynamic>> memberDetail(
          String communityId, String memberId) =>
      _guard(() async => _map(_data(await dio
          .get('v1/communities/$communityId/manual-members/$memberId'))));
  @override
  Future<void> editMember(
          String communityId, String memberId, Map<String, Object?> fields) =>
      _guard(() async {
        await dio.put('v1/communities/$communityId/manual-members/$memberId',
            data: fields);
      });
  @override
  Future<void> invite(String communityId, String memberId, String email,
          {required bool account}) =>
      _guard(() async {
        await dio.post(
            'v1/communities/$communityId/members/$memberId/${account ? 'account' : 'guardian'}-invitations',
            data: {'email': email});
      });
  @override
  Future<List<Map<String, dynamic>>> invitations() => _guard(() async => [
        for (final j in _data(await dio.get('v1/guardian-invitations')) as List)
          _map(j)
      ]);
  @override
  Future<void> sendEmailVerification() => _guard(() async {
        await dio.post('v1/auth/email/send-verification');
      });
  @override
  Future<void> claim(String id, String token) => _guard(() async {
        await dio
            .post('v1/guardian-invitations/$id/claim', data: {'token': token});
      });
  @override
  Future<List<Map<String, dynamic>>> dependents() => _guard(() async =>
      [for (final j in _data(await dio.get('v1/dependents')) as List) _map(j)]);
  @override
  Future<Map<String, dynamic>> dependent(String id) =>
      _guard(() async => _map(_data(await dio.get('v1/dependents/$id'))));
  @override
  Future<void> updateDependent(String id, Map<String, Object?> fields) =>
      _guard(() async {
        await dio.put('v1/dependents/$id', data: fields);
      });
  @override
  Future<void> revoke(String grantId) => _guard(() async {
        await dio.delete('v1/guardian-grants/$grantId');
      });
  @override
  Future<Map<String, dynamic>> card(String identityId, String memberId) =>
      _guard(() async => _map(_data(await dio
          .get('v1/dependents/$identityId/memberships/$memberId/card'))));
  @override
  Future<void> updateCommunity(String id, Map<String, Object?> fields) =>
      _guard(() async {
        await dio.put('v1/communities/$id', data: fields);
      });
}
