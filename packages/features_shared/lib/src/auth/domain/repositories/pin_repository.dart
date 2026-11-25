import '../entities/user.dart';

abstract interface class PinRepository {
  Future<bool> emailRecoveryAvailable();
  Future<User> login(String identifier, String pin);
  Future<void> save(String pin,
      {String? currentPin,
      String? currentPassword,
      String? verificationMethod,
      bool useRecentGoogleAuth = false});
  Future<void> recover(String identifier);
  Future<void> reset(String identifier, String code, String pin);
}
