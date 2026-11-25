import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:app_main/features/money_movement/presentation/bank_account_screen.dart';
import 'package:app_main/features/money_movement/presentation/payouts_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_detail_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_request_screen.dart';
import 'package:app_main/features/money_movement/presentation/transfer_screen.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/money_movement/movement_screens_test.dart'
    show movementApp, visibleTap, transferForm;
import '../test/features/money_movement/fake_movement_repository.dart';
import 'render_s03_test.dart' show fonts;

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final name in [
      'bank',
      'bank-bottom-large',
      'payouts',
      'payout-request',
      'payout-request-bottom-large',
      'payout-owner',
      'payout-owner-bottom',
      'payout-manager',
      'payout-manager-bottom-large',
      'payout-success',
      'payout-partial',
      'payout-mixed-closed',
      'payout-failed',
      'platform-queue-large',
      'proof-form',
      'proof-form-bottom-large',
      'proof-correction',
      'verify-dialog-large',
      'transfer-form',
      'transfer-confirm-large',
      'transfer-success',
      'transfer-history',
      'empty',
      'error',
      'loading'
    ]) {
      testWidgets('$name at $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repo = FakeMovement();
        Widget screen = const PayoutsScreen();
        if (name.startsWith('bank')) screen = const PrimaryBankScreen();
        if (name.startsWith('payout-request')) {
          screen = const PayoutRequestScreen(communityId: '1');
        }
        if (name.startsWith('payout-owner') ||
            name.startsWith('payout-manager') ||
            [
              'payout-success',
              'payout-partial',
              'payout-mixed-closed',
              'payout-failed',
              'verify-dialog-large'
            ].contains(name)) {
          repo.value = payoutFixture(
              manage: name.startsWith('payout-manager') ||
                  name == 'verify-dialog-large',
              status: name == 'payout-success'
                  ? 'succeeded'
                  : name == 'payout-failed'
                      ? 'failed'
                      : 'uncertain',
              pending: !['payout-success', 'payout-partial'].contains(name),
              longMoney: name.contains('large'));
          if (name == 'payout-mixed-closed') repo.value = mixedPayoutFixture();
          screen = const PayoutDetailScreen(id: 'payout-fixture');
        }
        if (name == 'platform-queue-large') {
          repo.value =
              payoutFixture(manage: true, platform: true, longMoney: true);
          screen = const PayoutsScreen(manage: true);
        }
        if (name.startsWith('proof-')) {
          repo.value = payoutFixture(manage: true, status: 'processing');
          screen = PayoutProofScreen(
              payout: repo.value,
              part: repo.value.parts.single,
              fragment: name == 'proof-correction'
                  ? repo.value.parts.single.fragments.single
                  : null);
        }
        if (name.startsWith('transfer-')) {
          screen = name == 'transfer-history'
              ? const TransferHistoryScreen()
              : const TransferScreen(communityId: '1');
        }
        if (name == 'empty') repo.empty = true;
        if (name == 'error') {
          repo.loadError = const NetworkException(
              'Koneksi terputus. Periksa jaringan lalu coba lagi.');
        }
        if (name == 'loading') repo.loadGate = Completer<void>();
        final boundaryKey = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: boundaryKey,
            child: movementApp(screen, repo,
                scale: name.contains('large') ? 1.5 : 1)));
        if (name == 'loading') {
          await t.pump(const Duration(milliseconds: 400));
        } else {
          await t.pumpAndSettle();
        }
        if (name == 'transfer-confirm-large' || name == 'transfer-success') {
          await transferForm(t);
          if (name == 'transfer-success') {
            await visibleTap(t, find.byKey(const Key('transfer-submit')));
          } else {
            await t.ensureVisible(find.byKey(const Key('transfer-confirm')));
            await t.pumpAndSettle();
          }
        }
        if (name == 'verify-dialog-large') {
          await visibleTap(t, find.byKey(const Key('verify-fragment-fixture')));
        }
        if (name.contains('bottom')) {
          await t.drag(find.byType(ListView), const Offset(0, -1500));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await t.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s05-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        if (name == 'loading') {
          repo.loadGate!.complete();
          await t.pumpAndSettle();
        }
      });
    }
  }
}
