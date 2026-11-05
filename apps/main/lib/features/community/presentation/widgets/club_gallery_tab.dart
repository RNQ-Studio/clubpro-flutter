import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community.dart';
import '../../domain/entities/community_draft.dart';
import '../community_providers.dart';
import 'club_common.dart';
import 'community_photo_viewer.dart';
import 'community_visuals.dart';

class ClubGalleryTab extends ConsumerStatefulWidget {
  const ClubGalleryTab({super.key, required this.community});

  /// Sama dengan `CommunityService::MAX_GALLERY_PHOTOS`.
  static const maxPhotos = 60;

  /// Foto per pemilihan.
  static const _batch = 6;

  final CommunityDetail community;

  @override
  ConsumerState<ClubGalleryTab> createState() => _ClubGalleryTabState();
}

class _ClubGalleryTabState extends ConsumerState<ClubGalleryTab> {
  bool _uploading = false;

  CommunityDetail get _community => widget.community;

  Future<void> _add() async {
    final room = ClubGalleryTab.maxPhotos - _community.photos.length;
    final repository = ref.read(communityRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    final List<CommunityImage> images;
    try {
      images = await ref
          .read(communityImagePickerProvider)
          .pickPhotos(math.min(room, ClubGalleryTab._batch));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }
    if (images.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    await runClubAction(
      context,
      () async {
        for (final image in images) {
          final assetId =
              await repository.uploadImage(image, category: 'community-photo');
          await repository.addPhoto(_community.id, assetId);
        }
      },
      success: images.length == 1
          ? 'Foto ditambahkan'
          : '${images.length} foto ditambahkan',
    );
    if (!mounted) return;
    // Foto yang sudah terunggah tetap tampil walau foto berikutnya gagal.
    ref.invalidate(communityDetailProvider(_community.id));
    setState(() => _uploading = false);
  }

  Future<void> _remove(CommunityPhoto photo) async {
    final confirmed = await confirmClubAction(
      context,
      title: 'Hapus foto ini?',
      message: 'Foto akan hilang dari galeri komunitas.',
      action: 'Hapus',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await runClubAction(
      context,
      () => ref
          .read(communityRepositoryProvider)
          .removePhoto(_community.id, photo.id),
      success: 'Foto dihapus',
    );
    if (mounted) ref.invalidate(communityDetailProvider(_community.id));
  }

  @override
  Widget build(BuildContext context) {
    final community = _community;
    final photos = community.photos;
    final canManage = community.canManage;
    final urls = [for (final photo in photos) photo.url];
    final full = photos.length >= ClubGalleryTab.maxPhotos;

    final addButton = OutlinedButton.icon(
      key: const Key('club-add-photo'),
      onPressed: _uploading || full ? null : _add,
      icon: _uploading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_photo_alternate_rounded, size: 20),
      label: Text(switch ((_uploading, full)) {
        (true, _) => 'Mengunggah...',
        (_, true) => 'Galeri penuh (${ClubGalleryTab.maxPhotos} foto)',
        _ => 'Tambah Foto',
      }),
    );

    Widget tile(int index, {double? aspectRatio}) {
      final photo = photos[index];
      final image = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('club-photo-$index'),
          onTap: () => showCommunityPhotoViewer(context, urls, index),
          child: CommunityNetworkImage(url: photo.url),
        ),
      );
      final content = !canManage
          ? image
          : Stack(
              fit: StackFit.expand,
              children: [
                image,
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: Key('club-photo-remove-$index'),
                      customBorder: const CircleBorder(),
                      onTap: () => _remove(photo),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Tooltip(
                          message: 'Hapus foto',
                          child: Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
      return aspectRatio == null
          ? content
          : AspectRatio(aspectRatio: aspectRatio, child: content);
    }

    return ClubTabScroll(
      storageKey: 'club-gallery',
      child: photos.isEmpty
          ? ClubEmptyState(
              icon: Icons.photo_library_rounded,
              title: 'Belum ada foto',
              message: canManage
                  ? 'Bagikan momen seru komunitas Anda di sini.'
                  : 'Foto kegiatan komunitas akan tampil di sini.',
              action: canManage ? addButton : null,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canManage) ...[
                  addButton,
                  const SizedBox(height: 12),
                ],
                // Foto pertama menjadi sorotan, sisanya kisi.
                tile(0, aspectRatio: 16 / 9),
                if (photos.length > 1) ...[
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [
                      for (var i = 1; i < photos.length; i++) tile(i),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
