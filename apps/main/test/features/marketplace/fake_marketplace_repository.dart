import 'dart:async';
import 'package:app_main/features/marketplace/domain/marketplace.dart';
import 'package:app_main/features/marketplace/domain/marketplace_repository.dart';
import 'package:core/core.dart';

const marketProductFixture = MarketProduct(
    id: 'product-1',
    name: 'Raket komunitas pilihan',
    description: 'Raket layak pakai untuk latihan rutin bersama komunitas.',
    price: 75000,
    stock: 3,
    version: 2,
    sellerId: '2',
    sellerName: 'Penjual Fixture',
    communityId: '2',
    communityName: 'Komunitas Penjual');
MarketOrder marketOrderFixture({String key = 'order-key'}) => MarketOrder(
    id: 'order-1',
    productId: 'product-1',
    name: marketProductFixture.name,
    description: marketProductFixture.description,
    quantity: 1,
    unitPrice: 75000,
    total: 75000,
    sellerName: 'Penjual Fixture',
    buyerName: 'Akun Uji',
    communityName: 'Komunitas Penjual',
    createdAt: '2026-11-26T00:00:00Z',
    key: key);

class MarketStorage implements StorageService {
  final values = <String, String>{};
  bool failWrite = false, failRead = false;
  @override
  Future<void> init() async {}
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('read unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('storage unavailable');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

class FakeMarketplace implements MarketplaceRepository {
  MarketProduct value = marketProductFixture;
  MarketOrder? completed;
  Object? loadError, buyError, saveError, uploadError;
  Completer<void>? gate, buyGate;
  bool empty = false, commitThenTimeout = false;
  int buyCalls = 0, lookupCalls = 0, uploadCalls = 0, saveCalls = 0;
  final requests = <Map<String, Object?>>[];
  final queries = <Map<String, Object?>>[];
  @override
  Future<MarketPage<MarketProduct>> products(
      {String? communityId,
      String? sellerId,
      String search = '',
      int page = 1,
      bool mine = false}) async {
    await gate?.future;
    if (loadError != null) throw loadError!;
    queries.add({
      'community': communityId,
      'seller': sellerId,
      'search': search,
      'page': page,
      'mine': mine
    });
    return MarketPage(empty ? [] : [value],
        page: page,
        lastPage: 2,
        activeCount: value.active ? 1 : 0,
        total: empty ? 0 : 1);
  }

  @override
  Future<MarketProduct> product(String id) async {
    if (loadError != null) throw loadError!;
    return value;
  }

  @override
  Future<MarketProduct> ownProduct(String id) => product(id);
  @override
  Future<MarketProduct> saveProduct(Map<String, Object?> fields,
      {String? id}) async {
    saveCalls++;
    requests.add(Map.of(fields));
    if (saveError != null) throw saveError!;
    return value;
  }

  @override
  Future<String> uploadImage(MarketImage image) async {
    uploadCalls++;
    if (uploadError != null) throw uploadError!;
    return 'asset-new';
  }

  @override
  Future<MarketQuote> quote(String productId, int quantity) async {
    if (loadError != null) throw loadError!;
    return MarketQuote(
        product: value,
        quantity: quantity,
        unitPrice: value.price,
        total: value.price * quantity,
        version: value.version,
        balance: 9000000000000);
  }

  @override
  Future<MarketOrder> buy(Map<String, Object?> fields) async {
    buyCalls++;
    requests.add(Map.of(fields));
    await buyGate?.future;
    if (buyError != null) throw buyError!;
    completed = marketOrderFixture(key: '${fields['idempotency_key']}');
    if (commitThenTimeout) {
      commitThenTimeout = false;
      throw const NetworkException('Hasil belum pasti.');
    }
    return completed!;
  }

  @override
  Future<MarketOrder?> orderByKey(String key) async {
    lookupCalls++;
    return completed;
  }

  @override
  Future<MarketPage<MarketOrder>> orders(
          {String direction = 'purchases', int page = 1}) async =>
      MarketPage(empty ? [] : [completed ?? marketOrderFixture()],
          page: page, lastPage: 1);
  @override
  Future<MarketOrder> order(String id) async =>
      completed ?? marketOrderFixture();
}
