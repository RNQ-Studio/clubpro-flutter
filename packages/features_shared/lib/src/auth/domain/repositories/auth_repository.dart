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

  /// Simpan sebagian data diri: hanya kunci di [fields] yang diubah
  /// (kunci API, mis. `birth_date`); nilai kosong mengosongkan isian.
  Future<User> updateProfile(Map<String, Object?> fields);
  Future<User> uploadAvatar(String filePath);
}
