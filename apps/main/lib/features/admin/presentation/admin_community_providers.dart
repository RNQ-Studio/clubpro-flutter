import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../community/domain/entities/community.dart';
import '../domain/entities/admin_community.dart';
import 'admin_providers.dart';

part 'admin_community_providers.g.dart';

/// Angka di halaman menu; menu tetap bisa dipakai bila gagal dimuat.
@riverpod
Future<AdminPanelSummary> adminSummary(Ref ref) =>
    ref.watch(adminRepositoryProvider).getSummary();

class AdminCommunitiesState {
  const AdminCommunitiesState({
    required this.communities,
    required this.summary,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<AdminCommunity> communities;
  final AdminCommunitySummary summary;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Gagal memuat halaman berikutnya; halaman yang sudah tampil tetap utuh.
  final String? loadMoreError;

  AdminCommunitiesState copyWith({
    List<AdminCommunity>? communities,
    AdminCommunitySummary? summary,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) =>
      AdminCommunitiesState(
        communities: communities ?? this.communities,
        summary: summary ?? this.summary,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Kelola Komunitas: semua status, terbaru di atas.
@riverpod
class AdminCommunitiesNotifier extends _$AdminCommunitiesNotifier {
  String _search = '';
  AdminCommunityFilter _filter = AdminCommunityFilter.all;

  /// Hanya respons permintaan terakhir yang dipakai: hasil pencarian lama bisa
  /// datang sesudah yang baru.
  int _generation = 0;

  @override
  Future<AdminCommunitiesState> build() => _firstPage();

  Future<AdminCommunitiesState> _firstPage() async {
    final page = await ref
        .read(adminRepositoryProvider)
        .getCommunities(page: 1, search: _search, filter: _filter);
    return AdminCommunitiesState(
      communities: page.communities,
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

  Future<void> setFilter(AdminCommunityFilter filter) {
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
      final next = await ref.read(adminRepositoryProvider).getCommunities(
            page: current.page + 1,
            search: _search,
            filter: _filter,
          );
      if (generation != _generation) return;
      // Pengajuan baru menggeser baris antarhalaman; jangan tampil dua kali.
      final seen = {for (final community in current.communities) community.id};
      state = AsyncData(current.copyWith(
        communities: [
          ...current.communities,
          ...next.communities.where((c) => !seen.contains(c.id)),
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

  /// Terapkan hasil verifikasi tanpa memuat ulang daftar.
  void applyUpdate(AdminCommunity updated) {
    final current = state.asData?.value;
    if (current == null) return;
    final index = current.communities
        .indexWhere((community) => community.id == updated.id);
    if (index < 0) return;

    state = AsyncData(current.copyWith(
      communities: [
        for (final community in current.communities)
          if (community.id != updated.id)
            community
          else if (_filter.matches(updated))
            updated,
      ],
      summary: current.summary.moved(
        current.communities[index].status,
        updated.status,
      ),
    ));
  }
}

/// Data lengkap satu komunitas beserta verifikasinya. Kegagalan diteruskan ke
/// pemanggil agar pesannya tampil; data yang sudah tampil tetap utuh.
@riverpod
class AdminCommunityDetailNotifier extends _$AdminCommunityDetailNotifier {
  @override
  Future<AdminCommunityDetail> build(String id) =>
      ref.read(adminRepositoryProvider).getCommunity(id);

  Future<void> review({required CommunityStatus status, String? note}) async {
    final current = state.requireValue;
    try {
      final updated = await ref.read(adminRepositoryProvider).reviewCommunity(
            id,
            status: status,
            expected: current.status,
            note: note,
          );
      if (!ref.mounted) return;
      state = AsyncData(updated);
      if (ref.exists(adminCommunitiesProvider)) {
        ref.read(adminCommunitiesProvider.notifier).applyUpdate(updated);
      }
      ref.invalidate(adminSummaryProvider);
    } on AdminConflictException {
      // Super admin lain sudah memutuskan: tampilkan keadaan terbarunya.
      if (ref.mounted) {
        ref.invalidateSelf();
        ref.invalidate(adminCommunitiesProvider);
        ref.invalidate(adminSummaryProvider);
      }
      rethrow;
    }
  }
}
