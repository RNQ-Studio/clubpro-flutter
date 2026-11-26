import 'dart:async';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_product_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_product_form_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_checkout_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_orders_screen.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_providers.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../community/fake_community_repository.dart';
import '../finance/finance_screens_test.dart' show FixtureAuth;
import '../money_movement/movement_screens_test.dart' show visibleTap;
import 'fake_marketplace_repository.dart';

class GuestMarketAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthUnauthenticated();
}

class MarketAuth extends FixtureAuth {
  @override
  Future<void> checkCurrentUser() async {}
}

class FakeMarketPin implements PinRepository {
  int saves = 0;
  @override
  Future<bool> emailRecoveryAvailable() async => false;
  @override
  Future<User> login(String identifier, String pin) async => const User(
      id: '1', name: 'Akun Uji', email: 'uji@anaklangit.manahpro.web.id');
  @override
  Future<void> save(String pin,
      {String? currentPin,
      String? currentPassword,
      String? verificationMethod,
      bool useRecentGoogleAuth = false}) async {
    saves++;
  }

  @override
  Future<void> recover(String identifier) async {}
  @override
  Future<void> reset(String identifier, String code, String pin) async {}
}

Widget marketApp(Widget screen, FakeMarketplace repo,
        {MarketStorage? storage,
        double scale = 1,
        bool guest = false,
        FakeCommunityImagePicker? picker}) =>
    ProviderScope(
        overrides: [
          marketplaceRepositoryProvider.overrideWithValue(repo),
          pinRepositoryProvider.overrideWithValue(FakeMarketPin()),
          storageServiceProvider.overrideWithValue(storage ?? MarketStorage()),
          authProvider
              .overrideWith(guest ? GuestMarketAuth.new : MarketAuth.new),
          communityRepositoryProvider.overrideWithValue(FakeCommunityRepository(
              joined: [testCommunity('2', name: 'Komunitas Penjual')])),
          communityImagePickerProvider
              .overrideWithValue(picker ?? FakeCommunityImagePicker())
        ],
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            routerConfig: GoRouter(initialLocation: '/screen', routes: [
              GoRoute(path: '/screen', builder: (_, s) => screen),
              GoRoute(
                  path: AppRoutes.marketProducts,
                  builder: (_, s) => const MarketplaceScreen()),
              GoRoute(
                  path: '/explore/products/:id',
                  builder: (_, s) =>
                      MarketProductScreen(id: s.pathParameters['id']!)),
              GoRoute(
                  path: '/explore/sellers/:id',
                  builder: (_, s) =>
                      MarketplaceScreen(sellerId: s.pathParameters['id']!)),
              GoRoute(
                  path: '/marketplace/checkout/:id',
                  builder: (_, s) =>
                      MarketCheckoutScreen(id: s.pathParameters['id']!)),
              GoRoute(
                  path: AppRoutes.marketOrders,
                  builder: (_, s) => const MarketOrdersScreen()),
              GoRoute(
                  path: '/marketplace/orders/:id',
                  builder: (_, s) =>
                      MarketOrderScreen(id: s.pathParameters['id']!)),
              GoRoute(
                  path: AppRoutes.myMarketProducts,
                  builder: (_, s) => const MarketplaceScreen(mine: true)),
              GoRoute(
                  path: '/account/pin',
                  builder: (_, s) => const PinScreen(mode: PinMode.manage)),
              GoRoute(
                  path: '/login',
                  builder: (_, s) => Scaffold(
                      body: Text(
                          'login:${decodeLoginReturn(s.uri.queryParameters['from'])}')))
            ])));
Future<void> checkoutForm(WidgetTester t) async {
  await t.enterText(find.byKey(const Key('checkout-pin')), '000000');
  await visibleTap(t, find.byKey(const Key('checkout-confirm')));
}

Future<void> newProductForm(WidgetTester t) async {
  await visibleTap(t, find.byKey(const Key('product-community')));
  await t.tap(find.text('Komunitas Penjual').last);
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('product-name')), 'Barang baru');
  await t.enterText(
      find.byKey(const Key('product-description')), 'Deskripsi barang baru');
  await t.enterText(
      find.descendant(
          of: find.byKey(const Key('product-price')),
          matching: find.byType(TextFormField)),
      '100000');
  await visibleTap(t, find.byKey(const Key('product-photo')));
}

void sizeMarket(WidgetTester t, {double width = 500, double height = 1200}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets(
      'catalogue detail quote PIN final and persisted history integration',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    await t.pumpWidget(marketApp(const MarketplaceScreen(), repo));
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('product-product-1')));
    await visibleTap(t, find.byKey(const Key('market-buy')));
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.buyCalls, 1);
    expect(repo.requests.single['expected_version'], 2);
    expect(repo.requests.single['pin'], '000000');
    expect(find.text('Pembelian berhasil'), findsOneWidget);
    await visibleTap(t, find.text('Riwayat pembelian & penjualan'));
    await visibleTap(t, find.byKey(const Key('order-order-1')));
    expect(find.text('Pembelian berhasil'), findsOneWidget);
    expect(find.textContaining('refund'), findsWidgets);
    expect(t.takeException(), null);
  });
  testWidgets('guest can browse and buying returns to same product checkout',
      (t) async {
    sizeMarket(t);
    await t.pumpWidget(marketApp(
        const MarketProductScreen(id: 'product-1'), FakeMarketplace(),
        guest: true));
    await t.pumpAndSettle();
    expect(find.textContaining('bersifat pilihan'), findsOneWidget);
    await visibleTap(t, find.byKey(const Key('market-buy')));
    expect(find.text('login:/marketplace/checkout/product-1'), findsOneWidget);
  });
  testWidgets('search pagination scoped by community and seller', (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    await t.pumpWidget(marketApp(
        const MarketplaceScreen(communityId: '2', sellerId: '9'), repo));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('market-search')), 'raket');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(repo.queries.last, containsPair('search', 'raket'));
    expect(repo.queries.last, containsPair('community', '2'));
    expect(repo.queries.last, containsPair('seller', '9'));
    await visibleTap(t, find.byTooltip('Halaman berikutnya'));
    expect(repo.queries.last, containsPair('page', 2));
  });
  testWidgets('busy double click buys only once', (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()..buyGate = Completer<void>();
    await t.pumpWidget(
        marketApp(const MarketCheckoutScreen(id: 'product-1'), repo));
    await t.pumpAndSettle();
    await checkoutForm(t);
    final button = find.byKey(const Key('checkout-pay'));
    await t.ensureVisible(button);
    await t.tap(button);
    await t.tap(button);
    await t.pump();
    expect(repo.buyCalls, 1);
    repo.buyGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('Pembelian berhasil'), findsOneWidget);
  });
  testWidgets('committed timeout lookup succeeds without second POST',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()..commitThenTimeout = true;
    final storage = MarketStorage();
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), repo,
        storage: storage));
    await t.pumpAndSettle();
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.buyCalls, 1);
    expect(storage.values, isNotEmpty);
    expect(storage.values.values.single, isNot(contains('pin')));
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.buyCalls, 1);
    expect(repo.lookupCalls, 1);
    expect(find.text('Pembelian berhasil'), findsOneWidget);
    expect(storage.values, isEmpty);
  });
  testWidgets('unknown survives rejected retry and reload with same payload',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()
      ..buyError = const NetworkException('timeout');
    final storage = MarketStorage();
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), repo,
        storage: storage));
    await t.pumpAndSettle();
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    final key = repo.requests.single['idempotency_key'];
    repo.buyError = const MarketRejected('PIN salah');
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(find.byKey(const Key('checkout-edit')), findsNothing);
    expect(repo.requests.last['idempotency_key'], key);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), repo,
        storage: storage));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('checkout-pin')), '000000');
    repo.buyError = null;
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.requests.last['idempotency_key'], key);
    expect(find.text('Pembelian berhasil'), findsOneWidget);
  });
  testWidgets('stale rejection permits refreshed quote with new key',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()
      ..buyError = const MarketRejected('Harga berubah');
    await t.pumpWidget(
        marketApp(const MarketCheckoutScreen(id: 'product-1'), repo));
    await t.pumpAndSettle();
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    final key = repo.requests.single['idempotency_key'];
    await visibleTap(t, find.byKey(const Key('checkout-edit')));
    repo.buyError = null;
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.requests.last['idempotency_key'], isNot(key));
  });
  testWidgets(
      'failed durable storage prevents POST until later successful write',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    final storage = MarketStorage()..failWrite = true;
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), repo,
        storage: storage));
    await t.pumpAndSettle();
    await checkoutForm(t);
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.buyCalls, 0);
    expect(storage.values, isEmpty);
    storage.failWrite = false;
    await visibleTap(t, find.byKey(const Key('checkout-pay')));
    expect(repo.buyCalls, 1);
  });
  testWidgets('unreadable durable request prevents any fresh checkout',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    final storage = MarketStorage()..failRead = true;
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), repo,
        storage: storage));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('checkout-pay')), findsNothing);
    expect(repo.buyCalls, 0);
    storage.failRead = false;
    await visibleTap(t, find.text('Coba Lagi'));
    expect(find.byKey(const Key('checkout-quantity')), findsOneWidget);
  });
  testWidgets('PIN setup successfully restores same checkout', (t) async {
    sizeMarket(t);
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), FakeMarketplace()));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Atur / pulihkan PIN transaksi'));
    await t.enterText(
        find.widgetWithText(TextFormField, 'Password akun saat ini'),
        'fixture-password');
    await t.enterText(find.widgetWithText(TextFormField, 'PIN baru'), '000000');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Ulangi PIN baru'), '000000');
    await visibleTap(t, find.text('Simpan PIN'));
    expect(find.byKey(const Key('checkout-quantity')), findsOneWidget);
  });
  testWidgets(
      'required account reauthentication retains PIN and checkout return',
      (t) async {
    sizeMarket(t);
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), FakeMarketplace()));
    await t.pumpAndSettle();
    await visibleTap(t, find.text('Atur / pulihkan PIN transaksi'));
    await visibleTap(
        t, find.text('Verifikasi ulang melalui Google / password'));
    final text =
        t.widget<Text>(find.textContaining('login:/account/pin')).data!;
    final destination = Uri.parse(text.substring('login:'.length));
    expect(destination.path, '/account/pin');
    expect(decodeLoginReturn(destination.queryParameters['from']),
        '/marketplace/checkout/product-1');
  });
  testWidgets(
      'keyboard scroll keeps PIN confirmation and pay reachable at large text',
      (t) async {
    sizeMarket(t);
    await t.pumpWidget(marketApp(
        const MarketCheckoutScreen(id: 'product-1'), FakeMarketplace(),
        scale: 1.5));
    await t.pumpAndSettle();
    t.view.viewInsets = const FakeViewPadding(bottom: 340);
    await t.scrollUntilVisible(find.byKey(const Key('checkout-pin')), 150,
        maxScrolls: 30, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.byKey(const Key('checkout-pin')));
    await t.enterText(find.byKey(const Key('checkout-pin')), '000000');
    await visibleTap(t, find.byKey(const Key('checkout-confirm')));
    final pay = find.byKey(const Key('checkout-pay'));
    await t.scrollUntilVisible(pay, 150,
        maxScrolls: 30, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(pay);
    expect(t.getSize(pay).height, greaterThanOrEqualTo(48));
    await t.tap(pay);
    await t.pumpAndSettle();
    expect(find.text('Pembelian berhasil'), findsOneWidget);
    expect(t.takeException(), null);
  });
  testWidgets('create product picks image bytes uploads and saves new listing',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    await t.pumpWidget(marketApp(const MarketProductFormScreen(), repo));
    await t.pumpAndSettle();
    await newProductForm(t);
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.uploadCalls, 1);
    expect(repo.saveCalls, 1);
    expect(repo.requests.single, containsPair('photo_asset_id', 'asset-new'));
    expect(repo.requests.single, containsPair('price', 100000));
    expect(find.text('Lapak saya'), findsWidgets);
  });
  testWidgets(
      'photo upload failure retains image for retry without creating product',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()
      ..uploadError = const NetworkException('Foto gagal diunggah');
    await t.pumpWidget(marketApp(const MarketProductFormScreen(), repo));
    await t.pumpAndSettle();
    await newProductForm(t);
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.uploadCalls, 1);
    expect(repo.saveCalls, 0);
    expect(find.text('Foto gagal diunggah'), findsOneWidget);
    repo.uploadError = null;
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.uploadCalls, 2);
    expect(repo.saveCalls, 1);
  });
  testWidgets(
      'save rejection reuses uploaded asset rather than uploading again',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()
      ..saveError = const MarketRejected('Kuota lima barang aktif terpenuhi');
    await t.pumpWidget(marketApp(const MarketProductFormScreen(), repo));
    await t.pumpAndSettle();
    await newProductForm(t);
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.uploadCalls, 1);
    expect(repo.saveCalls, 1);
    repo.saveError = null;
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.uploadCalls, 1);
    expect(repo.saveCalls, 2);
  });
  testWidgets('invalid image feedback is clear and no upload or save occurs',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace();
    await t.pumpWidget(marketApp(const MarketProductFormScreen(), repo,
        picker: FakeCommunityImagePicker(
            error: const CommunityImageException(
                'Format foto harus JPG, PNG, atau WebP.'))));
    await t.pumpAndSettle();
    await visibleTap(t, find.byKey(const Key('product-photo')));
    expect(find.text('Format foto harus JPG, PNG, atau WebP.'), findsOneWidget);
    expect(repo.uploadCalls, 0);
    expect(repo.saveCalls, 0);
  });
  testWidgets(
      'own inactive editor loads and can disable after membership removed',
      (t) async {
    sizeMarket(t);
    final repo = FakeMarketplace()
      ..value = const MarketProduct(
          id: 'product-1',
          name: 'Barang lama',
          description: 'Deskripsi lama',
          price: 100,
          stock: 0,
          version: 4,
          sellerId: '2',
          sellerName: 'Penjual',
          communityId: '99',
          communityName: 'Komunitas lama',
          photoAssetId: 'asset-old',
          active: false,
          canBuy: false);
    await t.pumpWidget(
        marketApp(const MarketProductFormScreen(id: 'product-1'), repo));
    await t.pumpAndSettle();
    expect(find.text('Komunitas asal tersimpan'), findsOneWidget);
    await visibleTap(t, find.byKey(const Key('product-save')));
    expect(repo.saveCalls, 1);
    expect(repo.requests.single['is_active'], false);
    expect(repo.requests.single['expected_version'], 4);
  });
}
