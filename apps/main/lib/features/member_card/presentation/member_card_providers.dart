import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../community/presentation/community_providers.dart';
import '../data/datasources/member_card_remote_data_source.dart';
import '../data/repositories/member_card_repository_impl.dart';
import '../domain/entities/member_card.dart';
import '../domain/repositories/member_card_repository.dart';

part 'member_card_providers.g.dart';

@Riverpod(keepAlive: true)
MemberCardRepository memberCardRepository(Ref ref) => MemberCardRepositoryImpl(
    MemberCardRemoteDataSource(ref.watch(apiClientProvider).dio));

/// Kartu anggota saya di komunitas [communityId].
@Riverpod(retry: noRetry)
Future<MemberCard> memberCard(Ref ref, String communityId) =>
    ref.watch(memberCardRepositoryProvider).getCard(communityId);
