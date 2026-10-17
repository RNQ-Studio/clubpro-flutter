/// Nilai-nilai data diri anggota club. Kode [apiValue] sama dengan backend.
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

enum BowType {
  recurve('recurve', 'Recurve'),
  compound('compound', 'Compound'),
  barebow('barebow', 'Barebow'),
  traditional('traditional', 'Tradisional / Horsebow');

  const BowType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static BowType? fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull;
}

enum BloodType {
  a('A'),
  b('B'),
  ab('AB'),
  o('O');

  const BloodType(this.apiValue);
  final String apiValue;
  String get label => apiValue;

  static BloodType? fromApi(Object? value) =>
      values.where((e) => e.apiValue == value).firstOrNull;
}

/// Satu isian data diri yang dihitung untuk kelengkapan profil.
class ProfileField {
  const ProfileField(this.key, this.label);

  final String key;
  final String label;

  /// Urutan & label sama dengan `MemberProfileService::COMPLETION_FIELDS`.
  static const all = [
    ProfileField('name', 'Nama lengkap'),
    ProfileField('avatar', 'Foto profil'),
    ProfileField('gender', 'Jenis kelamin'),
    ProfileField('birth_place', 'Tempat lahir'),
    ProfileField('birth_date', 'Tanggal lahir'),
    ProfileField('phone', 'Nomor HP / WhatsApp'),
    ProfileField('address', 'Alamat'),
    ProfileField('archery_started_at', 'Mulai berlatih panahan'),
    ProfileField('bow_type', 'Jenis busur'),
    ProfileField('blood_type', 'Golongan darah'),
    ProfileField('emergency_contact_name', 'Nama kontak darurat'),
    ProfileField('emergency_contact_phone', 'Nomor kontak darurat'),
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
