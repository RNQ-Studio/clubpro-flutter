import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/admin_community.dart';
import '../admin_community_providers.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Kelola Komunitas: semua pengajuan, terbaru di atas. Khusus super admin.
class AdminCommunitiesScreen extends StatelessWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminGate(child: _AdminCommunitiesView());
}

class _AdminCommunitiesView extends ConsumerStatefulWidget {
  const _AdminCommunitiesView();

  @override
  ConsumerState<_AdminCommunitiesView> createState() =>
      _AdminCommunitiesViewState();
}

class _AdminCommunitiesViewState extends ConsumerState<_AdminCommunitiesView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  AdminCommunityFilter _filter = AdminCommunityFilter.all;

  /// Ringkasan terakhir, agar angka di saringan tidak hilang saat memuat ulang.
  AdminCommunitySummary? _summary;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  AdminCommunitiesNotifier get _notifier =>
      ref.read(adminCommunitiesProvider.notifier);

  void _onSearchChanged(String value) {
    setState(() {}); // Tombol hapus mengikuti isi kolom.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _notifier.search(value),
    );
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {});
    _notifier.search('');
  }

  void _setFilter(AdminCommunityFilter filter) {
    setState(() => _filter = filter);
    _notifier.setFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final communities = ref.watch(adminCommunitiesProvider);
    _summary = communities.asData?.value.summary ?? _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Komunitas')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: RefreshIndicator(
            onRefresh: _notifier.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  sliver: SliverList.list(children: [
                    TextField(
                      key: const Key('admin-community-search'),
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari komunitas atau pengaju',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus pencarian',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: _clearSearch,
                              ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FilterChips(
                      selected: _filter,
                      summary: _summary,
                      onSelected: _setFilter,
                    ),
                  ]),
                ),
                ...communities.when(
                  skipLoadingOnRefresh: true,
                  loading: () => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (error, _) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AdminErrorView(
                        message: error.toString(),
                        onRetry: _notifier.retry,
                      ),
                    ),
                  ],
                  data: (state) => state.communities.isEmpty
                      ? [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyView(
                              searching:
                                  _searchController.text.trim().isNotEmpty,
                            ),
                          ),
                        ]
                      : [_CommunityList(state: state)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.summary,
    required this.onSelected,
  });

  final AdminCommunityFilter selected;
  final AdminCommunitySummary? summary;
  final ValueChanged<AdminCommunityFilter> onSelected;

  String _label(AdminCommunityFilter filter) {
    final counts = summary;
    if (counts == null) return filter.label;
    final status = filter.status;
    final count = status == null ? counts.total : counts.countOf(status);
    return '${filter.label} ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final filter in AdminCommunityFilter.values)
          ChoiceChip(
            key: Key('admin-community-filter-${filter.name}'),
            label: Text(_label(filter)),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}

class _CommunityList extends StatelessWidget {
  const _CommunityList({required this.state});

  final AdminCommunitiesState state;

  @override
  Widget build(BuildContext context) {
    final communities = state.communities;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      sliver: SliverList.separated(
        itemCount: communities.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index < communities.length) {
            return _CommunityRow(community: communities[index]);
          }
          return _ListFooter(key: ValueKey(state.page), state: state);
        },
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({required this.community});

  final AdminCommunity community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final submitter = community.submitter?.name ?? 'Akun terhapus';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('admin-community-${community.id}'),
        onTap: () => context.push(AppRoutes.adminCommunity(community.id)),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminHairline(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityLogo(name: community.name, url: community.logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        CommunityStatusBadge(status: community.status),
                        CommunityTypeBadge(
                          type: community.type,
                          label: community.typeLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      community.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                    Text(
                      'Diajukan $submitter · '
                      '${AdminTime.relative(community.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Akhir daftar. Dibangun saat mendekati layar, jadi halaman berikutnya dimuat
/// tepat waktu, juga di layar tinggi yang tidak perlu digulir.
class _ListFooter extends ConsumerStatefulWidget {
  const _ListFooter({super.key, required this.state});

  final AdminCommunitiesState state;

  @override
  ConsumerState<_ListFooter> createState() => _ListFooterState();
}

class _ListFooterState extends ConsumerState<_ListFooter> {
  @override
  void initState() {
    super.initState();
    if (widget.state.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(adminCommunitiesProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final error = state.loadMoreError;
    if (error != null) {
      return Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: ref.read(adminCommunitiesProvider.notifier).loadMore,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }
    if (state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.diversity_3_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              searching
                  ? 'Tidak ada komunitas yang cocok dengan pencarian'
                  : 'Belum ada komunitas pada saringan ini',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
