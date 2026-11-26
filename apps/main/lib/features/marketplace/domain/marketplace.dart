import 'dart:typed_data';

class MarketPage<T> {
  const MarketPage(this.items,
      {this.page = 1,
      this.lastPage = 1,
      this.total = 0,
      this.activeCount = 0,
      this.maxActive = 5});
  final List<T> items;
  final int page, lastPage, total, activeCount, maxActive;
}

class MarketProduct {
  const MarketProduct(
      {required this.id,
      required this.name,
      required this.description,
      required this.price,
      required this.stock,
      required this.version,
      required this.sellerId,
      required this.sellerName,
      required this.communityId,
      required this.communityName,
      this.photoAssetId,
      this.photoUrl,
      this.active = true,
      this.canBuy = true,
      this.unavailableReason = ''});
  final String id,
      name,
      description,
      sellerId,
      sellerName,
      communityId,
      communityName,
      unavailableReason;
  final String? photoAssetId, photoUrl;
  final int price, stock, version;
  final bool active, canBuy;
}

class MarketQuote {
  const MarketQuote(
      {required this.product,
      required this.quantity,
      required this.unitPrice,
      required this.total,
      required this.version,
      required this.balance});
  final MarketProduct product;
  final int quantity, unitPrice, total, version, balance;
}

class MarketOrder {
  const MarketOrder(
      {required this.id,
      required this.productId,
      required this.name,
      required this.description,
      required this.quantity,
      required this.unitPrice,
      required this.total,
      required this.sellerName,
      required this.buyerName,
      required this.communityName,
      required this.createdAt,
      this.photoUrl,
      this.key,
      this.status = 'succeeded'});
  final String id,
      productId,
      name,
      description,
      sellerName,
      buyerName,
      communityName,
      createdAt,
      status;
  final String? photoUrl, key;
  final int quantity, unitPrice, total;
}

class MarketImage {
  const MarketImage(this.bytes, this.name, this.mime);
  final Uint8List bytes;
  final String name, mime;
}

/// A definitive response rejects this attempt before finalization. An earlier
/// ambiguous attempt still requires lookup/replay using its original key.
class MarketRejected implements Exception {
  const MarketRejected(this.message);
  final String message;
  @override
  String toString() => message;
}
