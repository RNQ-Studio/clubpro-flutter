import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/achievements_remote_data_source.dart';
import '../data/achievements_repository_impl.dart';
import '../domain/achievements.dart';
import '../domain/achievements_repository.dart';
part 'achievements_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;
void _account(Ref ref) {
  ref.watch(authProvider);
}

@riverpod
AchievementsRepository achievementsRepository(Ref ref) =>
    AchievementsRepositoryImpl(
        AchievementsRemoteDataSource(ref.watch(apiClientProvider).dio));
@Riverpod(retry: _noRetry)
Future<AchievementRules> achievementRules(Ref ref, {bool admin = false}) {
  if (admin) _account(ref);
  return ref.watch(achievementsRepositoryProvider).rules(admin: admin);
}

@Riverpod(retry: _noRetry)
Future<AchievementPage> rankings(Ref ref,
        {String scope = 'communities',
        String? communityId,
        String period = 'month',
        String? month,
        String? asOf,
        String? gender,
        String? ageGroup,
        int page = 1}) =>
    ref.watch(achievementsRepositoryProvider).rankings(
        scope: scope,
        communityId: communityId,
        period: period,
        month: month,
        asOf: asOf,
        gender: gender,
        ageGroup: ageGroup,
        page: page);
@Riverpod(retry: _noRetry)
Future<AchievementPage> myAchievements(Ref ref, {int page = 1}) {
  _account(ref);
  return ref.watch(achievementsRepositoryProvider).mine(page: page);
}

@Riverpod(retry: _noRetry)
Future<AchievementPage> communityAchievements(Ref ref, String id,
    {int page = 1}) {
  _account(ref);
  return ref.watch(achievementsRepositoryProvider).community(id, page: page);
}

@Riverpod(retry: _noRetry)
Future<MemberAdPage> memberAds(Ref ref,
    {bool mine = false,
    String? communityId,
    String? sellerId,
    String search = '',
    int page = 1}) {
  if (mine) _account(ref);
  return ref.watch(achievementsRepositoryProvider).ads(
      mine: mine,
      communityId: communityId,
      sellerId: sellerId,
      search: search,
      page: page);
}

void invalidateAchievements(void Function(ProviderOrFamily) invalidate) {
  invalidate(rankingsProvider);
  invalidate(myAchievementsProvider);
  invalidate(communityAchievementsProvider);
}

@Riverpod(retry: _noRetry)
Future<List<Map<String, dynamic>>> achievementMembers(
    Ref ref, String communityId,
    {String search = '', int page = 1}) {
  _account(ref);
  return ref
      .watch(achievementsRepositoryProvider)
      .candidates(communityId, search: search, page: page);
}
