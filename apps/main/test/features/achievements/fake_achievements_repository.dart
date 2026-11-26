import 'dart:async';
import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/achievements/domain/achievements_repository.dart';

const rulesFixture = AchievementRules(version: 2, points: {
  'training_attendance': 1,
  'training_purchase': 1,
  'participation': 2,
  'champion': 3
}, ageBoundaries: [
  12,
  16,
  19,
  36,
  51
], ageGroups: {
  'u12': 'Di bawah 12 tahun',
  '12_15': '12–15 tahun',
  '16_18': '16–18 tahun',
  '19_35': '19–35 tahun',
  '36_50': '36–50 tahun',
  '51_plus': 'Di atas 50 tahun',
  'unknown': 'Usia belum lengkap'
}, history: [
  {
    'version': 2,
    'points': {
      'training_attendance': 1,
      'training_purchase': 1,
      'participation': 2,
      'champion': 3
    },
    'age_boundaries': [12, 16, 19, 36, 51],
    'changed_by': 1,
    'effective_at': '2026-11-26T01:00:00Z',
    'reason': 'Penyesuaian poin kegiatan'
  }
]);
const rowFixture = AchievementRow(
    id: '2',
    name: 'Atlet dengan nama panjang dari komunitas olahraga bersama',
    points: 999999999,
    rank: 1,
    communityId: '2',
    communityName: 'Komunitas Olahraga Anak Langit',
    type: 'champion',
    ageGroup: '19_35',
    gender: 'female',
    occurredAt: '2026-11-26T00:00:00Z',
    reference: 'HASIL/2026/11/001',
    memberId: '3',
    version: 1,
    actor: '1');
const adFixture = MemberAd(
    id: 'ad-1',
    title: 'Latihan bersama dan perlengkapan komunitas pilihan',
    body:
        'Informasi anggota untuk kegiatan bersama, jadwal dan perlengkapan. Judul dan isi yang panjang tetap dapat dibaca di layar kecil tanpa terpotong.',
    communityId: '2',
    communityName: 'Komunitas Olahraga Anak Langit',
    sellerId: '2',
    sellerName: 'Anggota komunitas dengan nama panjang',
    productId: 'product-1',
    version: 2);

class FakeAchievements implements AchievementsRepository {
  Object? error, saveError;
  Completer<void>? gate, saveGate;
  bool empty = false, canManage = true, canCorrect = true;
  int totalPoints = 999999999, mineCalls = 0;
  int saveCalls = 0, correctCalls = 0, ruleCalls = 0, deleteCalls = 0;
  final requests = <Map<String, Object?>>[], queries = <Map<String, Object?>>[];
  MemberAd value = adFixture;
  Future<void> load() async {
    await gate?.future;
    if (error != null) throw error!;
  }

  Future<void> save(Map<String, Object?> f) async {
    saveCalls++;
    requests.add(f);
    await saveGate?.future;
    if (saveError != null) throw saveError!;
  }

  AchievementPage page(int p, {bool own = false}) =>
      AchievementPage(empty ? [] : [rowFixture],
          page: p,
          lastPage: 2,
          total: 2,
          totalPoints: totalPoints,
          asOf: '2026-11-30',
          ruleVersion: 2,
          canManage: canManage,
          canCorrect: canCorrect);
  @override
  Future<AchievementRules> rules({bool admin = false}) async {
    await load();
    return rulesFixture;
  }

  @override
  Future<void> saveRules(Map<String, Object?> f) async {
    ruleCalls++;
    await save(f);
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
      int page = 1}) async {
    queries.add({
      'scope': scope,
      'community': communityId,
      'period': period,
      'month': month,
      'as_of': asOf,
      'gender': gender,
      'age_group': ageGroup,
      'page': page
    });
    await load();
    return this.page(page);
  }

  @override
  Future<AchievementPage> mine({int page = 1}) async {
    mineCalls++;
    await load();
    return this.page(page, own: true);
  }

  @override
  Future<AchievementPage> community(String id, {int page = 1}) async {
    await load();
    return this.page(page);
  }

  @override
  Future<List<Map<String, dynamic>>> candidates(String communityId,
      {String search = '', int page = 1}) async {
    await load();
    return [
      {'id': 3, 'name': 'Atlet Fixture', 'role': 'member'}
    ];
  }

  @override
  Future<void> create(String communityId, Map<String, Object?> f) => save(f);
  @override
  Future<void> correct(
      String communityId, String id, int version, String reason) async {
    correctCalls++;
    await save({'expected_version': version, 'reason': reason});
  }

  @override
  Future<MemberAdPage> ads(
      {bool mine = false,
      String? communityId,
      String? sellerId,
      String search = '',
      int page = 1}) async {
    queries.add({
      'mine': mine,
      'community': communityId,
      'seller': sellerId,
      'search': search,
      'page': page
    });
    await load();
    return MemberAdPage(empty ? [] : [value],
        page: page, lastPage: 2, total: 2, activeCount: 1);
  }

  @override
  Future<MemberAd> ad(String id) async {
    await load();
    return value;
  }

  @override
  Future<void> saveAd(Map<String, Object?> f, {String? id}) => save(f);
  @override
  Future<void> deleteAd(String id, int version) async {
    deleteCalls++;
    await save({'id': id, 'expected_version': version});
  }
}
