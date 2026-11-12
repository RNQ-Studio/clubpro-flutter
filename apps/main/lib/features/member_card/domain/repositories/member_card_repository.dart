import '../entities/member_card.dart';

abstract interface class MemberCardRepository {
  /// Kartu anggota pengguna yang login di komunitas [communityId].
  Future<MemberCard> getCard(String communityId);
}
