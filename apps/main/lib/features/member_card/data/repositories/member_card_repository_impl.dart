import '../../domain/entities/member_card.dart';
import '../../domain/repositories/member_card_repository.dart';
import '../datasources/member_card_remote_data_source.dart';

class MemberCardRepositoryImpl implements MemberCardRepository {
  const MemberCardRepositoryImpl(this._remote);

  final MemberCardRemoteDataSource _remote;

  @override
  Future<MemberCard> getCard(String communityId) =>
      _remote.fetchCard(communityId);
}
