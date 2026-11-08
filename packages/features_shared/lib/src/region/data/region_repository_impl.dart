import 'package:core/core.dart';
import 'package:dio/dio.dart';

import '../domain/entities/region.dart';
import '../domain/repositories/region_repository.dart';

/// `GET v1/regions/indonesia`: satu respons berisi semua provinsi dan
/// kabupaten/kotanya, sehingga pilihan kota langsung ada begitu provinsi dipilih.
class RegionRepositoryImpl implements RegionRepository {
  const RegionRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<RegionProvince>> getIndonesia() async {
    try {
      final response = await _dio.get('v1/regions/indonesia');
      final data = (response.data as Map<String, dynamic>)['data'];
      return [
        for (final item in data as List<dynamic>)
          regionProvinceFromJson(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw e.response == null
          ? const NetworkException(
              'Tidak dapat terhubung ke server. Periksa koneksi Anda.')
          : const ServerException('Gagal memuat daftar wilayah. Coba lagi.');
    }
  }
}

RegionProvince regionProvinceFromJson(Map<String, dynamic> json) =>
    RegionProvince(
      code: json['code'] as String,
      name: json['name'] as String,
      cities: [
        for (final city in json['cities'] as List<dynamic>)
          RegionCity(
            code: (city as Map<String, dynamic>)['code'] as String,
            name: city['name'] as String,
          ),
      ],
    );
