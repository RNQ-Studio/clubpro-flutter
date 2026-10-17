abstract class AppConfig {
  static late AppConfig instance;

  String get baseUrl;
  Environment get environment;

  /// Web client ID OAuth Google (serverClientId) untuk login Google; audiens
  /// ID token yang diverifikasi backend. Diisi saat build:
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`.
  /// `null` = login Google belum dikonfigurasi.
  String? get googleServerClientId =>
      _googleServerClientId.isEmpty ? null : _googleServerClientId;
}

const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

enum Environment {
  dev,
  staging,
  prod;

  factory Environment.fromString(String value) {
    return switch (value) {
      'staging' => Environment.staging,
      'prod' => Environment.prod,
      _ => Environment.dev,
    };
  }
}
