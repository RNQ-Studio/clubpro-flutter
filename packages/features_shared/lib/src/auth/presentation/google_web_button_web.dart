import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

// Satu instance: `renderButton` memakai hashCode konfigurasi sebagai key,
// instance baru per build akan membuat ulang tombolnya.
final _configuration = gsi.GSIButtonConfiguration(
  type: gsi.GSIButtonType.standard,
  theme: gsi.GSIButtonTheme.outline,
  size: gsi.GSIButtonSize.large,
  text: gsi.GSIButtonText.signinWith,
  shape: gsi.GSIButtonShape.pill,
  locale: 'id',
);

/// Tombol "Masuk dengan Google" resmi (Google Identity Services). ID token
/// hasilnya datang lewat `GoogleSignInService.webIdTokens`.
Widget googleWebButton() => gsi.renderButton(configuration: _configuration);
