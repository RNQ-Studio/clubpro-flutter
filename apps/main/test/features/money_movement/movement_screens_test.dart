import 'dart:async';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/money_movement/data/money_movement_remote_data_source.dart';
import 'package:app_main/features/money_movement/presentation/bank_account_screen.dart';
import 'package:app_main/features/money_movement/presentation/payouts_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_request_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_detail_screen.dart';
import 'package:app_main/features/money_movement/presentation/transfer_screen.dart';
import 'package:app_main/features/money_movement/presentation/money_movement_providers.dart';
import 'package:app_main/features/money_movement/presentation/movement_sharing.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../community/fake_community_repository.dart';
import '../finance/finance_screens_test.dart'
    show FakeFinance, FixtureAuth, billingFixture;
import 'fake_movement_repository.dart';

Widget movementApp(Widget screen, FakeMovement repo,
        {double scale = 1, FakeMovementSharing? sharing}) =>
    ProviderScope(
        overrides: [
          moneyMovementRepositoryProvider.overrideWithValue(repo),
          financeRepositoryProvider.overrideWithValue(FakeFinance()
            ..billingValue =
                billingFixture(state: 'active', active: true, amount: 0)),
          authProvider.overrideWith(FixtureAuth.new),
          communityRepositoryProvider.overrideWithValue(FakeCommunityRepository(
              detail: testDetail(myRole: CommunityRole.member),
              joined: [
                testCommunity('1',
                    name: 'Komunitas Fixture',
                    myRole: CommunityRole.member,
                    myStatus: CommunityMembershipStatus.active)
              ])),
          communityImagePickerProvider
              .overrideWithValue(FakeCommunityImagePicker()),
          movementSharingProvider
              .overrideWithValue(sharing ?? FakeMovementSharing())
        ],
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            routerConfig: GoRouter(initialLocation: '/screen', routes: [
              GoRoute(
                  path: '/',
                  builder: (_, s) =>
                      const Scaffold(body: Text('Kembali ke saldo')),
                  routes: [GoRoute(path: 'screen', builder: (_, s) => screen)]),
              GoRoute(
                  path: AppRoutes.primaryBank,
                  builder: (_, s) => const PrimaryBankScreen()),
              GoRoute(
                  path: AppRoutes.newTransfer,
                  builder: (_, s) => const TransferScreen(communityId: '1')),
              GoRoute(
                  path: '/wallet/payouts/:id',
                  builder: (_, s) =>
                      PayoutDetailScreen(id: s.pathParameters['id']!),
                  routes: [
                    GoRoute(
                        path: 'parts/:partId/proof',
                        builder: (_, s) => PayoutProofRouteScreen(
                            id: s.pathParameters['id']!,
                            partId: s.pathParameters['partId']!)),
                    GoRoute(
                        path: 'parts/:partId/fragments/:fragmentId',
                        builder: (_, s) => PayoutProofRouteScreen(
                            id: s.pathParameters['id']!,
                            partId: s.pathParameters['partId']!,
                            fragmentId: s.pathParameters['fragmentId']!))
                  ])
            ])));
void movementSize(WidgetTester t, {double width = 500, double height = 1200}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> visibleTap(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 200,
        maxScrolls: 30,
        scrollable: find
            .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable))
            .first);
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> transferForm(WidgetTester t) async {
  await t.enterText(find.byKey(const Key('transfer-search')), 'Tujuan');
  await t.pump(const Duration(milliseconds: 400));
  await t.pumpAndSettle();
  await visibleTap(t, find.byKey(const Key('recipient-2-2')));
  await t.enterText(
      find.byKey(const Key('transfer-amount')).findTextField(), '75000');
  await t.enterText(
      find.byKey(const Key('transfer-pin')), List.filled(6, '0').join());
  await visibleTap(t, find.byKey(const Key('transfer-confirm')));
}

extension _FieldFinder on Finder {
  Finder findTextField() =>
      find.descendant(of: this, matching: find.byType(TextFormField));
}

void main() {
  testWidgets(
      'third party primary account requires responsibility confirmation, preserves zeros and version',
      (t) async {
    movementSize(t);
    final repo = FakeMovement();
    await t.pumpWidget(movementApp(const PrimaryBankScreen(), repo));
    await t.pumpAndSettle();
    expect(find.text('Rekening tersimpan'), findsOneWidget);
    await t.enterText(find.byKey(const Key('bank-owner')), 'Pihak Ketiga Baru');
    await visibleTap(t, find.byKey(const Key('bank-save')));
    expect(repo.sent, isEmpty);
    await visibleTap(t, find.byKey(const Key('bank-ack')));
    await visibleTap(t, find.byKey(const Key('bank-save')));
    expect(repo.sent.single['account_name'], 'Pihak Ketiga Baru');
    expect(repo.sent.single['account_number'], bankFixture().accountNumber);
    expect(repo.sent.single['expected_version'], 2);
  });
  testWidgets(
      'transfer confirms recipient and atomic backend success before success UI',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..sendGate = Completer<void>();
    await t
        .pumpWidget(movementApp(const TransferScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await transferForm(t);
    await t.ensureVisible(find.byKey(const Key('transfer-submit')));
    await t.tap(find.byKey(const Key('transfer-submit')));
    await t.tap(find.byKey(const Key('transfer-submit')));
    await t.pump();
    expect(find.text('Transfer saldo berhasil'), findsNothing);
    expect(repo.sent.length, 1);
    expect(repo.sent.length, 1);
    repo.sendGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('Transfer saldo berhasil'), findsOneWidget);
    expect(repo.sent.single['recipient_identity_id'], 2);
    expect(repo.sent.single['recipient_community_id'], 2);
    expect(repo.sent.single['amount'], 75000);
  });
  testWidgets(
      'unknown transfer result retries same key without editing recipient or amount',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..sendError = const NetworkException('Koneksi terputus');
    await t
        .pumpWidget(movementApp(const TransferScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await transferForm(t);
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    expect(find.byKey(const Key('transfer-edit')), findsNothing);
    repo.sendError = null;
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['idempotency_key'], repo.sent[1]['idempotency_key']);
    expect(repo.sent[0]['amount'], repo.sent[1]['amount']);
  });
  testWidgets('definitive rejection allows corrected transfer with fresh key',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..sendError = const MovementRejectedException('Saldo kurang');
    await t
        .pumpWidget(movementApp(const TransferScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await transferForm(t);
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    await visibleTap(t, find.byKey(const Key('transfer-edit')));
    repo.sendError = null;
    await t.enterText(
        find.byKey(const Key('transfer-amount')).findTextField(), '60000');
    await visibleTap(t, find.byKey(const Key('transfer-confirm')));
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    expect(repo.sent[0]['idempotency_key'],
        isNot(repo.sent[1]['idempotency_key']));
    expect(repo.sent[1]['amount'], 60000);
  });
  testWidgets('payout unknown result preserves snapshot version and key',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..sendError = const NetworkException('Koneksi terputus');
    await t.pumpWidget(
        movementApp(const PayoutRequestScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('payout-amount')).findTextField(), '100000');
    await t.enterText(
        find.byKey(const Key('payout-pin')), List.filled(6, '0').join());
    await visibleTap(t, find.byKey(const Key('payout-ack')));
    await visibleTap(t, find.byKey(const Key('payout-submit')));
    await visibleTap(t, find.byKey(const Key('payout-submit')));
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['idempotency_key'], repo.sent[1]['idempotency_key']);
    expect(repo.sent[0]['bank_account_version'], 2);
    expect(find.byKey(const Key('payout-edit')), findsNothing);
  });
  testWidgets('uncertain partial payout warns and hides final cancellation',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(pending: false);
    await t.pumpWidget(
        movementApp(const PayoutDetailScreen(id: 'payout-fixture'), repo));
    await t.pumpAndSettle();
    expect(find.text('Hasil belum pasti'), findsOneWidget);
    expect(find.text('Batalkan: belum terkirim'), findsNothing);
    expect(find.textContaining('Jangan melakukan transfer bank ulang'),
        findsOneWidget);
  });
  testWidgets(
      'manager verify uses pending fragment and expected version only after acknowledgement',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(manage: true);
    await t.pumpWidget(
        movementApp(const PayoutDetailScreen(id: 'payout-fixture'), repo));
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('verify-fragment-fixture')));
    await visibleTap(t, find.byKey(const Key('payout-action-submit')));
    expect(repo.sent, isEmpty);
    await visibleTap(t, find.byKey(const Key('payout-action-ack')));
    await visibleTap(t, find.byKey(const Key('payout-action-submit')));
    expect(repo.actions, ['verify']);
    expect(repo.sent.single['expected_version'], 3);
  });
  testWidgets(
      'owner cannot verify or upload proof; destination masked by default',
      (t) async {
    movementSize(t);
    final repo = FakeMovement();
    await t.pumpWidget(
        movementApp(const PayoutDetailScreen(id: 'payout-fixture'), repo));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('verify-fragment-fixture')), findsNothing);
    expect(find.byKey(const Key('proof-add-part-fixture')), findsNothing);
    expect(find.textContaining(bankFixture().accountNumber), findsNothing);
  });
  testWidgets(
      'founder and member composers target distinct contacts; no send claim',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(manage: true);
    final share = FakeMovementSharing();
    await t.pumpWidget(movementApp(
        const PayoutDetailScreen(id: 'payout-fixture'), repo,
        sharing: share));
    await t.pumpAndSettle();
    await visibleTap(
        t, find.text('Siapkan pesan untuk Anggota Pemilik Fixture'));
    await visibleTap(t, find.text('Siapkan pesan untuk pendiri'));
    expect(share.composers.map((u) => u.path),
        ['/6280000000002', '/6280000000001']);
    expect(
        share.composers
            .every((u) => !u.query.contains(bankFixture().accountNumber)),
        true);
  });
  testWidgets('proof sharing sends private image bytes to local adapter',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(manage: true);
    final share = FakeMovementSharing();
    await t.pumpWidget(movementApp(
        const PayoutDetailScreen(id: 'payout-fixture'), repo,
        sharing: share));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Bagikan bukti'));
    expect(share.files.single.bytes, isNotEmpty);
    expect(share.texts.single, contains('Anggota Pemilik Fixture'));
    expect(share.texts.single, contains('•••• 0000'));
    expect(share.texts.single, isNot(contains('https://')));
  });
  testWidgets('invalid founder phone reports error without opening composer',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(validPhone: false);
    final share = FakeMovementSharing();
    await t.pumpWidget(movementApp(
        const PayoutDetailScreen(id: 'payout-fixture'), repo,
        sharing: share));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Siapkan pesan untuk pendiri'));
    expect(share.composers, isEmpty);
    expect(find.textContaining('Nomor WhatsApp pendiri belum tersedia'),
        findsWidgets);
  });
  testWidgets(
      'pending proof correction loads from fresh IDs and does not require new upload',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = payoutFixture(manage: true);
    await t.pumpWidget(movementApp(
        const PayoutProofRouteScreen(
            id: 'payout-fixture',
            partId: 'part-fixture',
            fragmentId: 'fragment-fixture'),
        repo));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('payout-pick-proof')), findsNothing);
    await t.enterText(
        find.byKey(const Key('proof-reference')), 'BANK-CORRECTED');
    await visibleTap(t, find.byKey(const Key('proof-destination-ack')));
    await visibleTap(t, find.byKey(const Key('payout-proof-submit')));
    expect(repo.actions, ['edit']);
    expect(repo.sent.single['bank_reference'], 'BANK-CORRECTED');
    expect(repo.sent.single.containsKey('proof_asset_id'), false);
  });
  testWidgets('released pending proof shows rejected and has no review actions',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..value = payoutFixture(manage: true, status: 'failed');
    await t.pumpWidget(
        movementApp(const PayoutDetailScreen(id: 'payout-fixture'), repo));
    await t.pumpAndSettle();
    await t.drag(find.byType(ListView), const Offset(0, -650));
    await t.pumpAndSettle();
    expect(find.textContaining('Ditolak: dipastikan belum terkirim'),
        findsOneWidget);
    expect(find.byKey(const Key('verify-fragment-fixture')), findsNothing);
  });
  for (final width in [500.0, 1280.0]) {
    testWidgets('platform queue, empty, error and loading at $width',
        (t) async {
      movementSize(t, width: width);
      final repo = FakeMovement()
        ..value = payoutFixture(manage: true, platform: true);
      await t.pumpWidget(
          movementApp(const PayoutsScreen(manage: true), repo, scale: 1.5));
      await t.pumpAndSettle();
      expect(repo.lastCommunity, null);
      expect(repo.lastManage, true);
      expect(find.text('Rekonsiliasi pencairan'), findsOneWidget);
      expect(t.takeException(), null);
    });
  }
  testWidgets('empty history and load retry use repository states', (t) async {
    movementSize(t);
    final repo = FakeMovement()..empty = true;
    await t.pumpWidget(movementApp(const TransferHistoryScreen(), repo));
    await t.pumpAndSettle();
    expect(find.text('Belum ada transfer saldo.'), findsOneWidget);
  });
  testWidgets(
      'unknown then rejected transfer cannot unlock or create a fresh key',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..sendError = const NetworkException('Hasil belum pasti');
    await t
        .pumpWidget(movementApp(const TransferScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await transferForm(t);
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    repo.sendError = const MovementRejectedException('PIN ditolak');
    await visibleTap(t, find.byKey(const Key('transfer-submit')));
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['idempotency_key'], repo.sent[1]['idempotency_key']);
    expect(find.byKey(const Key('transfer-edit')), findsNothing);
  });
  testWidgets(
      'unknown then rejected payout cannot unlock or create a fresh key',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..sendError = const NetworkException('Hasil belum pasti');
    await t.pumpWidget(
        movementApp(const PayoutRequestScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('payout-amount')).findTextField(), '100000');
    await t.enterText(
        find.byKey(const Key('payout-pin')), List.filled(6, '0').join());
    await visibleTap(t, find.byKey(const Key('payout-ack')));
    await visibleTap(t, find.byKey(const Key('payout-submit')));
    repo.sendError = const MovementRejectedException('PIN ditolak');
    await visibleTap(t, find.byKey(const Key('payout-submit')));
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['idempotency_key'], repo.sent[1]['idempotency_key']);
    expect(find.byKey(const Key('payout-edit')), findsNothing);
  });
  testWidgets(
      'proof pick upload input stages pending fragment separately from verify',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..value = payoutFixture(manage: true, status: 'processing');
    await t.pumpWidget(movementApp(
        PayoutProofScreen(payout: repo.value, part: repo.value.parts.single),
        repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('proof-amount')).findTextField(), '40000');
    await t.enterText(
        find.byKey(const Key('proof-reference')), 'BANK-SYNTHETIC');
    await t.enterText(find.byKey(const Key('proof-note')),
        'Pemeriksaan nominal manual fixture');
    await visibleTap(t, find.byKey(const Key('payout-pick-proof')));
    await visibleTap(t, find.byKey(const Key('proof-destination-ack')));
    await visibleTap(t, find.byKey(const Key('payout-proof-submit')));
    expect(repo.actions, ['proofs']);
    expect(repo.sent.single['amount'], 40000);
    expect(repo.sent.single['proof_asset_id'], isNotNull);
    expect(repo.sent.single['account_number'], bankFixture().accountNumber);
    expect(repo.sent.single['expected_version'], 3);
  });
  testWidgets('error retry, loading and empty payout use complete async states',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()
      ..loadError = const NetworkException('Koneksi terputus');
    await t.pumpWidget(movementApp(const PayoutsScreen(), repo));
    await t.pumpAndSettle();
    expect(find.text('Coba Lagi'), findsOneWidget);
    repo.loadError = null;
    repo.empty = true;
    await visibleTap(t, find.text('Coba Lagi'));
    expect(find.text('Belum ada pencairan pada filter ini.'), findsOneWidget);
  });
  testWidgets('payout proof deep link denies unrelated or final part',
      (t) async {
    movementSize(t);
    final repo = FakeMovement();
    await t.pumpWidget(movementApp(
        const PayoutProofRouteScreen(
            id: 'payout-fixture', partId: 'part-fixture'),
        repo));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('payout-proof-submit')), findsNothing);
    expect(find.textContaining('tidak tersedia untuk tindakan ini'),
        findsOneWidget);
  });
  testWidgets(
      'mixed source closed payout reconciles verified and released with no false held banner',
      (t) async {
    movementSize(t);
    final repo = FakeMovement()..value = mixedPayoutFixture();
    await t.pumpWidget(
        movementApp(const PayoutDetailScreen(id: 'payout-fixture'), repo));
    await t.pumpAndSettle();
    expect(find.textContaining('Pencairan selesai sebagian'), findsOneWidget);
    expect(find.text('Hasil belum pasti'), findsNothing);
    expect(find.text('Dilepas ke saldo Rp40.000'), findsOneWidget);
    expect(find.textContaining('Sisa saldo tetap ditahan'), findsNothing);
  });
}
