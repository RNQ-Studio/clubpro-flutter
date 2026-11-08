import 'package:core/core.dart';

import '../../../home/domain/entities/promotion_action.dart';

/// Status tayang dari server; jadwal yang diatur di back-office ikut dihitung.
enum AdminBannerStatus {
  live('Tayang'),
  inactive('Nonaktif'),
  scheduled('Terjadwal'),
  ended('Jadwal berakhir');

  const AdminBannerStatus(this.label);

  final String label;

  static AdminBannerStatus fromApi(Object? value) => values.firstWhere(
        (status) => status.name == value,
        orElse: () => AdminBannerStatus.inactive,
      );
}

/// Aksi tombol di bawah gambar promosi, disimpan sebagai `link_url`. Sama dengan
/// `Banner::APP_LINK_PATTERN` dan `Banner::WHATSAPP_LINK_PATTERN` di server.
enum AdminBannerLinkType {
  none('Tanpa tombol'),
  whatsapp('Chat WhatsApp'),
  external('Buka tautan di browser'),
  communities('Halaman app: Daftar Komunitas'),
  community('Halaman app: Komunitas tertentu'),
  createCommunity('Halaman app: Daftarkan Komunitas'),
  profile('Halaman app: Profil Saya');

  const AdminBannerLinkType(this.label);

  final String label;

  static final _communityPattern = RegExp(r'^/communities/([1-9][0-9]*)$');

  static AdminBannerLinkType of(String? link) {
    if (link == null || link.isEmpty) return none;
    if (link == AppRoutes.communities) return communities;
    if (link == AppRoutes.createCommunity) return createCommunity;
    if (link == AppRoutes.profile) return profile;
    if (communityId(link) != null) return community;
    if (PromotionActionKind.of(link) == PromotionActionKind.whatsapp) {
      return whatsapp;
    }
    return external;
  }

  /// Id komunitas bila [link] menuju halaman klub tertentu.
  static String? communityId(String? link) =>
      _communityPattern.firstMatch(link ?? '')?.group(1);

  /// Tautan untuk tujuan tetap; null untuk tujuan yang butuh isian.
  String? get fixedLink => switch (this) {
        none => null,
        communities => AppRoutes.communities,
        createCommunity => AppRoutes.createCommunity,
        profile => AppRoutes.profile,
        community || external || whatsapp => null,
      };

  /// Usulan label tombol saat aksi ini dipilih.
  String get suggestedLabel => switch (this) {
        none => '',
        whatsapp => PromotionActionKind.whatsapp.defaultLabel,
        external => PromotionActionKind.web.defaultLabel,
        communities => 'Cari Komunitas',
        community => 'Lihat Komunitas',
        createCommunity => 'Daftarkan Komunitas',
        profile => 'Lihat Profil',
      };
}

class AdminBannerCommunity {
  const AdminBannerCommunity({required this.id, required this.name});

  final String id;
  final String name;
}

class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.title,
    required this.isActive,
    required this.status,
    this.subtitle,
    this.imageUrl,
    this.linkUrl,
    this.buttonLabel,
    this.linkCommunity,
    this.startsAt,
    this.endsAt,
  });

  final String id;

  /// Kosong untuk foto yang sudah bertulisan.
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? linkUrl;

  /// Null = label bawaan sesuai aksi (data lama).
  final String? buttonLabel;

  /// Null bila tujuannya bukan komunitas, atau komunitasnya sudah terhapus.
  final AdminBannerCommunity? linkCommunity;
  final bool isActive;
  final AdminBannerStatus status;

  /// Jadwal tayang, hanya bisa diatur di back-office.
  final DateTime? startsAt;
  final DateTime? endsAt;

  AdminBannerLinkType get linkType => AdminBannerLinkType.of(linkUrl);

  /// Tujuan tombol untuk baris daftar.
  String get linkLabel => switch (linkType) {
        AdminBannerLinkType.community =>
          linkCommunity?.name ?? 'Komunitas tidak ditemukan',
        AdminBannerLinkType.external => linkUrl!,
        AdminBannerLinkType.whatsapp => 'WhatsApp '
            '${PromotionAction.formatWhatsappNumber(PromotionAction.whatsappNumber(linkUrl) ?? '')}',
        final type => type.label,
      };

  /// Label tombol seperti yang tampil di popup; null = tanpa tombol.
  String? get button {
    final kind = PromotionActionKind.of(linkUrl);
    if (kind == PromotionActionKind.none) return null;
    final label = buttonLabel?.trim() ?? '';
    return label.isEmpty ? kind.defaultLabel : label;
  }
}

class AdminBannerSummary {
  const AdminBannerSummary({
    required this.total,
    required this.live,
    required this.maxVisible,
    this.intervalHours = 24,
  });

  /// Batas jeda di server (`Banner::MAX_INTERVAL_HOURS`).
  static const maxIntervalHours = 720;

  final int total;
  final int live;

  /// Promosi terbanyak di popup Beranda.
  final int maxVisible;

  /// Popup tampil lagi di perangkat yang sama sesudah sekian jam.
  final int intervalHours;
}

class AdminBanners {
  const AdminBanners({required this.banners, required this.summary});

  /// Sesuai urutan tampil di Beranda.
  final List<AdminBanner> banners;
  final AdminBannerSummary summary;
}

/// Isian form; [imageAssetId] null saat foto tidak diganti.
class AdminBannerInput {
  const AdminBannerInput({
    required this.title,
    required this.subtitle,
    required this.linkUrl,
    required this.isActive,
    this.buttonLabel = '',
    this.imageAssetId,
  });

  final String title;
  final String subtitle;
  final String? linkUrl;
  final String buttonLabel;
  final bool isActive;
  final String? imageAssetId;

  Map<String, Object?> toPayload() {
    final title = this.title.trim();
    final subtitle = this.subtitle.trim();
    final link = linkUrl?.trim();
    final hasLink = link != null && link.isNotEmpty;
    final label = buttonLabel.trim();
    return {
      // Kolom teks selalu dikirim: server menolak permintaan tanpa kolom ini.
      'title': title.isEmpty ? null : title,
      'subtitle': subtitle.isEmpty ? null : subtitle,
      'link_url': hasLink ? link : null,
      // Tanpa aksi tidak ada tombol.
      'button_label': hasLink && label.isNotEmpty ? label : null,
      'is_active': isActive,
      if (imageAssetId != null) 'image_asset_id': imageAssetId,
    };
  }
}
