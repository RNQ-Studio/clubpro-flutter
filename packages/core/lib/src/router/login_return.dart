import 'dart:convert';

import 'app_routes.dart';

/// The web engine decodes the whole URL when writing browser history. A nested
/// URI query must therefore travel as an opaque URL-safe value across reloads.
String encodeLoginReturn(String destination) =>
    'v1.${base64Url.encode(utf8.encode(destination)).replaceAll('=', '')}';

/// Accept existing bookmarked `from=/path` links as well as the reload-safe token.
/// The result is always a local application URI, never an external redirect.
String? decodeLoginReturn(String? value) {
  if (value == null || value.length > 16384) return null;
  if (value.startsWith('v1.')) {
    try {
      value = utf8
          .decode(base64Url.decode(base64Url.normalize(value.substring(3))));
    } on FormatException {
      return null;
    }
  }
  final uri = Uri.tryParse(value);
  if (!value.startsWith('/') ||
      value.startsWith('//') ||
      value.startsWith('/login') ||
      value.startsWith(AppRoutes.authCheck) ||
      value.contains('\\') ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
      uri == null ||
      uri.hasScheme ||
      uri.hasAuthority) {
    return null;
  }
  return value;
}
