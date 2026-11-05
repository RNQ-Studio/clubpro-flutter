import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';

/// Warna merek CEO.
abstract final class CommunityColors {
  static const gold = Color(0xFFBE8815);
  static const goldLight = Color(0xFFDAA727);
  static const brown = Color(0xFF5C3A02);
  static const ink = Color(0xFF2B2416);
  static const success = Color(0xFF178A5B);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, brown, gold],
    stops: [0, 0.6, 1],
  );
}

/// Garis tipis; `outlineVariant` di tema app terlalu gelap untuk ini.
Color communityHairline(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

IconData communityTypeIcon(String? type) => switch (type) {
      'panahan' => Icons.my_location_rounded,
      'sepak_bola' || 'futsal' => Icons.sports_soccer_rounded,
      'bulu_tangkis' || 'tenis' => Icons.sports_tennis_rounded,
      'basket' => Icons.sports_basketball_rounded,
      'voli' => Icons.sports_volleyball_rounded,
      'lari' => Icons.directions_run_rounded,
      'bersepeda' => Icons.directions_bike_rounded,
      'bela_diri' => Icons.sports_martial_arts_rounded,
      'pecinta_alam' => Icons.terrain_rounded,
      'fashion' => Icons.checkroom_rounded,
      'fotografi' => Icons.photo_camera_rounded,
      'otomotif' => Icons.directions_car_rounded,
      'kuliner' => Icons.restaurant_rounded,
      'musik' => Icons.music_note_rounded,
      'seni_budaya' => Icons.palette_rounded,
      'gaming' => Icons.sports_esports_rounded,
      'teknologi' => Icons.memory_rounded,
      'bisnis_umkm' => Icons.storefront_rounded,
      'pendidikan' => Icons.school_rounded,
      'sosial' => Icons.volunteer_activism_rounded,
      'keagamaan' => Icons.menu_book_rounded,
      _ => Icons.category_rounded,
    };

/// Foto profil komunitas dari [bytes] atau [url]; selain itu inisial [name].
class CommunityLogo extends StatelessWidget {
  const CommunityLogo({
    super.key,
    required this.name,
    this.url,
    this.bytes,
    this.size = 56,
  });

  final String name;
  final String? url;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(gradient: CommunityColors.heroGradient),
      child: Center(
        child: Text(
          trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    final memory = bytes;
    final network = url;
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: memory != null
            ? Image.memory(memory, fit: BoxFit.cover)
            : network != null && network.isNotEmpty
                ? CommunityNetworkImage(url: network, fallback: fallback)
                : fallback,
      ),
    );
  }
}

/// Gambar dari server. Bucket tanpa CORS tetap tampil lewat elemen `<img>` di web.
class CommunityNetworkImage extends StatelessWidget {
  const CommunityNetworkImage({
    super.key,
    required this.url,
    this.fallback,
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget? fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (context, _, __) =>
          fallback ??
          ColoredBox(
            color: communityHairline(context),
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
    );
  }
}

class CommunityTypeBadge extends StatelessWidget {
  const CommunityTypeBadge(
      {super.key, required this.type, required this.label});

  final String? type;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CommunityColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(communityTypeIcon(type), size: 13, color: CommunityColors.gold),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CommunityColors.brown,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityStatusBadge extends StatelessWidget {
  const CommunityStatusBadge({super.key, required this.status});

  final CommunityStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      CommunityStatus.pending => (
          CommunityColors.brown,
          Icons.hourglass_top_rounded
        ),
      CommunityStatus.approved => (
          CommunityColors.success,
          Icons.verified_rounded
        ),
      CommunityStatus.rejected => (
          Theme.of(context).colorScheme.error,
          Icons.cancel_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isi layar saat gagal memuat.
class CommunityErrorView extends StatelessWidget {
  const CommunityErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bingkai putus-putus untuk tempat menambah foto.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 5.0;
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
