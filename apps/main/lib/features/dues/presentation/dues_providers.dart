import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../community/presentation/community_providers.dart';
import '../data/datasources/dues_remote_data_source.dart';
import '../data/repositories/dues_repository_impl.dart';
import '../domain/entities/dues.dart';
import '../domain/repositories/dues_repository.dart';

part 'dues_providers.g.dart';

@Riverpod(keepAlive: true)
DuesRepository duesRepository(Ref ref) =>
    DuesRepositoryImpl(DuesRemoteDataSource(ref.watch(apiClientProvider).dio));

/// Iuran saya di satu komunitas; [year] = tahun kalendernya (null = tahun ini).
@Riverpod(retry: noRetry)
Future<DuesOverview> duesOverview(Ref ref, String communityId, int? year) =>
    ref.watch(duesRepositoryProvider).getOverview(communityId, year: year);

@Riverpod(retry: noRetry)
Future<MemberDuesDetail> memberDues(
  Ref ref,
  String communityId,
  String userId,
  int year,
) =>
    ref
        .watch(duesRepositoryProvider)
        .getMember(communityId, userId, year: year);

class PagedState<T> {
  const PagedState({
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) =>
      PagedState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Pembayaran untuk diverifikasi pengelola; [status] null = semua (riwayat).
@Riverpod(retry: noRetry)
class DuesPaymentsNotifier extends _$DuesPaymentsNotifier {
  @override
  Future<PagedState<DuesPayment>> build(
    String communityId,
    DuesPaymentStatus? status,
  ) async {
    final page = await ref
        .watch(duesRepositoryProvider)
        .getPayments(communityId, page: 1, status: status);
    return PagedState(
      items: page.items,
      page: page.currentPage,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref
          .read(duesRepositoryProvider)
          .getPayments(communityId, page: current.page + 1, status: status);
      if (!ref.mounted) return;
      final seen = {for (final p in current.items) p.id};
      state = AsyncData(current.copyWith(
        items: [
          ...current.items,
          ...next.items.where((p) => !seen.contains(p.id))
        ],
        page: next.currentPage,
        hasMore: next.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ));
      }
    }
  }
}

/// Kalender iuran semua anggota untuk [year], bisa dicari per nama.
@Riverpod(retry: noRetry)
class MembersDuesNotifier extends _$MembersDuesNotifier {
  @override
  Future<PagedState<MemberDues>> build(
    String communityId,
    int year,
    String search,
  ) async {
    final page = await ref.watch(duesRepositoryProvider).getMembers(
          communityId,
          year: year,
          page: 1,
          search: search,
        );
    return PagedState(
      items: page.items,
      page: page.currentPage,
      hasMore: page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref.read(duesRepositoryProvider).getMembers(
            communityId,
            year: year,
            page: current.page + 1,
            search: search,
          );
      if (!ref.mounted) return;
      final seen = {for (final m in current.items) m.userId};
      state = AsyncData(current.copyWith(
        items: [
          ...current.items,
          ...next.items.where((m) => !seen.contains(m.userId)),
        ],
        page: next.currentPage,
        hasMore: next.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(
          isLoadingMore: false,
          loadMoreError: e.toString(),
        ));
      }
    }
  }
}

/// Segarkan semua yang bergantung pada iuran [communityId] sesudah ada perubahan.
/// Menerima `ref.invalidate` milik `Ref` maupun `WidgetRef`.
void invalidateDues(
  void Function(ProviderOrFamily provider) invalidate,
  String communityId,
) {
  invalidate(duesOverviewProvider);
  invalidate(memberDuesProvider);
  invalidate(duesPaymentsProvider);
  invalidate(membersDuesProvider);
  invalidate(communityDetailProvider(communityId));
}
