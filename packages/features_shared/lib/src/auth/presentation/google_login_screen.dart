import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'auth_provider.dart';
import 'auth_state.dart';

/// Halaman login yang hanya menyediakan "Masuk dengan Google".
///
/// Branding (judul, keterangan, logo) disediakan app. Setelah berhasil,
/// [onLoggedIn] menentukan tujuan; bawaannya `/`.
class GoogleLoginScreen extends ConsumerStatefulWidget {
  const GoogleLoginScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.logo,
    this.onLoggedIn,
  });

  final String title;
  final String? subtitle;
  final Widget? logo;
  final void Function(BuildContext context, AuthAuthenticated state)?
      onLoggedIn;

  @override
  ConsumerState<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends ConsumerState<GoogleLoginScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = 'Versi ${info.version}+${info.buildNumber}');
      }
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        final onLoggedIn = widget.onLoggedIn;
        if (onLoggedIn != null) {
          onLoggedIn(context, next);
        } else {
          context.go('/');
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    if (widget.logo != null) ...[
                      widget.logo!,
                      const SizedBox(height: 28),
                    ],
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const Spacer(flex: 3),
                    if (authState is AuthError) ...[
                      _ErrorBanner(message: authState.message),
                      const SizedBox(height: 16),
                    ],
                    _GoogleButton(
                      isLoading: isLoading,
                      onPressed: () =>
                          ref.read(authProvider.notifier).loginWithGoogle(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Belum punya akun? Akun anggota dibuat otomatis saat '
                      'pertama kali masuk dengan Google.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_version.isNotEmpty)
                      Text(
                        _version,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        key: const Key('google-sign-in-button'),
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleMark(size: 22),
                  SizedBox(width: 12),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  TextStyle(color: colorScheme.onErrorContainer, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Huruf "G" empat warna Google, digambar vektor.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleMarkPainter());
}

class _GoogleMarkPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final rect = Rect.fromCircle(
      center: Offset(s / 2, s / 2),
      radius: (s - stroke) / 2,
    );
    Paint arc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double deg(double d) => d * 3.141592653589793 / 180;

    canvas.drawArc(rect, deg(-150), deg(110), false, arc(_red));
    canvas.drawArc(rect, deg(150), deg(60), false, arc(_yellow));
    canvas.drawArc(rect, deg(40), deg(110), false, arc(_green));
    canvas.drawArc(rect, deg(-10), deg(50), false, arc(_blue));
    // Batang horizontal G.
    canvas.drawRect(
      Rect.fromLTWH(s / 2, s / 2 - stroke / 2, s / 2 - stroke * 0.05, stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
