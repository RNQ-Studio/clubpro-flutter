class AchievementRow {
  const AchievementRow(
      {required this.id,
      required this.name,
      required this.points,
      this.rank = 0,
      this.communityId = '',
      this.communityName = '',
      this.type = '',
      this.ageGroup = '',
      this.gender = '',
      this.occurredAt = '',
      this.version = 1,
      this.reference = '',
      this.status = 'final',
      this.memberId = '',
      this.ruleVersion = 1,
      this.actor = '',
      this.createdAt = '',
      this.correctedBy = '',
      this.correctedAt = '',
      this.correctionReason = ''});
  final String id,
      name,
      communityId,
      communityName,
      type,
      ageGroup,
      gender,
      occurredAt,
      reference,
      status,
      memberId,
      actor,
      createdAt,
      correctedBy,
      correctedAt,
      correctionReason;
  final int points, rank, version, ruleVersion;
}

class AchievementPage {
  const AchievementPage(this.items,
      {this.page = 1,
      this.lastPage = 1,
      this.total = 0,
      this.totalPoints = 0,
      this.asOf = '',
      this.ruleVersion = 1,
      this.canManage = false,
      this.canCorrect = false});
  final List<AchievementRow> items;
  final int page, lastPage, total, totalPoints, ruleVersion;
  final String asOf;
  final bool canManage, canCorrect;
}

class AchievementRules {
  const AchievementRules(
      {required this.version,
      required this.points,
      required this.ageBoundaries,
      this.ageGroups = const {},
      this.history = const []});
  final int version;
  final Map<String, int> points;
  final List<int> ageBoundaries;
  final Map<String, String> ageGroups;
  final List<Map<String, dynamic>> history;
}

class MemberAd {
  const MemberAd(
      {required this.id,
      required this.title,
      required this.body,
      required this.communityId,
      required this.communityName,
      required this.sellerId,
      required this.sellerName,
      this.photoAssetId,
      this.photoUrl,
      this.productId,
      this.active = true,
      this.version = 1});
  final String id,
      title,
      body,
      communityId,
      communityName,
      sellerId,
      sellerName;
  final String? photoAssetId, photoUrl, productId;
  final bool active;
  final int version;
}

class MemberAdPage {
  const MemberAdPage(this.items,
      {this.page = 1,
      this.lastPage = 1,
      this.total = 0,
      this.activeCount = 0,
      this.maxActive = 5});
  final List<MemberAd> items;
  final int page, lastPage, total, activeCount, maxActive;
}
