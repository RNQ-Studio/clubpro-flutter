import '../../../community/domain/entities/community.dart';

/// Status masa berlaku kartu menurut iuran bulanan yang lunas.
enum MemberCardStatus {
  /// Hari ini masih dalam masa berlaku.
  active('active'),

  /// Masa berlaku lewat: iuran bulan berikutnya menunggak.
  expired('expired'),

  /// Belum ada bulan iuran yang lunas.
  inactive('inactive'),

  /// Komunitas belum mengatur iuran: berlaku selama menjadi anggota.
  noDues('no_dues');

  const MemberCardStatus(this.apiValue);
  final String apiValue;

  static MemberCardStatus fromApi(Object? value) =>
      values.where((s) => s.apiValue == value).firstOrNull ?? inactive;

  /// Kartu sah dipakai hari ini.
  bool get isValid => this == active || this == noDues;
}

class MemberCardValidity {
  const MemberCardValidity({
    required this.status,
    this.validUntil,
    this.paidUntil,
    this.pendingPayment = false,
  });

  final MemberCardStatus status;

  /// Hari terakhir kartu berlaku (jatuh tempo bulan sesudah [paidUntil]).
  final DateTime? validUntil;

  /// Bulan terakhir yang lunas berturut-turut (tanggal 1 bulan itu).
  final DateTime? paidUntil;

  /// Ada pembayaran iuran yang menunggu verifikasi pengurus.
  final bool pendingPayment;
}

/// Kartu anggota pengguna yang login di satu komunitas.
class MemberCard {
  const MemberCard({
    required this.memberNumber,
    required this.name,
    required this.roleLabel,
    required this.community,
    required this.validity,
    this.avatarUrl,
    this.joinedAt,
  });

  final String memberNumber;
  final String name;
  final String? avatarUrl;
  final String roleLabel;
  final DateTime? joinedAt;
  final Community community;
  final MemberCardValidity validity;
}
