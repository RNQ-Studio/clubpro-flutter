/// Nilai-nilai data diri anggota. Kode [apiValue] sama dengan backend.
library;

enum MemberGender {
  male('male', 'Laki-laki'),
  female('female', 'Perempuan');

  const MemberGender(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static MemberGender? fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull;
}

/// Provinsi + kabupaten/kota data diri (kode Kemendagri dan namanya dari
/// server), mis. domisili atau wilayah sesuai NIK.
class MemberRegion {
  const MemberRegion({
    required this.provinceCode,
    required this.provinceName,
    required this.cityCode,
    required this.cityName,
  });

  final String provinceCode;
  final String provinceName;
  final String cityCode;
  final String cityName;

  /// "Kota Bandung, Jawa Barat".
  String get label => '$cityName, $provinceName';

  /// Dari kolom API `{prefix}_province_code` dst.; null bila belum lengkap.
  static MemberRegion? fromJson(Map<String, dynamic> json, String prefix) {
    final values = [
      for (final column in _columns) json['${prefix}_$column'],
    ];
    if (values.any((v) => v is! String || v.isEmpty)) return null;
    final [provinceCode, provinceName, cityCode, cityName] =
        values.cast<String>();
    return MemberRegion(
      provinceCode: provinceCode,
      provinceName: provinceName,
      cityCode: cityCode,
      cityName: cityName,
    );
  }

  Map<String, dynamic> toJson(String prefix) => {
        '${prefix}_province_code': provinceCode,
        '${prefix}_province_name': provinceName,
        '${prefix}_city_code': cityCode,
        '${prefix}_city_name': cityName,
      };

  static const _columns = [
    'province_code',
    'province_name',
    'city_code',
    'city_name',
  ];
}

/// Satu isian data diri yang dihitung untuk kelengkapan profil.
class ProfileField {
  const ProfileField(this.key, this.label);

  final String key;
  final String label;

  /// Urutan & label sama dengan `MemberProfileService::COMPLETION_FIELDS`.
  static const all = [
    ProfileField('name', 'Nama lengkap'),
    ProfileField('gender', 'Jenis kelamin'),
    ProfileField('phone', 'Nomor WhatsApp'),
    ProfileField('domicile', 'Provinsi & kota domisili'),
    ProfileField('nik_region', 'Provinsi & kota sesuai NIK'),
  ];
}

class ProfileCompletion {
  const ProfileCompletion({
    required this.completed,
    required this.total,
    required this.missing,
  });

  /// Dari isian yang terisi (kunci [ProfileField.key]); cadangan bila server
  /// belum mengirim `profile_completion`.
  factory ProfileCompletion.fromFilled(Set<String> filledKeys) {
    final missing =
        ProfileField.all.where((f) => !filledKeys.contains(f.key)).toList();
    return ProfileCompletion(
      completed: ProfileField.all.length - missing.length,
      total: ProfileField.all.length,
      missing: missing,
    );
  }

  factory ProfileCompletion.fromJson(Map<String, dynamic> json) =>
      ProfileCompletion(
        completed: (json['completed'] as num).toInt(),
        total: (json['total'] as num).toInt(),
        missing: [
          for (final item in (json['missing'] as List<dynamic>? ?? const []))
            ProfileField(
              (item as Map<String, dynamic>)['key'] as String,
              item['label'] as String,
            ),
        ],
      );

  final int completed;
  final int total;
  final List<ProfileField> missing;

  bool get isComplete => missing.isEmpty;

  /// Daftar isian penghitungnya sama dengan [ProfileField.all]. Server lama
  /// yang masih menghitung isian yang sudah dihapus (mis. tanggal lahir,
  /// kontak darurat) → `false`, dan app menghitung sendiri.
  bool get matchesAppFields =>
      total == ProfileField.all.length &&
      missing.every((f) => ProfileField.all.any((a) => a.key == f.key));

  /// 0.0 – 1.0
  double get ratio => total == 0 ? 1 : completed / total;

  int get percent => (ratio * 100).floor();

  Map<String, dynamic> toJson() => {
        'is_complete': isComplete,
        'completed': completed,
        'total': total,
        'percent': percent,
        'missing': [
          for (final f in missing) {'key': f.key, 'label': f.label},
        ],
      };
}
