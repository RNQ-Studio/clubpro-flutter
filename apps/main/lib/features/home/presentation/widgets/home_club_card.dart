import 'package:flutter/material.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Identitas ringkas komunitas aktif; rincian lengkap dibuka dari kartu.
class HomeClubCard extends StatelessWidget {
  const HomeClubCard({
    super.key,
    required this.community,
    required this.onOpen,
    this.onSwitch,
  });

  final Community community;
  final VoidCallback onOpen;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = community.myRole ?? CommunityRole.member;
    final members = community.membersCount;
    final metadata = '${community.typeLabel} · ${community.cityName}';
    final roleIcon = switch (role) {
      CommunityRole.creator => Icons.workspace_premium_rounded,
      CommunityRole.admin => Icons.shield_rounded,
      CommunityRole.officer => Icons.manage_accounts_rounded,
      CommunityRole.coach => Icons.sports_rounded,
      CommunityRole.member => Icons.person_rounded,
    };
    final status = community.status;
    final statusColor = switch (status) {
      CommunityStatus.approved => const Color(0xFF9DDAB6),
      CommunityStatus.pending => const Color(0xFFF0D18A),
      CommunityStatus.rejected => const Color(0xFFFFADAA),
    };

    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF242925), Color(0xFF353023)],
          ),
        ),
        child: InkWell(
          key: const Key('home-club-card'),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3EAD5),
                    shape: BoxShape.circle,
                  ),
                  child: CommunityLogo(
                    name: community.name,
                    url: community.logoUrl,
                    size: 42,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: community.name,
                        child: Text(
                          community.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Tooltip(
                        message: metadata,
                        child: Text(
                          metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFCDCEC8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Indicator(
                            icon: roleIcon,
                            text: role.label,
                            description: 'Peran Anda: ${role.label}',
                          ),
                          if (members != null)
                            _Indicator(
                              icon: Icons.groups_rounded,
                              text: '$members',
                              description: '$members anggota',
                            ),
                          _Indicator(
                            icon: switch (status) {
                              CommunityStatus.approved =>
                                Icons.verified_rounded,
                              CommunityStatus.pending =>
                                Icons.hourglass_top_rounded,
                              CommunityStatus.rejected => Icons.cancel_rounded,
                            },
                            text: switch (status) {
                              CommunityStatus.approved => null,
                              CommunityStatus.pending => 'Menunggu',
                              CommunityStatus.rejected => 'Ditolak',
                            },
                            description: status.label,
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onSwitch != null)
                  IconButton(
                    key: const Key('home-club-switch'),
                    tooltip: 'Ganti komunitas',
                    onPressed: onSwitch,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      minimumSize: const Size.square(44),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCDCEC8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Warna mendukung ikon dan teks singkat; arti lengkap tetap tersedia.
class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.icon,
    required this.description,
    this.text,
    this.color = const Color(0xFFF3EAD5),
  });

  final IconData icon;
  final String description;
  final String? text;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: description,
        child: Semantics(
          label: description,
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              if (text case final value?) ...[
                const SizedBox(width: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                ),
              ],
            ],
          ),
        ),
      );
}
