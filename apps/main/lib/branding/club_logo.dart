import 'package:flutter/material.dart';

/// Logo CEO: emblem teratai emas bertuliskan "CEO" di atas latar emas.
///
/// Sumber resolusi penuh ada di `tool/brand/logo-ceo.jpeg`; aset app
/// (`assets/branding/logo_ceo.jpg`, 512px) dan ikon launcher/web dibuat
/// darinya (`tool/render_launcher_icons_test.dart`). Gambar tidak punya
/// transparansi, jadi selalu tampil dengan latar emasnya sendiri.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, this.size = 80, this.fadeEdges = false});

  static const asset = 'assets/branding/logo_ceo.jpg';

  /// Warna latar logo, dipakai selama gambar dimuat.
  static const placeholderColor = Color(0xFFBE8815);

  final double size;

  /// `true` = tepi memudar radial (tanpa sudut ubin), untuk watermark di atas
  /// latar lain; emblem di tengah tetap utuh.
  final bool fadeEdges;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      cacheWidth: (size * dpr).round(),
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Logo CEO',
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
          wasSynchronouslyLoaded || frame != null
              ? child
              : ColoredBox(color: placeholderColor, child: child),
    );

    if (fadeEdges) {
      return SizedBox.square(
        dimension: size,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const RadialGradient(
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.55, 0.72],
          ).createShader(rect),
          child: image,
        ),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: image,
      ),
    );
  }
}
