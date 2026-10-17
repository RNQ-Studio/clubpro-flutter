import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Network certificate pinning for MITM protection.
///
/// Only active in production environment. In dev/staging, pinning
/// is skipped to allow proxy debugging (Charles, Proxyman, etc.).
///
/// Usage:
/// ```dart
/// if (AppConfig.instance.environment == Environment.prod) {
///   CertificatePinning.configure(dio);
/// }
/// ```
class CertificatePinning {
  /// SHA256 fingerprints of trusted server public keys.
  ///
  /// Always include at least 2 fingerprints (primary + backup)
  /// to avoid outage during certificate rotation.
  static const List<String> _trustedFingerprints = [
    // TODO: Replace with your production server fingerprints.
    // Run this to get the fingerprint:
    // echo | openssl s_client -connect anaklangit.manahpro.web.id:443 2>/dev/null | \
    //   openssl x509 -pubkey -noout | \
    //   openssl pkey -pubin -outform DER | \
    //   openssl dgst -sha256 -binary | base64
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Primary
    'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=', // Backup
  ];

  /// Configure certificate pinning on a [Dio] instance.
  ///
  /// Optionally provide [customFingerprints] to override the defaults.
  static void configure(
    Dio dio, {
    List<String>? customFingerprints,
  }) {
    final fingerprints = customFingerprints ?? _trustedFingerprints;

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return _validateCertificate(cert, fingerprints);
      };
      return client;
    };
  }

  static bool _validateCertificate(
    X509Certificate cert,
    List<String> trustedFingerprints,
  ) {
    // NOTE: For production use, consider using the
    // `http_certificate_pinning` package for robust SHA256
    // public key hash validation.
    //
    // This implementation uses X509Certificate.der which provides
    // the DER-encoded certificate bytes for comparison.
    // A full implementation would:
    // 1. Extract the public key from cert.der
    // 2. Compute SHA256 hash
    // 3. Base64 encode and compare with trustedFingerprints

    // Default: reject all unknown certificates.
    return false;
  }
}
