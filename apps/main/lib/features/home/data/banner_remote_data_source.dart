import 'package:dio/dio.dart';

import '../domain/entities/home_banner.dart';

class BannerRemoteDataSource {
  const BannerRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET v1/banners` — promosi aktif dalam jadwal tayang, sudah terurut, dan
  /// `meta.interval_hours`. Server lama tanpa meta → jeda bawaan.
  Future<HomePromotions> fetchPromotions() async {
    final response = await _dio.get('v1/banners');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List;
    final hours = (body['meta'] as Map<String, dynamic>?)?['interval_hours'];
    return HomePromotions(
      banners: [
        for (final item in data)
          HomeBanner.fromJson(item as Map<String, dynamic>),
      ],
      intervalHours: hours is int && hours > 0
          ? hours
          : HomePromotions.defaultIntervalHours,
    );
  }
}
