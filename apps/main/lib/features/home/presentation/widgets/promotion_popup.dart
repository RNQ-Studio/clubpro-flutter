import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../branding/club_logo.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/home_banner.dart';
import '../../domain/entities/promotion_action.dart';

/// Popup Paid Promotion: slider gambar portrait sebesar ±80% layar, tombol
/// tutup di pojok kanan atas, dan tombol aksi di bawah gambar.
///
/// Selesai dengan promosi yang tombol/gambarnya diketuk, atau null bila
/// ditutup. Aksinya dijalankan pemanggil sesudah popup tertutup.
Future<HomeBanner?> showPromotionPopup(
  BuildContext context,
  List<HomeBanner> banners,
) =>
    showGeneralDialog<HomeBanner>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Tutup promosi',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, _, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, __) => PromotionPopup(
        banners: banners,
        onAction: (banner) => Navigator.of(context).pop(banner),
        onClose: () => Navigator.of(context).pop(),
      ),
    );

/// Jalankan aksi promosi: rute app ditumpuk di atas Beranda; WhatsApp dan
/// tautan lain dibuka di luar app.
Future<void> openPromotionLink(BuildContext context, String? link) async {
  if (link == null || link.isEmpty) return;
  if (PromotionActionKind.of(link) == PromotionActionKind.appPage) {
    context.push(link);
    return;
  }
  final uri = Uri.tryParse(link);
  final external = PromotionActionKind.of(link) != PromotionActionKind.none;
  if (uri == null ||
      !external ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan tidak dapat dibuka')),
      );
    }
  }
}

class PromotionPopup extends StatefulWidget {
  const PromotionPopup({
    super.key,
    required this.banners,
    required this.onAction,
    required this.onClose,
    this.interval = const Duration(seconds: 5),
  });

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onAction;
  final VoidCallback onClose;

  /// Geser otomatis; geser manual menunda geser berikutnya.
  final Duration interval;

  /// Bagian layar yang boleh ditutup popup.
  static const heightFactor = 0.8;
  static const widthFactor = 0.9;
  static const maxWidth = 460.0;

  static const _buttonHeight = 52.0;
  static const _dotsHeight = 24.0;

  /// Titik indikator sudah memberi jarak sendiri.
  static double _buttonGap({required bool hasDots}) => hasDots ? 4 : 14;

  /// Ukuran gambar portrait terbesar yang muat bersama tombol dan titik.
  static Size imageSize(
    Size screen, {
    required bool hasButton,
    required bool hasDots,
  }) {
    final chrome =
        (hasButton ? _buttonGap(hasDots: hasDots) + _buttonHeight : 0) +
            (hasDots ? _dotsHeight : 0);
    final width = math.min(screen.width * widthFactor, maxWidth);
    final height = math.max(
      0.0,
      math.min(
        width / PromotionSlide.aspectRatio,
        screen.height * heightFactor - chrome,
      ),
    );
    return Size(height * PromotionSlide.aspectRatio, height);
  }

  @override
  State<PromotionPopup> createState() => _PromotionPopupState();
}

class _PromotionPopupState extends State<PromotionPopup> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) => _goTo(_index + 1));
  }

  void _goTo(int index) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      index % widget.banners.length,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
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
    final hasButton = banners.any((banner) => banner.button != null);
    final hasDots = banners.length > 1;
    final image = PromotionPopup.imageSize(
      MediaQuery.sizeOf(context),
      hasButton: hasButton,
      hasDots: hasDots,
    );
    final current = banners[_index.clamp(0, banners.length - 1)];

    return Center(
      child: SizedBox(
        key: const Key('promotion-popup'),
        width: image.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.fromSize(
              size: image,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      // Geser dengan mouse juga, bukan hanya sentuhan.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: PointerDeviceKind.values.toSet(),
                        ),
                        child: PageView.builder(
                          key: const Key('promotion-slider'),
                          controller: _controller,
                          itemCount: banners.length,
                          onPageChanged: (i) {
                            setState(() => _index = i);
                            _restartTimer();
                          },
                          itemBuilder: (context, i) {
                            final banner = banners[i];
                            return PromotionSlide(
                              key: Key('promotion-slide-${banner.id}'),
                              banner: banner,
                              rounded: false,
                              onTap: banner.button == null
                                  ? null
                                  : () => widget.onAction(banner),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _CloseButton(onPressed: widget.onClose),
                  ),
                ],
              ),
            ),
            if (hasDots)
              SizedBox(
                height: PromotionPopup._dotsHeight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < banners.length; i++)
                      _Dot(
                        key: Key('promotion-dot-$i'),
                        active: i == _index,
                        onTap: () => _goTo(i),
                      ),
                  ],
                ),
              ),
            if (hasButton) ...[
              SizedBox(height: PromotionPopup._buttonGap(hasDots: hasDots)),
              SizedBox(
                height: PromotionPopup._buttonHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (current.button) {
                    final label? => PromotionButton(
                        key: ValueKey('promotion-button-${current.id}'),
                        label: label,
                        action: current.action,
                        onPressed: () => widget.onAction(current),
                      ),
                    // Promosi tanpa tombol: ruangnya tetap agar tidak melompat.
                    null => const SizedBox.expand(),
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol aksi di bawah gambar; juga pratinjau di form Paid Promotion.
class PromotionButton extends StatelessWidget {
  const PromotionButton({
    super.key,
    required this.label,
    required this.action,
    this.onPressed,
  });

  final String label;
  final PromotionActionKind action;
  final VoidCallback? onPressed;

  /// Hijau WhatsApp yang masih terbaca dengan teks putih.
  static const whatsappGreen = Color(0xFF168B45);

  @override
  Widget build(BuildContext context) {
    final whatsapp = action == PromotionActionKind.whatsapp;
    return SizedBox(
      width: double.infinity,
      height: PromotionPopup._buttonHeight,
      child: FilledButton.icon(
        key: const Key('promotion-button'),
        style: FilledButton.styleFrom(
          backgroundColor: whatsapp ? whatsappGreen : null,
          foregroundColor: whatsapp ? Colors.white : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(switch (action) {
          PromotionActionKind.whatsapp => Icons.chat_rounded,
          PromotionActionKind.web => Icons.open_in_new_rounded,
          _ => Icons.arrow_forward_rounded,
        }),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white54),
      ),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        key: const Key('promotion-close'),
        tooltip: 'Tutup',
        onPressed: onPressed,
        color: Colors.white,
        icon: const Icon(Icons.close_rounded),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({super.key, required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}

/// Satu gambar promosi portrait; juga pratinjau di form Paid Promotion.
/// Gambar beda rasio tidak terpotong: tampil utuh di atas versi buramnya.
class PromotionSlide extends StatelessWidget {
  const PromotionSlide({
    super.key,
    required this.banner,
    this.onTap,
    this.imageBytes,
    this.rounded = true,
  });

  /// Lebar : tinggi (2:3, mis. 1080×1620).
  static const aspectRatio = 2 / 3;

  static const _gradient = [Color(0xFF5C3A02), Color(0xFFBE8815)];

  final HomeBanner banner;
  final VoidCallback? onTap;

  /// Foto yang baru dipilih, sebelum diunggah.
  final Uint8List? imageBytes;

  /// False bila pembungkusnya sudah membulatkan sudut.
  final bool rounded;

  Widget _image(BoxFit fit) {
    final bytes = imageBytes;
    if (bytes != null) return Image.memory(bytes, fit: fit);
    return CommunityNetworkImage(
      url: banner.imageUrl!,
      fit: fit,
      fallback: const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = banner.imageUrl;
    final hasImage = imageBytes != null || (url != null && url.isNotEmpty);
    final subtitle = banner.subtitle;
    final hasSubtitle = subtitle != null && subtitle.isNotEmpty;
    // Foto yang sudah bertulisan tidak ditimpa teks maupun gradasi gelap.
    final hasText = banner.title.isNotEmpty || hasSubtitle;

    final slide = Material(
      color: _gradient.first,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _gradient,
                ),
              ),
            ),
            if (hasImage) ...[
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: _image(BoxFit.cover),
              ),
              const ColoredBox(color: Color(0x40000000)),
              _image(BoxFit.contain),
            ] else
              const Center(
                child: Opacity(
                  opacity: 0.3,
                  child: ClubLogo(size: 160, fadeEdges: true),
                ),
              ),
            if (hasText) ...[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xAA000000)],
                    stops: [0.55, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (banner.title.isNotEmpty)
                      Text(
                        banner.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return rounded
        ? ClipRRect(borderRadius: BorderRadius.circular(20), child: slide)
        : slide;
  }
}
