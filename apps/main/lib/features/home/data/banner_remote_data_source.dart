import 'package:dio/dio.dart';

import '../domain/entities/home_banner.dart';

class BannerRemoteDataSource {
  const BannerRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET v1/banners` — banner aktif dalam jadwal tayang, sudah terurut.
  Future<List<HomeBanner>> fetchBanners() async {
    final response = await _dio.get('v1/banners');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return [
      for (final item in data)
        HomeBanner.fromJson(item as Map<String, dynamic>),
    ];
  }
}
