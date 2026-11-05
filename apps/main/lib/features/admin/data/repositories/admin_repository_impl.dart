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
}
