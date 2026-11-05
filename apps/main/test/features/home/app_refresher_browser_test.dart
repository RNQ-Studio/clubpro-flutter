// Menguji tombol Perbarui Aplikasi di Chrome sungguhan: API-nya hanya ada di browser,
// jadi `melos run test` melewatinya.
//
//   flutter test --platform chrome test/features/home/app_refresher_browser_test.dart
@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:app_main/features/home/data/app_refresher_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

Future<List<String>> _cacheNames() async {
  final keys = await web.window.caches.keys().toDart;
  return [for (final key in keys.toDart) key.toDart];
}

Future<void> _seedCache() => web.window.caches.open('versi-lama').toDart;

void main() {
  const token = 'token-login';
  final page = web.window.location.href;

  setUp(() {
    web.window.localStorage.setItem('sesi', token);
  });

  tearDown(() {
    web.window.localStorage.removeItem('sesi');
  });

  test('membuang Cache Storage lalu memuat ulang, login tetap ada', () async {
    await _seedCache();
    expect(await _cacheNames(), contains('versi-lama'));
    var reloads = 0;

    await WebAppRefresher(files: [page], reload: () => reloads++).refresh();

    expect(reloads, 1);
    expect(await _cacheNames(), isEmpty);
    expect(web.window.localStorage.getItem('sesi'), token);
  });

  test('tanpa koneksi: tidak memuat ulang dan cache lama tetap ada', () async {
    await _seedCache();
    var reloads = 0;

    await expectLater(
      WebAppRefresher(
        files: ['http://127.0.0.1:9/tidak-terjangkau.js'],
        reload: () => reloads++,
      ).refresh(),
      throwsA(anything),
    );

    expect(reloads, 0);
    expect(await _cacheNames(), contains('versi-lama'));
    await web.window.caches.delete('versi-lama').toDart;
  });

  test('file yang gagal diunduh (404) dianggap gagal', () async {
    var reloads = 0;
    final missing = Uri.parse(page).resolve('tidak-ada-${page.hashCode}.js');

    await expectLater(
      WebAppRefresher(files: [missing.toString()], reload: () => reloads++)
          .refresh(),
      throwsA(anything),
    );

    expect(reloads, 0);
  });
}
