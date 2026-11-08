// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null bila platform ini tidak memerlukannya.

@ProviderFor(appRefresher)
final appRefresherProvider = AppRefresherProvider._();

/// Null bila platform ini tidak memerlukannya.

final class AppRefresherProvider
    extends $FunctionalProvider<AppRefresher?, AppRefresher?, AppRefresher?>
    with $Provider<AppRefresher?> {
  /// Null bila platform ini tidak memerlukannya.
  AppRefresherProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appRefresherProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appRefresherHash();

  @$internal
  @override
  $ProviderElement<AppRefresher?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppRefresher? create(Ref ref) {
    return appRefresher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppRefresher? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppRefresher?>(value),
    );
  }
}

String _$appRefresherHash() => r'ba916431cb444a2928c2348c84491b8496a3f542';

@ProviderFor(bannerRemoteDataSource)
final bannerRemoteDataSourceProvider = BannerRemoteDataSourceProvider._();

final class BannerRemoteDataSourceProvider extends $FunctionalProvider<
    BannerRemoteDataSource,
    BannerRemoteDataSource,
    BannerRemoteDataSource> with $Provider<BannerRemoteDataSource> {
  BannerRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bannerRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bannerRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<BannerRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BannerRemoteDataSource create(Ref ref) {
    return bannerRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BannerRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BannerRemoteDataSource>(value),
    );
  }
}

String _$bannerRemoteDataSourceHash() =>
    r'a140578c8151d98ee849e6c2a58b5016943a3ce5';

@ProviderFor(promotionPopupStore)
final promotionPopupStoreProvider = PromotionPopupStoreProvider._();

final class PromotionPopupStoreProvider extends $FunctionalProvider<
    PromotionPopupStore,
    PromotionPopupStore,
    PromotionPopupStore> with $Provider<PromotionPopupStore> {
  PromotionPopupStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'promotionPopupStoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$promotionPopupStoreHash();

  @$internal
  @override
  $ProviderElement<PromotionPopupStore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PromotionPopupStore create(Ref ref) {
    return promotionPopupStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PromotionPopupStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PromotionPopupStore>(value),
    );
  }
}

String _$promotionPopupStoreHash() =>
    r'142eb5593a4f7d85f44b48dd0613f2df8a481da5';

/// Popup Paid Promotion dari Admin Panel. Belum ada promosi, offline, atau
/// server gagal → kosong, dan popup tidak tampil.

@ProviderFor(homePromotions)
final homePromotionsProvider = HomePromotionsProvider._();

/// Popup Paid Promotion dari Admin Panel. Belum ada promosi, offline, atau
/// server gagal → kosong, dan popup tidak tampil.

final class HomePromotionsProvider extends $FunctionalProvider<
        AsyncValue<HomePromotions>, HomePromotions, FutureOr<HomePromotions>>
    with $FutureModifier<HomePromotions>, $FutureProvider<HomePromotions> {
  /// Popup Paid Promotion dari Admin Panel. Belum ada promosi, offline, atau
  /// server gagal → kosong, dan popup tidak tampil.
  HomePromotionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homePromotionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homePromotionsHash();

  @$internal
  @override
  $FutureProviderElement<HomePromotions> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<HomePromotions> create(Ref ref) {
    return homePromotions(ref);
  }
}

String _$homePromotionsHash() => r'8419444ffdc1dbfd08b0de2d64284bd884b460e5';
