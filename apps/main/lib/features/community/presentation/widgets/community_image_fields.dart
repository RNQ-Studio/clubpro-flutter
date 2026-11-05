import 'package:flutter/material.dart';

import '../../domain/entities/community_draft.dart';
import 'community_visuals.dart';

/// Tempat memilih foto profil komunitas.
class CommunityLogoField extends StatelessWidget {
  const CommunityLogoField({
    super.key,
    required this.logo,
    required this.name,
    required this.onPick,
    this.error,
  });

  static const _size = 116.0;

  final CommunityImage? logo;
  final String name;
  final VoidCallback onPick;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = logo;
    final borderColor = error != null
        ? theme.colorScheme.error
        : CommunityColors.gold.withValues(alpha: 0.7);

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Pilih foto profil komunitas',
          child: InkWell(
            key: const Key('community-logo'),
            onTap: onPick,
            customBorder: const CircleBorder(),
            child: SizedBox.square(
              dimension: _size,
              child: Stack(
                children: [
                  if (image != null)
                    CommunityLogo(
                      name: name,
                      bytes: image.bytes,
                      size: _size,
                    )
                  else
                    CustomPaint(
                      painter: DashedBorderPainter(
                        color: borderColor,
                        radius: _size / 2,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_a_photo_rounded,
                              color: CommunityColors.gold,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Foto Profil',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: CommunityColors.brown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (image != null)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: CommunityColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          CommunityFieldError(error!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// Lampiran foto komunitas.
class CommunityPhotosField extends StatelessWidget {
  const CommunityPhotosField({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.error,
  });

  final List<CommunityImage> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = photos.length < CommunityDraft.maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lampiran Foto',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${photos.length}/${CommunityDraft.maxPhotos}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Foto kegiatan membantu super admin memverifikasi komunitas Anda.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final (index, photo) in photos.indexed)
              _PhotoTile(
                key: Key('community-photo-$index'),
                photo: photo,
                onRemove: () => onRemove(index),
              ),
            if (canAdd)
              _AddTile(
                hasError: error != null,
                onTap: onAdd,
              ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          CommunityFieldError(error!),
        ],
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({super.key, required this.photo, required this.onRemove});

  final CommunityImage photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(photo.bytes, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Tooltip(
                  message: 'Hapus foto',
                  child:
                      Icon(Icons.close_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.hasError, required this.onTap});

  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: const Key('community-add-photo'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: hasError
              ? theme.colorScheme.error
              : CommunityColors.gold.withValues(alpha: 0.7),
          radius: 12,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_photo_alternate_rounded,
                  color: CommunityColors.gold, size: 26),
              const SizedBox(height: 4),
              Text(
                'Tambah',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: CommunityColors.brown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pesan galat untuk isian yang bukan kolom teks.
class CommunityFieldError extends StatelessWidget {
  const CommunityFieldError(
    this.message, {
    super.key,
    this.textAlign = TextAlign.start,
  });

  final String message;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      textAlign: textAlign,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}
