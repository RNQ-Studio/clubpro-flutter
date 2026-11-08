// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(regionRepository)
final regionRepositoryProvider = RegionRepositoryProvider._();

final class RegionRepositoryProvider extends $FunctionalProvider<
    RegionRepository,
    RegionRepository,
    RegionRepository> with $Provider<RegionRepository> {
  RegionRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'regionRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$regionRepositoryHash();

  @$internal
  @override
  $ProviderElement<RegionRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegionRepository create(Ref ref) {
    return regionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegionRepository>(value),
    );
  }
}

String _$regionRepositoryHash() => r'9827cc20f4952f9e7a92e120573fe79c9f30edab';

/// Provinsi beserta kabupaten/kotanya; jarang berubah, jadi dimuat sekali per
/// sesi (dipakai form komunitas dan data diri).

@ProviderFor(indonesiaRegions)
final indonesiaRegionsProvider = IndonesiaRegionsProvider._();

/// Provinsi beserta kabupaten/kotanya; jarang berubah, jadi dimuat sekali per
/// sesi (dipakai form komunitas dan data diri).

final class IndonesiaRegionsProvider extends $FunctionalProvider<
        AsyncValue<List<RegionProvince>>,
        List<RegionProvince>,
        FutureOr<List<RegionProvince>>>
    with
        $FutureModifier<List<RegionProvince>>,
        $FutureProvider<List<RegionProvince>> {
  /// Provinsi beserta kabupaten/kotanya; jarang berubah, jadi dimuat sekali per
  /// sesi (dipakai form komunitas dan data diri).
  IndonesiaRegionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'indonesiaRegionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$indonesiaRegionsHash();

  @$internal
  @override
  $FutureProviderElement<List<RegionProvince>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<RegionProvince>> create(Ref ref) {
    return indonesiaRegions(ref);
  }
}

String _$indonesiaRegionsHash() => r'b9736ce8b17a008d255bf20fe048b77dfd614eec';
