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

/// Peran di dalam satu komunitas.
enum CommunityRole {
  creator('creator', 'Creator'),
  admin('admin', 'Admin'),
  member('member', 'Anggota');

  const CommunityRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  bool get canManage => this != member;

  static CommunityRole? fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull;
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
    this.myRole,
    this.membersCount,
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

  /// Peran pengguna yang login; null bila bukan anggota.
  final CommunityRole? myRole;
  final int? membersCount;

  String get location => '$cityName, $provinceName';
}

class CommunityPhoto {
  const CommunityPhoto({required this.id, required this.url});

  final String id;
  final String url;
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
    super.myRole,
    super.membersCount,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.photoUrls = const [],
    this.reviewNote,
    this.photos = const [],
    this.isMember = false,
    this.isJoinPending = false,
    this.canManage = false,
    this.pendingMembersCount = 0,
    this.upcomingActivitiesCount = 0,
  });

  final String address;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final List<String> photoUrls;

  /// Alasan penolakan; hanya terlihat oleh pengaju.
  final String? reviewNote;
  final List<CommunityPhoto> photos;

  /// Anggota aktif.
  final bool isMember;

  /// Permintaan bergabung menunggu persetujuan.
  final bool isJoinPending;

  /// Creator atau admin komunitas ini.
  final bool canManage;
  final int pendingMembersCount;
  final int upcomingActivitiesCount;

  bool get canJoin =>
      status == CommunityStatus.approved && !isMember && !isJoinPending;
}

class CommunityMember {
  const CommunityMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.joinedAt,
    this.requestedAt,
  });

  final String id;
  final String userId;
  final String name;
  final CommunityRole role;
  final String? avatarUrl;
  final DateTime? joinedAt;
  final DateTime? requestedAt;
}

class CommunityMembersPage {
  const CommunityMembersPage({
    required this.members,
    required this.currentPage,
    required this.lastPage,
  });

  final List<CommunityMember> members;
  final int currentPage;
  final int lastPage;
}

class CommunityActivity {
  const CommunityActivity({
    required this.id,
    required this.title,
    required this.startsAt,
    this.description,
    this.location,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String? description;
  final String? location;
}

class CommunityActivities {
  const CommunityActivities({this.upcoming = const [], this.past = const []});

  /// Terdekat lebih dulu.
  final List<CommunityActivity> upcoming;

  /// Terbaru lebih dulu.
  final List<CommunityActivity> past;
}

/// Isian kegiatan baru atau yang diubah.
class CommunityActivityInput {
  const CommunityActivityInput({
    required this.title,
    required this.startsAt,
    this.description = '',
    this.location = '',
  });

  final String title;
  final DateTime startsAt;
  final String description;
  final String location;

  Map<String, Object?> toPayload() => {
        'title': title.trim(),
        'starts_at': startsAt.toUtc().toIso8601String(),
        'description': description.trim().isEmpty ? null : description.trim(),
        'location': location.trim().isEmpty ? null : location.trim(),
      };
}

/// Komunitas yang sama antara pengguna yang login dan anggota yang dibuka.
class SharedCommunity {
  const SharedCommunity({
    required this.id,
    required this.name,
    required this.role,
    this.logoUrl,
    this.joinedAt,
  });

  final String id;
  final String name;
  final CommunityRole role;
  final String? logoUrl;
  final DateTime? joinedAt;
}

/// Profil sesama anggota: hanya data umum.
class CommunityMemberProfile {
  const CommunityMemberProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.registeredAt,
    this.communities = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? registeredAt;
  final List<SharedCommunity> communities;
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
