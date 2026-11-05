import 'dart:typed_data';

import 'community.dart';

/// Langkah form, berurutan.
enum CommunityFormStep {
  identity('Identitas', 'Kenalkan komunitas Anda'),
  location('Lokasi', 'Di mana komunitas Anda berada?'),
  contact('Kontak', 'Siapa yang bisa dihubungi?'),
  story('Cerita', 'Ceritakan dan tunjukkan komunitas Anda'),
  review('Tinjau', 'Periksa sekali lagi sebelum dikirim');

  const CommunityFormStep(this.label, this.title);
  final String label;
  final String title;

  bool get isLast => this == review;
}

/// Foto terpilih. [assetId] terisi sesudah terunggah, sehingga kirim ulang
/// tidak mengunggahnya lagi.
class CommunityImage {
  const CommunityImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    this.assetId,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final String? assetId;

  CommunityImage withAssetId(String? id) => CommunityImage(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
        assetId: id,
      );
}

/// Isian form pengajuan komunitas. Aturannya sama dengan `StoreCommunityRequest`.
class CommunityDraft {
  const CommunityDraft({
    this.logo,
    this.name = '',
    this.shortName = '',
    this.type,
    this.typeOther = '',
    this.province,
    this.city,
    this.address = '',
    this.contactName = '',
    this.contactPhone = '',
    this.contactEmail = '',
    this.description = '',
    this.photos = const [],
  });

  static const maxPhotos = 6;
  static const maxNameLength = 100;
  static const maxShortNameLength = 30;
  static const maxTypeOtherLength = 50;
  static const maxAddressLength = 500;
  static const maxContactNameLength = 100;
  static const maxContactEmailLength = 150;
  static const minDescriptionLength = 30;
  static const maxDescriptionLength = 2000;

  final CommunityImage? logo;
  final String name;
  final String shortName;
  final CommunityTypeOption? type;
  final String typeOther;
  final RegionProvince? province;
  final RegionCity? city;
  final String address;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String description;
  final List<CommunityImage> photos;

  bool get isEmpty =>
      logo == null &&
      name.trim().isEmpty &&
      shortName.trim().isEmpty &&
      type == null &&
      province == null &&
      address.trim().isEmpty &&
      contactName.trim().isEmpty &&
      contactPhone.trim().isEmpty &&
      contactEmail.trim().isEmpty &&
      description.trim().isEmpty &&
      photos.isEmpty;

  bool get isOtherType => type?.value == CommunityTypeOption.other;

  /// Label jenis yang akan tampil.
  String? get typeLabel {
    final other = typeOther.trim();
    return isOtherType && other.isNotEmpty ? other : type?.label;
  }

  /// `city` berisi kota terpilih; [clearCity] mengosongkannya saat provinsi berganti.
  CommunityDraft copyWith({
    CommunityImage? logo,
    String? name,
    String? shortName,
    CommunityTypeOption? type,
    String? typeOther,
    RegionProvince? province,
    RegionCity? city,
    bool clearCity = false,
    String? address,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? description,
    List<CommunityImage>? photos,
  }) =>
      CommunityDraft(
        logo: logo ?? this.logo,
        name: name ?? this.name,
        shortName: shortName ?? this.shortName,
        type: type ?? this.type,
        typeOther: typeOther ?? this.typeOther,
        province: province ?? this.province,
        city: clearCity ? null : city ?? this.city,
        address: address ?? this.address,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        contactEmail: contactEmail ?? this.contactEmail,
        description: description ?? this.description,
        photos: photos ?? this.photos,
      );

  static String _digits(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-.()]'), '');

  /// Pesan galat per isian pada [step]; kosong berarti boleh lanjut.
  Map<String, String> errorsFor(CommunityFormStep step) {
    String? length(String value, String label, int min, int max) {
      final length = value.trim().length;
      if (length == 0) return '$label wajib diisi';
      if (length < min) return '$label minimal $min karakter';
      if (length > max) return '$label maksimal $max karakter';
      return null;
    }

    final errors = <String, String?>{};
    switch (step) {
      case CommunityFormStep.identity:
        errors['logo_asset_id'] =
            logo == null ? 'Pilih foto profil komunitas' : null;
        errors['name'] = length(name, 'Nama komunitas', 3, maxNameLength);
        errors['short_name'] =
            length(shortName, 'Nama pendek', 2, maxShortNameLength);
        errors['type'] = type == null ? 'Pilih jenis komunitas' : null;
        if (isOtherType) {
          errors['type_other'] =
              length(typeOther, 'Jenis komunitas', 2, maxTypeOtherLength);
        }
      case CommunityFormStep.location:
        errors['province_code'] = province == null ? 'Pilih provinsi' : null;
        errors['city_code'] = city == null ? 'Pilih kota/kabupaten' : null;
        errors['address'] =
            length(address, 'Alamat lengkap', 10, maxAddressLength);
      case CommunityFormStep.contact:
        errors['contact_name'] =
            length(contactName, 'Nama kontak', 3, maxContactNameLength);
        final phone = _digits(contactPhone);
        errors['contact_phone'] = phone.isEmpty
            ? 'Nomor kontak wajib diisi'
            : RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)
                ? null
                : 'Nomor kontak tidak valid';
        final email = contactEmail.trim();
        errors['contact_email'] = email.isEmpty ||
                (email.length <= maxContactEmailLength &&
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email))
            ? null
            : 'Format email tidak valid';
      case CommunityFormStep.story:
        errors['description'] = length(description, 'Deskripsi',
            minDescriptionLength, maxDescriptionLength);
        errors['photo_asset_ids'] =
            photos.isEmpty ? 'Lampirkan minimal 1 foto' : null;
      case CommunityFormStep.review:
        break;
    }
    return {
      for (final entry in errors.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }

  /// Langkah pertama yang isiannya belum benar, atau null bila semua benar.
  CommunityFormStep? get firstInvalidStep {
    for (final step in CommunityFormStep.values) {
      if (errorsFor(step).isNotEmpty) return step;
    }
    return null;
  }

  /// Langkah yang memuat isian bernama [field] dari server.
  static CommunityFormStep stepOf(String field) => switch (field) {
        'province_code' ||
        'city_code' ||
        'address' =>
          CommunityFormStep.location,
        'contact_name' ||
        'contact_phone' ||
        'contact_email' =>
          CommunityFormStep.contact,
        'description' || 'photo_asset_ids' => CommunityFormStep.story,
        _ => CommunityFormStep.identity,
      };

  /// Isi `POST v1/communities`; semua foto harus sudah terunggah.
  Map<String, Object?> toPayload() => {
        'name': name.trim(),
        'short_name': shortName.trim(),
        'type': type?.value,
        if (isOtherType) 'type_other': typeOther.trim(),
        'description': description.trim(),
        'address': address.trim(),
        'province_code': province?.code,
        'city_code': city?.code,
        'contact_name': contactName.trim(),
        'contact_phone': _digits(contactPhone),
        if (contactEmail.trim().isNotEmpty)
          'contact_email': contactEmail.trim(),
        'logo_asset_id': logo?.assetId,
        'photo_asset_ids': [for (final photo in photos) photo.assetId],
      };
}

/// Server menolak satu isian; [field] menentukan langkah yang dibuka kembali.
class CommunityFieldException implements Exception {
  const CommunityFieldException(this.field, this.message);

  final String field;
  final String message;

  @override
  String toString() => message;
}

/// Foto terpilih tidak bisa dipakai.
class CommunityImageException implements Exception {
  const CommunityImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
