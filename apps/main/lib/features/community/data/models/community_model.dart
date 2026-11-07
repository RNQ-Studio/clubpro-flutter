import '../../domain/entities/community.dart';

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

class CommunityModel extends Community {
  const CommunityModel({
    required super.id,
    required super.name,
    required super.shortName,
    required super.type,
    required super.typeLabel,
    required super.status,
    required super.cityName,
    required super.provinceName,
    required super.description,
    super.logoUrl,
    super.createdAt,
    super.myRole,
    super.myStatus,
    super.membersCount,
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) => CommunityModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        shortName: json['short_name'] as String,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String,
        status: CommunityStatus.fromApi(json['status']),
        cityName: json['city_name'] as String,
        provinceName: json['province_name'] as String,
        description: json['description'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: _time(json['created_at']),
        myRole: CommunityRole.fromApi(json['my_role']),
        myStatus: CommunityMembershipStatus.fromApi(json['my_status']),
        membersCount: json['members_count'] as int?,
      );
}

class CommunityDetailModel extends CommunityDetail {
  const CommunityDetailModel({
    required super.id,
    required super.name,
    required super.shortName,
    required super.type,
    required super.typeLabel,
    required super.status,
    required super.cityName,
    required super.provinceName,
    required super.description,
    super.logoUrl,
    super.createdAt,
    super.myRole,
    super.membersCount,
    required super.address,
    required super.contactName,
    required super.contactPhone,
    super.contactEmail,
    super.photoUrls,
    super.reviewNote,
    super.photos,
    super.isMember,
    super.isJoinPending,
    super.canManage,
    super.pendingMembersCount,
    super.upcomingActivitiesCount,
  });

  factory CommunityDetailModel.fromJson(Map<String, dynamic> json) =>
      CommunityDetailModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        shortName: json['short_name'] as String,
        type: json['type'] as String,
        typeLabel: json['type_label'] as String,
        status: CommunityStatus.fromApi(json['status']),
        cityName: json['city_name'] as String,
        provinceName: json['province_name'] as String,
        description: json['description'] as String,
        logoUrl: json['logo_url'] as String?,
        createdAt: _time(json['created_at']),
        myRole: CommunityRole.fromApi(json['my_role']),
        membersCount: json['members_count'] as int?,
        address: json['address'] as String,
        contactName: json['contact_name'] as String,
        contactPhone: json['contact_phone'] as String,
        contactEmail: json['contact_email'] as String?,
        reviewNote: json['review_note'] as String?,
        photoUrls: [
          for (final url in (json['photo_urls'] as List<dynamic>? ?? const []))
            url.toString(),
        ],
        photos: [
          for (final photo in (json['photos'] as List<dynamic>? ?? const []))
            CommunityPhoto(
              id: (photo as Map<String, dynamic>)['id'].toString(),
              url: photo['url'] as String,
            ),
        ],
        isMember: json['my_status'] == 'active',
        isJoinPending: json['my_status'] == 'pending',
        canManage: json['can_manage'] == true,
        pendingMembersCount: json['pending_members_count'] as int? ?? 0,
        upcomingActivitiesCount: json['upcoming_activities_count'] as int? ?? 0,
      );
}

CommunityTypeOption communityTypeFromJson(Map<String, dynamic> json) =>
    CommunityTypeOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );

RegionProvince regionProvinceFromJson(Map<String, dynamic> json) =>
    RegionProvince(
      code: json['code'] as String,
      name: json['name'] as String,
      cities: [
        for (final city in json['cities'] as List<dynamic>)
          RegionCity(
            code: (city as Map<String, dynamic>)['code'] as String,
            name: city['name'] as String,
          ),
      ],
    );

/// `GET v1/communities`: `data` + `meta.pagination`.
CommunitiesPage communitiesPageFromJson(Map<String, dynamic> json) {
  final meta = json['meta'] as Map<String, dynamic>;
  final pagination = meta['pagination'] as Map<String, dynamic>;
  return CommunitiesPage(
    communities: [
      for (final community in json['data'] as List<dynamic>)
        CommunityModel.fromJson(community as Map<String, dynamic>),
    ],
    currentPage: pagination['current_page'] as int,
    lastPage: pagination['last_page'] as int,
  );
}

CommunityMember communityMemberFromJson(Map<String, dynamic> json) =>
    CommunityMember(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'] as String,
      role: CommunityRole.fromApi(json['role']) ?? CommunityRole.member,
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: _time(json['joined_at']),
      requestedAt: _time(json['requested_at']),
    );

/// `GET v1/communities/{id}/members`: `data` + `meta.pagination`.
CommunityMembersPage communityMembersPageFromJson(Map<String, dynamic> json) {
  final meta = json['meta'] as Map<String, dynamic>;
  final pagination = meta['pagination'] as Map<String, dynamic>;
  return CommunityMembersPage(
    members: [
      for (final member in json['data'] as List<dynamic>)
        communityMemberFromJson(member as Map<String, dynamic>),
    ],
    currentPage: pagination['current_page'] as int,
    lastPage: pagination['last_page'] as int,
  );
}

CommunityActivity communityActivityFromJson(Map<String, dynamic> json) =>
    CommunityActivity(
      id: json['id'].toString(),
      title: json['title'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      description: json['description'] as String?,
      location: json['location'] as String?,
    );

CommunityActivities communityActivitiesFromJson(Map<String, dynamic> json) =>
    CommunityActivities(
      upcoming: [
        for (final item in json['upcoming'] as List<dynamic>)
          communityActivityFromJson(item as Map<String, dynamic>),
      ],
      past: [
        for (final item in json['past'] as List<dynamic>)
          communityActivityFromJson(item as Map<String, dynamic>),
      ],
    );

CommunityMemberProfile communityMemberProfileFromJson(
  Map<String, dynamic> json,
) =>
    CommunityMemberProfile(
      id: json['id'].toString(),
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      registeredAt: _time(json['registered_at']),
      communities: [
        for (final item in json['communities'] as List<dynamic>)
          SharedCommunity(
            id: (item as Map<String, dynamic>)['id'].toString(),
            name: item['name'] as String,
            role: CommunityRole.fromApi(item['role']) ?? CommunityRole.member,
            logoUrl: item['logo_url'] as String?,
            joinedAt: _time(item['joined_at']),
          ),
      ],
    );
