import 'dart:async';

import 'package:app_main/features/admin/domain/entities/admin_user.dart';
import 'package:app_main/features/admin/domain/repositories/admin_repository.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';

const adminSummary = AdminSummary(
  total: 128,
  superAdmins: 2,
  activeLast7Days: 57,
  inactive: 3,
);

final adminDevices = [
  AdminDevice(
    id: 'd1',
    platform: 'web',
    deviceType: 'mobile',
    deviceName: 'Chrome 130 · Android 14 · SM-S918B',
    osVersion: 'Android 14',
    ipAddress: '180.244.128.1',
    location: 'Bekasi, West Java, Indonesia',
    lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  AdminDevice(
    id: 'd2',
    platform: 'web',
    deviceType: 'desktop',
    deviceName: 'Safari 17 · macOS',
    osVersion: 'macOS',
    ipAddress: '36.86.63.180',
    location: 'Jakarta, Indonesia',
    lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

AdminUser adminUser(
  String id, {
  String name = 'Rina Ayu Lestari',
  String email = 'rina.ayu@gmail.com',
  bool isSuperAdmin = false,
  bool isActive = true,
  DateTime? lastSeenAt,
  AdminDevice? device,
}) =>
    AdminUser(
      id: id,
      name: name,
      email: email,
      isSuperAdmin: isSuperAdmin,
      isActive: isActive,
      lastSeenAt: lastSeenAt,
      latestDevice: device,
    );

AdminUserDetail adminDetail({
  String id = '7',
  String name = 'Rina Ayu Lestari',
  bool isSuperAdmin = false,
  bool isActive = true,
  bool emailVerified = true,
  List<AdminDevice>? devices,
}) =>
    AdminUserDetail(
      id: id,
      name: name,
      email: 'rina.ayu@gmail.com',
      isSuperAdmin: isSuperAdmin,
      isActive: isActive,
      roles: isSuperAdmin ? const ['super-admin'] : const [],
      lastSeenAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastLoginAt: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime(2026, 10, 28, 9, 15),
      usesGoogle: true,
      phone: '081234567890',
      emailVerifiedAt: emailVerified ? DateTime(2026, 10, 28, 9, 15) : null,
      gender: MemberGender.female,
      birthPlace: 'Bandung',
      birthDate: DateTime(2001, 4, 12),
      address: 'Jl. Merdeka No. 10, Bandung',
      bloodType: BloodType.o,
      emergencyContactName: 'Ibu Sari',
      emergencyContactPhone: '081298765432',
      completion:
          const ProfileCompletion(completed: 10, total: 10, missing: []),
      devices: devices ?? adminDevices,
    );

/// Permintaan daftar yang diterima, untuk diperiksa test.
typedef AdminUsersCall = ({int page, String search, AdminUserFilter filter});

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    this.pages = const [],
    this.detail,
    this.error,
    this.actionError,
  });

  /// Halaman daftar berurutan; halaman ke-n dipakai untuk `page: n`.
  List<List<AdminUser>> pages;
  AdminUserDetail? detail;

  /// Melempar pada pengambilan data, bila diisi.
  AppException? error;

  /// Melempar pada aksi ubah data, bila diisi.
  AppException? actionError;

  /// Isi agar `getUsers` menunggu sampai test menyelesaikannya.
  Completer<void> Function(AdminUsersCall call)? gate;

  final calls = <AdminUsersCall>[];
  final actions = <String>[];

  @override
  Future<AdminUsersPage> getUsers({
    required int page,
    String search = '',
    AdminUserFilter filter = AdminUserFilter.all,
  }) async {
    final call = (page: page, search: search, filter: filter);
    calls.add(call);
    await gate?.call(call).future;
    final failure = error;
    if (failure != null) throw failure;
    return AdminUsersPage(
      users: page <= pages.length ? pages[page - 1] : const [],
      summary: adminSummary,
      currentPage: page,
      lastPage: pages.isEmpty ? 1 : pages.length,
    );
  }

  @override
  Future<AdminUserDetail> getUser(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return detail!;
  }

  @override
  Future<AdminUserDetail> setSuperAdmin(
    String id, {
    required bool enabled,
  }) async {
    actions.add('super-admin:$id:$enabled');
    final failure = actionError;
    if (failure != null) throw failure;
    return detail = adminDetail(id: id, isSuperAdmin: enabled);
  }

  @override
  Future<AdminUserDetail> setActive(String id, {required bool active}) async {
    actions.add('status:$id:$active');
    final failure = actionError;
    if (failure != null) throw failure;
    return detail = adminDetail(id: id, isActive: active);
  }
}
