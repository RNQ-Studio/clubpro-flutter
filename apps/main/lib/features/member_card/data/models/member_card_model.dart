import '../../../community/data/models/community_model.dart';
import '../../domain/entities/member_card.dart';

/// `GET v1/communities/{id}/card` → `data`.
MemberCard memberCardFromJson(Map<String, dynamic> json) {
  final validity = json['validity'] as Map<String, dynamic>? ?? const {};
  return MemberCard(
    memberNumber: json['member_number'] as String,
    name: json['name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    roleLabel: json['role_label'] as String? ?? 'Anggota',
    joinedAt: _date(json['joined_at'])?.toLocal(),
    community:
        CommunityModel.fromJson(json['community'] as Map<String, dynamic>),
    validity: MemberCardValidity(
      status: MemberCardStatus.fromApi(validity['status']),
      validUntil: _date(validity['valid_until']),
      paidUntil: _date(
        validity['paid_until'] is String
            ? '${validity['paid_until']}-01'
            : null,
      ),
      pendingPayment: validity['pending_payment'] == true,
    ),
  );
}

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
