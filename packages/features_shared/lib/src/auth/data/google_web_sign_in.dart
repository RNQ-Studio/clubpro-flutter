import 'dart:convert';
import 'dart:math';

import 'package:core/core.dart';

import 'google_sign_in_service.dart';
import 'google_web_browser.dart';

/// Hasil kembali dari halaman masuk Google (lihat [GoogleWebSignIn.capture]).
sealed class GoogleRedirectOutcome {
  const GoogleRedirectOutcome();
}

/// Google mengembalikan ID token untuk ditukar ke backend.
final class GoogleRedirectToken extends GoogleRedirectOutcome {
  const GoogleRedirectToken(this.idToken);

  final String idToken;
}

/// Masuk dibatalkan ([GoogleSignInCancelled]) atau gagal ([ServerException]).
final class GoogleRedirectFailure extends GoogleRedirectOutcome {
  const GoogleRedirectFailure(this.error);

  final Exception error;
}

/// Akses browser untuk [GoogleWebSignIn]; diganti tiruan saat test.
abstract interface class GoogleWebBrowser {
  Uri get location;

  void navigate(Uri url);

  /// Ganti alamat tanpa menambah riwayat.
  void replace(Uri url);

  String? read(String key);

  void write(String key, String value);

  void remove(String key);

  /// Halaman dipulihkan dari back-forward cache (kembali dari Google).
  Stream<void> get restored;
}

/// Login Google di web dengan pindah halaman ke Google lalu kembali (OpenID
/// Connect, `response_type=id_token`), tanpa popup.
///
/// Tombol Google resmi (GIS) membuka tab baru, dan Google kini mengalihkan
/// sebagian sesi browser ke alur FedCM yang di HP Android bisa berhenti di tab
/// putih kosong (`gsi/fedcm/signincontinue`). Pengalihan halaman penuh tidak
/// bergantung pada popup maupun FedCM.
///
/// `<origin app>` + [callbackPath] wajib terdaftar di "Authorized redirect
/// URIs" Web client di Google Cloud Console.
class GoogleWebSignIn {
  GoogleWebSignIn({
    required String? clientId,
    required GoogleWebBrowser browser,
    Random? random,
  })  : _clientId = clientId,
        _browser = browser,
        _random = random ?? Random.secure();

  /// Null di luar web.
  static GoogleWebSignIn? forPlatform() {
    final browser = platformGoogleWebBrowser();
    if (browser == null) return null;
    return GoogleWebSignIn(
      clientId: AppConfig.instance.googleServerClientId,
      browser: browser,
    );
  }

  static const callbackPath = '/auth/google';
  static const pendingKey = 'google_sign_in.pending';

  final String? _clientId;
  final GoogleWebBrowser _browser;
  final Random _random;
  GoogleRedirectOutcome? _outcome;

  bool get isConfigured => _clientId != null;

  Stream<void> get restored => _browser.restored;

  /// Pindah ke pemilih akun Google. Sesudah memilih, app dimuat ulang di
  /// [callbackPath] dan hasilnya dibaca [capture].
  void start() {
    final clientId = _clientId;
    if (clientId == null) {
      throw const ServerException(
        'Login Google belum dikonfigurasi di aplikasi ini. Hubungi pengurus komunitas.',
      );
    }
    final state = _randomToken();
    final nonce = _randomToken();
    _browser.write(pendingKey, jsonEncode({'state': state, 'nonce': nonce}));
    _browser.navigate(Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': '${_browser.location.origin}$callbackPath',
      'response_type': 'id_token',
      'scope': 'openid email profile',
      'prompt': 'select_account',
      'state': state,
      'nonce': nonce,
    }));
  }

  /// Panggil sekali sebelum router dibuat. Bila halaman ini kembalian dari
  /// Google, hasilnya disimpan untuk [takeOutcome] dan alamatnya diganti ke
  /// halaman login, agar token tidak tertinggal di alamat maupun riwayat.
  void capture() {
    final location = _browser.location;
    if (location.path != callbackPath) return;
    final pending = _browser.read(pendingKey);
    _browser.remove(pendingKey);
    _browser.replace(Uri(path: '/', fragment: '/login'));
    _outcome = _parse(Uri.splitQueryString(location.fragment), pending);
  }

  /// Hasil [capture], sekali ambil.
  GoogleRedirectOutcome? takeOutcome() {
    final outcome = _outcome;
    _outcome = null;
    return outcome;
  }

  static GoogleRedirectOutcome _parse(
    Map<String, String> params,
    String? pendingJson,
  ) {
    final error = params['error'];
    if (error != null) {
      return GoogleRedirectFailure(error == 'access_denied'
          ? const GoogleSignInCancelled()
          : ServerException('Login Google gagal ($error). Coba lagi.'));
    }

    // state: hasil ini dari permintaan yang dibuat app ini, di browser ini.
    final pending = _decodeMap(pendingJson);
    if (pending == null || params['state'] != pending['state']) {
      return const GoogleRedirectFailure(
        ServerException('Sesi login Google kedaluwarsa. Silakan masuk lagi.'),
      );
    }
    final idToken = params['id_token'];
    if (idToken == null || idToken.isEmpty) {
      return const GoogleRedirectFailure(
        ServerException('Google tidak mengirim token login. Coba lagi.'),
      );
    }
    // nonce: token ini diterbitkan untuk permintaan tersebut, bukan disisipkan.
    if (_decodeMap(_jwtPayload(idToken))?['nonce'] != pending['nonce']) {
      return const GoogleRedirectFailure(
        ServerException('Token login Google tidak cocok. Silakan masuk lagi.'),
      );
    }
    return GoogleRedirectToken(idToken);
  }

  static String? _jwtPayload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    } on FormatException {
      return null;
    }
  }

  static Map<String, dynamic>? _decodeMap(String? json) {
    if (json == null) return null;
    try {
      final value = jsonDecode(json);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  String _randomToken() => base64Url
      .encode(List<int>.generate(32, (_) => _random.nextInt(256)))
      .replaceAll('=', '');
}
