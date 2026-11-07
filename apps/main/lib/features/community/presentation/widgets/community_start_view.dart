import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import 'community_visuals.dart';

/// Untuk yang belum tergabung di komunitas mana pun: cari komunitas yang ada
/// (dengan rekomendasi anggota terbanyak) atau daftarkan komunitas baru.
/// Permintaan bergabung yang masih menunggu ikut ditampilkan.
class CommunityStartView extends StatelessWidget {
  const CommunityStartView({super.key, this.requests = const []});

  final List<Community> requests;

  @override
  Widget build(BuildContext context) {
    void open(Community community) =>
        context.push(AppRoutes.community(community.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (requests.isNotEmpty) ...[
          _PendingRequests(requests: requests, onOpen: open),
          const SizedBox(height: 20),
        ],
        _StartOptions(
          onFind: () => context.push(AppRoutes.communities),
          onCreate: () => context.push(AppRoutes.createCommunity),
        ),
        const SizedBox(height: 24),
        _Recommendations(
          requestedIds: {for (final c in requests) c.id},
          onOpen: open,
          onSeeAll: () => context.push(AppRoutes.communities),
        ),
      ],
    );
  }
}

class _PendingRequests extends StatelessWidget {
  const _PendingRequests({required this.requests, required this.onOpen});

  final List<Community> requests;
  final ValueChanged<Community> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('community-start-requests'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: CommunityColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CommunityColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 18,
                color: CommunityColors.brown,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Menunggu persetujuan pengurus',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CommunityColors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Anda bisa masuk sebagai anggota begitu permintaan bergabung '
            'diterima.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          for (final community in requests)
            _CommunityRow(
              rowKey: Key('community-start-request-${community.id}'),
              community: community,
              subtitle: community.location,
              onTap: () => onOpen(community),
            ),
        ],
      ),
    );
  }
}

class _StartOptions extends StatelessWidget {
  const _StartOptions({required this.onFind, required this.onCreate});

  final VoidCallback onFind;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final find = _StartOption(
      optionKey: const Key('community-start-find'),
      icon: Icons.travel_explore_rounded,
      title: 'Cari Komunitas',
      subtitle: 'Temukan komunitas yang sudah ada lalu minta bergabung.',
      primary: true,
      onTap: onFind,
    );
    final create = _StartOption(
      optionKey: const Key('community-start-create'),
      icon: Icons.add_business_rounded,
      title: 'Daftarkan Komunitas Baru',
      subtitle: 'Kelola komunitas Anda sendiri sebagai creator.',
      onTap: onCreate,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [find, const SizedBox(height: 10), create],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: find),
              const SizedBox(width: 12),
              Expanded(child: create),
            ],
          ),
        );
      },
    );
  }
}

class _StartOption extends StatelessWidget {
  const _StartOption({
    required this.optionKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final Key optionKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = primary ? Colors.white : theme.colorScheme.onSurface;
    final muted = primary ? Colors.white70 : theme.colorScheme.onSurfaceVariant;
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      color: primary ? null : theme.colorScheme.surface,
      child: Ink(
        decoration: BoxDecoration(
          gradient: primary ? CommunityColors.heroGradient : null,
          borderRadius: BorderRadius.circular(18),
          border: primary
              ? null
              : Border.all(color: CommunityColors.gold.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          key: optionKey,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.16)
                        : CommunityColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: primary ? Colors.white : CommunityColors.gold,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Recommendations extends ConsumerWidget {
  const _Recommendations({
    required this.requestedIds,
    required this.onOpen,
    required this.onSeeAll,
  });

  final Set<String> requestedIds;
  final ValueChanged<Community> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final recommended = ref.watch(recommendedCommunitiesProvider);
    final items = recommended.value;

    final Widget body;
    if (items != null) {
      body = items.isEmpty
          ? Text(
              'Belum ada komunitas terverifikasi. Jadilah yang pertama '
              'mendaftarkan komunitas Anda.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            )
          : Column(
              children: [
                for (final (index, community) in items.indexed)
                  _CommunityRow(
                    rowKey: Key('community-recommended-${community.id}'),
                    community: community,
                    rank: index + 1,
                    subtitle: '${community.typeLabel} · ${community.cityName}',
                    trailing: requestedIds.contains(community.id)
                        ? const _RequestedMark()
                        : _MembersCount(count: community.membersCount ?? 0),
                    onTap: () => onOpen(community),
                  ),
              ],
            );
    } else if (recommended.hasError) {
      body = Row(
        children: [
          Expanded(
            child: Text(
              'Rekomendasi gagal dimuat.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          TextButton(
            key: const Key('community-recommended-retry'),
            onPressed: () => ref.invalidate(recommendedCommunitiesProvider),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    } else {
      body = Column(
        children: [
          for (var i = 0; i < 3; i++) const _PlaceholderRow(),
        ],
      );
    }

    return Column(
      key: const Key('community-recommended'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi Komunitas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Paling banyak anggotanya',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const Key('community-recommended-all'),
              onPressed: onSeeAll,
              child: const Text('Lihat semua'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        body,
      ],
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.rowKey,
    required this.community,
    required this.subtitle,
    required this.onTap,
    this.rank,
    this.trailing,
  });

  final Key rowKey;
  final Community community;
  final String subtitle;
  final VoidCallback onTap;
  final int? rank;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: rowKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Row(
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 20,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: CommunityColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            CommunityLogo(
              name: community.name,
              url: community.logoUrl,
              size: 44,
            ),
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
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

class _MembersCount extends StatelessWidget {
  const _MembersCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'anggota',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RequestedMark extends StatelessWidget {
  const _RequestedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CommunityColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Menunggu',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CommunityColors.brown,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Bentuk baris selama rekomendasi dimuat, agar isi tidak melompat.
class _PlaceholderRow extends StatelessWidget {
  const _PlaceholderRow();

  @override
  Widget build(BuildContext context) {
    final color = communityHairline(context);
    Widget bar(double width) => Container(
          width: width,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 28),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar(140), const SizedBox(height: 8), bar(90)],
          ),
        ],
      ),
    );
  }
}
