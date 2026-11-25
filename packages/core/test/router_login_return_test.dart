import 'dart:convert';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final destination in [
    '/wallet',
    '/wallet/payouts?manage=1&community=1',
    '/wallet/payouts?manage=1',
    '/wallet/payouts/fixture/parts/part/proof',
    '/wallet?scope=community&community=1',
    '/explore?search=Nama%20Anggota%26Lain&community=7#bagian',
  ]) {
    test('return token survives actual web engine decoding: $destination', () {
      final token = encodeLoginReturn(destination);
      expect(token, matches(r'^v1\.[A-Za-z0-9_-]+$'));
      final uri =
          Uri(path: '/login', queryParameters: {'from': token, 'reauth': '1'});
      // Matches installed engine window.dart routeInformationUpdated serializer.
      final browserLocation = Uri.decodeComponent(
          Uri(path: uri.path, queryParameters: uri.queryParametersAll)
              .toString());
      final afterReload = Uri.parse(browserLocation);
      expect(
          decodeLoginReturn(afterReload.queryParameters['from']), destination);
      expect(afterReload.queryParameters['reauth'], '1');
      expect(decodeLoginReturn(destination), destination);
    });
  }
  for (final value in [
    'v1.not_base64!',
    'v1._w',
    '//outside.invalid',
    '/login?from=/',
    '/auth/check?from=/',
    'https://anaklangit.manahpro.web.id',
    '/\\outside.invalid',
    '/wallet\n'
  ]) {
    test('unsafe or malformed return rejected: ${value.codeUnits}', () {
      expect(decodeLoginReturn(value), null);
      expect(
          decodeLoginReturn(
              'v1.${base64Url.encode(utf8.encode(value)).replaceAll('=', '')}'),
          null);
    });
  }
}
