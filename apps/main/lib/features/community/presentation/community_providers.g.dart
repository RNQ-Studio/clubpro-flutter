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

/// Komunitas yang diikuti beserta permintaan bergabung yang masih menunggu,
/// untuk Beranda.

@ProviderFor(joinedCommunities)
final joinedCommunitiesProvider = JoinedCommunitiesProvider._();

/// Komunitas yang diikuti beserta permintaan bergabung yang masih menunggu,
/// untuk Beranda.

final class JoinedCommunitiesProvider extends $FunctionalProvider<
        AsyncValue<List<Community>>, List<Community>, FutureOr<List<Community>>>
    with $FutureModifier<List<Community>>, $FutureProvider<List<Community>> {
  /// Komunitas yang diikuti beserta permintaan bergabung yang masih menunggu,
  /// untuk Beranda.
  JoinedCommunitiesProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'joinedCommunitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$joinedCommunitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<Community>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Community>> create(Ref ref) {
    return joinedCommunities(ref);
  }
}

String _$joinedCommunitiesHash() => r'7d4ff4933ed8edb3bbb6b811b9290711f4ae12da';

/// Rekomendasi: komunitas terverifikasi dengan anggota aktif terbanyak.

@ProviderFor(recommendedCommunities)
final recommendedCommunitiesProvider = RecommendedCommunitiesProvider._();

/// Rekomendasi: komunitas terverifikasi dengan anggota aktif terbanyak.

final class RecommendedCommunitiesProvider extends $FunctionalProvider<
        AsyncValue<List<Community>>, List<Community>, FutureOr<List<Community>>>
    with $FutureModifier<List<Community>>, $FutureProvider<List<Community>> {
  /// Rekomendasi: komunitas terverifikasi dengan anggota aktif terbanyak.
  RecommendedCommunitiesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recommendedCommunitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recommendedCommunitiesHash();

  @$internal
  @override
  $FutureProviderElement<List<Community>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Community>> create(Ref ref) {
    return recommendedCommunities(ref);
  }
}

String _$recommendedCommunitiesHash() =>
    r'c46f860e1d1808d2dbf36af638e47cdce240fd1e';

@ProviderFor(communityActivities)
final communityActivitiesProvider = CommunityActivitiesFamily._();

final class CommunityActivitiesProvider extends $FunctionalProvider<
        AsyncValue<CommunityActivities>,
        CommunityActivities,
        FutureOr<CommunityActivities>>
    with
        $FutureModifier<CommunityActivities>,
        $FutureProvider<CommunityActivities> {
  CommunityActivitiesProvider._(
      {required CommunityActivitiesFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'communityActivitiesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityActivitiesHash();

  @override
  String toString() {
    return r'communityActivitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CommunityActivities> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CommunityActivities> create(Ref ref) {
    final argument = this.argument as String;
    return communityActivities(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityActivitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityActivitiesHash() =>
    r'13426d89d10ef87b245d6b8081690b7bd738481d';

final class CommunityActivitiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CommunityActivities>, String> {
  CommunityActivitiesFamily._()
      : super(
          retry: null,
          name: r'communityActivitiesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CommunityActivitiesProvider call(
    String id,
  ) =>
      CommunityActivitiesProvider._(argument: id, from: this);

  @override
  String toString() => r'communityActivitiesProvider';
}

@ProviderFor(communityMemberProfile)
final communityMemberProfileProvider = CommunityMemberProfileFamily._();

final class CommunityMemberProfileProvider extends $FunctionalProvider<
        AsyncValue<CommunityMemberProfile>,
        CommunityMemberProfile,
        FutureOr<CommunityMemberProfile>>
    with
        $FutureModifier<CommunityMemberProfile>,
        $FutureProvider<CommunityMemberProfile> {
  CommunityMemberProfileProvider._(
      {required CommunityMemberProfileFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'communityMemberProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityMemberProfileHash();

  @override
  String toString() {
    return r'communityMemberProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CommunityMemberProfile> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CommunityMemberProfile> create(Ref ref) {
    final argument = this.argument as String;
    return communityMemberProfile(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityMemberProfileProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityMemberProfileHash() =>
    r'fc2a2f5240dfd5a0102dcf4b9b1f859a3203de5b';

final class CommunityMemberProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CommunityMemberProfile>, String> {
  CommunityMemberProfileFamily._()
      : super(
          retry: null,
          name: r'communityMemberProfileProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CommunityMemberProfileProvider call(
    String userId,
  ) =>
      CommunityMemberProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'communityMemberProfileProvider';
}

/// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
/// dimuat ulang setiap detail komunitas disegarkan.

@ProviderFor(CommunityMembersNotifier)
final communityMembersProvider = CommunityMembersNotifierFamily._();

/// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
/// dimuat ulang setiap detail komunitas disegarkan.
final class CommunityMembersNotifierProvider extends $AsyncNotifierProvider<
    CommunityMembersNotifier, CommunityMembersState> {
  /// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
  /// dimuat ulang setiap detail komunitas disegarkan.
  CommunityMembersNotifierProvider._(
      {required CommunityMembersNotifierFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'communityMembersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityMembersNotifierHash();

  @override
  String toString() {
    return r'communityMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CommunityMembersNotifier create() => CommunityMembersNotifier();

  @override
  bool operator ==(Object other) {
    return other is CommunityMembersNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityMembersNotifierHash() =>
    r'1fa086d2284ce27ac8d8e4e5777d6ced70a6be2f';

/// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
/// dimuat ulang setiap detail komunitas disegarkan.

final class CommunityMembersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            CommunityMembersNotifier,
            AsyncValue<CommunityMembersState>,
            CommunityMembersState,
            FutureOr<CommunityMembersState>,
            String> {
  CommunityMembersNotifierFamily._()
      : super(
          retry: null,
          name: r'communityMembersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
  /// dimuat ulang setiap detail komunitas disegarkan.

  CommunityMembersNotifierProvider call(
    String communityId,
  ) =>
      CommunityMembersNotifierProvider._(argument: communityId, from: this);

  @override
  String toString() => r'communityMembersProvider';
}

/// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
/// dimuat ulang setiap detail komunitas disegarkan.

abstract class _$CommunityMembersNotifier
    extends $AsyncNotifier<CommunityMembersState> {
  late final _$args = ref.$arg as String;
  String get communityId => _$args;

  FutureOr<CommunityMembersState> build(
    String communityId,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<CommunityMembersState>, CommunityMembersState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<CommunityMembersState>, CommunityMembersState>,
        AsyncValue<CommunityMembersState>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
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
