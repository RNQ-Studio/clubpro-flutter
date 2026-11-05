import 'package:flutter/material.dart';

import '../../domain/entities/community_draft.dart';
import 'community_visuals.dart';

/// Pratinjau langsung: tampilan komunitas sesudah terverifikasi.
class CommunityPreviewCard extends StatelessWidget {
  const CommunityPreviewCard({super.key, required this.draft});

  final CommunityDraft draft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final name = draft.name.trim();
    final shortName = draft.shortName.trim();
    final description = draft.description.trim();
    final cover = draft.photos.firstOrNull;
    final location =
        [draft.city?.name, draft.province?.name].nonNulls.join(', ');
    final typeLabel = draft.typeLabel;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 118,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                if (cover != null)
                  Image.memory(cover.bytes, fit: BoxFit.cover)
                else
                  const DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: CommunityColors.heroGradient),
                  ),
                Positioned(
                  left: 14,
                  bottom: -30,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: CommunityLogo(
                      name: name,
                      bytes: draft.logo?.bytes,
                      size: 66,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 38, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Nama komunitas Anda' : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: name.isEmpty ? muted : null,
                  ),
                ),
                if (shortName.isNotEmpty)
                  Text(
                    shortName,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                const SizedBox(height: 8),
                if (typeLabel != null)
                  CommunityTypeBadge(type: draft.type?.value, label: typeLabel),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style:
                              theme.textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ],
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
