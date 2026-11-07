import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/club_common.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Anggota beberapa komunitas memilih dulu masuk sebagai anggota yang mana.
class HomeClubChooser extends StatelessWidget {
  const HomeClubChooser({
    super.key,
    required this.communities,
    required this.onChoose,
  });

  final List<Community> communities;
  final ValueChanged<Community> onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('home-club-chooser'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Masuk sebagai anggota komunitas mana?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Anda tergabung di ${communities.length} komunitas. Pilihan Anda '
          'diingat untuk kunjungan berikutnya dan bisa diganti kapan saja dari '
          'Beranda.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        for (final community in communities)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HomeClubOption(
              community: community,
              onTap: () => onChoose(community),
            ),
          ),
      ],
    );
  }
}

/// Satu komunitas yang bisa dipilih: logo, nama, peran, dan status.
class HomeClubOption extends StatelessWidget {
  const HomeClubOption({
    super.key,
    required this.community,
    required this.onTap,
    this.selected = false,
  });

  final Community community;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = community.myRole;
    return Material(
      color: selected
          ? CommunityColors.gold.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? CommunityColors.gold : communityHairline(context),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('home-club-option-${community.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CommunityLogo(
                name: community.name,
                url: community.logoUrl,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (role != null && role.canManage)
                          ClubRoleBadge(role: role)
                        else
                          Text(
                            CommunityRole.member.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (community.status != CommunityStatus.approved)
                          CommunityStatusBadge(status: community.status),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected
                    ? CommunityColors.gold
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lembar ganti komunitas aktif, beserta pintu mencari atau mendaftarkan
/// komunitas lain.
Future<void> showHomeClubSwitcher(
  BuildContext context, {
  required List<Community> communities,
  required Community? active,
  required ValueChanged<Community> onChoose,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      void close() => Navigator.pop(sheetContext);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                'Ganti Komunitas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masuk sebagai anggota komunitas lain.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              for (final community in communities)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HomeClubOption(
                    community: community,
                    selected: community.id == active?.id,
                    onTap: () {
                      close();
                      onChoose(community);
                    },
                  ),
                ),
              const Divider(height: 20),
              ListTile(
                key: const Key('home-switcher-find'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.travel_explore_rounded,
                  color: CommunityColors.gold,
                ),
                title: const Text('Cari komunitas lain'),
                onTap: () {
                  close();
                  context.push(AppRoutes.communities);
                },
              ),
              ListTile(
                key: const Key('home-switcher-create'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.add_business_rounded,
                  color: CommunityColors.gold,
                ),
                title: const Text('Daftarkan komunitas baru'),
                onTap: () {
                  close();
                  context.push(AppRoutes.createCommunity);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
