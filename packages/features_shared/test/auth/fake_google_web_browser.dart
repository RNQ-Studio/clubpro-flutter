import 'dart:async';
import 'dart:convert';

import 'package:features_shared/features_shared.dart';

/// Browser tiruan untuk [GoogleWebSignIn]: mencatat pindah halaman dan
/// penggantian alamat.
class FakeGoogleWebBrowser implements GoogleWebBrowser {
  FakeGoogleWebBrowser([String url = 'https://ceo-pro.web.app/#/login'])
      : location = Uri.parse(url);

  @override
  Uri location;
  final storage = <String, String>{};
  final navigated = <Uri>[];
  final replaced = <Uri>[];
  final restoredController = StreamController<void>.broadcast();

  @override
  void navigate(Uri url) => navigated.add(url);

  @override
  void replace(Uri url) => replaced.add(url);

  @override
  String? read(String key) => storage[key];

  @override
  void write(String key, String value) => storage[key] = value;

  @override
  void remove(String key) => storage.remove(key);

  @override
  Stream<void> get restored => restoredController.stream;
}

/// ID token tiruan (tanda tangan palsu) dengan [payload].
String fakeIdToken(Map<String, Object?> payload) {
  String part(Map<String, Object?> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'RS256'})}.${part(payload)}.c2lnbmF0dXJl';
}
