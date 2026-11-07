import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../../domain/entities/dues.dart';
import '../models/dues_models.dart';

class DuesRemoteDataSource {
  const DuesRemoteDataSource(this._dio);

  final Dio _dio;

  static String _base(String communityId) => 'v1/communities/$communityId/dues';

  Future<DuesOverview> fetchOverview(String communityId, {int? year}) =>
      _guard(() async {
        final response = await _dio.get(
          _base(communityId),
          queryParameters: {if (year != null) 'year': year},
        );
        return duesOverviewFromJson(_data(response) as Map<String, dynamic>);
      });

  Future<DuesSettings> saveSettings(
    String communityId,
    DuesSettingsInput input,
  ) =>
      _guard(() async {
        final response = await _dio.put(
          '${_base(communityId)}/settings',
          data: duesSettingsToPayload(input),
        );
        return duesSettingsFromJson(_data(response) as Map<String, dynamic>);
      });

  Future<DuesPayment> pay(
    String communityId, {
    required int monthsCount,
    required String proofAssetId,
    String? note,
  }) =>
      _guard(() async {
        final response = await _dio.post(
          '${_base(communityId)}/payments',
          data: {
            'months_count': monthsCount,
            'proof_asset_id': proofAssetId,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          },
        );
        return duesPaymentFromJson(_data(response) as Map<String, dynamic>);
      });

  Future<Paged<DuesPayment>> fetchPayments(
    String communityId, {
    required int page,
    DuesPaymentStatus? status,
  }) =>
      _guard(() async {
        final response = await _dio.get(
          '${_base(communityId)}/payments',
          queryParameters: {
            'page': page,
            if (status != null) 'status': status.apiValue,
          },
        );
        return pagedFromJson(
          response.data as Map<String, dynamic>,
          duesPaymentFromJson,
        );
      });

  Future<DuesPayment> approve(String communityId, String paymentId) =>
      _guard(() async {
        final response = await _dio
            .post('${_base(communityId)}/payments/$paymentId/approve');
        return duesPaymentFromJson(_data(response) as Map<String, dynamic>);
      });

  Future<DuesPayment> reject(
    String communityId,
    String paymentId,
    String note,
  ) =>
      _guard(() async {
        final response = await _dio.post(
          '${_base(communityId)}/payments/$paymentId/reject',
          data: {'note': note.trim()},
        );
        return duesPaymentFromJson(_data(response) as Map<String, dynamic>);
      });

  Future<Paged<MemberDues>> fetchMembers(
    String communityId, {
    required int year,
    required int page,
    String search = '',
  }) =>
      _guard(() async {
        final response = await _dio.get(
          '${_base(communityId)}/members',
          queryParameters: {
            'year': year,
            'page': page,
            if (search.isNotEmpty) 'search': search,
          },
        );
        return pagedFromJson(
          response.data as Map<String, dynamic>,
          memberDuesFromJson,
        );
      });

  Future<MemberDuesDetail> fetchMember(
    String communityId,
    String userId, {
    required int year,
  }) =>
      _guard(() async {
        final response = await _dio.get(
          '${_base(communityId)}/members/$userId',
          queryParameters: {'year': year},
        );
        return memberDuesDetailFromJson(
          _data(response) as Map<String, dynamic>,
        );
      });

  Future<void> setMonth(
    String communityId,
    String userId,
    DateTime month, {
    required bool paid,
  }) =>
      _guard(() => _dio.put(
            '${_base(communityId)}/members/$userId/months/'
            '${duesMonthToApi(month)}',
            data: {'paid': paid},
          ));

  Future<void> setEntryFee(
    String communityId,
    String userId, {
    required bool paid,
  }) =>
      _guard(() => _dio.put(
            '${_base(communityId)}/members/$userId/entry-fee',
            data: {'paid': paid},
          ));

  static Object? _data(Response<dynamic> response) =>
      (response.data as Map<String, dynamic>)['data'];

  static Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _error(e);
    }
  }

  static Exception _error(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final message = body is Map ? body['message'] as String? : null;
    return switch (status) {
      403 =>
        const ServerException('Anda tidak punya akses untuk tindakan ini.'),
      404 => ServerException(
          message ?? 'Fitur Iuran belum aktif di server. Coba lagi nanti.'),
      409 => ServerException(message ??
          'Data sudah berubah. Muat ulang untuk melihat yang terbaru.'),
      422 => _validationError(body),
      429 => const ServerException(
          'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.'),
      null => const NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi Anda.'),
      _ => const ServerException('Terjadi kesalahan pada server. Coba lagi.'),
    };
  }

  /// Isian pertama yang ditolak server; pesannya sudah berbahasa Indonesia.
  static Exception _validationError(Object? body) {
    if (body is Map && body['errors'] is Map) {
      final errors = body['errors'] as Map;
      if (errors.isNotEmpty) {
        final first = errors.entries.first;
        final messages = first.value;
        if (messages is List && messages.isNotEmpty) {
          return DuesFieldException(
            first.key.toString(),
            messages.first.toString(),
          );
        }
      }
    }
    return const ServerException('Data tidak valid.');
  }
}
