import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/datasources/auth_local_data_source.dart';
import '../data/google_sign_in_service.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_notifier.dart';

part 'auth_repository_provider.g.dart';

/// Must be overridden at app scope with a real [StorageService] implementation.
@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  throw UnimplementedError(
      'storageServiceProvider must be overridden in app scope');
}

@Riverpod(keepAlive: true)
DioClient _dioClient(Ref ref) {
  return DioClient(
    ref.watch(storageServiceProvider),
    // Refresh token ditolak → akhiri sesi agar router membuka /login.
    onLogout: () => ref.read(authProvider.notifier).sessionExpired(),
  );
}

/// Klien API bersama untuk fitur app (mis. Beranda): token otomatis, refresh,
/// dan sesi kedaluwarsa → kembali ke login.
@Riverpod(keepAlive: true)
DioClient apiClient(Ref ref) => ref.watch(_dioClientProvider);

@Riverpod(keepAlive: true)
GoogleSignInService googleSignInService(Ref ref) {
  return GoogleSignInService(
    serverClientId: AppConfig.instance.googleServerClientId,
  );
}

@Riverpod(keepAlive: true)
AuthRemoteDataSource _authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSource(ref.watch(_dioClientProvider).dio);
}

@Riverpod(keepAlive: true)
AuthLocalDataSource _authLocalDataSource(Ref ref) {
  return AuthLocalDataSource(ref.watch(storageServiceProvider));
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(_authRemoteDataSourceProvider),
    local: ref.watch(_authLocalDataSourceProvider),
    google: ref.watch(googleSignInServiceProvider),
  );
}
