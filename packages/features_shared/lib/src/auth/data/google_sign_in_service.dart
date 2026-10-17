import 'package:core/core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Pengguna menutup/membatalkan pemilih akun Google — bukan error.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Membungkus `google_sign_in` v7: memastikan `initialize` dipanggil sekali
/// dengan [serverClientId] (Web client ID) agar ID token ber-audiens backend.
class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? signIn, String? serverClientId})
      : _signIn = signIn ?? GoogleSignIn.instance,
        _serverClientId = serverClientId;

  final GoogleSignIn _signIn;
  final String? _serverClientId;
  Future<void>? _initialization;

  bool get isConfigured => _serverClientId != null;

  /// Tampilkan pemilih akun Google lalu kembalikan ID token untuk backend.
  ///
  /// Melempar [GoogleSignInCancelled] bila dibatalkan, atau [ServerException]
  /// berpesan bahasa Indonesia untuk kegagalan lain.
  Future<String> obtainIdToken() async {
    if (!isConfigured) {
      throw const ServerException(
        'Login Google belum dikonfigurasi di aplikasi ini. Hubungi pengurus club.',
      );
    }

    try {
      await (_initialization ??=
          _signIn.initialize(serverClientId: _serverClientId));
      final account = await _signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const ServerException(
          'Google tidak mengirim token login. Coba lagi.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      _initialization =
          e.code == GoogleSignInExceptionCode.clientConfigurationError
              ? null
              : _initialization;
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted =>
          const GoogleSignInCancelled(),
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          const ServerException(
            'Konfigurasi login Google tidak valid. Hubungi pengurus club.',
          ),
        GoogleSignInExceptionCode.uiUnavailable => const ServerException(
            'Pemilih akun Google tidak dapat dibuka di perangkat ini.',
          ),
        _ => ServerException(
            'Login Google gagal: ${e.description ?? e.code.name}',
          ),
      };
    }
  }

  /// Agar login berikutnya menampilkan pemilih akun lagi.
  Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await _signIn.signOut();
    } catch (_) {
      // Logout lokal tetap berjalan walau Google gagal sign-out.
    }
  }
}
