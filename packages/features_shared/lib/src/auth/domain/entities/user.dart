import '../../../profile/domain/entities/member_profile.dart';

class User {
  static const superAdminRole = 'super-admin';

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.roles = const [],
    this.gender,
    this.domicile,
    this.nikRegion,
    this.nikSameAsDomicile = false,
    ProfileCompletion? completion,
  }) : _completion = completion;

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final List<String> roles;

  // Data diri anggota (semua opsional; dilengkapi bertahap).
  final MemberGender? gender;
  final MemberRegion? domicile;

  /// Wilayah sesuai NIK (KTP). Bila [nikSameAsDomicile], server menyalinnya
  /// dari [domicile].
  final MemberRegion? nikRegion;
  final bool nikSameAsDomicile;

  final ProfileCompletion? _completion;

  /// Pembuka menu Admin Panel. Izin sebenarnya tetap ditentukan server.
  bool get isSuperAdmin => roles.contains(superAdminRole);

  /// Kelengkapan profil dari server; dihitung lokal bila server belum
  /// mengirimnya (aturan sama dengan backend).
  ProfileCompletion get completion =>
      _completion ??
      ProfileCompletion.fromFilled({
        if (name.trim().isNotEmpty) 'name',
        if (gender != null) 'gender',
        if (_filled(phone)) 'phone',
        if (domicile != null) 'domicile',
        if (nikRegion != null) 'nik_region',
      });

  static bool _filled(String? value) =>
      value != null && value.trim().isNotEmpty;
}
