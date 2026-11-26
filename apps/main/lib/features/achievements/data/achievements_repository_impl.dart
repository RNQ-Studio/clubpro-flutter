import '../../finance/data/finance_models.dart';
import '../domain/achievements.dart';
import '../domain/achievements_repository.dart';
import 'achievements_remote_data_source.dart';

int moneyOf(Object? x, {int fallback = 0}) =>
    x is int ? x : int.tryParse('$x') ?? fallback;

class AchievementsRepositoryImpl implements AchievementsRepository {
  const AchievementsRepositoryImpl(this.remote);
  final AchievementsRemoteDataSource remote;
  AchievementRow _row(Map<String, dynamic> j) {
    final c = financeMap(j['community']);
    return AchievementRow(
        id: textOf(j['id'] ?? j['identity_id'] ?? j['community_id']),
        name: j['member_name'] != null
            ? '${j['member_name']} · ${j['title']}'
            : textOf(j['name'] ?? j['title']),
        points: requiredMoney(j['points']),
        rank: moneyOf(j['rank']),
        communityId: textOf(c['id'] ?? j['community_id']),
        communityName: textOf(c['name']),
        type: textOf(j['type']),
        ageGroup: textOf(j['age_group']),
        gender: textOf(j['gender']),
        occurredAt: textOf(j['occurred_at']),
        version: moneyOf(j['version'], fallback: 1),
        ruleVersion: moneyOf(j['rule_version'], fallback: 1),
        reference: textOf(j['reference'] ?? j['source_id']),
        status: textOf(j['status']),
        memberId: textOf(j['member_id']),
        actor: textOf(j['created_by_name'] ??
            j['actor_name'] ??
            j['created_by'] ??
            j['actor_id']),
        createdAt: textOf(j['created_at']),
        correctedBy: textOf(j['corrected_by_name'] ?? j['corrected_by']),
        correctedAt: textOf(j['corrected_at']),
        correctionReason: textOf(j['correction_reason']));
  }

  AchievementPage _page(Map<String, dynamic> j) => AchievementPage(
      [for (final x in financeList(j['items'])) _row(financeMap(x))],
      page: moneyOf(j['current_page'], fallback: 1),
      lastPage: moneyOf(j['last_page'], fallback: 1),
      total: moneyOf(j['total']),
      totalPoints: moneyOf(j['total_points']),
      asOf: textOf(j['as_of']),
      ruleVersion: moneyOf(j['rule_version'], fallback: 1),
      canManage: j['can_manage'] == true,
      canCorrect: j['can_correct'] == true);
  MemberAd _ad(Map<String, dynamic> j) {
    final c = financeMap(j['community']), s = financeMap(j['seller']);
    return MemberAd(
        id: textOf(j['id']),
        title: textOf(j['title']),
        body: textOf(j['body']),
        communityId: textOf(c['id'] ?? j['community_id']),
        communityName: textOf(c['name']),
        sellerId: textOf(s['identity_id']),
        sellerName: textOf(s['name']),
        photoAssetId: j['photo_asset_id']?.toString(),
        photoUrl: j['photo_url']?.toString(),
        productId: j['target_product_id']?.toString(),
        active: j['is_active'] == true,
        version: moneyOf(j['version'], fallback: 1));
  }

  @override
  Future<AchievementRules> rules({bool admin = false}) async {
    final j = await remote.request('GET',
        admin ? 'admin/achievement-rules' : 'public/achievement-options');
    return AchievementRules(version: requiredMoney(j['version']), points: {
      for (final e in financeMap(j['points']).entries)
        e.key: requiredMoney(e.value)
    }, ageBoundaries: [
      for (final x in (j['age_boundaries'] as List? ?? [])) requiredMoney(x)
    ], ageGroups: {
      for (final x in financeList(j['age_groups']))
        textOf(financeMap(x)['id']): textOf(financeMap(x)['label'])
    }, history: [
      for (final x in financeList(j['history'])) financeMap(x)
    ]);
  }

  @override
  Future<void> saveRules(Map<String, Object?> fields) async {
    await remote.request('PUT', 'admin/achievement-rules', fields: fields);
  }

  @override
  Future<AchievementPage> rankings(
          {String scope = 'communities',
          String? communityId,
          String period = 'month',
          String? month,
          String? asOf,
          String? gender,
          String? ageGroup,
          int page = 1}) async =>
      _page(await remote.request('GET', 'public/rankings', query: {
        'scope': scope,
        'period': period,
        'page': page,
        if (communityId != null) 'community_id': communityId,
        if (month != null) 'month': month,
        if (asOf != null) 'as_of': asOf,
        if (gender != null) 'gender': gender,
        if (ageGroup != null) 'age_group': ageGroup
      }));
  @override
  Future<AchievementPage> mine({int page = 1}) async => _page(
      await remote.request('GET', 'achievements/me', query: {'page': page}));
  @override
  Future<List<Map<String, dynamic>>> candidates(String communityId,
          {String search = '', int page = 1}) async =>
      financeList((await remote.request(
          'GET', 'communities/$communityId/achievement-members',
          query: {'search': search, 'page': page}))['items']);
  @override
  Future<AchievementPage> community(String id, {int page = 1}) async =>
      _page(await remote.request('GET', 'communities/$id/achievements',
          query: {'page': page}));
  @override
  Future<void> create(String communityId, Map<String, Object?> fields) async {
    await remote.request('POST', 'communities/$communityId/achievements',
        fields: fields);
  }

  @override
  Future<void> correct(
      String communityId, String id, int version, String reason) async {
    await remote.request(
        'POST', 'communities/$communityId/achievements/$id/correct',
        fields: {'expected_version': version, 'reason': reason});
  }

  @override
  Future<MemberAdPage> ads(
      {bool mine = false,
      String? communityId,
      String? sellerId,
      String search = '',
      int page = 1}) async {
    final j = await remote.request(
        'GET', mine ? 'advertisements' : 'public/advertisements',
        query: {
          'search': search,
          'page': page,
          if (communityId != null) 'community_id': communityId,
          if (sellerId != null) 'seller_identity_id': sellerId
        });
    return MemberAdPage(
        [for (final x in financeList(j['items'])) _ad(financeMap(x))],
        page: moneyOf(j['current_page'], fallback: 1),
        lastPage: moneyOf(j['last_page'], fallback: 1),
        total: moneyOf(j['total']),
        activeCount: moneyOf(j['active_count']),
        maxActive: moneyOf(j['max_active'], fallback: 5));
  }

  @override
  Future<MemberAd> ad(String id) async =>
      _ad(await remote.request('GET', 'advertisements/$id'));
  @override
  Future<void> saveAd(Map<String, Object?> fields, {String? id}) async {
    await remote.request(id == null ? 'POST' : 'PUT',
        'advertisements${id == null ? '' : '/$id'}',
        fields: fields);
  }

  @override
  Future<void> deleteAd(String id, int version) async {
    await remote.request('DELETE', 'advertisements/$id',
        query: {'expected_version': version});
  }
}
