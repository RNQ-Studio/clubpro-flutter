import '../../../community/domain/entities/community.dart';

class AdminCommunityPerson {
  const AdminCommunityPerson({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
}

/// Satu baris di Kelola Komunitas.
class AdminCommunity {
  const AdminCommunity({
    required this.id,
    required this.name,
    required this.shortName,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.cityName,
    required this.provinceName,
    this.logoUrl,
    this.createdAt,
    this.reviewedAt,
    this.submitter,
  });

  final String id;
  final String name;
  final String shortName;
  final String type;
  final String typeLabel;
  final CommunityStatus status;
  final String cityName;
  final String provinceName;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  /// Null bila akun pengajunya sudah dihapus.
  final AdminCommunityPerson? submitter;

  String get location => '$cityName, $provinceName';
}

/// Data lengkap untuk diperiksa sebelum memutuskan.
class AdminCommunityDetail extends AdminCommunity {
  const AdminCommunityDetail({
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
    required this.description,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    this.photoUrls = const [],
    this.reviewNote,
    this.reviewer,
  });

  final String description;
  final String address;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final List<String> photoUrls;
  final String? reviewNote;
  final AdminCommunityPerson? reviewer;
}

/// Jumlah komunitas per status, tidak terpengaruh pencarian.
class AdminCommunitySummary {
  const AdminCommunitySummary({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;

  int countOf(CommunityStatus status) => switch (status) {
        CommunityStatus.pending => pending,
        CommunityStatus.approved => approved,
        CommunityStatus.rejected => rejected,
      };

  /// Satu komunitas berpindah status.
  AdminCommunitySummary moved(CommunityStatus from, CommunityStatus to) {
    int next(CommunityStatus status) =>
        countOf(status) + (status == to ? 1 : 0) - (status == from ? 1 : 0);
    return AdminCommunitySummary(
      total: total,
      pending: next(CommunityStatus.pending),
      approved: next(CommunityStatus.approved),
      rejected: next(CommunityStatus.rejected),
    );
  }
}

class AdminCommunitiesPage {
  const AdminCommunitiesPage({
    required this.communities,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
  });

  final List<AdminCommunity> communities;
  final AdminCommunitySummary summary;
  final int currentPage;
  final int lastPage;
}

/// Angka di halaman menu Admin Panel.
class AdminPanelSummary {
  const AdminPanelSummary(
      {required this.totalUsers, required this.communities});

  final int totalUsers;
  final AdminCommunitySummary communities;
}

/// Saringan Kelola Komunitas.
enum AdminCommunityFilter {
  all('Semua', null),
  pending('Menunggu', CommunityStatus.pending),
  approved('Terverifikasi', CommunityStatus.approved),
  rejected('Ditolak', CommunityStatus.rejected);

  const AdminCommunityFilter(this.label, this.status);
  final String label;
  final CommunityStatus? status;

  bool matches(AdminCommunity community) =>
      status == null || community.status == status;
}

/// Super admin lain sudah memutuskan lebih dulu; layar harus memuat ulang.
class AdminConflictException implements Exception {
  const AdminConflictException(this.message);

  final String message;

  @override
  String toString() => message;
}
