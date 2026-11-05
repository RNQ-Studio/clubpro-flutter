/// Status pengajuan. Hanya [approved] yang tampil di daftar umum.
enum CommunityStatus {
  pending('pending', 'Menunggu Verifikasi'),
  approved('approved', 'Terverifikasi'),
  rejected('rejected', 'Ditolak');

  const CommunityStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static CommunityStatus fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull ?? pending;
}

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.cityName,
    required this.provinceName,
    required this.description,
    this.logoUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String shortName;

  /// Nilai `CommunityTypeOption.value`.
  final String type;
  final String typeLabel;
  final CommunityStatus status;
  final String cityName;
  final String provinceName;
  final String description;
  final String? logoUrl;
  final DateTime? createdAt;

  String get location => '$cityName, $provinceName';
}

class CommunityDetail extends Community {
  const CommunityDetail({
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
    required this.address,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.photoUrls = const [],
  });

  final String address;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final List<String> photoUrls;
}

class CommunitiesPage {
  const CommunitiesPage({
    required this.communities,
    required this.currentPage,
    required this.lastPage,
  });

  final List<Community> communities;
  final int currentPage;
  final int lastPage;
}

class CommunityTypeOption {
  const CommunityTypeOption({required this.value, required this.label});

  /// Jenis yang isiannya ditulis sendiri oleh pengaju.
  static const other = 'lainnya';

  final String value;
  final String label;
}

class RegionCity {
  const RegionCity({required this.code, required this.name});

  final String code;
  final String name;
}

class RegionProvince {
  const RegionProvince({
    required this.code,
    required this.name,
    required this.cities,
  });

  final String code;
  final String name;
  final List<RegionCity> cities;
}
