import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});

  /// Pemilih akun Google → token backend. Melempar `GoogleSignInCancelled`
  /// bila pengguna membatalkan.
  Future<User> loginWithGoogle();

  /// Hapus sesi lokal tanpa memanggil server (token sudah tidak sah).
  Future<void> clearSession();

  Future<void> logout();
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });
  Future<User?> getCurrentUser();
  Future<User> updateProfile({required String name, required String email});
  Future<User> uploadAvatar(String filePath);
}
