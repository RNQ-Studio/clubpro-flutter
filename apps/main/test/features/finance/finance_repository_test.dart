import 'dart:convert';
import 'dart:typed_data';
import 'package:app_main/features/finance/data/finance_repository_impl.dart';
import 'package:app_main/features/finance/data/finance_remote_data_source.dart';
import 'package:app_main/features/finance/data/finance_models.dart';
import 'package:app_main/features/finance/presentation/finance_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.response);
  final (int, Map<String, Object?>) Function(RequestOptions) response;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    requests.add(options);
    final (status, body) = response(options);
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

FinanceRepositoryImpl repository(Adapter adapter) =>
    FinanceRepositoryImpl(FinanceRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter));
Map<String, Object?> envelope(Object? data) => {'success': true, 'data': data};
const invoiceJson = {
  'id': 'invoice-1',
  'kind': 'member',
  'period_start': '2026-11-26',
  'period_end': '2026-12-26',
  'amount': 100000,
  'paid_amount': 25000,
  'outstanding': 75000,
  'status': 'partially_paid'
};
const billingJson = {
  'scope': 'member',
  'platform_active': false,
  'entitlement': {
    'state': 'expired',
    'active': false,
    'arrears_amount': 75000,
    'billing_scheme': 'anniversary',
    'trial_start': '2026-11-19',
    'trial_end': '2026-11-26',
    'valid_until': '2026-12-26'
  },
  'settings': {
    'member_amount': 100000,
    'entry_fee': 50000,
    'period_months': 1,
    'platform_monthly_amount': 100000,
    'bank_name': 'Bank Uji',
    'account_number': '00001111',
    'account_name': 'Komunitas Fixture'
  },
  'invoices': [invoiceJson],
  'can_manage': true,
  'can_configure': false,
  'notices': [
    {
      'id': 4,
      'type': 'expiry',
      'message': 'Lunasi seluruh kewajiban.',
      'created_at': '2026-11-25T17:00:00Z'
    }
  ]
};
const receiptJson = {
  'id': 'receipt-1',
  'purpose': 'member',
  'status': 'pending',
  'community_id': 7,
  'claimed_amount': 75000,
  'verified_amount': null,
  'bank_reference': 'ref-fixture',
  'note': 'Bayar sebagian',
  'user': {'id': 1, 'name': 'Akun Uji'},
  'reviewer': null,
  'proof_url': null,
  'invoice_ids': ['invoice-1'],
  'created_at': '2026-11-25T23:15:00Z'
};
void main() {
  test(
      'wallet integer buckets preserve total without treating reserve as available',
      () async {
    final repo = repository(Adapter((o) {
      expect(o.path, 'v1/wallet');
      expect(o.queryParameters, {'scope': 'identity'});
      return (
        200,
        envelope({
          'available': 9007199254740001,
          'reserved': 123,
          'held': 45,
          'identity_id': 91
        })
      );
    }));
    final w = await repo.wallet();
    expect(w.available, 9007199254740001);
    expect(w.packageReserve, 123);
    expect(w.payoutHold, 45);
    expect(w.total, 9007199254740169);
    expect(w.identityId, '91');
  });
  test('history and detail retain scope filters signed amount actor and source',
      () async {
    final adapter = Adapter((o) {
      final t = {
        'id': 'journal-1',
        'operation': 'billing_pay:2',
        'amount': -75000,
        'community_id': 7,
        'reference': 'invoice-1',
        'actor': {'id': 1, 'name': 'Akun Uji'},
        'created_at': '2026-11-25T23:15:00Z',
        'postings': [
          {'bucket': 'available', 'amount': -75000}
        ]
      };
      return (
        200,
        envelope(o.path.endsWith('journal-1')
            ? t
            : {
                'items': [t],
                'current_page': 2,
                'last_page': 3,
                'total': 44
              })
      );
    });
    final repo = repository(adapter);
    final page = await repo.transactions(
        scope: 'community', communityId: '7', direction: 'out', page: 2);
    expect(page.page, 2);
    expect(page.hasMore, true);
    expect(page.items.single.amount, -75000);
    expect(adapter.requests.first.queryParameters, {
      'page': 2,
      'scope': 'community',
      'direction': 'out',
      'community_id': '7'
    });
    final detail = await repo.transaction('journal-1',
        scope: 'community', communityId: '7');
    expect(detail.actor, 'Akun Uji');
    expect(detail.postings.single.account, 'available');
    expect(detail.postings.single.amount, -75000);
    expect(adapter.requests.last.queryParameters,
        {'scope': 'community', 'community_id': '7'});
  });
  test('community and platform fund summaries use authorized scope', () async {
    final adapter = Adapter(
        (o) => (200, envelope({'available': 500000, 'currency': 'IDR'})));
    final repo = repository(adapter);
    expect((await repo.wallet(scope: 'community', communityId: '7')).available,
        500000);
    expect(adapter.requests.single.queryParameters,
        {'scope': 'community', 'community_id': '7'});
    await repo.wallet(scope: 'platform');
    expect(adapter.requests.last.queryParameters, {'scope': 'platform'});
  });
  test(
      'billing preserves partial amount and independent member/platform entitlement',
      () async {
    final adapter = Adapter((o) => (200, envelope(billingJson)));
    final repo = repository(adapter);
    final b = await repo.billing('7', targetMemberId: '42');
    expect(b.entitlement.state, 'expired');
    expect(b.platformActive, false);
    expect(b.invoices.single.paidAmount, 25000);
    expect(b.outstanding, 75000);
    expect(b.settings.periodMonths, 1);
    expect(b.notices.single.message, 'Lunasi seluruh kewajiban.');
    expect(adapter.requests.single.queryParameters,
        {'scope': 'member', 'target_member_id': '42'});
  });
  test('wallet payment and renewal send actor retry key and manual target',
      () async {
    final adapter = Adapter((o) => (200, envelope({'ok': true})));
    final repo = repository(adapter);
    await repo.pay('7', 'member', 'stable-key',
        targetMemberId: '42', invoiceIds: ['invoice-1'], expectedAmount: 75000);
    await repo.pay('7', 'member', 'stable-key',
        targetMemberId: '42', invoiceIds: ['invoice-1'], expectedAmount: 75000);
    expect(adapter.requests[0].data, {
      'scope': 'member',
      'idempotency_key': 'stable-key',
      'target_member_id': 42,
      'invoice_ids': ['invoice-1'],
      'expected_amount': 75000
    });
    expect(adapter.requests[1].data, adapter.requests[0].data);
    await repo.renew('7', 'platform');
    expect(adapter.requests.last.path, 'v1/communities/7/billing/renew');
  });
  test(
      'topup and direct payment share evidence fields and explicit allocation once',
      () async {
    final adapter = Adapter((o) => (201, envelope(receiptJson)));
    final repo = repository(adapter);
    final fields = {
      'community_id': '7',
      'claimed_amount': 75000,
      'proof_asset_id': 'private-proof',
      'bank_reference': 'ref-fixture',
      'idempotency_key': 'stable-key'
    };
    await repo.submitReceipt(fields);
    expect(adapter.requests.last.path, 'v1/communities/7/topups');
    await repo.submitReceipt({
      ...fields,
      'scope': 'member',
      'target_member_id': 42,
      'credit_excess': true,
      'invoice_ids': ['invoice-1']
    });
    final req = adapter.requests.last;
    expect(req.path, 'v1/communities/7/receipts');
    expect(req.data['purpose'], 'member');
    expect(req.data.containsKey('community_id'), false);
    expect(req.data.containsKey('scope'), false);
    expect(req.data['credit_excess'], true);
    expect(req.data['invoice_ids'], ['invoice-1']);
    expect(req.data['target_member_id'], 42);
  });
  test(
      'review sends verified not claimed amount bank source and stable retry key',
      () async {
    final adapter = Adapter((o) => (
          200,
          envelope({
            ...receiptJson,
            'status': 'verified',
            'verified_amount': 70000,
            'reviewer': {'id': 2, 'name': 'Admin Uji'},
            'reviewed_at': '2026-11-26T00:00:00Z'
          })
        ));
    final repo = repository(adapter);
    final receipt = await repo.verifyReceipt('receipt-1', {
      'community_id': '7',
      'verified_amount': 70000,
      'bank_reference': 'bank-source',
      'idempotency_key': 'retry-1',
      'note': 'Nominal diperiksa'
    });
    expect(receipt.verifiedAmount, 70000);
    expect(receipt.reviewedBy, 'Admin Uji');
    expect(adapter.requests.single.path,
        'v1/communities/7/receipts/receipt-1/verify');
    expect(adapter.requests.single.data.containsKey('community_id'), false);
    await repo.rejectReceipt('7', 'receipt-2', 'Bukti tidak sah', 'retry-2');
    expect(adapter.requests.last.path,
        'v1/communities/7/receipts/receipt-2/reject');
  });
  test('receipt list filters and per-purpose reviewer capability are retained',
      () async {
    final adapter = Adapter((o) => (
          200,
          envelope({
            'can_manage': true,
            'items': [
              {...receiptJson, 'can_review': false}
            ],
            'current_page': 1,
            'last_page': 2
          })
        ));
    final data = await repository(adapter)
        .receipts(communityId: '7', status: 'pending', manage: true);
    expect(adapter.requests.single.queryParameters,
        {'page': 1, 'status': 'pending'});
    expect(data.items.single.canReview, false);
    expect(data.items.single.proofUrl, null);
  });
  test('retention and archive preserve scoped subject and reason payload',
      () async {
    final adapter = Adapter((o) => (
          200,
          envelope({
            'members': [
              {
                'id': 42,
                'name': 'Anak Uji',
                'role': 'member',
                'review_due': true,
                'entitlement': {
                  'state': 'expired',
                  'active': false,
                  'arrears_amount': 100000
                }
              }
            ]
          })
        ));
    final repo = repository(adapter);
    final subject = (await repo.inactive('7')).single;
    expect(subject.reviewDue, true);
    await repo.decide('7', subject, 'retain', 'Dipertahankan untuk riwayat');
    expect(adapter.requests.last.data, {
      'subject': 'member',
      'member_id': 42,
      'action': 'retain',
      'reason': 'Dipertahankan untuk riwayat'
    });
  });
  for (final status in [402, 403, 404, 409, 422, 429, 500]) {
    test('HTTP$status surfaces actionable Indonesian failure', () async {
      final repo = repository(
          Adapter((o) => (status, {'message': 'Nominal sudah berubah.'})));
      await expectLater(repo.wallet(), throwsA(isA<Exception>()));
    });
  }
  test(
      'date only stays calendar date; UTC timestamp becomes WIB including next day',
      () {
    expect(financeDate('2026-11-26'), '26/11/2026');
    expect(financeDate('2026-11-25T23:15:00Z'), '26/11/2026 06:15 WIB');
    expect(financeDate('2026-11-26T06:15:00+07:00'), '26/11/2026 06:15 WIB');
  });
  test(
      'money validation forbids fraction negative zero and unsafe operational amount',
      () {
    for (final input in ['', '0', '-1', '1.2', '1000000001']) {
      expect(positiveRupiah(input), isNotNull);
    }
    expect(positiveRupiah('1000000000'), null);
    expect(positiveRupiah('0', zero: true), null);
    expect(money(9007199254740991), 9007199254740991);
  });
  test('unsafe fractional malformed and mismatched wallet amounts fail closed',
      () {
    for (final value in [1.1, '1.5', 'not-money', 9007199254740992]) {
      expect(() => money(value), throwsA(isA<Exception>()));
    }
    expect(() => walletFromJson({'available': 9007199254740991, 'reserved': 1}),
        throwsA(isA<Exception>()));
    expect(() => walletFromJson({'available': 100, 'total': 200}),
        throwsA(isA<Exception>()));
    expect(() => walletFromJson({'available': -1}), throwsA(isA<Exception>()));
    expect(() => walletFromJson({}), throwsA(isA<Exception>()));
  });
  test(
      'legacy manual paid rights expose unrecorded nominal without inventing zero cash',
      () {
    final b = billingFromJson({
      ...billingJson,
      'invoices': [
        {
          ...invoiceJson,
          'amount': 0,
          'paid_amount': 0,
          'outstanding': 0,
          'status': 'paid',
          'snapshot': {'legacy_nominal_unrecorded': true}
        }
      ]
    });
    expect(b.invoices.single.legacyNominalUnrecorded, true);
  });
  test(
      'legacy receipt statuses do not imply pending verification for approved history',
      () {
    expect(receiptStatus('legacy_verified'), 'Histori terverifikasi');
    expect(receiptStatus('legacy_rejected'), 'Histori ditolak');
    expect(receiptStatus('legacy_pending'), 'Histori menunggu verifikasi');
  });
  test(
      'platform inactivity actual wrapper retains subject identity and review capability',
      () async {
    final adapter = Adapter((o) => (
          200,
          envelope({
            'members': [],
            'community': {
              'id': 7,
              'name': 'Komunitas Uji',
              'review_due': true,
              'entitlement': {
                'state': 'expired',
                'active': false,
                'arrears_amount': 300000,
                'inactive_at': '2026-08-26'
              }
            }
          })
        ));
    final repo = repository(adapter);
    final subject = (await repo.inactive('7')).single;
    expect(subject.platform, true);
    expect(subject.id, '7');
    expect(subject.name, 'Komunitas Uji');
    expect(subject.reviewDue, true);
    expect(subject.entitlement.arrearsAmount, 300000);
    await repo.decide('7', subject, 'archive', 'Tidak digunakan lagi');
    expect(adapter.requests.last.data, {
      'subject': 'platform',
      'action': 'archive',
      'reason': 'Tidak digunakan lagi'
    });
  });
  test(
      'prorated invoice decodes immutable integer charge and normal period snapshot',
      () {
    final invoice = billingFromJson({
      ...billingJson,
      'invoices': [
        {
          ...invoiceJson,
          'amount': 43333,
          'paid_amount': 0,
          'outstanding': 43333,
          'snapshot': {
            'prorated': true,
            'covered_days': 26,
            'nominal_days': 30,
            'nominal_amount': 50000
          }
        }
      ]
    }).invoices.single;
    expect(invoice.prorated, true);
    expect(invoice.coveredDays, 26);
    expect(invoice.nominalDays, 30);
    expect(invoice.nominalAmount, 50000);
    expect(invoice.hasProrationDetails, true);
    expect(invoice.amount, 43333);
    expect(invoice.outstanding, 43333);
  });
  test('historical invoices without proration metadata keep prior behavior',
      () {
    for (final snapshot in [
      null,
      <String, Object?>{},
      {
        'prorated': null,
        'covered_days': null,
        'nominal_days': null,
        'nominal_amount': null
      }
    ]) {
      final invoice = billingFromJson({
        ...billingJson,
        'invoices': [
          {...invoiceJson, 'snapshot': snapshot}
        ]
      }).invoices.single;
      expect(invoice.prorated, false);
      expect(invoice.coveredDays, null);
      expect(invoice.nominalDays, null);
      expect(invoice.nominalAmount, null);
      expect(invoice.hasProrationDetails, false);
    }
  });
  test(
      'incomplete or invalid proration metadata cannot present misleading calculation',
      () {
    for (final snapshot in [
      {'prorated': true},
      {
        'prorated': true,
        'covered_days': 0,
        'nominal_days': 30,
        'nominal_amount': 50000
      },
      {
        'prorated': true,
        'covered_days': 31,
        'nominal_days': 30,
        'nominal_amount': 50000
      },
      {
        'prorated': true,
        'covered_days': 26,
        'nominal_days': 30,
        'nominal_amount': 0
      },
      {
        'prorated': false,
        'covered_days': 26,
        'nominal_days': 30,
        'nominal_amount': 50000
      },
    ]) {
      expect(
          billingFromJson({
            ...billingJson,
            'invoices': [
              {...invoiceJson, 'snapshot': snapshot}
            ]
          }).invoices.single.hasProrationDetails,
          false);
    }
    for (final amount in [1.5, '50000.5', 9007199254740992]) {
      expect(
          () => billingFromJson({
                ...billingJson,
                'invoices': [
                  {
                    ...invoiceJson,
                    'snapshot': {
                      'prorated': true,
                      'covered_days': 26,
                      'nominal_days': 30,
                      'nominal_amount': amount
                    }
                  }
                ]
              }),
          throwsA(isA<Exception>()));
    }
  });
}
