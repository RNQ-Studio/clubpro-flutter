import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_product_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_product_form_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_checkout_screen.dart';
import 'package:app_main/features/marketplace/presentation/market_orders_screen.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/marketplace/marketplace_screens_test.dart'
    show marketApp, checkoutForm;
import '../test/features/marketplace/fake_marketplace_repository.dart';
import '../test/features/money_movement/movement_screens_test.dart'
    show visibleTap;
import 'render_s03_test.dart' show fonts;

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final name in [
      'main',
      'community',
      'seller',
      'detail-guest',
      'detail-soldout',
      'my-products',
      'edit-inactive',
      'edit-bottom-large',
      'new-form',
      'checkout',
      'checkout-bottom-large',
      'checkout-keyboard',
      'checkout-unknown',
      'checkout-success',
      'purchase-history',
      'sale-history',
      'order-detail',
      'empty',
      'error',
      'loading'
    ]) {
      testWidgets('$name at $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repo = FakeMarketplace();
        final storage = MarketStorage();
        Widget screen = const MarketplaceScreen();
        if (name == 'community') {
          screen = const MarketplaceScreen(communityId: '2');
        }
        if (name == 'seller') screen = const MarketplaceScreen(sellerId: '2');
        if (name.startsWith('detail')) {
          screen = const MarketProductScreen(id: 'product-1');
        }
        if (name == 'detail-soldout') {
          repo.value = const MarketProduct(
              id: 'product-1',
              name: 'Barang stok habis',
              description:
                  'Stok habis tetap dapat dilihat; pembelian dinonaktifkan.',
              price: 999999999,
              stock: 0,
              version: 3,
              sellerId: '2',
              sellerName: 'Penjual dengan nama yang sangat panjang sekali',
              communityId: '2',
              communityName: 'Komunitas olahraga dengan nama sangat panjang',
              canBuy: false,
              unavailableReason: 'Stok habis.');
        }
        if (name == 'my-products') screen = const MarketplaceScreen(mine: true);
        if (name.startsWith('edit')) {
          screen = const MarketProductFormScreen(id: 'product-1');
          repo.value = const MarketProduct(
              id: 'product-1',
              name:
                  'Produk lama dengan nama panjang untuk menguji layout responsif dan teks',
              description:
                  'Deskripsi barang panjang yang tetap dapat dibaca setelah keanggotaan berakhir. Produk lama dapat dinonaktifkan. Harga dan foto transaksi final tidak berubah.',
              price: 999999999,
              stock: 10000,
              version: 3,
              sellerId: '2',
              sellerName: 'Penjual',
              communityId: '99',
              communityName: 'Komunitas lama',
              photoAssetId: 'asset-old',
              active: false,
              canBuy: false);
        }
        if (name == 'new-form') screen = const MarketProductFormScreen();
        if (name.startsWith('checkout')) {
          screen = const MarketCheckoutScreen(id: 'product-1');
        }
        if (name == 'checkout-unknown') {
          storage.values['market_checkout_1_product-1'] = jsonEncode({
            'product_id': 'product-1',
            'quantity': 1,
            'expected_version': 2,
            'expected_unit_price': 75000,
            'idempotency_key': 'request-fixture',
            'acknowledged': true
          });
        }
        if (name == 'purchase-history' || name == 'sale-history') {
          screen = const MarketOrdersScreen();
        }
        if (name == 'order-detail') {
          screen = const MarketOrderScreen(id: 'order-1');
        }
        if (name == 'empty') repo.empty = true;
        if (name == 'error') {
          repo.loadError = const NetworkException(
              'Koneksi terputus. Periksa jaringan lalu coba lagi.');
        }
        if (name == 'loading') repo.gate = Completer<void>();
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: key,
            child: marketApp(screen, repo,
                storage: storage,
                scale: name.contains('large') ? 1.5 : 1,
                guest: name == 'detail-guest')));
        if (name == 'loading') {
          await t.pump(const Duration(milliseconds: 300));
        } else {
          await t.pumpAndSettle();
        }
        if (name == 'sale-history') await visibleTap(t, find.text('Penjualan'));
        if (name == 'checkout-success') {
          await checkoutForm(t);
          await visibleTap(t, find.byKey(const Key('checkout-pay')));
        }
        if (name.contains('bottom')) {
          await t.drag(find.byType(ListView).first, const Offset(0, -1800));
          await t.pumpAndSettle();
        }
        if (name == 'checkout-keyboard') {
          t.view.viewInsets = const FakeViewPadding(bottom: 340);
          await t.ensureVisible(find.byKey(const Key('checkout-pin')));
          await t.tap(find.byKey(const Key('checkout-pin')));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir =
              Platform.environment['RENDER_DIR'] ?? 'build/marketplace-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        if (repo.gate != null) {
          repo.gate!.complete();
          await t.pumpAndSettle();
        }
      });
    }
  }
}
