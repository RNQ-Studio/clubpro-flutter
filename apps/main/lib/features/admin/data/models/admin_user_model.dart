import 'package:features_shared/features_shared.dart';

import '../../domain/entities/admin_user.dart';

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

List<String> _strings(Object? value) =>
    (value as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

AdminDevice? _device(Object? json) =>
    json is Map<String, dynamic> ? AdminDeviceModel.fromJson(json) : null;

class AdminDeviceModel extends AdminDevice {
  const AdminDeviceModel({
    required super.id,
    required super.platform,
    super.deviceType,
    super.deviceName,
    super.osVersion,
    super.appVersion,
    super.ipAddress,
    super.location,
    super.userAgent,
    super.lastActiveAt,
    super.createdAt,
  });

  factory AdminDeviceModel.fromJson(Map<String, dynamic> json) =>
      AdminDeviceModel(
        id: json['id'].toString(),
        platform: json['platform'] as String,
        deviceType: json['device_type'] as String?,
        deviceName: json['device_name'] as String?,
        osVersion: json['os_version'] as String?,
        appVersion: json['app_version'] as String?,
        ipAddress: json['ip_address'] as String?,
        location: json['location'] as String?,
        userAgent: json['user_agent'] as String?,
        lastActiveAt: _time(json['last_active_at']),
        createdAt: _time(json['created_at']),
      );
}

class AdminUserModel extends AdminUser {
  const AdminUserModel({
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
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) => AdminUserModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        roles: _strings(json['roles']),
        isSuperAdmin: json['is_super_admin'] == true,
        isActive: json['is_active'] != false,
        lastSeenAt: _time(json['last_seen_at']),
        lastLoginAt: _time(json['last_login_at']),
        createdAt: _time(json['created_at']),
        latestDevice: _device(json['latest_device']),
      );
}

class AdminUserDetailModel extends AdminUserDetail {
  const AdminUserDetailModel({
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
    super.phone,
    super.usesGoogle,
    super.emailVerifiedAt,
    super.phoneVerifiedAt,
    super.gender,
    super.birthPlace,
    super.birthDate,
    super.address,
    super.bloodType,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.completion,
    super.devices,
  });

  factory AdminUserDetailModel.fromJson(Map<String, dynamic> json) {
    final completion = json['profile_completion'];
    return AdminUserDetailModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      roles: _strings(json['roles']),
      isSuperAdmin: json['is_super_admin'] == true,
      isActive: json['is_active'] != false,
      lastSeenAt: _time(json['last_seen_at']),
      lastLoginAt: _time(json['last_login_at']),
      createdAt: _time(json['created_at']),
      phone: json['phone'] as String?,
      usesGoogle: json['login_method'] == 'google',
      emailVerifiedAt: _time(json['email_verified_at']),
      phoneVerifiedAt: _time(json['phone_verified_at']),
      gender: MemberGender.fromApi(json['gender']),
      birthPlace: json['birth_place'] as String?,
      birthDate: _time(json['birth_date']),
      address: json['address'] as String?,
      bloodType: BloodType.fromApi(json['blood_type']),
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      completion: completion is Map<String, dynamic>
          ? ProfileCompletion.fromJson(completion)
          : null,
      devices: [
        for (final device in (json['devices'] as List<dynamic>? ?? const []))
          AdminDeviceModel.fromJson(device as Map<String, dynamic>),
      ],
    );
  }
}

/// `GET v1/admin/users`: `data` + `meta.pagination` + `meta.summary`.
AdminUsersPage adminUsersPageFromJson(Map<String, dynamic> json) {
  final meta = json['meta'] as Map<String, dynamic>;
  final pagination = meta['pagination'] as Map<String, dynamic>;
  final summary = meta['summary'] as Map<String, dynamic>;
  return AdminUsersPage(
    users: [
      for (final user in json['data'] as List<dynamic>)
        AdminUserModel.fromJson(user as Map<String, dynamic>),
    ],
    summary: AdminSummary(
      total: summary['total'] as int,
      superAdmins: summary['super_admins'] as int,
      activeLast7Days: summary['active_last_7_days'] as int,
      inactive: summary['inactive'] as int,
    ),
    currentPage: pagination['current_page'] as int,
    lastPage: pagination['last_page'] as int,
  );
}
