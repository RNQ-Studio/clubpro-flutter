import 'achievements.dart';

abstract interface class AchievementsRepository {
  Future<AchievementRules> rules({bool admin = false});
  Future<void> saveRules(Map<String, Object?> fields);
  Future<AchievementPage> rankings(
      {String scope = 'communities',
      String? communityId,
      String period = 'month',
      String? month,
      String? asOf,
      String? gender,
      String? ageGroup,
      int page = 1});
  Future<AchievementPage> mine({int page = 1});
  Future<List<Map<String, dynamic>>> candidates(String communityId,
      {String search = '', int page = 1});
  Future<AchievementPage> community(String id, {int page = 1});
  Future<void> create(String communityId, Map<String, Object?> fields);
  Future<void> correct(
      String communityId, String id, int version, String reason);
  Future<MemberAdPage> ads(
      {bool mine = false,
      String? communityId,
      String? sellerId,
      String search = '',
      int page = 1});
  Future<MemberAd> ad(String id);
  Future<void> saveAd(Map<String, Object?> fields, {String? id});
  Future<void> deleteAd(String id, int version);
}
