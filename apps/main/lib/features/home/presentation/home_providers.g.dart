// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

@ProviderFor(homeBanners)
final homeBannersProvider = HomeBannersProvider._();

final class HomeBannersProvider extends $FunctionalProvider<
        AsyncValue<List<HomeBanner>>,
        List<HomeBanner>,
        FutureOr<List<HomeBanner>>>
    with $FutureModifier<List<HomeBanner>>, $FutureProvider<List<HomeBanner>> {
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

String _$homeBannersHash() => r'896bab6a657de2f78a1438fcbec48090137eff09';
