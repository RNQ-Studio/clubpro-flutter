import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_refresher.dart';
import '../data/banner_remote_data_source.dart';
import '../domain/app_refresher.dart';
import '../domain/entities/home_banner.dart';

part 'home_providers.g.dart';

/// Null bila platform ini tidak memerlukannya.
@riverpod
AppRefresher? appRefresher(Ref ref) => createAppRefresher();

@riverpod
BannerRemoteDataSource bannerRemoteDataSource(Ref ref) =>
    BannerRemoteDataSource(ref.watch(apiClientProvider).dio);

/// Hanya banner yang dikelola di Admin Panel. Belum ada banner, offline, atau
/// server gagal → kosong, dan Beranda tidak menampilkan bagian banner.
@riverpod
Future<List<HomeBanner>> homeBanners(Ref ref) async {
  try {
    return await ref.watch(bannerRemoteDataSourceProvider).fetchBanners();
  } catch (_) {
    return const [];
  }
}
