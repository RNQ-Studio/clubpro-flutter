// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(communityRepository)
final communityRepositoryProvider = CommunityRepositoryProvider._();

final class CommunityRepositoryProvider extends $FunctionalProvider<
    CommunityRepository,
    CommunityRepository,
    CommunityRepository> with $Provider<CommunityRepository> {
  CommunityRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityRepositoryHash();

  @$internal
  @override
  $ProviderElement<CommunityRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CommunityRepository create(Ref ref) {
    return communityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunityRepository>(value),
    );
  }
}

String _$communityRepositoryHash() =>
    r'5395891ae4560b9b6c94f75c2e87a7b59e28a372';

@ProviderFor(communityImagePicker)
final communityImagePickerProvider = CommunityImagePickerProvider._();

final class CommunityImagePickerProvider extends $FunctionalProvider<
    CommunityImagePicker,
    CommunityImagePicker,
    CommunityImagePicker> with $Provider<CommunityImagePicker> {
  CommunityImagePickerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityImagePickerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityImagePickerHash();

  @$internal
  @override
  $ProviderElement<CommunityImagePicker> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CommunityImagePicker create(Ref ref) {
    return communityImagePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunityImagePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunityImagePicker>(value),
    );
  }
}

String _$communityImagePickerHash() =>
    r'182edf5cf89fcc2f91e7610862fb4d906dde61af';

/// Jenis komunitas; jarang berubah, jadi dimuat sekali per sesi.

@ProviderFor(communityTypes)
final communityTypesProvider = CommunityTypesProvider._();

/// Jenis komunitas; jarang berubah, jadi dimuat sekali per sesi.

final class CommunityTypesProvider extends $FunctionalProvider<
        AsyncValue<List<CommunityTypeOption>>,
        List<CommunityTypeOption>,
        FutureOr<List<CommunityTypeOption>>>
    with
        $FutureModifier<List<CommunityTypeOption>>,
        $FutureProvider<List<CommunityTypeOption>> {
  /// Jenis komunitas; jarang berubah, jadi dimuat sekali per sesi.
  CommunityTypesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityTypesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityTypesHash();

  @$internal
  @override
  $FutureProviderElement<List<CommunityTypeOption>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<CommunityTypeOption>> create(Ref ref) {
    return communityTypes(ref);
  }
}

String _$communityTypesHash() => r'649da1f1aefe0ca73ff0ce373e7307dcb084a877';

/// Provinsi beserta kabupaten/kotanya; satu respons, sehingga pilihan kota
/// langsung tersedia begitu provinsi dipilih.

@ProviderFor(indonesiaRegions)
final indonesiaRegionsProvider = IndonesiaRegionsProvider._();

/// Provinsi beserta kabupaten/kotanya; satu respons, sehingga pilihan kota
/// langsung tersedia begitu provinsi dipilih.

final class IndonesiaRegionsProvider extends $FunctionalProvider<
        AsyncValue<List<RegionProvince>>,
        List<RegionProvince>,
        FutureOr<List<RegionProvince>>>
    with
        $FutureModifier<List<RegionProvince>>,
        $FutureProvider<List<RegionProvince>> {
  /// Provinsi beserta kabupaten/kotanya; satu respons, sehingga pilihan kota
  /// langsung tersedia begitu provinsi dipilih.
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

String _$indonesiaRegionsHash() => r'f6f09ec687e03b134bc1d7b7e4ef0d826149cba9';

/// Pengajuan milik pengguna yang login.

@ProviderFor(myCommunities)
final myCommunitiesProvider = MyCommunitiesProvider._();

/// Pengajuan milik pengguna yang login.

final class MyCommunitiesProvider extends $FunctionalProvider<
        AsyncValue<List<Community>>, List<Community>, FutureOr<List<Community>>>
    with $FutureModifier<List<Community>>, $FutureProvider<List<Community>> {
  /// Pengajuan milik pengguna yang login.
  MyCommunitiesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'myCommunitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myCommunitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<Community>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Community>> create(Ref ref) {
    return myCommunities(ref);
  }
}

String _$myCommunitiesHash() => r'ed4de557d96b841565ed615a4473bea0bcd1a20a';

@ProviderFor(communityDetail)
final communityDetailProvider = CommunityDetailFamily._();

final class CommunityDetailProvider extends $FunctionalProvider<
        AsyncValue<CommunityDetail>, CommunityDetail, FutureOr<CommunityDetail>>
    with $FutureModifier<CommunityDetail>, $FutureProvider<CommunityDetail> {
  CommunityDetailProvider._(
      {required CommunityDetailFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'communityDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityDetailHash();

  @override
  String toString() {
    return r'communityDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CommunityDetail> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CommunityDetail> create(Ref ref) {
    final argument = this.argument as String;
    return communityDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityDetailHash() => r'39d30526705bd63326e9c62beb17815f686ab2dd';

final class CommunityDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CommunityDetail>, String> {
  CommunityDetailFamily._()
      : super(
          retry: null,
          name: r'communityDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CommunityDetailProvider call(
    String id,
  ) =>
      CommunityDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'communityDetailProvider';
}

/// Daftar komunitas terverifikasi: cari, saring jenis, dan muat bertahap.

@ProviderFor(CommunitiesNotifier)
final communitiesProvider = CommunitiesNotifierProvider._();

/// Daftar komunitas terverifikasi: cari, saring jenis, dan muat bertahap.
final class CommunitiesNotifierProvider
    extends $AsyncNotifierProvider<CommunitiesNotifier, CommunitiesState> {
  /// Daftar komunitas terverifikasi: cari, saring jenis, dan muat bertahap.
  CommunitiesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communitiesNotifierHash();

  @$internal
  @override
  CommunitiesNotifier create() => CommunitiesNotifier();
}

String _$communitiesNotifierHash() =>
    r'277f13772de468acba7e484615cdd81b7d2099f8';

/// Daftar komunitas terverifikasi: cari, saring jenis, dan muat bertahap.

abstract class _$CommunitiesNotifier extends $AsyncNotifier<CommunitiesState> {
  FutureOr<CommunitiesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CommunitiesState>, CommunitiesState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CommunitiesState>, CommunitiesState>,
        AsyncValue<CommunitiesState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
