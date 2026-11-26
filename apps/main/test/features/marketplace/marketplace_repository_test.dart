import 'dart:convert';
import 'dart:typed_data';
import 'package:app_main/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:app_main/features/marketplace/data/marketplace_repository_impl.dart';
import 'package:app_main/features/marketplace/data/marketplace_models.dart';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> productJson() => {
      'id': 'product-1',
      'name': 'Barang',
      'description': 'Deskripsi',
      'price': 75000,
      'stock': 3,
      'version': 2,
      'is_active': true,
      'can_buy': true,
      'photo_asset_id': 'asset-id',
      'photo_url': null,
      'seller': {'identity_id': 2, 'name': 'Penjual'},
      'community': {'id': 2, 'name': 'Komunitas', 'slug': null}
    };
Map<String, Object?> orderJson() => {
      'id': 'order-1',
      'product_id': 'product-1',
      'quantity': 2,
      'unit_price': 75000,
      'total': 150000,
      'status': 'succeeded',
      'journal_id': 'journal-1',
      'no_refund': true,
      'created_at': '2026-11-26T00:00:00Z',
      'idempotency_key': 'same-key',
      'snapshot': {
        'product': {
          'id': 'product-1',
          'name': 'Barang historis',
          'description': 'Deskripsi lama',
          'photo_url': null,
          'version': 2
        },
        'seller': {'identity_id': 2, 'name': 'Penjual'},
        'buyer': {'identity_id': 1, 'name': 'Pembeli'},
        'community': {'id': 2, 'name': 'Komunitas'}
      }
    };

class MarketAdapter implements HttpClientAdapter {
  int status = 200;
  Object? payload;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    request = options;
    return ResponseBody.fromString(jsonEncode(payload), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MarketAdapter adapter;
  late MarketplaceRepositoryImpl repo;
  setUp(() {
    adapter = MarketAdapter();
    repo = MarketplaceRepositoryImpl(MarketplaceRemoteDataSource(
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..httpClientAdapter = adapter));
  });
  test('catalogue actual API envelope and filters pagination', () async {
    adapter.payload = {
      'success': true,
      'data': {
        'items': [productJson()],
        'current_page': 2,
        'last_page': 4,
        'total': 9
      }
    };
    final p = await repo.products(
        communityId: '2', sellerId: '7', search: 'raket', page: 2);
    expect(p.items.single.price, 75000);
    expect(p.page, 2);
    expect(p.lastPage, 4);
    expect(adapter.request!.path, 'v1/public/products');
    expect(adapter.request!.queryParameters,
        containsPair('seller_identity_id', '7'));
    expect(adapter.request!.queryParameters, containsPair('search', 'raket'));
  });
  test('own inactive product uses authenticated detail endpoint', () async {
    adapter.payload = {
      'data': {...productJson(), 'is_active': false, 'can_buy': false}
    };
    final p = await repo.ownProduct('product-1');
    expect(p.active, false);
    expect(adapter.request!.path, 'v1/marketplace/products/product-1');
  });
  test(
      'quote uses server totals version balance and rejects broken conservation',
      () async {
    final j = {
      'product': productJson(),
      'quantity': 2,
      'unit_price': 75000,
      'total': 150000,
      'product_version': 2,
      'available_balance': 900000,
      'no_refund': true
    };
    adapter.payload = {'data': j};
    final q = await repo.quote('product-1', 2);
    expect(q.total, 150000);
    expect(q.version, 2);
    expect(adapter.request!.data, {'product_id': 'product-1', 'quantity': 2});
    j['total'] = 140000;
    expect(() => marketQuoteFromJson(j), throwsA(isA<FinanceDataException>()));
  });
  test('order history parses immutable snapshot not live product', () async {
    adapter.payload = {
      'data': {
        'items': [orderJson()],
        'current_page': 1,
        'last_page': 1
      }
    };
    final p = await repo.orders(direction: 'sales');
    expect(p.items.single.name, 'Barang historis');
    expect(p.items.single.buyerName, 'Pembeli');
    expect(adapter.request!.queryParameters['direction'], 'sales');
  });
  test(
      'idempotent order POST sends original fields and accepts only final result',
      () async {
    adapter.payload = {'data': orderJson()};
    final fields = {
      'product_id': 'product-1',
      'quantity': 2,
      'expected_version': 2,
      'expected_unit_price': 75000,
      'pin': '000000',
      'idempotency_key': 'same-key',
      'acknowledged': true
    };
    final o = await repo.buy(fields);
    expect(o.total, 150000);
    expect(adapter.request!.data, fields);
    expect(() => marketOrderFromJson({...orderJson(), 'status': 'pending'}),
        throwsA(isA<FinanceDataException>()));
  });
  test('lookup404 means absent while lookup500 remains unknown', () async {
    adapter.status = 404;
    adapter.payload = {'message': 'Not found'};
    expect(await repo.orderByKey('same-key'), null);
    adapter.status = 500;
    expect(repo.orderByKey('same-key'), throwsA(isA<ServerException>()));
  });
  test('definitive error uses field message and auth error remains distinct',
      () async {
    adapter.status = 422;
    adapter.payload = {
      'message': 'The given data was invalid.',
      'errors': {
        'quantity': ['Stok tidak cukup.']
      }
    };
    await expectLater(
        repo.buy({}),
        throwsA(isA<MarketRejected>()
            .having((e) => e.message, 'message', 'Stok tidak cukup.')));
    adapter.status = 401;
    await expectLater(
        repo.buy({}), throwsA(isA<FinanceAuthenticationException>()));
  });
  test('photo multipart uses bytes type retain expiry and response asset id',
      () async {
    adapter.payload = {
      'data': {'id': 'asset-id'}
    };
    expect(
        await repo.uploadImage(MarketImage(
            Uint8List.fromList([1, 2, 3]), 'foto.png', 'image/png')),
        'asset-id');
    final form = adapter.request!.data as FormData;
    expect(Map.fromEntries(form.fields)['type'], 'marketplace-product');
    expect(form.files.single.value.filename, 'foto.png');
    expect(form.files.single.value.length, 3);
  });
  test('price float unsafe integer and malformed final totals rejected', () {
    expect(() => marketProductFromJson({...productJson(), 'price': 75.5}),
        throwsA(isA<FinanceDataException>()));
    expect(() => marketOrderFromJson({...orderJson(), 'total': 149999}),
        throwsA(isA<FinanceDataException>()));
    expect(
        () => marketProductFromJson(
            {...productJson(), 'price': 9007199254740992}),
        throwsA(isA<FinanceDataException>()));
  });
}
