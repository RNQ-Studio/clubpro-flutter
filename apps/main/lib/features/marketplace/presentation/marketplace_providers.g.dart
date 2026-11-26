// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'marketplace_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(marketplaceRepository)
final marketplaceRepositoryProvider = MarketplaceRepositoryProvider._();

final class MarketplaceRepositoryProvider extends $FunctionalProvider<
    MarketplaceRepository,
    MarketplaceRepository,
    MarketplaceRepository> with $Provider<MarketplaceRepository> {
  MarketplaceRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'marketplaceRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketplaceRepositoryHash();

  @$internal
  @override
  $ProviderElement<MarketplaceRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarketplaceRepository create(Ref ref) {
    return marketplaceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarketplaceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarketplaceRepository>(value),
    );
  }
}

String _$marketplaceRepositoryHash() =>
    r'37688d36a65fed6c4f5c3512755ed72a67416d75';

@ProviderFor(marketProducts)
final marketProductsProvider = MarketProductsFamily._();

final class MarketProductsProvider extends $FunctionalProvider<
        AsyncValue<MarketPage<MarketProduct>>,
        MarketPage<MarketProduct>,
        FutureOr<MarketPage<MarketProduct>>>
    with
        $FutureModifier<MarketPage<MarketProduct>>,
        $FutureProvider<MarketPage<MarketProduct>> {
  MarketProductsProvider._(
      {required MarketProductsFamily super.from,
      required ({
        String? communityId,
        String? sellerId,
        String search,
        int page,
        bool mine,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'marketProductsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketProductsHash();

  @override
  String toString() {
    return r'marketProductsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MarketPage<MarketProduct>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarketPage<MarketProduct>> create(Ref ref) {
    final argument = this.argument as ({
      String? communityId,
      String? sellerId,
      String search,
      int page,
      bool mine,
    });
    return marketProducts(
      ref,
      communityId: argument.communityId,
      sellerId: argument.sellerId,
      search: argument.search,
      page: argument.page,
      mine: argument.mine,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketProductsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketProductsHash() => r'47bcff9d5f5a31681b1e6a36ffafb331572c54be';

final class MarketProductsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MarketPage<MarketProduct>>,
            ({
              String? communityId,
              String? sellerId,
              String search,
              int page,
              bool mine,
            })> {
  MarketProductsFamily._()
      : super(
          retry: _noRetry,
          name: r'marketProductsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MarketProductsProvider call({
    String? communityId,
    String? sellerId,
    String search = '',
    int page = 1,
    bool mine = false,
  }) =>
      MarketProductsProvider._(argument: (
        communityId: communityId,
        sellerId: sellerId,
        search: search,
        page: page,
        mine: mine,
      ), from: this);

  @override
  String toString() => r'marketProductsProvider';
}

@ProviderFor(marketProduct)
final marketProductProvider = MarketProductFamily._();

final class MarketProductProvider extends $FunctionalProvider<
        AsyncValue<MarketProduct>, MarketProduct, FutureOr<MarketProduct>>
    with $FutureModifier<MarketProduct>, $FutureProvider<MarketProduct> {
  MarketProductProvider._(
      {required MarketProductFamily super.from, required String super.argument})
      : super(
          retry: _noRetry,
          name: r'marketProductProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketProductHash();

  @override
  String toString() {
    return r'marketProductProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MarketProduct> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarketProduct> create(Ref ref) {
    final argument = this.argument as String;
    return marketProduct(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketProductProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketProductHash() => r'1669e9fd44940b33919dc701efdcf5301a684d57';

final class MarketProductFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MarketProduct>, String> {
  MarketProductFamily._()
      : super(
          retry: _noRetry,
          name: r'marketProductProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MarketProductProvider call(
    String id,
  ) =>
      MarketProductProvider._(argument: id, from: this);

  @override
  String toString() => r'marketProductProvider';
}

@ProviderFor(marketOrders)
final marketOrdersProvider = MarketOrdersFamily._();

final class MarketOrdersProvider extends $FunctionalProvider<
        AsyncValue<MarketPage<MarketOrder>>,
        MarketPage<MarketOrder>,
        FutureOr<MarketPage<MarketOrder>>>
    with
        $FutureModifier<MarketPage<MarketOrder>>,
        $FutureProvider<MarketPage<MarketOrder>> {
  MarketOrdersProvider._(
      {required MarketOrdersFamily super.from,
      required ({
        String direction,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'marketOrdersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketOrdersHash();

  @override
  String toString() {
    return r'marketOrdersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MarketPage<MarketOrder>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarketPage<MarketOrder>> create(Ref ref) {
    final argument = this.argument as ({
      String direction,
      int page,
    });
    return marketOrders(
      ref,
      direction: argument.direction,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketOrdersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketOrdersHash() => r'66b283710109dc29ab2520ac3a72dba3f9e2c5e4';

final class MarketOrdersFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MarketPage<MarketOrder>>,
            ({
              String direction,
              int page,
            })> {
  MarketOrdersFamily._()
      : super(
          retry: _noRetry,
          name: r'marketOrdersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MarketOrdersProvider call({
    String direction = 'purchases',
    int page = 1,
  }) =>
      MarketOrdersProvider._(argument: (
        direction: direction,
        page: page,
      ), from: this);

  @override
  String toString() => r'marketOrdersProvider';
}

@ProviderFor(marketOrder)
final marketOrderProvider = MarketOrderFamily._();

final class MarketOrderProvider extends $FunctionalProvider<
        AsyncValue<MarketOrder>, MarketOrder, FutureOr<MarketOrder>>
    with $FutureModifier<MarketOrder>, $FutureProvider<MarketOrder> {
  MarketOrderProvider._(
      {required MarketOrderFamily super.from, required String super.argument})
      : super(
          retry: _noRetry,
          name: r'marketOrderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$marketOrderHash();

  @override
  String toString() {
    return r'marketOrderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MarketOrder> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MarketOrder> create(Ref ref) {
    final argument = this.argument as String;
    return marketOrder(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MarketOrderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$marketOrderHash() => r'eb5509e13755139ebf070902c83f1a23d960a8df';

final class MarketOrderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MarketOrder>, String> {
  MarketOrderFamily._()
      : super(
          retry: _noRetry,
          name: r'marketOrderProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MarketOrderProvider call(
    String id,
  ) =>
      MarketOrderProvider._(argument: id, from: this);

  @override
  String toString() => r'marketOrderProvider';
}
