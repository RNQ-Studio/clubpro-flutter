import 'promotion_action.dart';

/// Satu slide popup Paid Promotion di Beranda (dari Admin Panel).
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    this.buttonLabel,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> json) => HomeBanner(
        id: json['id'].toString(),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String?,
        linkUrl: json['link_url'] as String?,
        buttonLabel: json['button_label'] as String?,
      );

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  /// Aksi tombol: rute app (`/…`), chat WhatsApp (`https://wa.me/…`), atau
  /// tautan https yang dibuka di browser.
  final String? linkUrl;

  /// Null/kosong → label bawaan sesuai aksi.
  final String? buttonLabel;

  PromotionActionKind get action => PromotionActionKind.of(linkUrl);

  /// Label tombol di bawah gambar; null = tanpa tombol.
  String? get button {
    final kind = action;
    if (kind == PromotionActionKind.none) return null;
    final label = buttonLabel?.trim() ?? '';
    return label.isEmpty ? kind.defaultLabel : label;
  }
}

/// Isi popup Paid Promotion beserta jedanya.
class HomePromotions {
  const HomePromotions({
    this.banners = const [],
    this.intervalHours = defaultIntervalHours,
  });

  /// Sama dengan `Banner::DEFAULT_INTERVAL_HOURS` di server.
  static const defaultIntervalHours = 24;

  /// Sudah terurut; kosong = popup tidak tampil.
  final List<HomeBanner> banners;

  /// Popup tampil lagi di perangkat yang sama sesudah sekian jam.
  final int intervalHours;

  /// Popup layak tampil bila belum pernah, atau sudah lewat [intervalHours]
  /// sejak terakhir tampil. Jam perangkat mundur → dianggap belum lewat.
  bool isDue(DateTime? lastShown, DateTime now) {
    if (banners.isEmpty) return false;
    if (lastShown == null) return true;
    return !now.difference(lastShown).isNegative &&
        now.difference(lastShown) >= Duration(hours: intervalHours);
  }
}
