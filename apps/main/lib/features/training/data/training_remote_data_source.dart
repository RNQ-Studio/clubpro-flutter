import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../../finance/data/finance_models.dart';
import '../../finance/domain/finance.dart';

class TrainingRemoteDataSource {
  const TrainingRemoteDataSource(this.dio);
  final Dio dio;
  Future<Map<String, dynamic>> request(String method, String path,
      {Map<String, Object?>? fields, Map<String, Object?>? query}) async {
    try {
      final r = await dio.request<dynamic>('v1/$path',
          data: fields,
          queryParameters: query,
          options: Options(method: method));
      return financeMap(financeMap(r.data)['data']);
    } on DioException catch (e) {
      final j = financeMap(e.response?.data),
          errors = financeMap(financeMap(e.response?.data)['errors']);
      String? message = j['message'] as String?;
      if (errors.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty) {
        message = '${(errors.values.first as List).first}';
      }
      throw switch (e.response?.statusCode) {
        401 => const FinanceAuthenticationException(),
        402 => const ServerException(
            'Masa aktif keanggotaan atau komunitas berakhir. Buka Keanggotaan & pembayaran.'),
        403 => const ServerException(
            'Anda tidak berhak melakukan tindakan latihan ini.'),
        404 => const ServerException(
            'Data latihan tidak ditemukan. Muat ulang lalu coba lagi.'),
        409 => FinanceConflictException(
            message ?? 'Data sudah berubah. Muat ulang sebelum mencoba lagi.'),
        422 => ServerException(
            message == null || message == 'The given data was invalid.'
                ? 'Periksa kembali isian latihan.'
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
