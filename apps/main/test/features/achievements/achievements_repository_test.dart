import 'package:app_main/features/achievements/data/achievements_remote_data_source.dart';
import 'package:app_main/features/achievements/data/achievements_repository_impl.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import '../marketplace/marketplace_repository_test.dart' show MarketAdapter;

void main() {
  late MarketAdapter adapter;
  late AchievementsRepositoryImpl repo;
  setUp(() {
    adapter = MarketAdapter();
    repo = AchievementsRepositoryImpl(AchievementsRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter));
  });
  test(
      'public ranking envelope preserves dense ranks and signed points provenance',
      () async {
    adapter.payload = {
      'data': {
        'items': [
          {'community_id': 2, 'name': 'Komunitas A', 'points': 3, 'rank': 1},
          {'community_id': 4, 'name': 'Komunitas B', 'points': 3, 'rank': 1}
        ],
        'current_page': 2,
        'last_page': 3,
        'total': 5,
        'as_of': '2026-11-30',
        'rule_version': 2
      }
    };
    final p = await repo.rankings(
        scope: 'communities',
        period: 'month',
        month: '2026-11',
        gender: 'female',
        ageGroup: 'unknown',
        page: 2);
    expect(p.items.map((r) => r.rank), [1, 1]);
    expect(p.items.first.id, '2');
    expect(p.asOf, '2026-11-30');
    expect(adapter.request!.path, 'v1/public/rankings');
    expect(
        adapter.request!.queryParameters, containsPair('age_group', 'unknown'));
    expect(adapter.request!.queryParameters, containsPair('month', '2026-11'));
  });
  test('own points negative correction and total independent from money',
      () async {
    adapter.payload = {
      'data': {
        'items': [
          {
            'id': 'ledger-1',
            'type': 'manual_correction',
            'points': -3,
            'source_id': 'source-1',
            'actor_name': 'Pendiri Fixture',
            'created_at': '2026-11-26T01:00:00Z',
            'rule_version': 2,
            'community': {'id': 2, 'name': 'Komunitas A'}
          }
        ],
        'total_points': 1,
        'current_page': 1,
        'last_page': 1
      }
    };
    final p = await repo.mine();
    expect(p.totalPoints, 1);
    expect(p.items.single.points, -3);
    expect(p.items.single.reference, 'source-1');
    expect(p.items.single.actor, 'Pendiri Fixture');
    expect(p.items.single.createdAt, '2026-11-26T01:00:00Z');
    expect(adapter.request!.path, 'v1/achievements/me');
  });
  test('central rule integer boundaries and audit history parsed', () async {
    adapter.payload = {
      'data': {
        'version': 2,
        'points': {'training_attendance': 1, 'champion': 3},
        'age_boundaries': [12, 16, 19, 36, 51],
        'age_groups': [
          {'id': 'unknown', 'label': 'Usia belum lengkap'}
        ],
        'history': [
          {'version': 2, 'reason': 'Audit', 'changed_by': 1}
        ]
      }
    };
    final r = await repo.rules(admin: true);
    expect(r.ageBoundaries, [12, 16, 19, 36, 51]);
    expect(r.ageGroups['unknown'], 'Usia belum lengkap');
    expect(r.history.single['changed_by'], 1);
    expect(adapter.request!.path, 'v1/admin/achievement-rules');
  });
  test('manual creation forwards source key no client point award', () async {
    adapter.payload = {'data': {}};
    await repo.create('2', {
      'member_id': 7,
      'type': 'champion',
      'reference': 'HASIL/001',
      'idempotency_key': 'same-source'
    });
    expect(adapter.request!.path, 'v1/communities/2/achievements');
    expect(adapter.request!.method, 'POST');
    expect(
        adapter.request!.data, containsPair('idempotency_key', 'same-source'));
    expect((adapter.request!.data as Map).containsKey('points'), false);
    await repo.correct('2', 'event-1', 3, 'Hasil diperbaiki');
    expect(adapter.request!.data,
        {'expected_version': 3, 'reason': 'Hasil diperbaiki'});
  });
  test('coach safe picker uses dedicated minimal endpoint', () async {
    adapter.payload = {
      'data': {
        'items': [
          {'id': 7, 'name': 'Atlet', 'role': 'member'}
        ]
      }
    };
    expect(
        (await repo.candidates('2', search: 'Atlet', page: 2)).single['id'], 7);
    expect(adapter.request!.path, 'v1/communities/2/achievement-members');
    expect(adapter.request!.queryParameters, {'search': 'Atlet', 'page': 2});
  });
  test('ads public and owner snapshot selected server-side', () async {
    adapter.payload = {
      'data': {
        'items': [
          {
            'id': 'ad-1',
            'title': 'Judul',
            'body': 'Isi iklan',
            'version': 2,
            'target_product_id': 'product-1',
            'is_active': true,
            'seller': {'identity_id': 7, 'name': 'Penjual'},
            'community': {'id': 2, 'name': 'Komunitas'}
          }
        ],
        'current_page': 1,
        'last_page': 2,
        'active_count': 1,
        'max_active': 5
      }
    };
    final p = await repo.ads(communityId: '2', sellerId: '7', search: 'Judul');
    expect(p.items.single.productId, 'product-1');
    expect(p.items.single.communityId, '2');
    expect(adapter.request!.path, 'v1/public/advertisements');
    await repo.ads(mine: true);
    expect(adapter.request!.path, 'v1/advertisements');
  });
  test('ad edits and delete carry optimistic version', () async {
    adapter.payload = {'data': {}};
    await repo.saveAd({'expected_version': 2, 'title': 'Baru'}, id: 'ad-1');
    expect(adapter.request!.method, 'PUT');
    expect(adapter.request!.data, containsPair('expected_version', 2));
    await repo.deleteAd('ad-1', 3);
    expect(adapter.request!.method, 'DELETE');
    expect(adapter.request!.queryParameters, {'expected_version': 3});
  });
  test('malformed decimal points rejected', () async {
    adapter.payload = {
      'data': {
        'items': [
          {'id': 1, 'points': 1.5}
        ]
      }
    };
    expect(repo.mine(), throwsA(isA<FinanceDataException>()));
  });
  for (final code in [401, 403, 404, 409, 422, 500]) {
    test('HTTP $code uses safe Indonesian failure', () async {
      adapter.status = code;
      adapter.payload = {'message': 'The given data was invalid.'};
      expect(
          repo.mine(),
          throwsA(code == 401
              ? isA<FinanceAuthenticationException>()
              : code == 409
                  ? isA<FinanceConflictException>()
                  : isA<AppException>()));
    });
  }
}
