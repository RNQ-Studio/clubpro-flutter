import 'package:features_shared/features_shared.dart';

/// Perangkat yang pernah dipakai pengguna. Lokasi hanya perkiraan dari IP.
class AdminDevice {
  const AdminDevice({
    required this.id,
    required this.platform,
    this.deviceType,
    this.deviceName,
    this.osVersion,
    this.appVersion,
    this.ipAddress,
    this.location,
    this.userAgent,
    this.lastActiveAt,
    this.createdAt,
  });

  final String id;
  final String platform;

  /// `desktop`, `mobile`, atau `tablet`; null bila tidak diketahui.
  final String? deviceType;
  final String? deviceName;
  final String? osVersion;
  final String? appVersion;
  final String? ipAddress;
  final String? location;
  final String? userAgent;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;

  String get label => deviceName ?? platform;
}

/// Satu baris di daftar pengguna terdaftar.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.roles = const [],
    this.isSuperAdmin = false,
    this.isActive = true,
    this.lastSeenAt,
    this.lastLoginAt,
    this.createdAt,
    this.latestDevice,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<String> roles;
  final bool isSuperAdmin;
  final bool isActive;
  final DateTime? lastSeenAt;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final AdminDevice? latestDevice;
}

/// Data lengkap satu pengguna.
class AdminUserDetail extends AdminUser {
  const AdminUserDetail({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl,
    super.roles,
    super.isSuperAdmin,
    super.isActive,
    super.lastSeenAt,
    super.lastLoginAt,
    super.createdAt,
    super.latestDevice,
    this.phone,
    this.usesGoogle = false,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.gender,
    this.birthPlace,
    this.birthDate,
    this.address,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.completion,
    this.devices = const [],
  });

  final String? phone;
  final bool usesGoogle;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final MemberGender? gender;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? address;
  final BloodType? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final ProfileCompletion? completion;
  final List<AdminDevice> devices;
}

/// Ringkasan seluruh pengguna, tidak terpengaruh pencarian.
class AdminSummary {
  const AdminSummary({
    required this.total,
    required this.superAdmins,
    required this.activeLast7Days,
    required this.inactive,
  });

  final int total;
  final int superAdmins;
  final int activeLast7Days;
  final int inactive;

  AdminSummary copyWith({int? superAdmins, int? inactive}) => AdminSummary(
        total: total,
        superAdmins: superAdmins ?? this.superAdmins,
        activeLast7Days: activeLast7Days,
        inactive: inactive ?? this.inactive,
      );
}

class AdminUsersPage {
  const AdminUsersPage({
    required this.users,
    required this.summary,
    required this.currentPage,
    required this.lastPage,
  });

  final List<AdminUser> users;
  final AdminSummary summary;
  final int currentPage;
  final int lastPage;
}

/// Saringan daftar pengguna.
enum AdminUserFilter {
  all('Semua'),
  superAdmin('Super Admin'),
  active('Aktif'),
  inactive('Nonaktif');

  const AdminUserFilter(this.label);
  final String label;

  bool matches(AdminUser user) => switch (this) {
        all => true,
        superAdmin => user.isSuperAdmin,
        active => user.isActive,
        inactive => !user.isActive,
      };
}
