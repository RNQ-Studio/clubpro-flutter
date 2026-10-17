import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../google_sign_in_service.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    GoogleSignInService? google,
  })  : _remote = remote,
        _local = local,
        _google = google;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final GoogleSignInService? _google;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final user = await _remote.login(email: email, password: password);
    await _local.saveUser(user);
    return user;
  }

  @override
  Future<User> loginWithGoogle() async {
    final google = _google;
    if (google == null) {
      throw StateError('GoogleSignInService belum disediakan.');
    }
    final idToken = await google.obtainIdToken();
    final result = await _remote.loginWithGoogle(idToken);
    await _local.saveUser(result.user);
    return result.user;
  }

  @override
  Future<void> clearSession() async {
    await _local.clearUser();
    await _google?.signOut();
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Fail-safe: even if backend logout fails (e.g. offline),
      // we must still clear the local user session.
    } finally {
      await _local.clearUser();
      await _google?.signOut();
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _remote.register(
      name: name,
      email: email,
      password: password,
    );
    await _local.saveUser(user);
    return user;
  }

  @override
  Future<User?> getCurrentUser() async {
    final cached = await _local.getUser();
    if (cached == null) return null;

    try {
      final fresh = await _remote.getMe();
      return _keepToken(fresh, cached);
    } catch (_) {
      // Gracefully fallback to cached user on connection failure/offline
      return cached;
    }
  }

  @override
  Future<User> updateProfile(Map<String, Object?> fields) async {
    final updated = await _remote.updateProfile(fields);
    return _keepToken(updated, await _local.getUser());
  }

  @override
  Future<User> uploadAvatar(String filePath) async {
    final updated = await _remote.uploadAvatar(filePath);
    return _keepToken(updated, await _local.getUser());
  }

  /// Data user terbaru dari server + token sesi yang sedang dipakai.
  Future<UserModel> _keepToken(UserModel fresh, UserModel? current) async {
    final merged = fresh.copyWith(token: current?.token);
    await _local.saveUser(merged);
    return merged;
  }
}
