import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import '../widgets/club_common.dart';
import '../widgets/community_visuals.dart';

/// Profil sesama anggota: hanya data umum.
class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = communityMemberProfileProvider(userId);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Anggota')),
      body: ref.watch(provider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => CommunityErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (profile) => _ProfileBody(profile: profile),
          ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final CommunityMemberProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registeredAt = profile.registeredAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    gradient: CommunityColors.heroGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClubAvatar(
                          name: profile.name,
                          url: profile.avatarUrl,
                          radius: 46,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          profile.name,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (registeredAt != null)
                        Text(
                          'Di CEO sejak '
                          '${AppDateUtils.monthYearId(registeredAt.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ClubGroupTitle(
                  'Komunitas yang Sama',
                  count: profile.communities.length,
                ),
                if (profile.communities.isEmpty)
                  Text(
                    'Belum ada komunitas yang sama.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (final community in profile.communities)
                  _SharedCommunityTile(community: community),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SharedCommunityTile extends StatelessWidget {
  const _SharedCommunityTile({required this.community});

  final SharedCommunity community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joinedAt = community.joinedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('member-community-${community.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(AppRoutes.community(community.id)),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: communityHairline(context)),
            ),
            child: Row(
              children: [
                CommunityLogo(
                  name: community.name,
                  url: community.logoUrl,
                  size: 46,
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
                      if (joinedAt != null)
                        Text(
                          'Bergabung '
                          '${AppDateUtils.longDateId(joinedAt.toLocal())}',
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
                if (community.role.canManage)
                  ClubRoleBadge(role: community.role)
                else
                  Text(
                    community.role.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
