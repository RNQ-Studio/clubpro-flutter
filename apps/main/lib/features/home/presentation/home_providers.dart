import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_refresher.dart';
import '../data/banner_remote_data_source.dart';
import '../data/prefs_promotion_popup_store.dart';
import '../domain/app_refresher.dart';
import '../domain/entities/home_banner.dart';
import '../domain/repositories/promotion_popup_store.dart';

part 'home_providers.g.dart';

/// Null bila platform ini tidak memerlukannya.
@riverpod
AppRefresher? appRefresher(Ref ref) => createAppRefresher();

@riverpod
BannerRemoteDataSource bannerRemoteDataSource(Ref ref) =>
    BannerRemoteDataSource(ref.watch(apiClientProvider).dio);

@riverpod
PromotionPopupStore promotionPopupStore(Ref ref) => PrefsPromotionPopupStore();

/// Popup Paid Promotion dari Admin Panel. Belum ada promosi, offline, atau
/// server gagal → kosong, dan popup tidak tampil.
@riverpod
Future<HomePromotions> homePromotions(Ref ref) async {
  try {
    return await ref.watch(bannerRemoteDataSourceProvider).fetchPromotions();
  } catch (_) {
    return const HomePromotions();
  }
}
