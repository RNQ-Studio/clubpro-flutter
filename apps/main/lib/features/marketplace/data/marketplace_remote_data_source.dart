import 'package:core/core.dart';
import 'package:dio/dio.dart';
import '../../finance/data/finance_models.dart';
import '../../finance/domain/finance.dart';
import '../domain/marketplace.dart';

class MarketplaceRemoteDataSource {
  const MarketplaceRemoteDataSource(this.dio);
  final Dio dio;
  Future<Map<String, dynamic>> request(String path,
      {String method = 'GET',
      Object? data,
      Map<String, Object?>? query,
      bool nullable404 = false}) async {
    try {
      final r = await dio.request('v1/$path',
          data: data, queryParameters: query, options: Options(method: method));
      return financeMap(financeMap(r.data)['data']);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 && nullable404) return {};
      if (code == 401) throw const FinanceAuthenticationException();
      final body = financeMap(e.response?.data),
          errors = financeMap(financeMap(e.response?.data)['errors']);
      String message = textOf(body['message']);
      if (errors.isNotEmpty &&
          errors.values.first is List &&
          (errors.values.first as List).isNotEmpty) {
        message = '${(errors.values.first as List).first}';
      }
      if (message.isEmpty || message == 'The given data was invalid.') {
        message =
            'Permintaan ditolak. Periksa data, stok, saldo, dan hak akses Anda.';
      }
      if (code != null && code >= 400 && code < 500) {
        throw MarketRejected(message);
      }
      if (code == null) {
        throw const NetworkException(
            'Koneksi terputus. Hasil pembayaran belum pasti; periksa transaksi dengan referensi yang sama.');
      }
      throw const ServerException(
          'Server belum mengonfirmasi hasil. Periksa transaksi sebelum mencoba lagi.');
    }
  }

  Future<String> upload(MarketImage image) async {
    final mime = image.mime.split('/');
    final j = await request('assets/upload',
        method: 'POST',
        data: FormData.fromMap({
          'type': 'marketplace-product',
          'file': MultipartFile.fromBytes(image.bytes,
              filename: image.name,
              contentType: DioMediaType(mime.first, mime.last)),
          'retain_until': DateTime.now()
              .toUtc()
              .add(const Duration(days: 7))
              .toIso8601String()
        }));
    final id = textOf(j['id']);
    if (id.isEmpty) throw const FinanceDataException();
    return id;
  }
}
