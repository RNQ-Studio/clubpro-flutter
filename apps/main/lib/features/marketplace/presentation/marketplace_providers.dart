import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/marketplace.dart';
import '../domain/marketplace_repository.dart';
import '../data/marketplace_repository_impl.dart';
import '../data/marketplace_remote_data_source.dart';
part 'marketplace_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;
@Riverpod(keepAlive: true)
MarketplaceRepository marketplaceRepository(Ref ref) =>
    MarketplaceRepositoryImpl(
        MarketplaceRemoteDataSource(ref.watch(apiClientProvider).dio));
@Riverpod(retry: _noRetry)
Future<MarketPage<MarketProduct>> marketProducts(Ref ref,
        {String? communityId,
        String? sellerId,
        String search = '',
        int page = 1,
        bool mine = false}) =>
    ref.watch(marketplaceRepositoryProvider).products(
        communityId: communityId,
        sellerId: sellerId,
        search: search,
        page: page,
        mine: mine);
@Riverpod(retry: _noRetry)
Future<MarketProduct> marketProduct(Ref ref, String id) =>
    ref.watch(marketplaceRepositoryProvider).product(id);
@Riverpod(retry: _noRetry)
Future<MarketPage<MarketOrder>> marketOrders(Ref ref,
        {String direction = 'purchases', int page = 1}) =>
    ref
        .watch(marketplaceRepositoryProvider)
        .orders(direction: direction, page: page);
@Riverpod(retry: _noRetry)
Future<MarketOrder> marketOrder(Ref ref, String id) =>
    ref.watch(marketplaceRepositoryProvider).order(id);
void invalidateMarketplace(void Function(ProviderOrFamily) invalidate) {
  invalidate(marketProductsProvider);
  invalidate(marketProductProvider);
  invalidate(marketOrdersProvider);
  invalidate(marketOrderProvider);
}
