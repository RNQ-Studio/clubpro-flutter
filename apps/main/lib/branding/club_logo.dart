import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo Anak Langit Archery: target panahan berwarna standar World Archery
/// (putih, hitam, biru, merah, emas) dengan anak panah menancap, di atas
/// latar langit. Digambar vektor agar tajam di semua ukuran; ikon launcher
/// dirender dari painter yang sama (`tool/render_launcher_icons_test.dart`).
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, this.size = 80, this.withBackground = true});

  final double size;

  /// `false` = hanya target + panah, untuk diletakkan di atas latar sendiri.
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child:
          CustomPaint(painter: ClubLogoPainter(withBackground: withBackground)),
    );
  }
}

class ClubLogoPainter extends CustomPainter {
  const ClubLogoPainter({this.withBackground = true, this.cornerRadius = 0.22});

  final bool withBackground;

  /// Radius sudut latar, relatif terhadap sisi (0 = persegi penuh).
  final double cornerRadius;

  static const skyTop = Color(0xFF0B2A5B);
  static const skyMid = Color(0xFF1E6FD9);
  static const skyBottom = Color(0xFF7CC4FF);

  // Urutan cincin dari luar ke dalam: 2 putih, 2 hitam, 2 biru, 2 merah, 2 emas.
  static const _ringColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
    Color(0xFF1C1C1E),
    Color(0xFF1C1C1E),
    Color(0xFF2F80ED),
    Color(0xFF2F80ED),
    Color(0xFFE5383B),
    Color(0xFFE5383B),
    Color(0xFFFFC72C),
    Color(0xFFFFC72C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size.square(s);

    if (withBackground) {
      final background = RRect.fromRectAndRadius(
        rect,
        Radius.circular(s * cornerRadius),
      );
      canvas.drawRRect(
        background,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skyTop, skyMid, skyBottom],
            stops: [0, 0.55, 1],
          ).createShader(rect),
      );
    }

    final center = Offset(s * 0.47, s * 0.53);
    final radius = s * (withBackground ? 0.33 : 0.46);

    // Bayangan lembut agar target "berdiri" di atas langit.
    if (withBackground) {
      canvas.drawCircle(
        center.translate(0, s * 0.015),
        radius * 1.02,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
      );
    }

    for (var i = 0; i < _ringColors.length; i++) {
      final r = radius * (_ringColors.length - i) / _ringColors.length;
      canvas.drawCircle(center, r, Paint()..color = _ringColors[i]);
      // Garis pemisah cincin: gelap di zona putih, terang di zona hitam.
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.004
          ..color = i < 2
              ? const Color(0xFF8E8E93)
              : Colors.white.withValues(alpha: i < 4 ? 0.55 : 0.35),
      );
    }

    // Anak panah menancap di tengah, datang dari kanan atas.
    final angle = -math.pi / 4;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final tip = center + direction * (radius * 0.04);
    final tail = center + direction * (s * (withBackground ? 0.52 : 0.62));
    final shaftWidth = s * 0.03;

    canvas.drawLine(
      tip,
      tail,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..strokeWidth = shaftWidth * 1.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      tip,
      tail,
      Paint()
        ..color = const Color(0xFFF5F5F7)
        ..strokeWidth = shaftWidth
        ..strokeCap = StrokeCap.round,
    );

    // Bulu panah (fletching): dua sirip di dekat ekor.
    final normal = Offset(-direction.dy, direction.dx);
    final fletchPaint = Paint()..color = const Color(0xFFFF8A00);
    for (final side in [1.0, -1.0]) {
      // Lebar di belakang (dekat nock), meruncing ke arah mata panah.
      final rear = tail - direction * (s * 0.025);
      final wide = tail - direction * (s * 0.05) + normal * (side * s * 0.05);
      final front = tail - direction * (s * 0.15);
      final path = Path()
        ..moveTo(rear.dx, rear.dy)
        ..lineTo(wide.dx, wide.dy)
        ..lineTo(front.dx, front.dy)
        ..close();
      canvas.drawPath(path, fletchPaint);
    }

    // Titik tancap: lingkaran kecil gelap di pusat emas.
    canvas.drawCircle(
      tip,
      shaftWidth * 0.75,
      Paint()..color = const Color(0xFF3A2A00),
    );
  }

  @override
  bool shouldRepaint(covariant ClubLogoPainter oldDelegate) =>
      oldDelegate.withBackground != withBackground ||
      oldDelegate.cornerRadius != cornerRadius;
}
