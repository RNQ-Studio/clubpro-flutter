import '../../../community/domain/entities/community.dart';
import '../../domain/entities/admin_community.dart';

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

AdminCommunityPerson? _person(Object? json) => json is Map<String, dynamic>
    ? AdminCommunityPerson(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      )
    : null;

class AdminCommunityModel extends AdminCommunity {
  const AdminCommunityModel({
    required super.id,
    required super.name,
    required super.shortName,
    required super.type,
    required super.typeLabel,
    required super.status,
    required super.cityName,
    required super.provinceName,
    super.logoUrl,
    super.createdAt,
    super.reviewedAt,
    super.submitter,
  });

  factory AdminCommunityModel.fromJson(Map<String, dynamic> json) =>
      AdminCommunityModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        shortName: json['short_name'] as String,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String,
        status: CommunityStatus.fromApi(json['status']),
        cityName: json['city_name'] as String,
        provinceName: json['province_name'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: _time(json['created_at']),
        reviewedAt: _time(json['reviewed_at']),
        submitter: _person(json['submitter']),
      );
}

class AdminCommunityDetailModel extends AdminCommunityDetail {
  const AdminCommunityDetailModel({
    required super.id,
    required super.name,
    required super.shortName,
    required super.type,
    required super.typeLabel,
    required super.status,
    required super.cityName,
    required super.provinceName,
    super.logoUrl,
    super.createdAt,
    super.reviewedAt,
    super.submitter,
    required super.description,
    required super.address,
    required super.contactName,
    required super.contactPhone,
    super.contactEmail,
    super.photoUrls,
    super.reviewNote,
    super.reviewer,
  });

  factory AdminCommunityDetailModel.fromJson(Map<String, dynamic> json) =>
      AdminCommunityDetailModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        shortName: json['short_name'] as String,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String,
        status: CommunityStatus.fromApi(json['status']),
        cityName: json['city_name'] as String,
        provinceName: json['province_name'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: _time(json['created_at']),
        reviewedAt: _time(json['reviewed_at']),
        submitter: _person(json['submitter']),
        description: json['description'] as String,
        address: json['address'] as String,
        contactName: json['contact_name'] as String,
        contactPhone: json['contact_phone'] as String,
        contactEmail: json['contact_email'] as String?,
        photoUrls: [
          for (final url in (json['photo_urls'] as List<dynamic>? ?? const []))
            url.toString(),
        ],
        reviewNote: json['review_note'] as String?,
        reviewer: _person(json['reviewer']),
      );
}

AdminCommunitySummary adminCommunitySummaryFromJson(
  Map<String, dynamic> json,
) =>
    AdminCommunitySummary(
      total: json['total'] as int,
      pending: json['pending'] as int,
      approved: json['approved'] as int,
      rejected: json['rejected'] as int,
    );

/// `GET v1/admin/summary`.
AdminPanelSummary adminPanelSummaryFromJson(Map<String, dynamic> json) =>
    AdminPanelSummary(
      totalUsers: (json['users'] as Map<String, dynamic>)['total'] as int,
      communities: adminCommunitySummaryFromJson(
        json['communities'] as Map<String, dynamic>,
      ),
    );

/// `GET v1/admin/communities`: `data` + `meta.pagination` + `meta.summary`.
AdminCommunitiesPage adminCommunitiesPageFromJson(Map<String, dynamic> json) {
  final meta = json['meta'] as Map<String, dynamic>;
  final pagination = meta['pagination'] as Map<String, dynamic>;
  return AdminCommunitiesPage(
    communities: [
      for (final community in json['data'] as List<dynamic>)
        AdminCommunityModel.fromJson(community as Map<String, dynamic>),
    ],
    summary: adminCommunitySummaryFromJson(
      meta['summary'] as Map<String, dynamic>,
    ),
    currentPage: pagination['current_page'] as int,
    lastPage: pagination['last_page'] as int,
  );
}
