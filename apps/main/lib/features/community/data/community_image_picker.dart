import 'package:image_picker/image_picker.dart';

import '../domain/entities/community_draft.dart';

/// Pemilih foto. Foto dikecilkan saat dipilih agar unggahan cepat; byte dibaca
/// lewat `XFile` karena di web tidak ada path berkas.
class CommunityImagePicker {
  const CommunityImagePicker();

  static const _maxBytes = 5 * 1024 * 1024;

  static const _mimeByExtension = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  Future<CommunityImage?> pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    return file == null ? null : _read(file);
  }

  /// Memilih sampai [limit] foto.
  Future<List<CommunityImage>> pickPhotos(int limit) async {
    final picker = ImagePicker();
    // `pickMultiImage` menolak limit di bawah 2.
    final files = limit < 2
        ? [
            await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 80,
            ),
          ].nonNulls.toList()
        : await picker.pickMultiImage(
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 80,
            limit: limit,
          );
    return [for (final file in files.take(limit)) await _read(file)];
  }

  Future<CommunityImage> _read(XFile file) async {
    final extension = file.name.split('.').last.toLowerCase();
    final mimeType = file.mimeType ?? _mimeByExtension[extension];
    if (mimeType == null || !_mimeByExtension.containsValue(mimeType)) {
      throw const CommunityImageException(
          'Format foto harus JPG, PNG, atau WebP.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > _maxBytes) {
      throw const CommunityImageException('Ukuran foto maksimal 5 MB.');
    }
    return CommunityImage(
      bytes: bytes,
      filename: file.name,
      mimeType: mimeType,
    );
  }
}
