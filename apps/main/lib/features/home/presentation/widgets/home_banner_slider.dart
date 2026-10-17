import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../branding/club_logo.dart';
import '../../domain/entities/home_banner.dart';

/// Banner slider Beranda: geser manual atau otomatis tiap [interval].
class HomeBannerSlider extends StatefulWidget {
  const HomeBannerSlider({
    super.key,
    required this.banners,
    required this.onTap,
    this.interval = const Duration(seconds: 5),
  });

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onTap;
  final Duration interval;

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  // Latar banner tanpa gambar: warna-warna cincin target.
  static const _gradients = [
    [Color(0xFF0B2A5B), Color(0xFF1E6FD9)],
    [Color(0xFF7A1F1F), Color(0xFFD62F33)],
    [Color(0xFF6B4A00), Color(0xFFC98A00)],
    [Color(0xFF0F4D35), Color(0xFF178A5B)],
  ];

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant HomeBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = 0;
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 8,
          child: PageView.builder(
            key: const Key('home-banner-slider'),
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _restartTimer(); // geser manual menunda geser otomatis berikutnya
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BannerCard(
                banner: banners[i],
                gradient: _gradients[i % _gradients.length],
                onTap: () => widget.onTap(banners[i]),
              ),
            ),
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _index
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.gradient,
    required this.onTap,
  });

  final HomeBanner banner;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = banner.imageUrl;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    final text = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          banner.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
            height: 1.2,
          ),
        ),
        if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            banner.subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: gradient.first,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
              if (hasImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              else
                const Positioned(
                  right: -18,
                  bottom: -18,
                  child: Opacity(
                    opacity: 0.22,
                    child: ClubLogo(size: 150, withBackground: false),
                  ),
                ),
              // Gradasi gelap bawah agar teks terbaca di atas gambar.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0x99000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 48, 16),
                child: text,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
