import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/member_card.dart';
import '../models/member_card_model.dart';

class MemberCardRemoteDataSource {
  const MemberCardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<MemberCard> fetchCard(String communityId) async {
    try {
      final response = await _dio.get('v1/communities/$communityId/card');
      return memberCardFromJson(
        (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  static Exception _error(DioException e) {
    final message = switch (e.response?.data) {
      {'message': final String message} when message.isNotEmpty => message,
      _ => null,
    };
    return switch (e.response?.statusCode) {
      403 => ServerException(
          message ?? 'Kartu anggota hanya untuk anggota aktif komunitas ini.'),
      404 => const ServerException(
          'Kartu anggota belum tersedia. Komunitas tidak ditemukan atau fitur '
          'belum aktif di server.'),
      null => const NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      _ => const ServerException('Gagal memuat kartu anggota. Coba lagi.'),
    };
  }
}
