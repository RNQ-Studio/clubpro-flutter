import '../../domain/entities/admin_banner.dart';

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

AdminBanner adminBannerFromJson(Map<String, dynamic> json) {
  final community = json['link_community'];
  return AdminBanner(
    id: json['id'].toString(),
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String?,
    imageUrl: json['image_url'] as String?,
    linkUrl: json['link_url'] as String?,
    buttonLabel: json['button_label'] as String?,
    linkCommunity: community is Map<String, dynamic>
        ? AdminBannerCommunity(
            id: community['id'].toString(),
            name: community['name'] as String,
          )
        : null,
    isActive: json['is_active'] as bool,
    status: AdminBannerStatus.fromApi(json['status']),
    startsAt: _time(json['starts_at']),
    endsAt: _time(json['ends_at']),
  );
}

AdminBannerSummary adminBannerSummaryFromJson(Map<String, dynamic> json) =>
    AdminBannerSummary(
      total: json['total'] as int,
      live: json['live'] as int,
      maxVisible: json['max_visible'] as int,
      // Server lama tanpa jeda popup → bawaan server.
      intervalHours: json['interval_hours'] as int? ?? 24,
    );

/// `GET v1/admin/banners`: `data` + `meta.summary`.
AdminBanners adminBannersFromJson(Map<String, dynamic> json) => AdminBanners(
      banners: [
        for (final banner in json['data'] as List<dynamic>)
          adminBannerFromJson(banner as Map<String, dynamic>),
      ],
      summary: adminBannerSummaryFromJson(
        (json['meta'] as Map<String, dynamic>)['summary']
            as Map<String, dynamic>,
      ),
    );
