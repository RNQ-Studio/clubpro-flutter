import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/member_card/data/datasources/member_card_remote_data_source.dart';
import 'package:app_main/features/member_card/domain/entities/member_card.dart';
import 'package:app_main/features/member_card/domain/repositories/member_card_repository.dart';
import 'package:app_main/features/member_card/presentation/member_card_providers.dart';
import 'package:app_main/features/member_card/presentation/screens/member_card_screen.dart';
import 'package:app_main/features/member_card/presentation/widgets/member_card_view.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../community/fake_community_repository.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

({MemberCardRemoteDataSource source, _Adapter adapter}) _source(
    int status, String body) {
  final adapter = _Adapter(status, body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: MemberCardRemoteDataSource(dio), adapter: adapter);
}

MemberCard _card({
  String communityId = '1',
  String communityName = 'Pemanah Nusantara',
  MemberCardStatus status = MemberCardStatus.active,
  DateTime? validUntil,
  DateTime? paidUntil,
  bool pending = false,
  String name = 'Rina Ayu Lestari',
}) =>
    MemberCard(
      memberNumber: 'PN-000042',
      name: name,
      roleLabel: 'Anggota',
      joinedAt: DateTime(2026, 3, 2),
      community: testCommunity(communityId, name: communityName),
      validity: MemberCardValidity(
        status: status,
        validUntil: validUntil,
        paidUntil: paidUntil,
        pendingPayment: pending,
      ),
    );

class _FakeCards implements MemberCardRepository {
  _FakeCards(this.cards);

  final Map<String, Object> cards;
  final calls = <String>[];

  @override
  Future<MemberCard> getCard(String communityId) async {
    calls.add(communityId);
    final result = cards[communityId];
    if (result is MemberCard) return result;
    throw result ?? const ServerException('Tidak ada kartu.');
  }
}

class _Joined extends ActiveCommunityNotifier {
  _Joined(this.joined);

  final List<Community> joined;

  @override
  Future<MyCommunities> build() async =>
      MyCommunities(joined: joined, active: joined.firstOrNull);
}

Widget _app(_FakeCards cards, {List<Community> joined = const []}) {
  final router = GoRouter(
    initialLocation: '/c/1/card',
    routes: [
      GoRoute(
        path: '/c/:id/card',
        builder: (_, state) =>
            MemberCardScreen(communityId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/communities/:id/dues',
        builder: (_, state) => Text('IURAN ${state.pathParameters['id']}'),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (_, state) => Text('BAYAR ${state.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      memberCardRepositoryProvider.overrideWithValue(cards),
      activeCommunityProvider.overrideWith(() => _Joined(joined)),
    ],
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
}

void _screen(WidgetTester tester, Size size, {double textScale = 1}) {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  group('kontrak dengan respons server sungguhan', () {
    test('kartu aktif dengan pembayaran menunggu', () async {
      final fixture =
          File('test/features/member_card/fixtures/member_card.json')
              .readAsStringSync();
      final (:source, :adapter) = _source(200, fixture);

      final card = await source.fetchCard('1');

      expect(adapter.request!.path, 'v1/communities/1/card');
      expect(card.memberNumber, 'PN-000002');
      expect(card.name, 'Rina Ayu Lestari');
      expect(card.roleLabel, 'Admin');
      expect(card.joinedAt, DateTime.utc(2026, 3, 2, 2).toLocal());
      expect(card.community.name, 'Pemanah Nusantara');
      expect(card.community.shortName, 'PN');
      expect(card.community.logoUrl, isNotNull);
      expect(card.validity.status, MemberCardStatus.active);
      expect(card.validity.validUntil, DateTime(2026, 12, 10));
      expect(card.validity.paidUntil, DateTime(2026, 11));
      expect(card.validity.pendingPayment, isTrue);
    });

    test('status tanpa iuran & tanggal kosong', () async {
      final body = jsonDecode(
          File('test/features/member_card/fixtures/member_card.json')
              .readAsStringSync()) as Map<String, dynamic>;
      (body['data'] as Map<String, dynamic>)['validity'] = {
        'status': 'no_dues',
        'valid_until': null,
        'paid_until': null,
        'pending_payment': false,
      };

      final card = await _source(200, jsonEncode(body)).source.fetchCard('1');

      expect(card.validity.status, MemberCardStatus.noDues);
      expect(card.validity.status.isValid, isTrue);
      expect(card.validity.validUntil, isNull);
      expect(card.validity.paidUntil, isNull);
    });

    test('bukan anggota aktif → pesan dari server', () async {
      final source = _source(403,
              '{"success":false,"message":"Kartu anggota hanya untuk anggota aktif komunitas ini."}')
          .source;

      expect(
        () => source.fetchCard('1'),
        throwsA(isA<ServerException>().having((e) => e.message, 'message',
            'Kartu anggota hanya untuk anggota aktif komunitas ini.')),
      );
    });

    test('server lama tanpa endpoint (404) → pesan jelas', () async {
      expect(
        () => _source(404, '{}').source.fetchCard('1'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', contains('belum tersedia'))),
      );
    });
  });

  group('layar Kartu Anggota', () {
    testWidgets('aktif: identitas, nomor, masa berlaku, dan penjelasannya',
        (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(_FakeCards({
        '1': _card(
            validUntil: DateTime(2026, 12, 10), paidUntil: DateTime(2026, 11)),
      })));
      await tester.pumpAndSettle();

      expect(find.text('Kartu Anggota'), findsOneWidget);
      expect(find.text('Pemanah Nusantara'), findsOneWidget);
      expect(find.text('KARTU ANGGOTA'), findsOneWidget);
      expect(find.text('Rina Ayu Lestari'), findsOneWidget);
      expect(find.text('PN-000042'), findsOneWidget);
      expect(find.text('Mar 2026'), findsOneWidget);
      expect(find.text('10 Des 2026'), findsOneWidget);
      expect(
          find.byKey(const Key('member-card-status-active')), findsOneWidget);
      expect(find.text('Kartu aktif'), findsOneWidget);
      expect(find.textContaining('Iuran lunas hingga November 2026'),
          findsOneWidget);
      expect(find.textContaining('sampai 10 Desember 2026'), findsOneWidget);
      // Masih berlaku: tidak didesak membayar.
      expect(find.byKey(const Key('member-card-pay')), findsNothing);
      expect(find.byKey(const Key('member-card-dues')), findsOneWidget);
    });

    testWidgets('kedaluwarsa: kartu abu-abu, ajakan bayar iuran',
        (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(_FakeCards({
        '1': _card(
          status: MemberCardStatus.expired,
          validUntil: DateTime(2026, 5, 10),
          paidUntil: DateTime(2026, 4),
        ),
      })));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('member-card-status-expired')), findsOneWidget);
      expect(find.text('KEDALUWARSA'), findsOneWidget);
      expect(find.text('Kartu tidak berlaku'), findsOneWidget);
      expect(find.textContaining('berakhir 10 Mei 2026'), findsOneWidget);

      await tester.tap(find.byKey(const Key('member-card-pay')));
      await tester.pumpAndSettle();
      expect(find.text('BAYAR 1'), findsOneWidget);
    });

    testWidgets('belum aktif: tanpa tanggal berlaku, ajakan bayar',
        (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(_FakeCards({
        '1': _card(status: MemberCardStatus.inactive),
      })));
      await tester.pumpAndSettle();

      expect(find.text('BELUM AKTIF'), findsOneWidget);
      expect(find.text('Kartu belum aktif'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('member-card-valid-until')))
            .data,
        '—',
      );
      expect(find.byKey(const Key('member-card-pay')), findsOneWidget);
    });

    testWidgets('pembayaran menunggu: catatan, tanpa tombol bayar ganda',
        (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(_FakeCards({
        '1': _card(status: MemberCardStatus.inactive, pending: true),
      })));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member-card-pending')), findsOneWidget);
      expect(find.textContaining('sedang diverifikasi'), findsOneWidget);
      expect(find.byKey(const Key('member-card-pay')), findsNothing);
    });

    testWidgets('tanpa iuran: berlaku selama anggota, tanpa tombol iuran',
        (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(_FakeCards({
        '1': _card(status: MemberCardStatus.noDues),
      })));
      await tester.pumpAndSettle();

      expect(find.text('Selama anggota'), findsOneWidget);
      expect(find.text('AKTIF'), findsOneWidget);
      expect(find.textContaining('belum menetapkan iuran'), findsOneWidget);
      expect(find.byKey(const Key('member-card-pay')), findsNothing);
      expect(find.byKey(const Key('member-card-dues')), findsNothing);
    });

    for (final (status, gradient) in [
      (MemberCardStatus.active, MemberCardView.validGradient),
      (MemberCardStatus.noDues, MemberCardView.validGradient),
      (MemberCardStatus.expired, MemberCardView.invalidGradient),
      (MemberCardStatus.inactive, MemberCardView.invalidGradient),
    ]) {
      testWidgets(
          'warna kartu ${status.apiValue}: '
          '${gradient == MemberCardView.validGradient ? 'emas' : 'abu-abu'}',
          (tester) async {
        _screen(tester, const Size(390, 844));
        await tester.pumpWidget(_app(_FakeCards({
          '1': _card(
            status: status,
            validUntil: DateTime(2026, 12, 10),
            paidUntil: DateTime(2026, 11),
          ),
        })));
        await tester.pumpAndSettle();

        final gradients = tester
            .widgetList<DecoratedBox>(find.descendant(
              of: find.byKey(const Key('member-card')),
              matching: find.byType(DecoratedBox),
            ))
            .map((d) => (d.decoration as BoxDecoration).gradient)
            .whereType<LinearGradient>();
        expect(gradients, contains(gradient));
      });
    }

    testWidgets('gagal dimuat → pesan & coba lagi', (tester) async {
      _screen(tester, const Size(390, 844));
      final cards = _FakeCards({
        '1': const ServerException(
            'Kartu anggota hanya untuk anggota aktif komunitas ini.'),
      });
      await tester.pumpWidget(_app(cards));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member-card-error')), findsOneWidget);
      expect(
          find.text('Kartu anggota hanya untuk anggota aktif komunitas ini.'),
          findsOneWidget);

      cards.cards['1'] = _card(status: MemberCardStatus.noDues);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('member-card')), findsOneWidget);
      expect(cards.calls, ['1', '1']);
    });

    testWidgets('anggota beberapa komunitas bisa berganti kartu',
        (tester) async {
      _screen(tester, const Size(390, 844));
      final cards = _FakeCards({
        '1': _card(status: MemberCardStatus.noDues),
        '2': _card(
          communityId: '2',
          communityName: 'Fotografer Priangan',
          status: MemberCardStatus.expired,
          validUntil: DateTime(2026, 5, 10),
          paidUntil: DateTime(2026, 4),
        ),
      });
      await tester.pumpWidget(_app(cards, joined: [
        testCommunity('1'),
        testCommunity('2', name: 'Fotografer Priangan'),
      ]));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(
                find.byKey(const Key('member-card-community-1')))
            .selected,
        isTrue,
      );
      expect(find.text('AKTIF'), findsOneWidget);

      await tester
          .ensureVisible(find.byKey(const Key('member-card-community-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('member-card-community-2')));
      await tester.pumpAndSettle();

      expect(cards.calls, ['1', '2']);
      expect(
        find.descendant(
          of: find.byKey(const Key('member-card')),
          matching: find.text('Fotografer Priangan'),
        ),
        findsOneWidget,
      );
      expect(find.text('KEDALUWARSA'), findsOneWidget);
    });

    testWidgets('satu komunitas → tanpa pilihan komunitas', (tester) async {
      _screen(tester, const Size(390, 844));
      await tester.pumpWidget(_app(
        _FakeCards({'1': _card(status: MemberCardStatus.noDues)}),
        joined: [testCommunity('1')],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
    });

    for (final (label, size, scale) in [
      ('ponsel kecil + teks besar', const Size(320, 640), 1.3),
      ('ponsel', const Size(390, 844), 1.0),
      ('desktop', const Size(1280, 800), 1.0),
    ]) {
      testWidgets('kartu tanpa overflow, rasio kartu tetap: $label',
          (tester) async {
        _screen(tester, size, textScale: scale);
        await tester.pumpWidget(_app(_FakeCards({
          '1': _card(
            name: 'Raden Ajeng Kartini Dewi Sartika Lestari Wulandari',
            communityName:
                'Komunitas Pemanah Tradisional Nusantara Jawa Barat Raya',
            validUntil: DateTime(2026, 12, 10),
            paidUntil: DateTime(2026, 11),
          ),
        })));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final card = tester.getSize(find.byKey(const Key('member-card')));
        expect(card.width / card.height,
            closeTo(MemberCardView.aspectRatio, 0.01));
        expect(card.width, lessThanOrEqualTo(MemberCardScreen.maxWidth));
      });
    }
  });
}
