import 'package:app_main/config/main_config.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/billing_screen.dart';
import 'package:app_main/features/finance/presentation/wallet_screen.dart';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/marketplace/presentation/market_checkout_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_orders_screen.dart';
import 'package:app_main/features/money_movement/domain/money_movement.dart';
import 'package:app_main/features/money_movement/presentation/payout_detail_screen.dart';
import 'package:app_main/features/money_movement/presentation/payout_request_screen.dart';
import 'package:app_main/features/training/domain/training.dart';
import 'package:app_main/features/training/presentation/training_screen.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'features/achievements/fake_achievements_repository.dart';
import 'features/community/fake_community_repository.dart';
import 'features/finance/finance_screens_test.dart' show FakeFinance;
import 'features/marketplace/fake_marketplace_repository.dart';
import 'features/money_movement/fake_movement_repository.dart';
import 'features/training/fake_training_repository.dart';
import 's07_lobby_journeys_test.dart'
    show LobbyCards, lobbyApplication, tapLobbyLink;

// Repository fixtures simulate successful server responses. These tests prove the
// actual App/router invalidates and renders cross-feature data; API/ledger tests
// independently prove that the backend produces those responses atomically.
class _Finance extends FakeFinance {
  void move({required int spend, int reserve = 0, int hold = 0}) {
    walletValue = WalletSummary(
        available: walletValue.available - spend,
        packageReserve: walletValue.packageReserve + reserve,
        payoutHold: walletValue.payoutHold + hold);
  }

  @override
  Future<void> pay(String communityId, String scope, String key,
      {String? targetMemberId,
      required List<String> invoiceIds,
      required int expectedAmount}) async {
    await super.pay(communityId, scope, key,
        targetMemberId: targetMemberId,
        invoiceIds: invoiceIds,
        expectedAmount: expectedAmount);
    move(spend: expectedAmount);
  }
}

class _Training extends FakeTraining {
  _Training(this.finance);
  final _Finance finance;
  @override
  Future<void> purchase(String communityId, TrainingPackage package,
      int version, String key) async {
    await super.purchase(communityId, package, version, key);
    finance.move(spend: package.price, reserve: package.price);
  }
}

class _Market extends FakeMarketplace {
  _Market(this.finance);
  final _Finance finance;
  @override
  Future<MarketOrder> buy(Map<String, Object?> fields) async {
    final order = await super.buy(fields);
    finance.move(spend: order.total);
    return order;
  }
}

class _Movement extends FakeMovement {
  _Movement(this.finance) {
    value = payoutFixture(status: 'requested');
  }
  final _Finance finance;
  @override
  Future<Payout> requestPayout(Map<String, Object?> fields) async {
    final payout = await super.requestPayout(fields);
    final amount = fields['amount']! as int;
    finance.move(spend: amount, hold: amount);
    return payout;
  }
}

Future<void> _tap(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> _boot(WidgetTester t, double width, _Finance finance,
    {FakeTraining? training,
    FakeMarketplace? market,
    FakeMovement? movement}) async {
  t.view.physicalSize = Size(width, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  appRouter.go('/');
  await t.pumpWidget(lobbyApplication(
      storage: MarketStorage(),
      role: CommunityRole.member,
      communities: FakeCommunityRepository(
          joined: [testCommunity('2', myRole: CommunityRole.member)],
          detail: testDetail(id: '2', myRole: CommunityRole.member)),
      finance: finance,
      points: FakeAchievements(),
      training: training ?? FakeTraining(),
      market: market ?? FakeMarketplace(),
      movement: movement,
      cards: LobbyCards()));
  await t.pumpAndSettle();
}

bool _primaryFocusInside(Finder target) {
  final roots = target.evaluate().toSet();
  final context = FocusManager.instance.primaryFocus?.context;
  if (context is! Element) return false;
  if (roots.contains(context)) return true;
  var inside = false;
  context.visitAncestorElements((ancestor) {
    if (roots.contains(ancestor)) inside = true;
    return !inside;
  });
  return inside;
}

Future<void> _tabTo(WidgetTester t, Finder target) async {
  expect(target, findsOneWidget);
  for (var i = 0; i < 40 && !_primaryFocusInside(target); i++) {
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pumpAndSettle();
  }
  expect(_primaryFocusInside(target), isTrue,
      reason: 'Keyboard focus must reach the requested control');
  expect(target.hitTestable(), findsOneWidget,
      reason: 'Focused control must be visible and usable');
}

Future<void> _shiftTab(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await t.sendKeyEvent(LogicalKeyboardKey.tab);
  await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    AppConfig.instance = MainConfig();
    PackageInfo.setMockInitialValues(
        appName: 'CEO',
        packageName: 'fixture',
        version: '1',
        buildNumber: '1',
        buildSignature: '');
  });
  for (final width in [500.0, 1280.0]) {
    testWidgets(
        'actual App checkout accepts keyboard only after terms at $width',
        (t) async {
      final finance = _Finance();
      final market = _Market(finance);
      await _boot(t, width, finance, market: market);
      await tapLobbyLink(t, 'market-entry-main');
      await _tap(t, find.byKey(const Key('product-product-1')));
      await _tap(t, find.byKey(const Key('market-buy')));
      final pin = find.byKey(const Key('checkout-pin'));
      final terms = find.byKey(const Key('checkout-confirm'));
      final pay = find.byKey(const Key('checkout-pay'));
      FocusManager.instance.primaryFocus?.unfocus();
      await _tabTo(t, pin);
      await t.enterText(pin, List.generate(6, (i) => '${i + 1}').join());
      expect(_primaryFocusInside(pin), isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(_primaryFocusInside(terms), isTrue);
      await _shiftTab(t);
      expect(_primaryFocusInside(pin), isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(_primaryFocusInside(terms), isTrue);
      expect(t.widget<CheckboxListTile>(terms).value, isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(t.widget<CheckboxListTile>(terms).value, isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(_primaryFocusInside(pay), isTrue);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(market.buyCalls, 1);
      expect(find.text('Pembelian berhasil'), findsOneWidget);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'actual App keyboard opens cancels and confirms billing at $width',
        (t) async {
      final finance = _Finance();
      await _boot(t, width, finance);
      await tapLobbyLink(t, 'member-lobby-dues');
      final pay = find.byKey(const Key('billing-pay-wallet'));
      FocusManager.instance.primaryFocus?.unfocus();
      await _tabTo(t, pay);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(find.text('Bayar dari saldo?'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Bayar dari saldo?'), findsNothing);
      expect(finance.payKeys, isEmpty);
      await _tabTo(t, pay);
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(find.text('Bayar dari saldo?'), findsOneWidget);
      await _tabTo(t, find.widgetWithText(FilledButton, 'Bayar sekarang'));
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(finance.payKeys, hasLength(1));
      expect(find.text('Aktif'), findsOneWidget);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('actual App billing payment then wallet at $width', (t) async {
      final finance = _Finance();
      await _boot(t, width, finance);
      await tapLobbyLink(t, 'member-lobby-dues');
      expect(find.byType(BillingScreen), findsOneWidget);
      await _tap(t, find.byKey(const Key('billing-pay-wallet')));
      await _tap(t, find.text('Bayar sekarang'));
      expect(find.text('Aktif'), findsOneWidget);
      expect(finance.paidExpectedAmount, 150000);
      expect(finance.paidInvoiceIds, ['invoice-1']);
      expect(finance.payKeys, hasLength(1));
      appRouter.pop();
      await t.pumpAndSettle();
      await tapLobbyLink(t, 'home-wallet');
      expect(find.byType(WalletScreen), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
      expect(finance.walletValue.available, 50000);
      expect(finance.walletValue.packageReserve, 50000);
      expect(finance.walletValue.payoutHold, 25000);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'actual App package purchase refreshes original wallet at $width',
        (t) async {
      final finance = _Finance();
      final training = _Training(finance);
      await _boot(t, width, finance, training: training);
      await tapLobbyLink(t, 'home-wallet');
      expect(find.text('Rp200.000'), findsOneWidget);
      appRouter.pop();
      await t.pumpAndSettle();
      await tapLobbyLink(t, 'member-lobby-packages');
      expect(find.byType(TrainingScreen), findsOneWidget);
      await _tap(t, find.byKey(const Key('training-buy-7')));
      await _tap(t, find.byKey(const Key('training-buy-confirm')));
      expect(training.calls, ['purchase']);
      expect(training.bodies.single['expected_price'], 100003);
      expect(find.textContaining('Paket berhasil dibeli.'), findsOneWidget);
      appRouter.pop();
      await t.pumpAndSettle();
      await tapLobbyLink(t, 'home-wallet');
      expect(find.text('Rp99.997'), findsOneWidget);
      expect(find.text('Rp150.003'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('actual App catalogue checkout history and wallet at $width',
        (t) async {
      final finance = _Finance();
      final market = _Market(finance);
      await _boot(t, width, finance, market: market);
      await tapLobbyLink(t, 'home-wallet');
      appRouter.pop();
      await t.pumpAndSettle();
      await tapLobbyLink(t, 'market-entry-main');
      await _tap(t, find.byKey(const Key('product-product-1')));
      await _tap(t, find.byKey(const Key('market-buy')));
      expect(find.byType(MarketCheckoutScreen), findsOneWidget);
      await t.enterText(find.byKey(const Key('checkout-pin')),
          List.generate(6, (i) => '${i + 1}').join());
      await _tap(t, find.byKey(const Key('checkout-confirm')));
      await _tap(t, find.byKey(const Key('checkout-pay')));
      expect(find.text('Pembelian berhasil'), findsOneWidget);
      expect(market.buyCalls, 1);
      expect(market.requests.single['product_id'], 'product-1');
      expect(market.requests.single['expected_unit_price'], 75000);
      await _tap(t, find.text('Riwayat pembelian & penjualan'));
      expect(find.byType(MarketOrdersScreen), findsOneWidget);
      await _tap(t, find.byKey(const Key('order-order-1')));
      expect(find.byType(MarketOrderScreen), findsOneWidget);
      expect(find.text('Total Rp75.000'), findsOneWidget);
      appRouter.go(AppRoutes.wallet);
      await t.pumpAndSettle();
      expect(find.text('Rp125.000'), findsOneWidget);
      expect(find.text('Rp50.000'), findsOneWidget);
      expect(find.text('Rp25.000'), findsOneWidget);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('actual App payout request freezes held balance at $width',
        (t) async {
      final finance = _Finance();
      final movement = _Movement(finance);
      await _boot(t, width, finance, movement: movement);
      await tapLobbyLink(t, 'home-wallet');
      await _tap(t, find.widgetWithText(OutlinedButton, 'Pencairan'));
      await _tap(t, find.widgetWithText(FilledButton, 'Ajukan pencairan'));
      expect(find.byType(PayoutRequestScreen), findsOneWidget);
      await _tap(t, find.byKey(const Key('payout-community')));
      await _tap(t, find.text('Pemanah Nusantara').last);
      await t.enterText(find.byKey(const Key('payout-amount')), '100000');
      await t.enterText(find.byKey(const Key('payout-pin')),
          List.generate(6, (i) => '${i + 1}').join());
      await _tap(t, find.byKey(const Key('payout-ack')));
      await _tap(t, find.byKey(const Key('payout-submit')));
      expect(find.byType(PayoutDetailScreen), findsOneWidget);
      expect(find.textContaining('PAYOUT-FIXTURE'), findsOneWidget);
      expect(movement.sent, hasLength(1));
      expect(movement.sent.single['amount'], 100000);
      expect(movement.sent.single['bank_account_version'], 2);
      expect(movement.sent.single['acknowledged'], true);
      appRouter.go(AppRoutes.wallet);
      await t.pumpAndSettle();
      expect(find.text('Rp100.000'), findsOneWidget);
      expect(find.text('Rp125.000'), findsOneWidget);
      expect(find.text('Rp50.000'), findsOneWidget);
      expect(t.takeException(), null);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
