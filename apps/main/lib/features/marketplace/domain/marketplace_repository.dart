import 'marketplace.dart';

abstract class MarketplaceRepository {
  Future<MarketPage<MarketProduct>> products(
      {String? communityId,
      String? sellerId,
      String search = '',
      int page = 1,
      bool mine = false});
  Future<MarketProduct> product(String id);
  Future<MarketProduct> ownProduct(String id);
  Future<MarketProduct> saveProduct(Map<String, Object?> fields, {String? id});
  Future<String> uploadImage(MarketImage image);
  Future<MarketQuote> quote(String productId, int quantity);
  Future<MarketOrder> buy(Map<String, Object?> fields);
  Future<MarketOrder?> orderByKey(String key);
  Future<MarketPage<MarketOrder>> orders(
      {String direction = 'purchases', int page = 1});
  Future<MarketOrder> order(String id);
}
