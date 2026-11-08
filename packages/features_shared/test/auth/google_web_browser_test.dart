// Menguji login Google pindah halaman dengan window Chrome sungguhan: alamat,
// riwayat, dan localStorage hanya ada di browser, jadi `melos run test`
// melewatinya.
//
//   flutter test --platform chrome test/auth/google_web_browser_test.dart
@TestOn('browser')
library;

import 'package:features_shared/features_shared.dart';
import 'package:features_shared/src/auth/data/google_web_browser_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import 'fake_google_web_browser.dart';

void main() {
  final page = web.window.location.href;

  tearDown(() {
    web.window.history.replaceState(null, '', page);
    web.window.localStorage.removeItem(GoogleWebSignIn.pendingKey);
  });

  test('kembalian dari Google: token diambil, alamat bersih tanpa riwayat baru',
      () {
    final browser = WindowGoogleWebBrowser();
    final signIn = GoogleWebSignIn(clientId: 'web-client', browser: browser);
    web.window.localStorage
        .setItem(GoogleWebSignIn.pendingKey, '{"state":"s1","nonce":"n1"}');
    final token = fakeIdToken({'nonce': 'n1'});
    web.window.history
        .replaceState(null, '', '/auth/google#state=s1&id_token=$token');
    final historyLength = web.window.history.length;

    signIn.capture();

    expect(signIn.takeOutcome(),
        isA<GoogleRedirectToken>().having((o) => o.idToken, 'idToken', token));
    expect(web.window.location.pathname, '/');
    expect(web.window.location.hash, '#/login');
    expect(web.window.location.href, isNot(contains(token)));
    expect(web.window.history.length, historyLength);
    expect(web.window.localStorage.getItem(GoogleWebSignIn.pendingKey), isNull);
  });

  test('alamat kembali = origin halaman + /auth/google', () {
    final browser = WindowGoogleWebBrowser();

    expect('${browser.location.origin}${GoogleWebSignIn.callbackPath}',
        '${web.window.location.origin}/auth/google');
  });
}
