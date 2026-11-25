import 'dart:convert';
import 'dart:typed_data';

import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/money_movement/data/money_movement_models.dart';
import 'package:app_main/features/money_movement/data/money_movement_remote_data_source.dart';
import 'package:app_main/features/money_movement/data/money_movement_repository_impl.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the actual HTTP mapper. No external request, PIN or real bank is used.
class _MovementAdapter implements HttpClientAdapter {
  _MovementAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? data, {int status = 200}) =>
    ResponseBody.fromString(jsonEncode({'success': true, 'data': data}), status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });

MoneyMovementRepositoryImpl _repository(_MovementAdapter adapter) =>
    MoneyMovementRepositoryImpl(MoneyMovementRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter));

Map<String, Object?> _bank({bool full = true}) => {
      'bank_code': 'FIXTURE',
      'bank_name': 'Bank Fixture',
      if (full) 'account_number': List.filled(8, '0').join(),
      'account_name': 'Pihak Ketiga Fixture',
      'masked_number': '****0000',
      'version': 1,
      'is_primary': true,
    };

Map<String, Object?> _transfer() => {
      'id': 'transfer-fixture',
      'reference': 'TRANSFER-FIXTURE',
      'amount': 75000,
      'status': 'succeeded',
      'community_id': 1,
      'recipient_community_id': 2,
      'sender': {'identity_id': 1, 'name': 'Pengirim Fixture'},
      'recipient': {'identity_id': 2, 'name': 'Penerima Fixture'},
      'direction': 'in',
      'created_at': '2026-11-26T00:15:00Z',
      'journal_id': 'journal-fixture',
    };

Map<String, Object?> _payout({bool platform = false, bool full = true}) => {
      'id': 'payout-fixture',
      'reference': 'PAYOUT-FIXTURE',
      'community_id': 1,
      'member': {'identity_id': 1, 'name': 'Pemilik Fixture'},
      'member_contact': {'available': false, 'phone': null},
      'amount': 100000,
      'verified_amount': 40000,
      'remaining_amount': 60000,
      'released_amount': 0,
      'status': 'uncertain',
      'version': 4,
      'destination': _bank(full: full),
      'created_at': '2026-11-26T00:15:00Z',
      'updated_at': '2026-11-26T00:18:00Z',
      'can_manage': true,
      'can_cancel': false,
      'parts': [
        {
          'id': 'part-fixture',
          'community_id': platform ? null : 1,
          'community_name':
              platform ? 'Treasury platform' : 'Komunitas Fixture',
          'source_account': {
            'configured': true,
            'bank_name': 'Bank Asal Fixture',
            'account_name': 'Kas Asal Fixture',
            'masked_number': '****0000',
          },
          'amount': 100000,
          'verified_amount': 40000,
          'remaining_amount': 60000,
          'status': 'uncertain',
          'version': 4,
          'can_manage': true,
          'founder_contact': {'phone': null, 'available': false},
          'fragments': [
            {
              'id': 'fragment-fixture',
              'amount': 40000,
              'bank_reference': 'BANK-OUTGOING-FIXTURE',
              'note': 'Bukti sintetis, bukan transfer bank.',
              'status': 'verified',
              'proof_asset_id': 'proof-fixture',
              'proof_url': null,
              'created_at': '2026-11-26T00:16:00Z',
              'verified_at': '2026-11-26T00:18:00Z',
              'verified_by': 'Petugas Fixture',
            }
          ],
          'events': [
            {
              'status': 'uncertain',
              'actor_name': 'Petugas Fixture',
              'at': '2026-11-26T00:18:00Z',
              'note': 'Sisa tetap ditahan.',
            }
          ],
        }
      ],
    };

void main() {
  test(
      'primary account PUT preserves zero-prefixed number and expected version',
      () async {
    final adapter = _MovementAdapter((_) => _json({'account': _bank()}));
    final repository = _repository(adapter);
    final fields = {..._bank(), 'expected_version': 0, 'acknowledged': true};
    final account = await repository.savePrimaryAccount(fields);
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, 'v1/bank-accounts/primary');
    expect(adapter.requests.single.data, fields);
    expect(account.accountNumber, List.filled(8, '0').join());
    expect(account.accountName, 'Pihak Ketiga Fixture');
    expect(account.version, 1);
  });

  test(
      'actual transfer maps both parties and preserves POST idempotency fields',
      () async {
    final adapter = _MovementAdapter((_) => _json(_transfer(), status: 201));
    final fields = <String, Object?>{
      'community_id': 1,
      'recipient_identity_id': 2,
      'recipient_community_id': 2,
      'amount': 75000,
      'pin': List.filled(6, '0').join(),
      'idempotency_key': 'application-request-fixture',
    };
    final transfer = await _repository(adapter).transfer(fields);
    expect(adapter.requests.single.path, 'v1/transfers');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.data, fields);
    expect(transfer.sender, 'Pengirim Fixture');
    expect(transfer.recipient, 'Penerima Fixture');
    expect(transfer.amount, 75000);
    expect(transfer.direction, 'in');
  });

  test('own transfer history uses backend pagination and recipient direction',
      () async {
    final adapter = _MovementAdapter((_) => _json({
          'items': [_transfer()],
          'current_page': 2,
          'last_page': 3,
          'total': 41,
        }));
    final page = await _repository(adapter).transfers(page: 2);
    expect(adapter.requests.single.queryParameters, {'page': 2});
    expect(page.page, 2);
    expect(page.lastPage, 3);
    expect(page.items.single.direction, 'in');
  });

  test(
      'recipient search can reach later pages without changing selected context',
      () async {
    final adapter = _MovementAdapter((_) => _json({
          'items': [
            {
              'identity_id': 24,
              'member_id': 45,
              'name': 'Nama Sama Fixture',
              'community_id': 2,
              'community_name': 'Komunitas Tujuan Fixture',
            }
          ],
          'current_page': 2,
          'last_page': 3,
          'total': 41,
        }));
    final page =
        await _repository(adapter).recipients('Nama Sama', '1', page: 2);
    expect(adapter.requests.single.queryParameters,
        {'q': 'Nama Sama', 'community_id': '1', 'page': 2});
    expect(page.page, 2);
    expect(page.lastPage, 3);
    expect(page.items.single.identityId, '24');
    expect(page.items.single.communityId, '2');
  });

  test(
      'platform payout queue uses handler flag and accepts null part community',
      () async {
    final adapter = _MovementAdapter((_) => _json({
          'items': [_payout(platform: true, full: false)],
          'current_page': 1,
          'last_page': 1,
          'total': 1,
          'can_manage': true,
        }));
    final page = await _repository(adapter).payouts(manage: true);
    expect(adapter.requests.single.queryParameters['handler'], 'platform');
    expect(adapter.requests.single.queryParameters['scope'], 'manage');
    expect(adapter.requests.single.queryParameters.containsKey('community_id'),
        false);
    final payout = page.items.single;
    expect(payout.parts.single.communityId, '');
    expect(payout.destination.accountNumber, '');
    expect(payout.verified, 40000);
    expect(payout.remaining, 60000);
    expect(payout.parts.single.sourceAccount?.bankName, 'Bank Asal Fixture');
  });

  test('actual failed part shape derives released money without optional field',
      () {
    final payout = _payout();
    final part = Map<String, Object?>.from((payout['parts']! as List).single);
    part.addAll({
      'verified_amount': 0,
      'remaining_amount': 0,
      'status': 'failed',
      'fragments': <Object?>[],
    });
    payout.addAll({
      'verified_amount': 0,
      'remaining_amount': 0,
      'released_amount': 100000,
      'status': 'failed',
      'parts': [part],
    });
    expect(part.containsKey('released_amount'), false);
    final parsed = payoutFromJson(payout);
    expect(parsed.released, 100000);
    expect(parsed.parts.single.released, 100000);
    expect(parsed.parts.single.remaining, 0);
  });

  test(
      'payout create, proof input, correction and verification use exact methods',
      () async {
    final adapter = _MovementAdapter((_) => _json(_payout()));
    final repository = _repository(adapter);
    const fields = <String, Object?>{
      'amount': 40000,
      'expected_version': 4,
      'idempotency_key': 'application-fixture',
    };
    await repository.requestPayout(fields);
    await repository.partAction('part-fixture', 'proofs', fields);
    await repository.editPendingFragment(
        'part-fixture', 'fragment-fixture', fields);
    await repository.partAction('part-fixture', 'verify', fields,
        fragmentId: 'fragment-fixture');
    expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
      'POST v1/payouts',
      'POST v1/payout-parts/part-fixture/proofs',
      'PUT v1/payout-parts/part-fixture/fragments/fragment-fixture',
      'POST v1/payout-parts/part-fixture/fragments/fragment-fixture/verify',
    ]);
    expect(adapter.requests.every((r) => r.data == fields), true);
  });

  test('community and platform reconciliation use distinct scoped endpoints',
      () async {
    final adapter = _MovementAdapter((_) => _json({
          'parts_amount': '100000',
          'verified_amount': '40000',
          'held_amount': '60000',
          'released_amount': '0',
          'balanced': true,
        }));
    final repository = _repository(adapter);
    final community = await repository.reconciliation('1');
    final platform = await repository.reconciliation('platform');
    expect(adapter.requests.map((r) => r.path), [
      'v1/communities/1/payout-reconciliation',
      'v1/payout-reconciliation',
    ]);
    expect(community.requested, 100000);
    expect(platform.held, 60000);
    expect(platform.balanced, true);
  });

  test(
      'server rejection and state conflict are distinguished from unknown result',
      () async {
    for (final status in [422, 409, 500]) {
      final adapter = _MovementAdapter((_) => ResponseBody.fromString(
              jsonEncode({
                'success': false,
                'message': 'Hasil fixture',
                'errors': {
                  'amount': ['Nominal fixture ditolak']
                },
              }),
              status,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType]
              }));
      final result = _repository(adapter).transfer({'amount': 1});
      if (status == 422) {
        await expectLater(result, throwsA(isA<MovementRejectedException>()));
      } else if (status == 409) {
        await expectLater(result, throwsA(isA<FinanceConflictException>()));
      } else {
        await expectLater(result, throwsA(isA<ServerException>()));
      }
    }
    final adapter = _MovementAdapter((_) => throw DioException(
        requestOptions: RequestOptions(path: 'v1/transfers'),
        type: DioExceptionType.connectionTimeout));
    await expectLater(_repository(adapter).transfer({'amount': 1}),
        throwsA(isA<NetworkException>()));
  });

  test('private proof downloads require HTTPS and validated image bytes',
      () async {
    final adapter =
        _MovementAdapter((_) => ResponseBody.fromBytes([137, 80, 78, 71], 200,
            headers: {
              Headers.contentTypeHeader: ['image/png']
            }));
    final repository = _repository(adapter);
    await expectLater(
        repository.proof('http://anaklangit.manahpro.web.id/private-proof'),
        throwsA(isA<ServerException>()));
    expect(adapter.requests, isEmpty);
    final proof = await repository.proof(
        'https://anaklangit.manahpro.web.id/private-proof?signed=fixture');
    expect(proof.mimeType, 'image/png');
    expect(proof.bytes, [137, 80, 78, 71]);
    final badAdapter =
        _MovementAdapter((_) => ResponseBody.fromBytes([1, 2, 3], 200,
            headers: {
              Headers.contentTypeHeader: ['text/html']
            }));
    await expectLater(
        _repository(badAdapter)
            .proof('https://anaklangit.manahpro.web.id/private-proof'),
        throwsA(isA<ServerException>()));
  });

  test(
      'financial parser rejects fractional, missing and incomplete success money',
      () {
    for (final value in [null, 1.25, '1.25', 9007199254740992]) {
      expect(() => payoutFromJson({..._payout(), 'amount': value}),
          throwsA(isA<FinanceDataException>()));
    }
    expect(() => payoutFromJson({..._payout(), 'status': 'succeeded'}),
        throwsA(isA<FinanceDataException>()));
    expect(() => memberTransferFromJson({..._transfer(), 'status': 'pending'}),
        throwsA(isA<FinanceDataException>()));
  });
}
