import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/datasources/admin_remote_data_source.dart';
import '../data/repositories/admin_repository_impl.dart';
import '../domain/entities/admin_user.dart';
import '../domain/repositories/admin_repository.dart';

part 'admin_providers.g.dart';

@riverpod
AdminRepository adminRepository(Ref ref) => AdminRepositoryImpl(
      AdminRemoteDataSource(ref.watch(apiClientProvider).dio),
    );

class AdminUsersState {
  const AdminUsersState({
    required this.users,
    required this.summary,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<AdminUser> users;
  final AdminSummary summary;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Gagal memuat halaman berikutnya; halaman yang sudah tampil tetap utuh.
  final String? loadMoreError;

  AdminUsersState copyWith({
    List<AdminUser>? users,
    AdminSummary? summary,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) =>
      AdminUsersState(
        users: users ?? this.users,
        summary: summary ?? this.summary,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Daftar pengguna terdaftar: cari, saring, dan muat bertahap.
@riverpod
class AdminUsersNotifier extends _$AdminUsersNotifier {
  String _search = '';
  AdminUserFilter _filter = AdminUserFilter.all;

  /// Hanya respons permintaan terakhir yang dipakai: hasil pencarian lama bisa
  /// datang sesudah yang baru.
  int _generation = 0;

  @override
  Future<AdminUsersState> build() => _firstPage();

  Future<AdminUsersState> _firstPage() async {
    final page = await ref
        .read(adminRepositoryProvider)
        .getUsers(page: 1, search: _search, filter: _filter);
    return AdminUsersState(
      users: page.users,
      summary: page.summary,
      page: page.currentPage,
      hasMore: page.currentPage < page.lastPage,
    );
  }

  Future<void> _reload({bool showLoading = true}) async {
    final generation = ++_generation;
    if (showLoading) state = const AsyncLoading();
    final result = await AsyncValue.guard(_firstPage);
    if (generation == _generation) state = result;
  }

  Future<void> search(String query) {
    final search = query.trim();
    if (search == _search) return Future.value();
    _search = search;
    return _reload();
  }

  Future<void> setFilter(AdminUserFilter filter) {
    if (filter == _filter) return Future.value();
    _filter = filter;
    return _reload();
  }

  /// Tarik untuk segarkan: daftar lama tetap tampil selama memuat.
  Future<void> refresh() => _reload(showLoading: false);

  /// Ulangi sesudah gagal, dengan pencarian dan saringan yang sama.
  Future<void> retry() => _reload();

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final generation = _generation;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref.read(adminRepositoryProvider).getUsers(
            page: current.page + 1,
            search: _search,
            filter: _filter,
          );
      if (generation != _generation) return;
      // Akses baru bisa menggeser baris antarhalaman; jangan tampil dua kali.
      final seen = {for (final user in current.users) user.id};
      state = AsyncData(current.copyWith(
        users: [
          ...current.users,
          ...next.users.where((user) => !seen.contains(user.id)),
        ],
        summary: next.summary,
        page: next.currentPage,
        hasMore: next.currentPage < next.lastPage,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (generation != _generation) return;
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      ));
    }
  }

  /// Terapkan hasil aksi di layar detail tanpa memuat ulang daftar.
  void applyUpdate(AdminUser updated) {
    final current = state.asData?.value;
    if (current == null) return;
    final index = current.users.indexWhere((user) => user.id == updated.id);
    if (index < 0) return;

    final before = current.users[index];
    final summary = current.summary;
    state = AsyncData(current.copyWith(
      users: [
        for (final user in current.users)
          if (user.id != updated.id)
            user
          else if (_filter.matches(updated))
            updated,
      ],
      summary: summary.copyWith(
        superAdmins: summary.superAdmins +
            (updated.isSuperAdmin ? 1 : 0) -
            (before.isSuperAdmin ? 1 : 0),
        inactive: summary.inactive +
            (updated.isActive ? 0 : 1) -
            (before.isActive ? 0 : 1),
      ),
    ));
  }
}

/// Data lengkap satu pengguna beserta aksinya. Kegagalan aksi diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
@riverpod
class AdminUserDetailNotifier extends _$AdminUserDetailNotifier {
  @override
  Future<AdminUserDetail> build(String id) =>
      ref.read(adminRepositoryProvider).getUser(id);

  Future<void> setSuperAdmin({required bool enabled}) => _apply(
        ref.read(adminRepositoryProvider).setSuperAdmin(id, enabled: enabled),
      );

  Future<void> setActive({required bool active}) => _apply(
        ref.read(adminRepositoryProvider).setActive(id, active: active),
      );

  Future<void> _apply(Future<AdminUserDetail> action) async {
    final updated = await action;
    state = AsyncData(updated);
    if (ref.exists(adminUsersProvider)) {
      ref.read(adminUsersProvider.notifier).applyUpdate(updated);
    }
  }
}
