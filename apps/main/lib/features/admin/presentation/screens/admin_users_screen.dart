import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_user.dart';
import '../admin_providers.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_user_row.dart';
import '../widgets/admin_widgets.dart';

/// Kelola User: ringkasan dan daftar pengguna terdaftar. Khusus super admin.
class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminGate(child: _AdminUsersView());
}

class _AdminUsersView extends ConsumerStatefulWidget {
  const _AdminUsersView();

  @override
  ConsumerState<_AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<_AdminUsersView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  AdminUserFilter _filter = AdminUserFilter.all;

  /// Ringkasan terakhir, agar tidak hilang saat daftar memuat ulang.
  AdminSummary? _summary;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  AdminUsersNotifier get _notifier => ref.read(adminUsersProvider.notifier);

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

  void _setFilter(AdminUserFilter filter) {
    setState(() => _filter = filter);
    _notifier.setFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final data = users.asData?.value;
    _summary = data?.summary ?? _summary;
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola User')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= adminTableMinWidth;
              return RefreshIndicator(
                onRefresh: _notifier.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      sliver: SliverList.list(children: [
                        if (summary != null) ...[
                          _SummaryGrid(summary: summary, wide: wide),
                          const SizedBox(height: 16),
                        ],
                        _SearchField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                        ),
                        const SizedBox(height: 12),
                        _FilterChips(selected: _filter, onSelected: _setFilter),
                        const SizedBox(height: 8),
                        if (wide && data != null && data.users.isNotEmpty)
                          const AdminUserTableHeader(),
                      ]),
                    ),
                    ...users.when(
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
                      data: (state) => state.users.isEmpty
                          ? [
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _EmptyView(
                                  searching:
                                      _searchController.text.trim().isNotEmpty,
                                ),
                              ),
                            ]
                          : [_UserList(state: state)],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary, required this.wide});

  final AdminSummary summary;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final tiles = [
      _SummaryTile(
        label: 'Total Pengguna',
        value: summary.total,
        icon: Icons.groups_rounded,
        color: const Color(0xFF1E6FD9),
      ),
      _SummaryTile(
        label: 'Super Admin',
        value: summary.superAdmins,
        icon: Icons.admin_panel_settings_rounded,
        color: adminGold,
      ),
      _SummaryTile(
        label: 'Aktif 7 Hari',
        value: summary.activeLast7Days,
        icon: Icons.bolt_rounded,
        color: const Color(0xFF178A5B),
      ),
      _SummaryTile(
        label: 'Nonaktif',
        value: summary.inactive,
        icon: Icons.person_off_rounded,
        color: error,
      ),
    ];
    if (wide) {
      return Row(
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tile),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(children: [
          Expanded(child: tiles[0]),
          const SizedBox(width: 10),
          Expanded(child: tiles[1]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: tiles[2]),
          const SizedBox(width: 10),
          Expanded(child: tiles[3]),
        ]),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
      key: const Key('admin-search'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari nama, email, atau nomor HP',
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final AdminUserFilter selected;
  final ValueChanged<AdminUserFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final filter in AdminUserFilter.values)
          ChoiceChip(
            key: Key('admin-filter-${filter.name}'),
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}

class _UserList extends ConsumerWidget {
  const _UserList({required this.state});

  final AdminUsersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = state.users;
    return SliverList.separated(
      itemCount: users.length + 1,
      separatorBuilder: (context, _) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: adminHairline(context),
      ),
      itemBuilder: (context, index) {
        if (index < users.length) {
          final user = users[index];
          return AdminUserRow(
            user: user,
            onTap: () => context.push(AppRoutes.adminUser(user.id)),
          );
        }
        return _ListFooter(key: ValueKey(state.page), state: state);
      },
    );
  }
}

/// Akhir daftar. Dibangun saat mendekati layar, jadi halaman berikutnya dimuat
/// tepat waktu, juga di layar tinggi yang tidak perlu digulir.
class _ListFooter extends ConsumerStatefulWidget {
  const _ListFooter({super.key, required this.state});

  final AdminUsersState state;

  @override
  ConsumerState<_ListFooter> createState() => _ListFooterState();
}

class _ListFooterState extends ConsumerState<_ListFooter> {
  @override
  void initState() {
    super.initState();
    if (widget.state.hasMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(adminUsersProvider.notifier).loadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final error = state.loadMoreError;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error, textAlign: TextAlign.center),
            TextButton(
              onPressed: ref.read(adminUsersProvider.notifier).loadMore,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }
    if (state.hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const AdminLocationCredit();
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
            Icon(Icons.person_search_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              searching
                  ? 'Tidak ada pengguna yang cocok dengan pencarian'
                  : 'Belum ada pengguna pada saringan ini',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
