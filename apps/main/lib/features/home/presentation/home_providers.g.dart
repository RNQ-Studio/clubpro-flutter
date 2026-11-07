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

/// Hanya banner yang dikelola di Admin Panel. Belum ada banner, offline, atau
/// server gagal → kosong, dan Beranda tidak menampilkan bagian banner.

@ProviderFor(homeBanners)
final homeBannersProvider = HomeBannersProvider._();

/// Hanya banner yang dikelola di Admin Panel. Belum ada banner, offline, atau
/// server gagal → kosong, dan Beranda tidak menampilkan bagian banner.

final class HomeBannersProvider extends $FunctionalProvider<
        AsyncValue<List<HomeBanner>>,
        List<HomeBanner>,
        FutureOr<List<HomeBanner>>>
    with $FutureModifier<List<HomeBanner>>, $FutureProvider<List<HomeBanner>> {
  /// Hanya banner yang dikelola di Admin Panel. Belum ada banner, offline, atau
  /// server gagal → kosong, dan Beranda tidak menampilkan bagian banner.
  HomeBannersProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeBannersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeBannersHash();

  @$internal
  @override
  $FutureProviderElement<List<HomeBanner>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<HomeBanner>> create(Ref ref) {
    return homeBanners(ref);
  }
}

String _$homeBannersHash() => r'f647074798b0ab042466595c19f35502bcd62e5a';
