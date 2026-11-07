import 'package:flutter/material.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Komunitas aktif di Beranda: Anda masuk sebagai anggota komunitas ini.
class HomeClubCard extends StatelessWidget {
  const HomeClubCard({
    super.key,
    required this.community,
    required this.onOpen,
    this.onSwitch,
  });

  final Community community;
  final VoidCallback onOpen;

  /// Null bila hanya tergabung di satu komunitas.
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = community.myRole ?? CommunityRole.member;
    final members = community.membersCount;

    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: CommunityColors.heroGradient),
        child: InkWell(
          key: const Key('home-club-card'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CommunityLogo(
                        name: community.name,
                        url: community.logoUrl,
                        size: 54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masuk sebagai ${role.label.toLowerCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: CommunityColors.goldLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            community.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${community.typeLabel} · ${community.cityName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onSwitch != null) ...[
                      const SizedBox(width: 6),
                      _SwitchButton(onPressed: onSwitch!),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      icon: switch (role) {
                        CommunityRole.creator =>
                          Icons.workspace_premium_rounded,
                        CommunityRole.admin => Icons.shield_rounded,
                        CommunityRole.member => Icons.person_rounded,
                      },
                      label: role.label,
                    ),
                    if (members != null)
                      _Chip(
                        icon: Icons.groups_rounded,
                        label: '$members anggota',
                      ),
                    if (community.status != CommunityStatus.approved)
                      _Chip(
                        icon: community.status == CommunityStatus.pending
                            ? Icons.hourglass_top_rounded
                            : Icons.cancel_rounded,
                        label: community.status.label,
                        highlight: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('home-club-switch'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
      label: const Text('Ganti'),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;

  /// Status yang perlu diperhatikan, mis. menunggu verifikasi.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final foreground = highlight ? CommunityColors.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? CommunityColors.goldLight
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
