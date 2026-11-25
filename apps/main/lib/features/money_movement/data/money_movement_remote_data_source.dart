import 'dart:typed_data';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../../finance/data/finance_models.dart';
import '../../finance/data/finance_remote_data_source.dart';
import '../../finance/domain/finance.dart';
import '../domain/money_movement.dart';

class MovementRejectedException extends FinanceConflictException {
  const MovementRejectedException(super.message);
}

class MoneyMovementRemoteDataSource extends FinanceRemoteDataSource {
  const MoneyMovementRemoteDataSource(super.dio);
  @override
  Future<Map<String, dynamic>> post(String path, Map<String, Object?> fields) =>
      _mutate('POST', path, fields);
  Future<Map<String, dynamic>> put(String path, Map<String, Object?> fields) =>
      _mutate('PUT', path, fields);
  Future<Map<String, dynamic>> _mutate(
      String method, String path, Map<String, Object?> fields) async {
    try {
      final r = await dio.request('v1/$path',
          data: fields, options: Options(method: method));
      return financeMap(financeMap(r.data)['data']);
    } on DioException catch (e) {
      final body = financeMap(e.response?.data);
      var message = body['message']?.toString();
      final errors = financeMap(body['errors']);
      if (errors.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty) {
        message = '${(errors.values.first as List).first}';
      }
      final code = e.response?.statusCode;
      if (code == 401) {
        throw const FinanceAuthenticationException();
      }
      if ([400, 402, 403, 404, 422, 429].contains(code)) {
        throw MovementRejectedException(message == null ||
                message == 'The given data was invalid.'
            ? 'Permintaan ditolak. Periksa isian dan hak akses sebelum mencoba lagi.'
            : message);
      }
      if (code == 409) {
        throw FinanceConflictException(
            message ?? 'Data berubah. Muat ulang status sebelum mencoba lagi.');
      }
      if (code == null) {
        throw const NetworkException(
            'Koneksi terputus. Hasil belum diketahui; coba lagi dengan permintaan yang sama.');
      }
      throw const ServerException(
          'Server belum mengonfirmasi hasil. Periksa riwayat dan coba lagi dengan permintaan yang sama.');
    }
  }

  Future<ProofFile> proof(String url) async {
    final uri = Uri.tryParse(url), base = Uri.tryParse(dio.options.baseUrl);
    if (uri == null || uri.scheme != 'https' || uri.host != base?.host) {
      throw const ServerException(
          'Tautan bukti tidak sah. Muat ulang detail pencairan.');
    }
    try {
      final r = await dio.get<List<int>>(url,
          options: Options(responseType: ResponseType.bytes));
      final mime = (r.headers.value('content-type') ?? '').split(';').first;
      final bytes = Uint8List.fromList(r.data ?? []);
      if (!['image/png', 'image/jpeg', 'image/webp'].contains(mime) ||
          bytes.isEmpty ||
          bytes.length > 5 * 1024 * 1024) {
        throw const ServerException('Bukti gambar tidak sah.');
      }
      return ProofFile(bytes, mime);
    } on DioException {
      throw const ServerException(
          'Bukti belum dapat diambil. Muat ulang untuk memperbarui tautan privat.');
    }
  }
}
