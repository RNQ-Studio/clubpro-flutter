import 'dart:convert';

import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_google_web_browser.dart';

const clientId = 'web-client.apps.googleusercontent.com';

void main() {
  late FakeGoogleWebBrowser browser;
  late GoogleWebSignIn signIn;

  setUp(() {
    browser = FakeGoogleWebBrowser();
    signIn = GoogleWebSignIn(clientId: clientId, browser: browser);
  });

  /// Mulai masuk, lalu kembali ke app seperti yang dilakukan Google.
  GoogleRedirectOutcome? returnFromGoogle(
    String Function(Map<String, String> request) fragment,
  ) {
    signIn.start();
    final request = browser.navigated.single.queryParameters;
    browser.location =
        Uri.parse('https://ceo-pro.web.app/auth/google#${fragment(request)}');
    signIn.capture();
    return signIn.takeOutcome();
  }

  String tokenFor(Map<String, String> request) =>
      fakeIdToken({'nonce': request['nonce'], 'email': 'rina@gmail.com'});

  test('mulai: pindah ke pemilih akun Google, tanpa popup', () {
    signIn.start();

    final url = browser.navigated.single;
    expect(url.origin, 'https://accounts.google.com');
    expect(url.path, '/o/oauth2/v2/auth');
    expect(url.queryParameters, containsPair('client_id', clientId));
    expect(url.queryParameters,
        containsPair('redirect_uri', 'https://ceo-pro.web.app/auth/google'));
    expect(url.queryParameters, containsPair('response_type', 'id_token'));
    expect(url.queryParameters, containsPair('scope', 'openid email profile'));
    expect(url.queryParameters, containsPair('prompt', 'select_account'));

    final pending = jsonDecode(browser.storage[GoogleWebSignIn.pendingKey]!);
    expect(pending['state'], url.queryParameters['state']);
    expect(pending['nonce'], url.queryParameters['nonce']);
    expect(url.queryParameters['state'], hasLength(greaterThanOrEqualTo(43)));
    expect(url.queryParameters['nonce'], isNot(url.queryParameters['state']));
  });

  test('state & nonce acak tiap kali mulai', () {
    signIn.start();
    signIn.start();

    final [first, second] = browser.navigated;
    expect(
        first.queryParameters['state'], isNot(second.queryParameters['state']));
    expect(
        first.queryParameters['nonce'], isNot(second.queryParameters['nonce']));
  });

  test('alamat kembali mengikuti origin app (mis. uji lokal)', () {
    browser.location = Uri.parse('http://localhost:5055/#/login');

    signIn.start();

    expect(browser.navigated.single.queryParameters['redirect_uri'],
        'http://localhost:5055/auth/google');
  });

  test('tanpa Web client ID: belum dikonfigurasi, tidak pindah halaman', () {
    final unconfigured = GoogleWebSignIn(clientId: null, browser: browser);

    expect(unconfigured.isConfigured, isFalse);
    expect(
      unconfigured.start,
      throwsA(isA<ServerException>().having(
          (e) => e.message, 'message', contains('belum dikonfigurasi'))),
    );
    expect(browser.navigated, isEmpty);
  });

  test('kembali dengan ID token → token; alamat & sesi tertunda dibersihkan',
      () {
    late String token;
    final outcome = returnFromGoogle((request) {
      token = tokenFor(request);
      return 'state=${request['state']}&id_token=$token&authuser=0';
    });

    expect(outcome,
        isA<GoogleRedirectToken>().having((o) => o.idToken, 'idToken', token));
    expect(browser.replaced.single.toString(), '/#/login');
    expect(browser.storage, isEmpty);
    // Sekali ambil.
    expect(signIn.takeOutcome(), isNull);
  });

  test('bukan alamat kembalian → tidak ada hasil, tidak ada yang diubah', () {
    browser.storage[GoogleWebSignIn.pendingKey] = '{"state":"s","nonce":"n"}';
    browser.location = Uri.parse('https://ceo-pro.web.app/#/login');

    signIn.capture();

    expect(signIn.takeOutcome(), isNull);
    expect(browser.replaced, isEmpty);
    expect(browser.storage, isNotEmpty);
  });

  test('dibatalkan di halaman Google → batal tanpa pesan', () {
    final outcome = returnFromGoogle(
        (request) => 'error=access_denied&state=${request['state']}');

    expect(
      outcome,
      isA<GoogleRedirectFailure>()
          .having((o) => o.error, 'error', isA<GoogleSignInCancelled>()),
    );
    expect(browser.replaced.single.toString(), '/#/login');
  });

  for (final (label, fragment, message) in [
    (
      'galat lain dari Google',
      (Map<String, String> r) => 'error=server_error&state=${r['state']}',
      'Login Google gagal (server_error)',
    ),
    (
      'state berbeda (bukan permintaan app ini)',
      (Map<String, String> r) =>
          'state=lain&id_token=${fakeIdToken({'nonce': r['nonce']})}',
      'kedaluwarsa',
    ),
    (
      'tanpa ID token',
      (Map<String, String> r) => 'state=${r['state']}',
      'tidak mengirim token',
    ),
    (
      'nonce berbeda (token disisipkan)',
      (Map<String, String> r) =>
          'state=${r['state']}&id_token=${fakeIdToken({'nonce': 'lain'})}',
      'tidak cocok',
    ),
    (
      'ID token rusak',
      (Map<String, String> r) => 'state=${r['state']}&id_token=bukan.jwt',
      'tidak cocok',
    ),
  ]) {
    test('$label → gagal dengan pesan', () {
      final outcome = returnFromGoogle(fragment);

      expect(
        outcome,
        isA<GoogleRedirectFailure>().having(
          (o) => o.error,
          'error',
          isA<ServerException>()
              .having((e) => e.message, 'message', contains(message)),
        ),
      );
      expect(browser.storage, isEmpty);
    });
  }

  test('sesi tertunda hilang (browser lain/dibersihkan) → minta masuk lagi',
      () {
    browser.location = Uri.parse(
        'https://ceo-pro.web.app/auth/google#state=s&id_token=${fakeIdToken({
          'nonce': 'n'
        })}');

    signIn.capture();

    expect(
      signIn.takeOutcome(),
      isA<GoogleRedirectFailure>()
          .having((o) => o.error.toString(), 'error', contains('kedaluwarsa')),
    );
  });
}
