import 'package:app_main/features/money_movement/data/money_movement_remote_data_source.dart';
import 'package:app_main/features/money_movement/presentation/bank_account_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_detail_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_request_screen.dart';
import 'package:app_main/features/money_movement/presentation/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_movement_repository.dart';
import 'movement_screens_test.dart' show movementApp, movementSize;

void _keyboardViewport(WidgetTester tester) {
  movementSize(tester, width: 500, height: 800);
  tester.view.viewPadding = const FakeViewPadding(bottom: 34);
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
}

Future<void> _reach(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 180,
        scrollable: find
            .descendant(
                of: find.byType(ListView), matching: find.byType(Scrollable))
            .first,
        maxScrolls: 35);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _reach(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  await _reach(tester, finder);
  final input =
      find.descendant(of: finder, matching: find.byType(TextFormField));
  await tester.enterText(input.evaluate().isEmpty ? finder : input, text);
  await tester.pumpAndSettle();
}

void _expectSafeKeyboardAction(WidgetTester tester, Finder finder) {
  final rectangle = tester.getRect(finder);
  expect(rectangle.bottom, lessThanOrEqualTo(500.1),
      reason: 'The action must remain above the 300px software keyboard.');
  expect(rectangle.top, greaterThanOrEqualTo(0));
  expect(rectangle.height, greaterThanOrEqualTo(48));
  expect(
      find.ancestor(of: finder, matching: find.byType(SafeArea)), findsWidgets);
  expect(tester.takeException(), null);
}

void main() {
  testWidgets(
      'PIN is obscured, digits-only and bounded while keyboard submit stays reachable',
      (tester) async {
    _keyboardViewport(tester);
    final repository = FakeMovement()
      ..sendError = const MovementRejectedException('Fixture input ditolak');
    await tester.pumpWidget(movementApp(
        const TransferScreen(communityId: '1'), repository,
        scale: 1.5));
    await tester.pumpAndSettle();
    await _enter(tester, 'transfer-search', 'Tujuan');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('recipient-2-2')));
    await _enter(tester, 'transfer-amount', '75000');
    final mixed = List.generate(8, (i) => '$i${i.isEven ? 'x' : ''}').join();
    await _enter(tester, 'transfer-pin', mixed);
    final pin = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('transfer-pin')),
        matching: find.byType(TextField)));
    expect(pin.obscureText, true);
    expect(pin.enableSuggestions, false);
    expect(pin.autocorrect, false);
    expect(pin.keyboardType, TextInputType.number);
    expect(pin.controller!.text, List.generate(6, (i) => '$i').join());
    expect(pin.decoration?.labelText, 'PIN transaksi (6 digit)');
    await _tap(tester, find.byKey(const Key('transfer-confirm')));
    final submit = find.byKey(const Key('transfer-submit'));
    await _reach(tester, submit);
    _expectSafeKeyboardAction(tester, submit);
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.sent.single['amount'], 75000);
    expect(repository.sent.single['pin'], pin.controller!.text);
  });

  testWidgets(
      'primary bank confirmation and save remain usable above keyboard and safe inset',
      (tester) async {
    _keyboardViewport(tester);
    final repository = FakeMovement();
    await tester.pumpWidget(
        movementApp(const PrimaryBankScreen(), repository, scale: 1.5));
    await tester.pumpAndSettle();
    await _enter(tester, 'bank-owner', 'Pihak Ketiga Fixture Diubah');
    await _tap(tester, find.byKey(const Key('bank-ack')));
    final submit = find.byKey(const Key('bank-save'));
    await _reach(tester, submit);
    _expectSafeKeyboardAction(tester, submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
        repository.sent.single['account_name'], 'Pihak Ketiga Fixture Diubah');
    expect(repository.sent.single['acknowledged'], true);
    expect(find.text('Rekening utama tersimpan.'), findsOneWidget);
  });

  testWidgets(
      'proof amount and manual reference can be completed with keyboard without hiding action',
      (tester) async {
    _keyboardViewport(tester);
    final repository = FakeMovement()
      ..value = payoutFixture(manage: true, status: 'processing');
    await tester.pumpWidget(movementApp(
        PayoutProofScreen(
            payout: repository.value, part: repository.value.parts.single),
        repository,
        scale: 1.5));
    await tester.pumpAndSettle();
    await _enter(tester, 'proof-amount', '40000');
    await _enter(tester, 'proof-reference', 'OUTGOING-KEYBOARD-FIXTURE');
    await _enter(tester, 'proof-note', 'Pemeriksaan sintetis dengan keyboard.');
    await _tap(tester, find.byKey(const Key('payout-pick-proof')));
    await _tap(tester, find.byKey(const Key('proof-destination-ack')));
    final submit = find.byKey(const Key('payout-proof-submit'));
    await _reach(tester, submit);
    _expectSafeKeyboardAction(tester, submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(repository.actions, ['proofs']);
    expect(repository.sent.single['amount'], 40000);
    expect(
        repository.sent.single['bank_reference'], 'OUTGOING-KEYBOARD-FIXTURE');
  });

  for (final screen in <Widget>[
    const PayoutRequestScreen(communityId: '999'),
    const TransferScreen(communityId: '999'),
  ]) {
    testWidgets(
        'stale community deep link safely requires selection in ${screen.runtimeType}',
        (tester) async {
      _keyboardViewport(tester);
      await tester.pumpWidget(movementApp(screen, FakeMovement(), scale: 1.5));
      await tester.pumpAndSettle();
      final finder = find.byKey(Key(screen is PayoutRequestScreen
          ? 'payout-community'
          : 'transfer-community'));
      await _reach(tester, finder);
      final dropdown = tester.widget<DropdownButtonFormField<String>>(finder);
      expect(dropdown.initialValue, null);
      expect(tester.takeException(), null);
    });
  }
}
