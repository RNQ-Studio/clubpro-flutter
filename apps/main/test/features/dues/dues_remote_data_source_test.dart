import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/community/data/models/community_model.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/dues/data/datasources/dues_remote_data_source.dart';
import 'package:app_main/features/dues/domain/entities/dues.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
String _fixture(String name) =>
    File('test/features/dues/fixtures/$name.json').readAsStringSync();

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);

  final int? status;
  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    final status = this.status;
    if (status == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

({DuesRemoteDataSource source, _FakeAdapter adapter}) _source(
  int? status, [
  String body = '{"success":true,"data":null}',
]) {
  final adapter = _FakeAdapter(status, body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: DuesRemoteDataSource(dio), adapter: adapter);
}

void main() {
  group('ringkasan iuran saya', () {
    test('setelan, kalender, tunggakan, dan riwayat dari respons asli',
        () async {
      final fake = _source(200, _fixture('dues_me'));

      final overview = await fake.source.fetchOverview('1', year: 2026);

      expect(fake.adapter.request!.path, 'v1/communities/1/dues');
      expect(fake.adapter.request!.queryParameters, {'year': 2026});

      final settings = overview.settings;
      expect(settings.configured, isTrue);
      expect(settings.monthlyAmount, 50000);
      expect(settings.entryFee, 100000);
      expect(settings.startDate, DateTime(2026, 3, 10));
      expect(settings.dueDay, 10);
      expect(settings.bankName, 'BCA');
      expect(settings.accountNumber, '1234567890');
      expect(overview.canManage, isFalse);
      expect(overview.pendingPaymentsCount, isNull);

      final me = overview.me!;
      expect(me.calendar.billableFrom, DateTime(2026, 3));
      expect(me.calendar.arrearsCount, 3);
      expect(me.calendar.paidUntil, DateTime(2026, 5));
      expect(me.calendar.entryFeePaid, isTrue);
      expect(me.entryFeeDue, 0);
      expect(me.calendar.months, hasLength(12));
      expect(me.calendar.months.map((m) => m.status), [
        DuesMonthStatus.none,
        DuesMonthStatus.none,
        DuesMonthStatus.paid,
        DuesMonthStatus.paid,
        DuesMonthStatus.paid,
        DuesMonthStatus.pending,
        DuesMonthStatus.pending,
        DuesMonthStatus.overdue,
        DuesMonthStatus.overdue,
        DuesMonthStatus.overdue,
        DuesMonthStatus.due,
        DuesMonthStatus.upcoming,
      ]);
      expect(me.nextUnpaidMonths.first, DateTime(2026, 8));
      expect(me.nextUnpaidMonths, hasLength(12));

      final rejected = overview.payments
          .firstWhere((p) => p.status == DuesPaymentStatus.rejected);
      expect(rejected.reviewNote, 'Nominal transfer kurang Rp50.000');
      expect(rejected.months, [DateTime(2026, 3), DateTime(2026, 4)]);
      expect(rejected.entryFee, 100000);
      expect(rejected.totalAmount, 200000);
      expect(rejected.reviewedBy, 'Rina Ayu');
    });

    test('tahun berjalan: parameter tahun tidak dikirim', () async {
      final fake = _source(200, _fixture('dues_me'));

      await fake.source.fetchOverview('1');

      expect(fake.adapter.request!.queryParameters, isEmpty);
    });

    test('pengelola: jumlah pembayaran menunggu', () async {
      final overview = await _source(200, _fixture('dues_me_manager'))
          .source
          .fetchOverview('1');

      expect(overview.canManage, isTrue);
      expect(overview.pendingPaymentsCount, 1);
      expect(overview.me!.entryFeeDue, 100000);
    });
  });

  test('simpan setelan: rupiah utuh, tanggal ISO, nomor rekening angka saja',
      () async {
    final fake = _source(200, _fixture('dues_settings'));

    final settings = await fake.source.saveSettings(
      '1',
      DuesSettingsInput(
        monthlyAmount: 50000,
        entryFee: 0,
        startDate: DateTime(2026, 3, 10),
        bankName: ' BCA ',
        accountNumber: '123-456 7890',
        accountName: ' Komunitas Pemanah ',
      ),
    );

    expect(fake.adapter.request!.method, 'PUT');
    expect(fake.adapter.request!.path, 'v1/communities/1/dues/settings');
    expect(fake.adapter.request!.data, {
      'dues_amount': 50000,
      'entry_fee': 0,
      'dues_start_date': '2026-03-10',
      'dues_bank_name': 'BCA',
      'dues_account_number': '1234567890',
      'dues_account_name': 'Komunitas Pemanah',
    });
    expect(settings.configured, isTrue);
    expect(settings.accountName, 'Komunitas Pemanah Nusantara');
  });

  test('bayar: jumlah bulan, bukti, catatan', () async {
    final fake = _source(201, _fixture('dues_payment_created'));

    final payment = await fake.source.pay(
      '1',
      monthsCount: 2,
      proofAssetId: 'aset-1',
      note: '  dari m-banking ',
    );

    expect(fake.adapter.request!.path, 'v1/communities/1/dues/payments');
    expect(fake.adapter.request!.data, {
      'months_count': 2,
      'proof_asset_id': 'aset-1',
      'note': 'dari m-banking',
    });
    expect(payment.status, DuesPaymentStatus.pending);
    expect(payment.months, [DateTime(2026, 6), DateTime(2026, 7)]);
    expect(payment.totalAmount, 100000);
    expect(payment.proofUrl, startsWith('https://anaklangit.manahpro.web.id/'));
  });

  test('bayar tanpa catatan: catatan tidak dikirim', () async {
    final fake = _source(201, _fixture('dues_payment_created'));

    await fake.source
        .pay('1', monthsCount: 1, proofAssetId: 'aset-1', note: '  ');

    expect((fake.adapter.request!.data as Map).containsKey('note'), isFalse);
  });

  test('daftar verifikasi: status menjadi parameter, halaman terbaca',
      () async {
    final fake = _source(200, _fixture('dues_payments_pending'));

    final page = await fake.source
        .fetchPayments('1', page: 2, status: DuesPaymentStatus.pending);

    expect(fake.adapter.request!.queryParameters,
        {'page': 2, 'status': 'pending'});
    expect(page.items.single.userName, 'Budi Santoso');
    expect(page.items.single.status, DuesPaymentStatus.pending);
    expect(page.hasMore, isFalse);
  });

  test('terima & tolak', () async {
    final approve = _source(200, _fixture('dues_payment_created'));
    await approve.source.approve('1', '7');
    expect(approve.adapter.request!.path,
        'v1/communities/1/dues/payments/7/approve');

    final reject = _source(200, _fixture('dues_payment_created'));
    await reject.source.reject('1', '7', ' Nominal kurang ');
    expect(reject.adapter.request!.path,
        'v1/communities/1/dues/payments/7/reject');
    expect(reject.adapter.request!.data, {'note': 'Nominal kurang'});
  });

  test('kalender semua anggota', () async {
    final fake = _source(200, _fixture('dues_members'));

    final page = await fake.source
        .fetchMembers('1', year: 2026, page: 1, search: 'budi');

    expect(fake.adapter.request!.queryParameters,
        {'year': 2026, 'page': 1, 'search': 'budi'});
    final budi = page.items.firstWhere((m) => m.name == 'Budi Santoso');
    expect(budi.calendar.arrearsCount, 3);
    expect(budi.role, CommunityRole.member);
    expect(budi.calendar.months, hasLength(12));
    final creator = page.items.firstWhere((m) => m.name == 'Rina Ayu');
    expect(creator.role, CommunityRole.creator);
  });

  test('kalender satu anggota beserta riwayatnya', () async {
    final fake = _source(200, _fixture('dues_member'));

    final detail = await fake.source.fetchMember('1', '2', year: 2026);

    expect(fake.adapter.request!.path, 'v1/communities/1/dues/members/2');
    expect(detail.member.name, 'Budi Santoso');
    expect(detail.member.entryFeeDue, 0);
    expect(detail.member.calendar.entryFeePaid, isTrue);
    expect(detail.payments, hasLength(3));
    expect(detail.settings.entryFee, 100000);
  });

  test('ubah status bulan & uang masuk', () async {
    final month = _source(200);
    await month.source.setMonth('1', '2', DateTime(2026, 3), paid: true);
    expect(month.adapter.request!.method, 'PUT');
    expect(month.adapter.request!.path,
        'v1/communities/1/dues/members/2/months/2026-03');
    expect(month.adapter.request!.data, {'paid': true});

    final fee = _source(200);
    await fee.source.setEntryFee('1', '2', paid: false);
    expect(
        fee.adapter.request!.path, 'v1/communities/1/dues/members/2/entry-fee');
    expect(fee.adapter.request!.data, {'paid': false});
  });

  group('galat', () {
    test('422: isian dan pesan server', () async {
      final fake = _source(422, _fixture('dues_pending_month_error'));

      await expectLater(
        fake.source.setMonth('1', '2', DateTime(2026, 6), paid: true),
        throwsA(isA<DuesFieldException>()
            .having((e) => e.field, 'field', 'month')
            .having(
                (e) => e.message, 'message', contains('menunggu verifikasi'))),
      );
    });

    test('409: pesan server apa adanya', () async {
      final fake = _source(409, _fixture('dues_review_conflict'));

      await expectLater(
        fake.source.approve('1', '7'),
        throwsA(isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Pembayaran ini sudah diverifikasi. Muat ulang untuk melihat yang '
              'terbaru.',
        )),
      );
    });

    test('403, 404 tanpa pesan, dan offline', () async {
      await expectLater(
        _source(403, '{}').source.fetchOverview('1'),
        throwsA(isA<ServerException>().having(
            (e) => e.message, 'message', contains('tidak punya akses'))),
      );
      await expectLater(
        _source(404, '{}').source.fetchOverview('1'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('belum aktif'))),
      );
      await expectLater(
        _source(null).source.fetchOverview('1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  test('detail komunitas: iuran diatur & pembayaran menunggu', () {
    final json = jsonDecode(
      File('test/features/community/fixtures/community_detail_manager.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

    final detail =
        CommunityDetailModel.fromJson(json['data'] as Map<String, dynamic>);

    expect(detail.duesConfigured, isTrue);
    expect(detail.pendingDuesPaymentsCount, 1);
    expect(detail.canManage, isTrue);
  });
}
