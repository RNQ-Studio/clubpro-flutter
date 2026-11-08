import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';

import '../features/home/presentation/widgets/home_app_version.dart';
import 'club_brand.dart';
import 'club_logo.dart';

/// Halaman awal sebelum login: hanya nama app dan kepanjangannya, tombol
/// Google, serta versi dan tombol perbarui paksa ke versi web terbaru.
/// Selalu bertema gelap hitam-emas, apa pun tema perangkat.
class ClubLoginPage extends StatelessWidget {
  const ClubLoginPage({super.key, this.onLoggedIn});

  final void Function(BuildContext context, AuthAuthenticated state)?
      onLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: GoogleLoginScreen(
        title: ClubBrand.name,
        header: const ClubLoginHero(),
        background: const ClubLoginBackdrop(),
        footer: const HomeAppVersion(),
        signupHint: null,
        onLoggedIn: onLoggedIn,
      ),
    );
  }
}

/// Kepala halaman login: logo bercahaya, "CEO", dan kepanjangannya. Muncul
/// perlahan saat halaman dibuka.
class ClubLoginHero extends StatelessWidget {
  const ClubLoginHero({super.key});

  static const logoSize = 116.0;

  /// Huruf "CEO" bergradasi seperti emblem emas di logo.
  static const _goldText = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8E6A8), ClubBrand.gold, ClubBrand.goldDeep],
    stops: [0, 0.55, 1],
  );

  static const _nameSpacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 16), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(logoSize * 0.22),
              boxShadow: [
                BoxShadow(
                  color: ClubBrand.gold.withValues(alpha: 0.42),
                  blurRadius: 72,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const ClubLogo(size: logoSize),
          ),
          const SizedBox(height: 36),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: _goldText.createShader,
            // Jarak huruf juga ditambahkan sesudah huruf terakhir; diimbangi
            // agar tetap di tengah.
            child: const Padding(
              padding: EdgeInsets.only(left: _nameSpacing),
              child: Text(
                ClubBrand.name,
                key: Key('login-brand-name'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 60,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: _nameSpacing,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(
                colors: [
                  Color(0x00BE8815),
                  ClubBrand.gold,
                  Color(0x00BE8815),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            ClubBrand.tagline.toUpperCase(),
            key: const Key('login-brand-tagline'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

/// Latar halaman login: hitam hangat dengan cahaya emas lembut di atas.
class ClubLoginBackdrop extends StatelessWidget {
  const ClubLoginBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15110A), Color(0xFF0B0A08), Color(0xFF050505)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.45),
            radius: 0.9,
            colors: [Color(0x40BE8815), Color(0x00BE8815)],
          ),
        ),
      ),
    );
  }
}
