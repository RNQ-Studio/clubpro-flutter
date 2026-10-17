import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';

import '../../domain/entities/quote_entity.dart';
import '../quotes_notifier.dart';

/// Filter options for the quotes list.
enum _QuoteFilter { all, active, inactive }

/// Sort options for the quotes list.
enum _QuoteSort { newest, authorAZ }

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  final _searchController = TextEditingController();
  _QuoteFilter _filter = _QuoteFilter.all;
  _QuoteSort _sort = _QuoteSort.newest;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quotesProvider.notifier).syncInBackground();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QuoteEntity> _applyFiltersAndSort(List<QuoteEntity> quotes) {
    var result = List<QuoteEntity>.from(quotes);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((q) =>
              q.text.toLowerCase().contains(query) ||
              q.author.toLowerCase().contains(query))
          .toList();
    }

    // Apply filter
    switch (_filter) {
      case _QuoteFilter.active:
        result = result.where((q) => q.isActive).toList();
      case _QuoteFilter.inactive:
        result = result.where((q) => !q.isActive).toList();
      case _QuoteFilter.all:
        break;
    }

    // Apply sort
    switch (_sort) {
      case _QuoteSort.newest:
        result.sort((a, b) => (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000)));
      case _QuoteSort.authorAZ:
        result.sort(
            (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final quotesAsync = ref.watch(quotesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 56, bottom: 16, right: 16),
              title: Text(
                l10n.quotesTitle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.3),
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<_QuoteSort>(
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Sort',
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _QuoteSort.newest,
                    child: Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 18,
                            color: _sort == _QuoteSort.newest
                                ? colorScheme.primary
                                : null),
                        const SizedBox(width: 8),
                        Text(l10n.quotesSortNewest),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: _QuoteSort.authorAZ,
                    child: Row(
                      children: [
                        Icon(Icons.sort_by_alpha,
                            size: 18,
                            color: _sort == _QuoteSort.authorAZ
                                ? colorScheme.primary
                                : null),
                        const SizedBox(width: 8),
                        Text(l10n.quotesSortAZ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.quotesSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Filter chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: l10n.quotesFilterAll,
                    selected: _filter == _QuoteFilter.all,
                    onSelected: () =>
                        setState(() => _filter = _QuoteFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.quotesFilterActive,
                    selected: _filter == _QuoteFilter.active,
                    onSelected: () =>
                        setState(() => _filter = _QuoteFilter.active),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.quotesFilterInactive,
                    selected: _filter == _QuoteFilter.inactive,
                    onSelected: () =>
                        setState(() => _filter = _QuoteFilter.inactive),
                  ),
                ],
              ),
            ),

            // Premium background sync loading indicator
            if (quotesAsync.isLoading && quotesAsync.hasValue) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      child: SizedBox(
                        height: 3,
                        child: LinearProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Menyinkronkan data dengan server...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Quotes list
            Expanded(
              child: quotesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorState(
                  message: l10n.quotesLoadError,
                  onRetry: () =>
                      ref.read(quotesProvider.notifier).refreshQuotes(),
                  retryLabel: l10n.quotesRetry,
                ),
                data: (quotes) {
                  final filtered = _applyFiltersAndSort(quotes);

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      message: quotes.isEmpty
                          ? l10n.quotesEmpty
                          : l10n.quotesSearchHint,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 16, 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.collections_bookmark_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Ditemukan ${filtered.length} kutipan untuk pencarian "${_searchQuery}"'
                                  : 'Menampilkan ${filtered.length} kutipan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              ref.read(quotesProvider.notifier).refreshQuotes(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final quote = filtered[index];
                              return _QuoteCard(
                                quote: quote,
                                onTap: () => context.push(
                                  '${AppRoutes.editQuote}/${quote.localId}',
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, ref, quote),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createQuote),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.quotesAdd),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    QuoteEntity quote,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quotesDelete),
        content: Text(l10n.quotesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.quotesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.quotesConfirmDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(quotesProvider.notifier).removeQuote(quote.localId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.quotesDeleteSuccess)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneral)),
          );
        }
      }
    }
  }
}

// ─── Supporting Widgets ─────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      side: BorderSide.none,
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.onTap,
    required this.onDelete,
  });

  final QuoteEntity quote;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: quote icon + sync status + delete
              Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  _SyncBadge(quote: quote, l10n: l10n),
                  const Spacer(),
                  if (!quote.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.quotesFilterInactive,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: colorScheme.error, size: 20),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quote text
              Text(
                '"${quote.text}"',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Author & source
              Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '— ${quote.author}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (quote.source != null && quote.source!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.book_outlined,
                        size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        quote.source!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (quote.createdAt != null) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ditambahkan ${AppDateUtils.timeAgo(quote.createdAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.quote, required this.l10n});

  final QuoteEntity quote;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData icon;
    String label;
    Color color;

    if (quote.isSynced) {
      icon = Icons.cloud_done_outlined;
      label = l10n.quotesSynced;
      color = Colors.green;
    } else if (quote.syncAction == 'create') {
      icon = Icons.cloud_upload_outlined;
      label = l10n.quotesSyncPending;
      color = Colors.orange;
    } else if (quote.syncAction == 'update') {
      icon = Icons.cloud_sync_outlined;
      label = l10n.quotesSyncOfflineEdit;
      color = colorScheme.tertiary;
    } else {
      icon = Icons.cloud_off_outlined;
      label = l10n.quotesWorkingOffline;
      color = colorScheme.error;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote_rounded,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
