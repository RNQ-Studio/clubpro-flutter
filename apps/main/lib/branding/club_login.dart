import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/widgets/home_app_version.dart';
import 'club_brand.dart';
import 'club_logo.dart';

/// Pembuka CEO dengan identitas hitam–emas dan akses masuk yang ringkas.
class ClubLoginPage extends StatelessWidget {
  const ClubLoginPage({super.key, this.onLoggedIn});

  final void Function(BuildContext context, AuthAuthenticated state)?
      onLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark.copyWith(
        colorScheme: AppTheme.dark.colorScheme.copyWith(
          primary: const Color(0xFFE4C580),
          onPrimary: const Color(0xFF171510),
          surface: const Color(0xFF181A1B),
          onSurface: const Color(0xFFF5F2EA),
          outlineVariant: const Color(0xFF3B3C3B),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF5F2EA),
            minimumSize: const Size(0, 50),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            side: const BorderSide(color: Color(0xFF3B3C3B)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: GoogleLoginScreen(
        title: ClubBrand.name,
        header: const ClubLoginHero(),
        background: const ClubLoginBackdrop(),
        contentBuilder: (context, header, actions) =>
            _ClubLoginLayout(header: header, actions: actions),
        footer: const _LoginOptions(),
        signupHint: null,
        onLoggedIn: onLoggedIn,
      ),
    );
  }
}

class _ClubLoginLayout extends StatelessWidget {
  const _ClubLoginLayout({required this.header, required this.actions});

  final Widget header;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900 &&
            MediaQuery.textScalerOf(context).scale(16) <= 20.8;
        final inset = constraints.maxWidth < 400 ? 20.0 : 32.0;
        final identity = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 44 : 24,
            vertical: wide ? 56 : 28,
          ),
          child: header,
        );
        final signIn = Padding(
          padding: EdgeInsets.all(wide ? 40 : 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: actions,
          ),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(inset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  (constraints.maxHeight - inset * 2).clamp(0, double.infinity),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 1000 : 440),
                  child: Container(
                    key: const Key('login-panel'),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF181A1B),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF333432)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 48,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: wide
                        ? Stack(
                            children: [
                              const Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.5,
                                  child: _IdentityPanel(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          right: BorderSide(
                                              color: Color(0xFF333432)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(child: identity),
                                  Expanded(child: Center(child: signIn)),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _IdentityPanel(child: identity),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFF333432),
                              ),
                              Center(child: signIn),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const HomeAppVersion(),
              ],
            ),
          ),
        );
      }),
    ));
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23221D), Color(0xFF151716)],
          ),
        ),
        child: child,
      );
}

class _LoginOptions extends StatelessWidget {
  const _LoginOptions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodButton(
          icon: Icons.dialpad_rounded,
          label: 'Masuk dengan PIN',
          onPressed: () =>
              context.push(authMethodLocation(context, '/login/pin')),
        ),
        const SizedBox(height: 10),
        _MethodButton(
          icon: Icons.lock_outline_rounded,
          label: 'Masuk dengan Password',
          onPressed: () =>
              context.push(authMethodLocation(context, '/login/password')),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFF333432)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push('/explore'),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Jelajahi sebagai Pengunjung',
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFFB6B7B1)),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFFB6B7B1)),
          ],
        ),
      );
}

/// Identitas statis: tetap terbaca pada frame pertama di perangkat lambat.
class ClubLoginHero extends StatelessWidget {
  const ClubLoginHero({super.key});

  static const logoSize = 80.0;
  static const _nameSpacing = 8.0;

  @override
  Widget build(BuildContext context) => Column(
        key: const Key('login-identity'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClubLogo(size: logoSize),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: _nameSpacing),
            child: Text(
              ClubBrand.name,
              key: Key('login-brand-name'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 52,
                height: 1.05,
                fontWeight: FontWeight.w500,
                letterSpacing: _nameSpacing,
                color: Color(0xFFE4C580),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 270),
            child: Text(
              ClubBrand.tagline.toUpperCase(),
              key: const Key('login-brand-tagline'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.8,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.4,
                color: Color(0xFFB6B7B1),
              ),
            ),
          ),
        ],
      );
}

/// Latar arang lembut agar identitas dan pilihan masuk tetap menjadi fokus.
class ClubLoginBackdrop extends StatelessWidget {
  const ClubLoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -0.8),
            radius: 1.5,
            colors: [Color(0xFF24231F), Color(0xFF0D1011)],
          ),
        ),
      );
}
