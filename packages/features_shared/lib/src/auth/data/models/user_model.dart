import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.roles,
    this.token,
    this.refreshToken,
  });

  final String? token;

  /// Disimpan terpisah dari JSON user (lihat AuthLocalDataSource).
  final String? refreshToken;

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
        token: json['token'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'roles': roles,
        if (token != null) 'token': token,
      };

  UserModel copyWith({String? token, String? refreshToken}) => UserModel(
        id: id,
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        roles: roles,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
      );
}
