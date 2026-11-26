import 'package:flutter/material.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Identitas komunitas aktif. Status dan peran tetap terlihat tanpa mengulang
/// nama peran pada beberapa baris; pemilih komunitas memiliki ruang sendiri.
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
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CommunityColors.ink, CommunityColors.brown],
          ),
        ),
        child: InkWell(
          key: const Key('home-club-card'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Komunitas aktif',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFFF0D18A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (onSwitch != null) ...[
                      const SizedBox(width: 8),
                      _SwitchButton(onPressed: onSwitch!),
                    ] else
                      const Icon(Icons.arrow_outward_rounded,
                          color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 14),
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
                        size: 48,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${community.typeLabel} · ${community.cityName}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      icon: switch (role) {
                        CommunityRole.creator =>
                          Icons.workspace_premium_rounded,
                        CommunityRole.admin => Icons.shield_rounded,
                        CommunityRole.officer => Icons.manage_accounts_rounded,
                        CommunityRole.coach => Icons.sports_rounded,
                        CommunityRole.member => Icons.person_rounded,
                      },
                      label: 'Masuk sebagai ${role.label.toLowerCase()}',
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
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFF0D18A)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
