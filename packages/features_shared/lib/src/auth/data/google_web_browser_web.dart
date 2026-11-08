import 'package:web/web.dart' as web;

import 'google_web_sign_in.dart';

GoogleWebBrowser? platformGoogleWebBrowser() => WindowGoogleWebBrowser();

/// `localStorage`, bukan `sessionStorage`: dari ikon di layar utama HP,
/// halaman Google bisa terbuka di jendela lain sebelum kembali ke app.
class WindowGoogleWebBrowser implements GoogleWebBrowser {
  @override
  Uri get location => Uri.parse(web.window.location.href);

  @override
  void navigate(Uri url) => web.window.location.assign(url.toString());

  @override
  void replace(Uri url) =>
      web.window.history.replaceState(null, '', url.toString());

  @override
  String? read(String key) => web.window.localStorage.getItem(key);

  @override
  void write(String key, String value) =>
      web.window.localStorage.setItem(key, value);

  @override
  void remove(String key) => web.window.localStorage.removeItem(key);

  @override
  Stream<void> get restored => web.EventStreamProviders.pageShowEvent
      .forTarget(web.window)
      .where((event) => (event as web.PageTransitionEvent).persisted);
}
