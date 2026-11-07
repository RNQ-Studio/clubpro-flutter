import 'dart:async';

import 'package:app_main/features/admin/domain/entities/admin_banner.dart';
import 'package:app_main/features/admin/domain/entities/admin_community.dart';
import 'package:app_main/features/admin/domain/entities/admin_user.dart';
import 'package:app_main/features/admin/domain/repositories/admin_repository.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
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

const adminCommunitySummary = AdminCommunitySummary(
  total: 12,
  pending: 3,
  approved: 8,
  rejected: 1,
);

AdminCommunity adminCommunity(
  String id, {
  String name = 'Pemanah Nusantara',
  CommunityStatus status = CommunityStatus.pending,
  String submitter = 'Rina Ayu',
  DateTime? createdAt,
}) =>
    AdminCommunity(
      id: id,
      name: name,
      shortName: 'PN',
      type: 'panahan',
      typeLabel: 'Panahan',
      status: status,
      cityName: 'Kota Bandung',
      provinceName: 'Jawa Barat',
      createdAt: createdAt,
      submitter: AdminCommunityPerson(id: '7', name: submitter),
    );

AdminCommunityDetail adminCommunityDetail({
  String id = '5',
  CommunityStatus status = CommunityStatus.pending,
  String? reviewNote,
  DateTime? reviewedAt,
  AdminCommunityPerson? reviewer,
  List<String> photoUrls = const [
    'https://anaklangit.manahpro.web.id/foto-1.jpg',
    'https://anaklangit.manahpro.web.id/foto-2.jpg',
  ],
}) =>
    AdminCommunityDetail(
      id: id,
      name: 'Pemanah Nusantara',
      shortName: 'PN',
      type: 'panahan',
      typeLabel: 'Panahan',
      status: status,
      cityName: 'Kota Bandung',
      provinceName: 'Jawa Barat',
      createdAt: DateTime(2026, 11, 5, 9, 15),
      submitter: const AdminCommunityPerson(
        id: '7',
        name: 'Rina Ayu',
        email: 'rina.ayu@gmail.com',
      ),
      description: 'Komunitas pecinta panahan tradisional yang rutin berlatih '
          'setiap akhir pekan di Bandung.',
      address: 'Jl. Merdeka No. 10, Sumur Bandung',
      contactName: 'Budi Santoso',
      contactPhone: '081234567890',
      contactEmail: 'pengurus@gmail.com',
      photoUrls: photoUrls,
      reviewNote: reviewNote,
      reviewedAt: reviewedAt,
      reviewer: reviewer,
    );

const adminBannerSummary =
    AdminBannerSummary(total: 4, live: 3, maxVisible: 10);

AdminBanner adminBanner(
  String id, {
  String title = 'Latihan Bersama',
  String? subtitle,
  String? imageUrl = 'https://storage.googleapis.com/bucket/banner.jpg',
  String? linkUrl,
  AdminBannerCommunity? linkCommunity,
  AdminBannerStatus status = AdminBannerStatus.live,
  DateTime? startsAt,
  DateTime? endsAt,
}) =>
    AdminBanner(
      id: id,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      linkCommunity: linkCommunity,
      isActive: status != AdminBannerStatus.inactive,
      status: status,
      startsAt: startsAt,
      endsAt: endsAt,
    );

/// Permintaan daftar yang diterima, untuk diperiksa test.
typedef AdminUsersCall = ({int page, String search, AdminUserFilter filter});

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository({
    this.pages = const [],
    this.detail,
    this.error,
    this.actionError,
    this.communityPages = const [],
    this.community,
    this.summaryError,
    this.reviewError,
    List<AdminBanner>? banners,
  }) : banners = banners ?? [];

  /// Halaman daftar berurutan; halaman ke-n dipakai untuk `page: n`.
  List<List<AdminUser>> pages;
  AdminUserDetail? detail;

  /// Melempar pada pengambilan data, bila diisi.
  AppException? error;

  /// Melempar pada aksi ubah data, bila diisi.
  AppException? actionError;

  /// Halaman Kelola Komunitas berurutan.
  List<List<AdminCommunity>> communityPages;
  AdminCommunityDetail? community;
  Exception? summaryError;

  /// Melempar pada verifikasi, satu kali.
  Exception? reviewError;

  /// Kelola Banner, sesuai urutan tampil.
  List<AdminBanner> banners;
  Exception? bannersError;

  /// Melempar pada aksi banner berikutnya, satu kali.
  Exception? bannerActionError;

  /// Isi agar penyimpanan urutan menunggu sampai test menyelesaikannya.
  Completer<void>? reorderGate;

  /// Isi agar tambah/ubah banner menunggu sampai test menyelesaikannya.
  Completer<void>? saveGate;
  int bannerLoads = 0;
  final bannerSaves = <({String? id, AdminBannerInput input})>[];
  final bannerDeletes = <String>[];
  final bannerOrders = <List<String>>[];

  final communityCalls =
      <({int page, String search, AdminCommunityFilter filter})>[];
  final reviews =
      <({CommunityStatus status, CommunityStatus expected, String? note})>[];
  int summaryLoads = 0;

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

  @override
  Future<AdminPanelSummary> getSummary() async {
    summaryLoads++;
    final failure = summaryError;
    if (failure != null) throw failure;
    return const AdminPanelSummary(
      totalUsers: 128,
      communities: adminCommunitySummary,
      banners: adminBannerSummary,
    );
  }

  @override
  Future<AdminCommunitiesPage> getCommunities({
    required int page,
    String search = '',
    AdminCommunityFilter filter = AdminCommunityFilter.all,
  }) async {
    communityCalls.add((page: page, search: search, filter: filter));
    final failure = error;
    if (failure != null) throw failure;
    return AdminCommunitiesPage(
      communities:
          page <= communityPages.length ? communityPages[page - 1] : const [],
      summary: adminCommunitySummary,
      currentPage: page,
      lastPage: communityPages.isEmpty ? 1 : communityPages.length,
    );
  }

  @override
  Future<AdminCommunityDetail> getCommunity(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return community!;
  }

  @override
  Future<AdminCommunityDetail> reviewCommunity(
    String id, {
    required CommunityStatus status,
    required CommunityStatus expected,
    String? note,
  }) async {
    reviews.add((status: status, expected: expected, note: note));
    final failure = reviewError;
    if (failure != null) {
      reviewError = null;
      throw failure;
    }
    return community = adminCommunityDetail(
      id: id,
      status: status,
      reviewNote: status == CommunityStatus.rejected ? note : null,
      reviewedAt: DateTime(2026, 11, 5, 14, 30),
      reviewer: const AdminCommunityPerson(id: '1', name: 'Pemilik'),
    );
  }

  void _bannerAction() {
    final failure = bannerActionError;
    if (failure != null) {
      bannerActionError = null;
      throw failure;
    }
  }

  AdminBanners _banners() => AdminBanners(
        banners: List.of(banners),
        summary: AdminBannerSummary(
          total: banners.length,
          live: banners.where((b) => b.status == AdminBannerStatus.live).length,
          maxVisible: 10,
        ),
      );

  @override
  Future<AdminBanners> getBanners() async {
    bannerLoads++;
    final failure = bannersError;
    if (failure != null) throw failure;
    return _banners();
  }

  @override
  Future<AdminBanner> createBanner(AdminBannerInput input) async {
    bannerSaves.add((id: null, input: input));
    await saveGate?.future;
    _bannerAction();
    final banner = adminBanner(
      '${100 + bannerSaves.length}',
      title: input.title,
      linkUrl: input.linkUrl,
      status:
          input.isActive ? AdminBannerStatus.live : AdminBannerStatus.inactive,
    );
    banners = [...banners, banner];
    return banner;
  }

  @override
  Future<AdminBanner> updateBanner(String id, AdminBannerInput input) async {
    bannerSaves.add((id: id, input: input));
    _bannerAction();
    final banner = adminBanner(
      id,
      title: input.title,
      linkUrl: input.linkUrl,
      status:
          input.isActive ? AdminBannerStatus.live : AdminBannerStatus.inactive,
    );
    banners = [for (final b in banners) b.id == id ? banner : b];
    return banner;
  }

  @override
  Future<void> deleteBanner(String id) async {
    bannerDeletes.add(id);
    _bannerAction();
    banners = banners.where((b) => b.id != id).toList();
  }

  @override
  Future<AdminBanners> reorderBanners(List<String> ids) async {
    bannerOrders.add(ids);
    await reorderGate?.future;
    _bannerAction();
    final byId = {for (final b in banners) b.id: b};
    banners = [for (final id in ids) byId[id]!];
    return _banners();
  }
}
