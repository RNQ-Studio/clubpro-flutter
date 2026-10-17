import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/presentation/auth_state.dart';

/// Foto profil anggota + tombol ganti foto. Foto langsung diunggah saat
/// dipilih (terpisah dari tombol Simpan form).
class ProfileAvatarPicker extends ConsumerStatefulWidget {
  const ProfileAvatarPicker(
      {super.key, this.radius = 48, this.editable = true});

  final double radius;
  final bool editable;

  @override
  ConsumerState<ProfileAvatarPicker> createState() =>
      _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends ConsumerState<ProfileAvatarPicker> {
  bool _uploading = false;

  Future<void> _choose() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      setState(() => _uploading = true);
      await ref.read(authProvider.notifier).uploadAvatar(image.path);
      messenger.showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final avatarUrl = user?.avatarUrl;
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
    final initial = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()[0].toUpperCase()
        : '?';

    return SizedBox.square(
      dimension: widget.radius * 2 + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
            ),
            child: CircleAvatar(
              radius: widget.radius,
              backgroundColor: colorScheme.primaryContainer,
              foregroundImage: hasPhoto ? NetworkImage(avatarUrl) : null,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: widget.radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          if (_uploading)
            Container(
              width: widget.radius * 2,
              height: widget.radius * 2,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          if (widget.editable && !_uploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: colorScheme.primary,
                shape: CircleBorder(
                  side: BorderSide(color: colorScheme.surface, width: 2.5),
                ),
                child: InkWell(
                  key: const Key('change-avatar'),
                  customBorder: const CircleBorder(),
                  onTap: _choose,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
