import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/community_image_picker.dart';
import '../data/datasources/community_remote_data_source.dart';
import '../data/repositories/community_repository_impl.dart';
import '../domain/entities/community.dart';
import '../domain/repositories/community_repository.dart';

part 'community_providers.g.dart';

@Riverpod(keepAlive: true)
CommunityRepository communityRepository(Ref ref) => CommunityRepositoryImpl(
      CommunityRemoteDataSource(ref.watch(apiClientProvider).dio),
    );

@riverpod
CommunityImagePicker communityImagePicker(Ref ref) =>
    const CommunityImagePicker();

/// Jenis komunitas; jarang berubah, jadi dimuat sekali per sesi.
@Riverpod(keepAlive: true)
Future<List<CommunityTypeOption>> communityTypes(Ref ref) =>
    ref.watch(communityRepositoryProvider).getTypes();

/// Provinsi beserta kabupaten/kotanya; satu respons, sehingga pilihan kota
/// langsung tersedia begitu provinsi dipilih.
@Riverpod(keepAlive: true)
Future<List<RegionProvince>> indonesiaRegions(Ref ref) =>
    ref.watch(communityRepositoryProvider).getRegions();

/// Pengajuan milik pengguna yang login.
@riverpod
Future<List<Community>> myCommunities(Ref ref) =>
    ref.watch(communityRepositoryProvider).getMine();

@riverpod
Future<CommunityDetail> communityDetail(Ref ref, String id) =>
    ref.watch(communityRepositoryProvider).getCommunity(id);

/// Komunitas yang diikuti, untuk Beranda.
@riverpod
Future<List<Community>> joinedCommunities(Ref ref) =>
    ref.watch(communityRepositoryProvider).getJoined();

@riverpod
Future<CommunityActivities> communityActivities(Ref ref, String id) =>
    ref.watch(communityRepositoryProvider).getActivities(id);

@riverpod
Future<CommunityMemberProfile> communityMemberProfile(
  Ref ref,
  String userId,
) =>
    ref.watch(communityRepositoryProvider).getMemberProfile(userId);

class CommunityMembersState {
  const CommunityMembersState({
    this.members = const [],
    this.requests = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<CommunityMember> members;

  /// Permintaan bergabung; hanya terisi untuk creator/admin.
  final List<CommunityMember> requests;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  CommunityMembersState copyWith({
    List<CommunityMember>? members,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      CommunityMembersState(
        members: members ?? this.members,
        requests: requests,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Anggota satu komunitas. Daftarnya hanya dimuat untuk sesama anggota, dan ikut
/// dimuat ulang setiap detail komunitas disegarkan.
@riverpod
class CommunityMembersNotifier extends _$CommunityMembersNotifier {
  @override
  Future<CommunityMembersState> build(String communityId) async {
    final detail = await ref.watch(communityDetailProvider(communityId).future);
    if (!detail.isMember && !detail.canManage) {
      return const CommunityMembersState();
    }

    final repository = ref.read(communityRepositoryProvider);
    final active = repository.getMembers(communityId, page: 1);
    final requests = detail.canManage
        ? repository.getMembers(communityId, page: 1, pending: true)
        : null;

    final page = await active;
    return CommunityMembersState(
      members: page.members,
      requests: (await requests)?.members ?? const [],
      page: page.currentPage,
      hasMore: page.currentPage < page.lastPage,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref
          .read(communityRepositoryProvider)
          .getMembers(communityId, page: current.page + 1);
      if (!ref.mounted) return;
      final seen = {for (final member in current.members) member.id};
      state = AsyncData(current.copyWith(
        members: [
          ...current.members,
          ...next.members.where((member) => !seen.contains(member.id)),
        ],
        page: next.currentPage,
        hasMore: next.currentPage < next.lastPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      if (ref.mounted) state = AsyncData(current);
      rethrow;
    }
  }
}

class CommunitiesState {
  const CommunitiesState({
    required this.communities,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Community> communities;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  /// Gagal memuat halaman berikutnya; halaman yang sudah tampil tetap utuh.
  final String? loadMoreError;

  CommunitiesState copyWith({
    List<Community>? communities,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) =>
      CommunitiesState(
        communities: communities ?? this.communities,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Daftar komunitas terverifikasi: cari, saring jenis, dan muat bertahap.
@riverpod
class CommunitiesNotifier extends _$CommunitiesNotifier {
  String _search = '';
  String? _type;

  /// Hanya respons permintaan terakhir yang dipakai: hasil pencarian lama bisa
  /// datang sesudah yang baru.
  int _generation = 0;

  @override
  Future<CommunitiesState> build() => _firstPage();

  Future<CommunitiesState> _firstPage() async {
    final page = await ref
        .read(communityRepositoryProvider)
        .getCommunities(page: 1, search: _search, type: _type);
    return CommunitiesState(
      communities: page.communities,
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

  Future<void> setType(String? type) {
    if (type == _type) return Future.value();
    _type = type;
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
      final next = await ref.read(communityRepositoryProvider).getCommunities(
            page: current.page + 1,
            search: _search,
            type: _type,
          );
      if (generation != _generation) return;
      final seen = {for (final community in current.communities) community.id};
      state = AsyncData(current.copyWith(
        communities: [
          ...current.communities,
          ...next.communities.where((c) => !seen.contains(c.id)),
        ],
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
}
