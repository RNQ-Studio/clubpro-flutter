import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/biometric_auth_service.dart';
import '../domain/usecases/get_current_user_use_case.dart';
import '../domain/usecases/login_use_case.dart';
import '../domain/usecases/logout_use_case.dart';
import '../domain/usecases/register_use_case.dart';
import 'auth_repository_provider.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  late GetCurrentUserUseCase _getCurrentUser;
  late LoginUseCase _login;
  late LogoutUseCase _logout;
  late RegisterUseCase _register;

  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    _getCurrentUser = GetCurrentUserUseCase(repo);
    _login = LoginUseCase(repo);
    _logout = LogoutUseCase(repo);
    _register = RegisterUseCase(repo);
    return const AuthInitial();
  }

  /// Call this once during app bootstrap to restore a cached session.
  Future<void> checkCurrentUser() async {
    state = const AuthLoading();
    try {
      final user = await _getCurrentUser();
      state =
          user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final user = await _login(email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user =
          await _register(name: name, email: email, password: password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await _logout();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> updateUserProfile({
    required String name,
    required String email,
  }) async {
    if (state is! AuthAuthenticated) return;

    final repository = ref.read(authRepositoryProvider);
    try {
      final updatedUser =
          await repository.updateProfile(name: name, email: email);
      state = AuthAuthenticated(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  /// Authenticate using device biometrics (fingerprint / Face ID).
  ///
  /// Only works when the user already has a valid cached session (token).
  /// If biometric verification succeeds, restores the session via
  /// [checkCurrentUser].
  Future<void> loginWithBiometric() async {
    state = const AuthLoading();

    final biometricService = ref.read(biometricAuthServiceProvider);
    final isSupported = await biometricService.isDeviceSupported();

    if (!isSupported) {
      state = const AuthError('Biometric tidak didukung di perangkat ini');
      return;
    }

    final authenticated = await biometricService.authenticate(
      localizedReason: 'Verifikasi identitas Anda untuk masuk',
    );

    if (authenticated) {
      // Biometric passed — try to restore cached session.
      await checkCurrentUser();
    } else {
      state = const AuthError('Verifikasi biometric gagal');
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    if (state is! AuthAuthenticated) return;

    final repository = ref.read(authRepositoryProvider);
    try {
      final updatedUser = await repository.uploadAvatar(filePath);
      state = AuthAuthenticated(updatedUser);
    } catch (e) {
      rethrow;
    }
  }
}
