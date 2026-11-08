import '../../../community/domain/entities/community.dart';
import '../entities/admin_banner.dart';
import '../entities/admin_community.dart';
import '../entities/admin_user.dart';

abstract interface class AdminRepository {
  Future<AdminUsersPage> getUsers({
    required int page,
    String search = '',
    AdminUserFilter filter = AdminUserFilter.all,
  });

  Future<AdminUserDetail> getUser(String id);

  Future<AdminUserDetail> setSuperAdmin(String id, {required bool enabled});

  Future<AdminUserDetail> setActive(String id, {required bool active});

  Future<AdminPanelSummary> getSummary();

  Future<AdminCommunitiesPage> getCommunities({
    required int page,
    String search = '',
    AdminCommunityFilter filter = AdminCommunityFilter.all,
  });

  Future<AdminCommunityDetail> getCommunity(String id);

  /// [expected] adalah status yang sedang dilihat; lihat
  /// [AdminConflictException].
  Future<AdminCommunityDetail> reviewCommunity(
    String id, {
    required CommunityStatus status,
    required CommunityStatus expected,
    String? note,
  });

  Future<AdminBanners> getBanners();

  Future<AdminBanner> createBanner(AdminBannerInput input);

  Future<AdminBanner> updateBanner(String id, AdminBannerInput input);

  Future<void> deleteBanner(String id);

  /// [ids] memuat semua banner; daftar basi → [AdminConflictException].
  Future<AdminBanners> reorderBanners(List<String> ids);

  /// Popup Paid Promotion tampil lagi sesudah [hours] jam.
  Future<AdminBanners> updatePromotionInterval(int hours);
}
