import 'package:core/core.dart';

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

/// Halaman yang dibuka saat banner diketuk, disimpan sebagai `link_url`.
/// Sama dengan `Banner::APP_LINK_PATTERN` di server.
enum AdminBannerLinkType {
  none('Tidak membuka apa pun'),
  communities('Daftar Komunitas'),
  community('Komunitas tertentu'),
  createCommunity('Daftarkan Komunitas'),
  profile('Profil Saya'),
  external('Tautan luar (situs web)');

  const AdminBannerLinkType(this.label);

  final String label;

  static final _communityPattern = RegExp(r'^/communities/([1-9][0-9]*)$');

  static AdminBannerLinkType of(String? link) {
    if (link == null || link.isEmpty) return none;
    if (link == AppRoutes.communities) return communities;
    if (link == AppRoutes.createCommunity) return createCommunity;
    if (link == AppRoutes.profile) return profile;
    if (communityId(link) != null) return community;
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
        community || external => null,
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

  /// Null bila tujuannya bukan komunitas, atau komunitasnya sudah terhapus.
  final AdminBannerCommunity? linkCommunity;
  final bool isActive;
  final AdminBannerStatus status;

  /// Jadwal tayang, hanya bisa diatur di back-office.
  final DateTime? startsAt;
  final DateTime? endsAt;

  AdminBannerLinkType get linkType => AdminBannerLinkType.of(linkUrl);

  /// Tujuan ketuk untuk baris daftar.
  String get linkLabel => switch (linkType) {
        AdminBannerLinkType.community =>
          linkCommunity?.name ?? 'Komunitas tidak ditemukan',
        AdminBannerLinkType.external => linkUrl!,
        final type => type.label,
      };
}

class AdminBannerSummary {
  const AdminBannerSummary({
    required this.total,
    required this.live,
    required this.maxVisible,
  });

  final int total;
  final int live;

  /// Banner terbanyak di slider Beranda.
  final int maxVisible;
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
    this.imageAssetId,
  });

  final String title;
  final String subtitle;
  final String? linkUrl;
  final bool isActive;
  final String? imageAssetId;

  Map<String, Object?> toPayload() {
    final title = this.title.trim();
    final subtitle = this.subtitle.trim();
    final link = linkUrl?.trim();
    return {
      // Kolom teks selalu dikirim: server menolak permintaan tanpa kolom ini.
      'title': title.isEmpty ? null : title,
      'subtitle': subtitle.isEmpty ? null : subtitle,
      'link_url': link == null || link.isEmpty ? null : link,
      'is_active': isActive,
      if (imageAssetId != null) 'image_asset_id': imageAssetId,
    };
  }
}
