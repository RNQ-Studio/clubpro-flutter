import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import '../widgets/community_card.dart';
import '../widgets/community_visuals.dart';

/// Menu Komunitas: daftar komunitas terverifikasi dan pengajuan sendiri.
class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String? _type;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  CommunitiesNotifier get _notifier => ref.read(communitiesProvider.notifier);

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

  void _setType(String? type) {
    setState(() => _type = type);
    _notifier.setType(type);
  }

  Future<void> _refresh() async {
    ref.invalidate(myCommunitiesProvider);
    await _notifier.refresh();
  }

  void _create() => context.push(AppRoutes.createCommunity);

  @override
  Widget build(BuildContext context) {
    final communities = ref.watch(communitiesProvider);
    final filtered = _type != null || _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Komunitas')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('community-create'),
        heroTag: 'community-create',
        backgroundColor: CommunityColors.brown,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Daftarkan Komunitas'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  sliver: SliverList.list(children: [
                    _SearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 10),
                    _TypeFilter(selected: _type, onSelected: _setType),
                    _MySubmissions(onOpen: _open),
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
                      child: CommunityErrorView(
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
                              filtered: filtered,
                              onCreate: _create,
                            ),
                          ),
                        ]
                      : [
                          _CommunityGrid(state: state, onOpen: _open),
                          SliverToBoxAdapter(child: _ListFooter(state: state)),
                        ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(Community community) =>
      context.push(AppRoutes.community(community.id));
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('community-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari nama komunitas atau kota',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        isDense: true,
      ),
    );
  }
}

class _TypeFilter extends ConsumerWidget {
  const _TypeFilter({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gagal memuat jenis tidak menghalangi daftarnya.
    final types = ref.watch(communityTypesProvider).asData?.value;
    if (types == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(null, 'Semua'),
          for (final type in types) _chip(type.value, type.label),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: Key('community-filter-${value ?? 'semua'}'),
        label: Text(label),
        selected: value == selected,
        onSelected: (_) => onSelected(value),
      ),
    );
  }
}

/// Pengajuan yang belum tampil di daftar umum, agar pengaju tahu statusnya.
class _MySubmissions extends ConsumerWidget {
  const _MySubmissions({required this.onOpen});

  final ValueChanged<Community> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myCommunitiesProvider).asData?.value ?? const [];
    final waiting = mine
        .where((community) => community.status != CommunityStatus.approved)
        .toList();
    if (waiting.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengajuan Saya',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          for (final community in waiting)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CommunityCard(
                community: community,
                showStatus: true,
                onTap: () => onOpen(community),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityGrid extends StatelessWidget {
  const _CommunityGrid({required this.state, required this.onOpen});

  final CommunitiesState state;
  final ValueChanged<Community> onOpen;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 500,
          mainAxisExtent: 148 * scale,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: state.communities.length,
        itemBuilder: (context, index) {
          final community = state.communities[index];
          return CommunityCard(
            community: community,
            onTap: () => onOpen(community),
          );
        },
      ),
    );
  }
}

/// Akhir daftar. Dibangun saat mendekati layar, jadi halaman berikutnya dimuat
/// tepat waktu, juga di layar tinggi yang tidak perlu digulir.
class _ListFooter extends ConsumerStatefulWidget {
  const _ListFooter({required this.state});

  final CommunitiesState state;

  @override
  ConsumerState<_ListFooter> createState() => _ListFooterState();
}

class _ListFooterState extends ConsumerState<_ListFooter> {
  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(_ListFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.page != widget.state.page) _loadIfNeeded();
  }

  void _loadIfNeeded() {
    if (!widget.state.hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(communitiesProvider.notifier).loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final error = state.loadMoreError;
    return Padding(
      // Ruang agar kartu terakhir tidak tertutup tombol Daftarkan Komunitas.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      child: error != null
          ? Column(
              children: [
                Text(error, textAlign: TextAlign.center),
                TextButton(
                  onPressed: ref.read(communitiesProvider.notifier).loadMore,
                  child: const Text('Coba Lagi'),
                ),
              ],
            )
          : state.hasMore
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.filtered, required this.onCreate});

  final bool filtered;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CommunityColors.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.diversity_3_rounded,
                size: 40,
                color: CommunityColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'Tidak ada komunitas yang cocok'
                  : 'Belum ada komunitas terverifikasi',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Coba kata kunci atau jenis yang lain.'
                  : 'Jadilah yang pertama mendaftarkan komunitas Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
