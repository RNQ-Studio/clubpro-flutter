// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_community_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(activeCommunityStore)
final activeCommunityStoreProvider = ActiveCommunityStoreProvider._();

final class ActiveCommunityStoreProvider extends $FunctionalProvider<
    ActiveCommunityStore,
    ActiveCommunityStore,
    ActiveCommunityStore> with $Provider<ActiveCommunityStore> {
  ActiveCommunityStoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'activeCommunityStoreProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeCommunityStoreHash();

  @$internal
  @override
  $ProviderElement<ActiveCommunityStore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ActiveCommunityStore create(Ref ref) {
    return activeCommunityStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveCommunityStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveCommunityStore>(value),
    );
  }
}

String _$activeCommunityStoreHash() =>
    r'78c770cdc40a53cbb6d6631ef9a503a28900ecb1';

/// Komunitas aktif di Beranda. Satu komunitas → langsung aktif; beberapa →
/// pilihan terakhir pengguna (disimpan per akun di perangkat), atau belum ada
/// sampai pengguna memilih.

@ProviderFor(ActiveCommunityNotifier)
final activeCommunityProvider = ActiveCommunityNotifierProvider._();

/// Komunitas aktif di Beranda. Satu komunitas → langsung aktif; beberapa →
/// pilihan terakhir pengguna (disimpan per akun di perangkat), atau belum ada
/// sampai pengguna memilih.
final class ActiveCommunityNotifierProvider
    extends $AsyncNotifierProvider<ActiveCommunityNotifier, MyCommunities> {
  /// Komunitas aktif di Beranda. Satu komunitas → langsung aktif; beberapa →
  /// pilihan terakhir pengguna (disimpan per akun di perangkat), atau belum ada
  /// sampai pengguna memilih.
  ActiveCommunityNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: noRetry,
          name: r'activeCommunityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$activeCommunityNotifierHash();

  @$internal
  @override
  ActiveCommunityNotifier create() => ActiveCommunityNotifier();
}

String _$activeCommunityNotifierHash() =>
    r'8888f7744172f2a94de286f3c33db2a3ef8898ee';

/// Komunitas aktif di Beranda. Satu komunitas → langsung aktif; beberapa →
/// pilihan terakhir pengguna (disimpan per akun di perangkat), atau belum ada
/// sampai pengguna memilih.

abstract class _$ActiveCommunityNotifier extends $AsyncNotifier<MyCommunities> {
  FutureOr<MyCommunities> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MyCommunities>, MyCommunities>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<MyCommunities>, MyCommunities>,
        AsyncValue<MyCommunities>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

/// Hanya berubah saat akun berganti, bukan setiap profil disegarkan.

@ProviderFor(_userId)
final _userIdProvider = _UserIdProvider._();

/// Hanya berubah saat akun berganti, bukan setiap profil disegarkan.

final class _UserIdProvider
    extends $FunctionalProvider<String?, String?, String?>
    with $Provider<String?> {
  /// Hanya berubah saat akun berganti, bukan setiap profil disegarkan.
  _UserIdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'_userIdProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$_userIdHash();

  @$internal
  @override
  $ProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String? create(Ref ref) {
    return _userId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$_userIdHash() => r'e0509d43d128ea5858d90ccaa84f9408b405076b';
