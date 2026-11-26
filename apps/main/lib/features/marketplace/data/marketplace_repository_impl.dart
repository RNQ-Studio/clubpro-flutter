import '../../finance/data/finance_models.dart';
import '../domain/marketplace.dart';
import '../domain/marketplace_repository.dart';
import 'marketplace_models.dart';
import 'marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  const MarketplaceRepositoryImpl(this.remote);
  final MarketplaceRemoteDataSource remote;
  MarketPage<T> _page<T>(
          Map<String, dynamic> j, T Function(Map<String, dynamic>) parse) =>
      MarketPage([for (final x in financeList(j['items'])) parse(x)],
          page: money(j['current_page']) < 1 ? 1 : money(j['current_page']),
          lastPage: money(j['last_page']) < 1 ? 1 : money(j['last_page']),
          total: money(j['total']),
          activeCount: money(j['active_count']),
          maxActive: money(j['max_active']) < 1 ? 5 : money(j['max_active']));
  @override
  Future<MarketPage<MarketProduct>> products(
          {String? communityId,
          String? sellerId,
          String search = '',
          int page = 1,
          bool mine = false}) async =>
      _page(
          await remote.request(
              mine ? 'marketplace/products' : 'public/products',
              query: {
                if (communityId != null) 'community_id': communityId,
                if (sellerId != null) 'seller_identity_id': sellerId,
                'search': search,
                'page': page
              }),
          marketProductFromJson);
  @override
  Future<MarketProduct> product(String id) async =>
      marketProductFromJson(await remote.request('public/products/$id'));
  @override
  Future<MarketProduct> ownProduct(String id) async =>
      marketProductFromJson(await remote.request('marketplace/products/$id'));
  @override
  Future<MarketProduct> saveProduct(Map<String, Object?> fields,
          {String? id}) async =>
      marketProductFromJson(await remote.request(
          'marketplace/products${id == null ? '' : '/$id'}',
          method: id == null ? 'POST' : 'PUT',
          data: fields));
  @override
  Future<String> uploadImage(MarketImage image) => remote.upload(image);
  @override
  Future<MarketQuote> quote(String productId, int quantity) async =>
      marketQuoteFromJson(await remote.request('marketplace/quote',
          method: 'POST',
          data: {'product_id': productId, 'quantity': quantity}));
  @override
  Future<MarketOrder> buy(Map<String, Object?> fields) async =>
      marketOrderFromJson(await remote.request('marketplace/orders',
          method: 'POST', data: fields));
  @override
  Future<MarketOrder?> orderByKey(String key) async {
    final j = await remote.request(
        'marketplace/orders/by-key/${Uri.encodeComponent(key)}',
        nullable404: true);
    return j.isEmpty ? null : marketOrderFromJson(j);
  }

  @override
  Future<MarketPage<MarketOrder>> orders(
          {String direction = 'purchases', int page = 1}) async =>
      _page(
          await remote.request('marketplace/orders',
              query: {'direction': direction, 'page': page}),
          marketOrderFromJson);
  @override
  Future<MarketOrder> order(String id) async =>
      marketOrderFromJson(await remote.request('marketplace/orders/$id'));
}
