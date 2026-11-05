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
