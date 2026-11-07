import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/community_providers.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Komunitas yang dibuat, dikelola, atau diikuti; tepat di bawah info anggota.
class HomeMyCommunities extends ConsumerWidget {
  const HomeMyCommunities({super.key});

  static const _bubbleSize = 62.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final communities = ref.watch(joinedCommunitiesProvider);

    return communities.when(
      skipLoadingOnRefresh: true,
      // Tetap memberi ruang agar isi Beranda tidak melompat saat data tiba.
      loading: () => const SizedBox(height: 112),
      // Beranda tetap utuh walau daftar ini gagal dimuat.
      error: (_, __) => const SizedBox.shrink(),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Komunitas Saya',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (items.isEmpty)
            Row(
              children: [
                const _DiscoverBubble(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ikut komunitas. Temukan yang cocok, atau daftarkan '
                    'komunitas Anda.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              height: 88 * MediaQuery.textScalerOf(context).scale(1),
              child: ListView(
                key: const Key('home-my-communities'),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final community in items)
                    _CommunityBubble(community: community),
                  const _DiscoverBubble(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityBubble extends StatelessWidget {
  const _CommunityBubble({required this.community});

  final Community community;

  @override
  Widget build(BuildContext context) {
    final role = community.myRole;
    final waiting = community.status != CommunityStatus.approved;
    return _Bubble(
      bubbleKey: Key('home-community-${community.id}'),
      label: community.shortName,
      onTap: () => context.push(AppRoutes.community(community.id)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: waiting
                  ? null
                  : const LinearGradient(
                      colors: [
                        CommunityColors.goldLight,
                        CommunityColors.brown,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: waiting ? communityHairline(context) : null,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: CommunityLogo(
                name: community.name,
                url: community.logoUrl,
                size: HomeMyCommunities._bubbleSize - 9,
              ),
            ),
          ),
          if (waiting)
            const Positioned(
              right: -2,
              bottom: -2,
              child: _Mark(
                icon: Icons.hourglass_top_rounded,
                color: CommunityColors.brown,
              ),
            )
          else if (role?.canManage ?? false)
            Positioned(
              right: -2,
              bottom: -2,
              child: _Mark(
                icon: role == CommunityRole.creator
                    ? Icons.workspace_premium_rounded
                    : Icons.shield_rounded,
                color: role == CommunityRole.creator
                    ? CommunityColors.gold
                    : const Color(0xFF1E6FD9),
              ),
            ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}

/// Ajakan mencari komunitas.
class _DiscoverBubble extends StatelessWidget {
  const _DiscoverBubble();

  @override
  Widget build(BuildContext context) {
    return _Bubble(
      bubbleKey: const Key('home-discover-communities'),
      label: 'Cari',
      onTap: () => context.go(AppRoutes.communities),
      child: SizedBox.square(
        dimension: HomeMyCommunities._bubbleSize,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: CommunityColors.gold.withValues(alpha: 0.7),
            radius: HomeMyCommunities._bubbleSize / 2,
          ),
          child: const Icon(Icons.add_rounded, color: CommunityColors.gold),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.bubbleKey,
    required this.label,
    required this.onTap,
    required this.child,
  });

  final Key bubbleKey;
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: bubbleKey,
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            child,
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
