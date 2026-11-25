import 'dart:convert';
import 'dart:typed_data';
import 'package:app_main/features/directory/data/directory_repository_impl.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responses follow ApiResponse, PublicCommunityResource/PublicMemberResource,
/// ManualMemberService and GuardianController resources in clubpro-laravel.
class _FixtureAdapter implements HttpClientAdapter {
  _FixtureAdapter(this.respond);
  final (int, Object) Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests.add(options);
    final (status, body) = respond(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_FixtureAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
      ..httpClientAdapter = adapter;
Map<String, Object?> _page(List<Map<String, Object?>> data,
        {int current = 2, int last = 4}) =>
    {
      'success': true,
      'message': 'OK',
      'data': data,
      'meta': {
        'pagination': {
          'current_page': current,
          'last_page': last,
          'per_page': 20,
          'total': 67
        }
      }
    };
const _community = <String, Object?>{
  'id': 7,
  'name': 'Komunitas Uji',
  'short_name': 'KU',
  'type': 'panahan',
  'type_label': 'Panahan',
  'description': 'Latihan bersama',
  'city_name': 'Kota Bandung',
  'province_name': 'Jawa Barat',
  'logo_url': null,
  'members_count': 4
};
void main() {
  test(
      'public paginator maps identity and membership separately with community origin',
      () async {
    final adapter = _FixtureAdapter((o) {
      expect(o.queryParameters.containsKey('status'), false);
      if (o.path == 'v1/public/communities') {
        expect(o.queryParameters, {'search': 'komunitas', 'page': 2});
        return (200, _page([_community]));
      }
      expect(o.path, 'v1/public/members');
      expect(o.queryParameters,
          {'search': 'Rina', 'page': 3, 'community_id': '7', 'role': 'coach'});
      return (
        200,
        _page([
          {
            'id': 91,
            'membership_id': 42,
            'name': 'Rina',
            'avatar_url': null,
            'role': 'coach',
            'role_label': 'Pelatih',
            'community': {
              'id': 7,
              'name': 'Komunitas Uji',
              'short_name': 'KU',
              'city_name': 'Kota Bandung'
            }
          }
        ], current: 3)
      );
    });
    final repo = DirectoryRepositoryImpl(_dio(adapter));
    final communities =
        await repo.search(members: false, search: 'komunitas', page: 2);
    expect(communities.page, 2);
    expect(communities.lastPage, 4);
    expect(communities.items.single.id, '7');
    expect(communities.items.single.subtitle, 'Kota Bandung · Panahan');
    final members = await repo.search(
        members: true,
        search: 'Rina',
        communityId: '7',
        role: 'coach',
        page: 3);
    final member = members.items.single;
    expect(members.page, 3);
    expect(member.id, '91');
    expect(member.membershipId, '42');
    expect(member.communityId, '7');
    expect(member.role, 'coach');
    expect(member.subtitle, 'Pelatih · Komunitas Uji');
    expect(adapter.requests.length, 2);
  });
  test(
      'manual create sends stable retry key and private detail keeps identity/grants',
      () async {
    const fields = <String, Object?>{
      'name': 'Anak Uji',
      'birth_date': '2016-05-20',
      'gender': null,
      'account_email': null,
      'external_reference': 'anak-01',
      'idempotency_key': '11111111-1111-4111-8111-111111111111'
    };
    final adapter = _FixtureAdapter((o) {
      if (o.method == 'POST') {
        expect(o.path, 'v1/communities/7/manual-members');
        expect(o.data, fields);
        return (
          201,
          {
            'success': true,
            'data': {
              'id': 42,
              'user_id': null,
              'member_identity_id': 91,
              'is_manual': true,
              'name': 'Anak Uji',
              'role': 'member',
              'status': 'active'
            }
          }
        );
      }
      expect(o.method, 'GET');
      expect(o.path, 'v1/communities/7/manual-members/42');
      return (
        200,
        {
          'success': true,
          'data': {
            'id': 42,
            'user_id': null,
            'member_identity_id': 91,
            'name': 'Anak Uji',
            'birth_date': '2016-05-20',
            'gender': null,
            'external_reference': 'anak-01',
            'account_email': null,
            'guardian_grants': [
              {
                'id': 8,
                'email': 'wali@anaklangit.manahpro.web.id',
                'verified_at': '2026-11-26T01:00:00+07:00',
                'revoked_at': null
              }
            ]
          }
        }
      );
    });
    final repo = DirectoryRepositoryImpl(_dio(adapter));
    final created = await repo.createMember('7', fields);
    expect(created['id'], 42);
    expect(created['user_id'], null);
    expect(created['member_identity_id'], 91);
    final detail = await repo.memberDetail('7', created['id'].toString());
    expect(detail['birth_date'], '2016-05-20');
    expect(detail['external_reference'], 'anak-01');
    expect((detail['guardian_grants'] as List).single['id'], 8);
    expect(adapter.requests.length, 2);
  });
  test(
      'dependent detail retains own grant and KTA nested validity on scoped route',
      () async {
    final adapter = _FixtureAdapter((o) {
      if (o.path == 'v1/dependents/91') {
        return (
          200,
          {
            'success': true,
            'data': {
              'id': 91,
              'name': 'Anak Uji',
              'user_id': null,
              'grant_id': 8,
              'is_public': false,
              'birth_date': '2016-05-20',
              'gender': null,
              'memberships': [
                {
                  'id': 42,
                  'community_id': 7,
                  'community_name': 'Komunitas Uji',
                  'status': 'active',
                  'role': 'member',
                  'member_number': 'KU-000042'
                }
              ]
            }
          }
        );
      }
      expect(o.path, 'v1/dependents/91/memberships/42/card');
      return (
        200,
        {
          'success': true,
          'data': {
            'name': 'Anak Uji',
            'member_number': 'KU-000042',
            'role_label': 'Anggota',
            'community_name': 'Komunitas Uji',
            'validity': {
              'status': 'active',
              'valid_until': '2026-12-05',
              'paid_until': '2026-11-01',
              'pending_payment': false
            }
          }
        }
      );
    });
    final repo = DirectoryRepositoryImpl(_dio(adapter));
    final dependent = await repo.dependent('91');
    expect(dependent['grant_id'], 8);
    expect((dependent['memberships'] as List).single['id'], 42);
    final card = await repo.card(dependent['id'].toString(), '42');
    expect(card['member_number'], 'KU-000042');
    expect(card.containsKey('valid_until'), false);
    expect((card['validity'] as Map)['valid_until'], '2026-12-05');
    expect((card['validity'] as Map)['status'], 'active');
  });
  test(
      'forbidden and field validation errors retain actionable Indonesian messages',
      () async {
    final adapter = _FixtureAdapter((o) => o.method == 'GET'
        ? (
            403,
            {
              'success': false,
              'message': 'Anda tidak berhak mengelola anggota komunitas ini.'
            }
          )
        : (
            422,
            {
              'success': false,
              'message': 'The given data was invalid.',
              'errors': {
                'external_reference': ['Referensi lokal sudah digunakan.']
              }
            }
          ));
    final repo = DirectoryRepositoryImpl(_dio(adapter));
    await expectLater(
        repo.memberDetail('7', '42'),
        throwsA(isA<ServerException>().having((e) => e.toString(), 'message',
            contains('Anda tidak berhak mengakses data ini.'))));
    await expectLater(
        repo.createMember('7', {'name': 'Anak'}),
        throwsA(isA<ServerException>().having((e) => e.toString(), 'message',
            contains('Referensi lokal sudah digunakan.'))));
  });
  for (final status in [403, 404, 500]) {
    test('generic English HTTP $status becomes Indonesian UI error', () async {
      final adapter = _FixtureAdapter((o) => (
            status,
            {
              'success': false,
              'message': status == 403
                  ? 'This action is unauthorized.'
                  : 'Resource not found.'
            }
          ));
      final repo = DirectoryRepositoryImpl(_dio(adapter));
      final expected = switch (status) {
        403 => 'Anda tidak berhak mengakses data ini.',
        404 => 'Data tidak ditemukan.',
        _ => 'Server sedang mengalami kendala. Silakan coba lagi.'
      };
      await expectLater(
          repo.community('7'),
          throwsA(isA<ServerException>()
              .having((e) => e.toString(), 'message', contains(expected))));
    });
  }
}
