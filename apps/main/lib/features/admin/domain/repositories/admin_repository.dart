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
}
