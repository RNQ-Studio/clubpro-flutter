import '../../../community/domain/entities/community.dart';
import '../../domain/entities/admin_banner.dart';
import '../../domain/entities/admin_community.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<AdminUsersPage> getUsers({
    required int page,
    String search = '',
    AdminUserFilter filter = AdminUserFilter.all,
  }) =>
      _remote.fetchUsers(page: page, search: search, filter: filter);

  @override
  Future<AdminUserDetail> getUser(String id) => _remote.fetchUser(id);

  @override
  Future<AdminUserDetail> setSuperAdmin(String id, {required bool enabled}) =>
      _remote.setSuperAdmin(id, enabled: enabled);

  @override
  Future<AdminUserDetail> setActive(String id, {required bool active}) =>
      _remote.setActive(id, active: active);

  @override
  Future<AdminPanelSummary> getSummary() => _remote.fetchSummary();

  @override
  Future<AdminCommunitiesPage> getCommunities({
    required int page,
    String search = '',
    AdminCommunityFilter filter = AdminCommunityFilter.all,
  }) =>
      _remote.fetchCommunities(page: page, search: search, filter: filter);

  @override
  Future<AdminCommunityDetail> getCommunity(String id) =>
      _remote.fetchCommunity(id);

  @override
  Future<AdminCommunityDetail> reviewCommunity(
    String id, {
    required CommunityStatus status,
    required CommunityStatus expected,
    String? note,
  }) =>
      _remote.reviewCommunity(
        id,
        status: status,
        expected: expected,
        note: note,
      );

  @override
  Future<AdminBanners> getBanners() => _remote.fetchBanners();

  @override
  Future<AdminBanner> createBanner(AdminBannerInput input) =>
      _remote.createBanner(input);

  @override
  Future<AdminBanner> updateBanner(String id, AdminBannerInput input) =>
      _remote.updateBanner(id, input);

  @override
  Future<void> deleteBanner(String id) => _remote.deleteBanner(id);

  @override
  Future<AdminBanners> reorderBanners(List<String> ids) =>
      _remote.reorderBanners(ids);
}
