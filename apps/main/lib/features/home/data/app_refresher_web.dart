import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../domain/app_refresher.dart';

AppRefresher? createAppRefresher() => WebAppRefresher();

/// Ikon di layar utama HP tidak punya tombol muat ulang, dan tab sering hanya
/// dilanjutkan dari memori. Login tersimpan di localStorage, jadi tidak tersentuh.
class WebAppRefresher implements AppRefresher {
  WebAppRefresher({
    this.files = const [
      'index.html',
      'flutter_bootstrap.js',
      'flutter.js',
      'main.dart.js',
      'version.json',
    ],
    void Function()? reload,
  }) : _reload = reload ?? (() => web.window.location.reload());

  final List<String> files;
  final void Function() _reload;

  @override
  Future<void> refresh() async {
    // Unduh dulu: tanpa koneksi, memuat ulang halaman akan mematikan app.
    await Future.wait(files.map(_download));
    await _clearServiceWorkers();
    await _clearCacheStorage();
    _reload();
  }

  /// `cache: 'reload'` melewati cache HTTP dan menggantikan isinya.
  Future<void> _download(String file) async {
    final response = await web.window
        .fetch(file.toJS, web.RequestInit(cache: 'reload'))
        .toDart;
    if (!response.ok) {
      throw Exception('Gagal mengunduh $file (${response.status})');
    }
  }

  // Browser dalam aplikasi lain bisa tidak punya kedua API di bawah; muat ulang
  // tetap berguna tanpanya.
  Future<void> _clearServiceWorkers() async {
    try {
      final registrations =
          await web.window.navigator.serviceWorker.getRegistrations().toDart;
      for (final registration in registrations.toDart) {
        await registration.unregister().toDart;
      }
    } catch (_) {}
  }

  Future<void> _clearCacheStorage() async {
    try {
      final keys = await web.window.caches.keys().toDart;
      for (final key in keys.toDart) {
        await web.window.caches.delete(key.toDart).toDart;
      }
    } catch (_) {}
  }
}
