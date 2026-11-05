// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminRepository)
final adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider extends $FunctionalProvider<AdminRepository,
    AdminRepository, AdminRepository> with $Provider<AdminRepository> {
  AdminRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'12eb29d4e2fada5548f55aaa1689803c3eb106bb';

/// Daftar pengguna terdaftar: cari, saring, dan muat bertahap.

@ProviderFor(AdminUsersNotifier)
final adminUsersProvider = AdminUsersNotifierProvider._();

/// Daftar pengguna terdaftar: cari, saring, dan muat bertahap.
final class AdminUsersNotifierProvider
    extends $AsyncNotifierProvider<AdminUsersNotifier, AdminUsersState> {
  /// Daftar pengguna terdaftar: cari, saring, dan muat bertahap.
  AdminUsersNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminUsersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminUsersNotifierHash();

  @$internal
  @override
  AdminUsersNotifier create() => AdminUsersNotifier();
}

String _$adminUsersNotifierHash() =>
    r'961e121401824eb0caf68159ad90253af9c21dce';

/// Daftar pengguna terdaftar: cari, saring, dan muat bertahap.

abstract class _$AdminUsersNotifier extends $AsyncNotifier<AdminUsersState> {
  FutureOr<AdminUsersState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AdminUsersState>, AdminUsersState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AdminUsersState>, AdminUsersState>,
        AsyncValue<AdminUsersState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}

/// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

@ProviderFor(AdminUserDetailNotifier)
final adminUserDetailProvider = AdminUserDetailNotifierFamily._();

/// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
final class AdminUserDetailNotifierProvider
    extends $AsyncNotifierProvider<AdminUserDetailNotifier, AdminUserDetail> {
  /// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
  /// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
  AdminUserDetailNotifierProvider._(
      {required AdminUserDetailNotifierFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'adminUserDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminUserDetailNotifierHash();

  @override
  String toString() {
    return r'adminUserDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AdminUserDetailNotifier create() => AdminUserDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is AdminUserDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$adminUserDetailNotifierHash() =>
    r'd238fe320f64891d3bb83308f25eda4562bd102a';

/// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

final class AdminUserDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
            AdminUserDetailNotifier,
            AsyncValue<AdminUserDetail>,
            AdminUserDetail,
            FutureOr<AdminUserDetail>,
            String> {
  AdminUserDetailNotifierFamily._()
      : super(
          retry: null,
          name: r'adminUserDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
  /// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

  AdminUserDetailNotifierProvider call(
    String id,
  ) =>
      AdminUserDetailNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'adminUserDetailProvider';
}

/// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.

abstract class _$AdminUserDetailNotifier
    extends $AsyncNotifier<AdminUserDetail> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  FutureOr<AdminUserDetail> build(
    String id,
  );
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AdminUserDetail>, AdminUserDetail>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AdminUserDetail>, AdminUserDetail>,
        AsyncValue<AdminUserDetail>,
        Object?,
        Object?>;
    element.handleCreate(
        ref,
        () => build(
              _$args,
            ));
  }
}
