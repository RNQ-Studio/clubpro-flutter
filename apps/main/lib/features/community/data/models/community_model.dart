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
    required super.address,
    required super.contactName,
    required super.contactPhone,
    super.contactEmail,
    super.photoUrls,
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
        address: json['address'] as String,
        contactName: json['contact_name'] as String,
        contactPhone: json['contact_phone'] as String,
        contactEmail: json['contact_email'] as String?,
        photoUrls: [
          for (final url in (json['photo_urls'] as List<dynamic>? ?? const []))
            url.toString(),
        ],
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
