// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Must be overridden at app scope with a real [StorageService] implementation.

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

/// Must be overridden at app scope with a real [StorageService] implementation.

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  /// Must be overridden at app scope with a real [StorageService] implementation.
  StorageServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'storageServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'787d32136255490cfbade7b1c0582ed63386b00b';

@ProviderFor(_dioClient)
final _dioClientProvider = _DioClientProvider._();

final class _DioClientProvider
    extends $FunctionalProvider<DioClient, DioClient, DioClient>
    with $Provider<DioClient> {
  _DioClientProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'_dioClientProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$_dioClientHash();

  @$internal
  @override
  $ProviderElement<DioClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DioClient create(Ref ref) {
    return _dioClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DioClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DioClient>(value),
    );
  }
}

String _$_dioClientHash() => r'a005edf1935e40cd4ff045e6a242c57efd4f2d35';

@ProviderFor(googleSignInService)
final googleSignInServiceProvider = GoogleSignInServiceProvider._();

final class GoogleSignInServiceProvider extends $FunctionalProvider<
    GoogleSignInService,
    GoogleSignInService,
    GoogleSignInService> with $Provider<GoogleSignInService> {
  GoogleSignInServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'googleSignInServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$googleSignInServiceHash();

  @$internal
  @override
  $ProviderElement<GoogleSignInService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoogleSignInService create(Ref ref) {
    return googleSignInService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoogleSignInService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoogleSignInService>(value),
    );
  }
}

String _$googleSignInServiceHash() =>
    r'7c5e1b61240a2acb5a2d5cfd32741be2171deec2';

@ProviderFor(_authRemoteDataSource)
final _authRemoteDataSourceProvider = _AuthRemoteDataSourceProvider._();

final class _AuthRemoteDataSourceProvider extends $FunctionalProvider<
    AuthRemoteDataSource,
    AuthRemoteDataSource,
    AuthRemoteDataSource> with $Provider<AuthRemoteDataSource> {
  _AuthRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'_authRemoteDataSourceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$_authRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRemoteDataSource create(Ref ref) {
    return _authRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDataSource>(value),
    );
  }
}

String _$_authRemoteDataSourceHash() =>
    r'c957d8eb810290121f8512b71032239ebcff888a';

@ProviderFor(_authLocalDataSource)
final _authLocalDataSourceProvider = _AuthLocalDataSourceProvider._();

final class _AuthLocalDataSourceProvider extends $FunctionalProvider<
    AuthLocalDataSource,
    AuthLocalDataSource,
    AuthLocalDataSource> with $Provider<AuthLocalDataSource> {
  _AuthLocalDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'_authLocalDataSourceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$_authLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthLocalDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthLocalDataSource create(Ref ref) {
    return _authLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthLocalDataSource>(value),
    );
  }
}

String _$_authLocalDataSourceHash() =>
    r'5de44b07b2fca0e849bc1caa381d4333ec7bdb67';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'220747c5facff8f0fb5492754fb64da0ab783650';
