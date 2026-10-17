import '../../../profile/domain/entities/member_profile.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.roles = const [],
    this.gender,
    this.birthPlace,
    this.birthDate,
    this.address,
    this.archeryStartedAt,
    this.bowType,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    ProfileCompletion? completion,
  }) : _completion = completion;

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final List<String> roles;

  // Data diri anggota club (semua opsional; dilengkapi bertahap).
  final MemberGender? gender;
  final String? birthPlace;
  final DateTime? birthDate;
  final String? address;

  /// Bulan & tahun pertama mencoba panahan (hari = 1).
  final DateTime? archeryStartedAt;
  final BowType? bowType;
  final BloodType? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  final ProfileCompletion? _completion;

  /// Kelengkapan profil dari server; dihitung lokal bila server belum
  /// mengirimnya (aturan sama dengan backend).
  ProfileCompletion get completion =>
      _completion ??
      ProfileCompletion.fromFilled({
        if (name.trim().isNotEmpty) 'name',
        if (_filled(avatarUrl)) 'avatar',
        if (gender != null) 'gender',
        if (_filled(birthPlace)) 'birth_place',
        if (birthDate != null) 'birth_date',
        if (_filled(phone)) 'phone',
        if (_filled(address)) 'address',
        if (archeryStartedAt != null) 'archery_started_at',
        if (bowType != null) 'bow_type',
        if (bloodType != null) 'blood_type',
        if (_filled(emergencyContactName)) 'emergency_contact_name',
        if (_filled(emergencyContactPhone)) 'emergency_contact_phone',
      });

  static bool _filled(String? value) =>
      value != null && value.trim().isNotEmpty;
}
