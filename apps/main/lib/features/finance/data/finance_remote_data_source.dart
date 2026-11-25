import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'finance_models.dart';
import '../domain/finance.dart';

class FinanceRemoteDataSource {
  const FinanceRemoteDataSource(this.dio);
  final Dio dio;
  Future<Map<String, dynamic>> get(String path,
          [Map<String, Object?>? query]) =>
      _request(() => dio.get('v1/$path', queryParameters: query));
  Future<Map<String, dynamic>> post(String path, Map<String, Object?> fields) =>
      _request(() => dio.post('v1/$path', data: fields));
  Future<Map<String, dynamic>> patch(
          String path, Map<String, Object?> fields) =>
      _request(() => dio.patch('v1/$path', data: fields));
  Future<Map<String, dynamic>> _request(
      Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      return financeMap(response.data)['data'] is Map
          ? financeMap(financeMap(response.data)['data'])
          : financeMap(response.data);
    } on DioException catch (e) {
      final body = financeMap(e.response?.data);
      String? message = body['message'] as String?;
      final errors = financeMap(body['errors']);
      if (errors.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty) {
        message = '${(errors.values.first as List).first}';
      }
      throw switch (e.response?.statusCode) {
        401 => const FinanceAuthenticationException(),
        402 => const ServerException(
            'Masa aktif komunitas atau keanggotaan berakhir. Buka Keanggotaan & pembayaran untuk melunasi kewajiban.'),
        403 =>
          const ServerException('Anda tidak berhak melakukan tindakan ini.'),
        404 => const ServerException(
            'Data pembayaran tidak ditemukan. Muat ulang lalu coba lagi.'),
        409 => FinanceConflictException(message ??
            'Transaksi sudah berubah. Muat ulang riwayat sebelum mencoba lagi.'),
        422 => ServerException(
            message == null || message == 'The given data was invalid.'
                ? 'Periksa nominal dan isian pembayaran Anda.'
                : message),
        429 => const ServerException(
            'Terlalu banyak permintaan. Coba lagi beberapa saat lagi.'),
        null => const NetworkException(
            'Tidak dapat terhubung. Periksa koneksi lalu coba lagi.'),
        _ =>
          const ServerException('Server sedang mengalami kendala. Coba lagi.'),
      };
    }
  }
}
