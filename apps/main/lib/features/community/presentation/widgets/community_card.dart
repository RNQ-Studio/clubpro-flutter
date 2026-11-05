import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';
import 'community_visuals.dart';

/// Satu komunitas di daftar.
class CommunityCard extends StatelessWidget {
  const CommunityCard({
    super.key,
    required this.community,
    required this.onTap,
    this.showStatus = false,
  });

  final Community community;
  final VoidCallback onTap;

  /// Untuk pengajuan sendiri; daftar umum selalu terverifikasi.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('community-${community.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: communityHairline(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityLogo(name: community.name, url: community.logoUrl),
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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        CommunityTypeBadge(
                          type: community.type,
                          label: community.typeLabel,
                        ),
                        if (showStatus)
                          CommunityStatusBadge(status: community.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            community.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!showStatus) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
