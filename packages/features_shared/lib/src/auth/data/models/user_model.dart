import 'package:core/core.dart';

import '../../../profile/domain/entities/member_profile.dart';
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.roles,
    super.gender,
    super.birthPlace,
    super.birthDate,
    super.address,
    super.bloodType,
    super.emergencyContactName,
    super.emergencyContactPhone,
    this.serverCompletion,
    this.token,
    this.refreshToken,
  }) : super(completion: serverCompletion);

  final String? token;

  /// Disimpan terpisah dari JSON user (lihat AuthLocalDataSource).
  final String? refreshToken;

  /// `profile_completion` dari server (null bila server lama).
  final ProfileCompletion? serverCompletion;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        gender: MemberGender.fromApi(json['gender']),
        birthPlace: json['birth_place'] as String?,
        birthDate: _date(json['birth_date']),
        address: json['address'] as String?,
        bloodType: BloodType.fromApi(json['blood_type']),
        emergencyContactName: json['emergency_contact_name'] as String?,
        emergencyContactPhone: json['emergency_contact_phone'] as String?,
        serverCompletion: _matchingCompletion(json['profile_completion']),
        token: json['token'] as String?,
      );

  /// Cache lokal (mode offline) memakai bentuk JSON yang sama dengan API.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'roles': roles,
        if (gender != null) 'gender': gender!.apiValue,
        if (birthPlace != null) 'birth_place': birthPlace,
        if (birthDate != null) 'birth_date': AppDateUtils.isoDate(birthDate!),
        if (address != null) 'address': address,
        if (bloodType != null) 'blood_type': bloodType!.apiValue,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
        if (serverCompletion != null)
          'profile_completion': serverCompletion!.toJson(),
        if (token != null) 'token': token,
      };

  /// Salinan dengan token; data profil tetap.
  UserModel copyWith({String? token, String? refreshToken}) => UserModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        roles: roles,
        gender: gender,
        birthPlace: birthPlace,
        birthDate: birthDate,
        address: address,
        bloodType: bloodType,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        serverCompletion: serverCompletion,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  /// `profile_completion` server dipakai hanya bila daftar isiannya sama
  /// dengan app; selain itu (server/cache lama) dihitung lokal.
  static ProfileCompletion? _matchingCompletion(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final completion = ProfileCompletion.fromJson(json);
    return completion.matchesAppFields ? completion : null;
  }

  static DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}
