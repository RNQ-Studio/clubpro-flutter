import '../../finance/data/finance_models.dart';
import '../../finance/domain/finance.dart';
import '../domain/marketplace.dart';

MarketProduct marketProductFromJson(Map<String, dynamic> j) {
  final s = financeMap(j['seller']), c = financeMap(j['community']);
  final price = requiredMoney(j['price']),
      stock = requiredMoney(j['stock']),
      version = requiredMoney(j['version']);
  if (price < 1 || stock < 0 || version < 1 || textOf(j['id']).isEmpty) {
    throw const FinanceDataException();
  }
  return MarketProduct(
      id: textOf(j['id']),
      name: textOf(j['name']),
      description: textOf(j['description']),
      price: price,
      stock: stock,
      version: version,
      sellerId: textOf(s['identity_id']),
      sellerName: textOf(s['name']),
      communityId: textOf(c['id']),
      communityName: textOf(c['name']),
      photoAssetId: j['photo_asset_id']?.toString(),
      photoUrl: j['photo_url']?.toString(),
      active: j['is_active'] == true,
      canBuy: j['can_buy'] == true,
      unavailableReason: textOf(j['unavailable_reason']));
}

MarketQuote marketQuoteFromJson(Map<String, dynamic> j) {
  final p = marketProductFromJson(financeMap(j['product'])),
      q = requiredMoney(j['quantity']),
      unit = requiredMoney(j['unit_price']),
      total = requiredMoney(j['total']),
      balance = requiredMoney(j['available_balance']),
      version = requiredMoney(j['product_version']);
  if (q < 1 ||
      unit < 1 ||
      q * unit != total ||
      balance < 0 ||
      j['no_refund'] != true ||
      version < 1) {
    throw const FinanceDataException();
  }
  return MarketQuote(
      product: p,
      quantity: q,
      unitPrice: unit,
      total: total,
      version: version,
      balance: balance);
}

MarketOrder marketOrderFromJson(Map<String, dynamic> j) {
  final snap = financeMap(j['snapshot']), p = financeMap(snap['product']);
  final q = requiredMoney(j['quantity']),
      unit = requiredMoney(j['unit_price']),
      total = requiredMoney(j['total']);
  if (q < 1 ||
      unit < 1 ||
      total != q * unit ||
      j['status'] != 'succeeded' ||
      j['no_refund'] != true ||
      textOf(j['id']).isEmpty) {
    throw const FinanceDataException();
  }
  return MarketOrder(
      id: textOf(j['id']),
      productId: textOf(j['product_id']),
      name: textOf(p['name']),
      description: textOf(p['description']),
      quantity: q,
      unitPrice: unit,
      total: total,
      sellerName: textOf(financeMap(snap['seller'])['name']),
      buyerName: textOf(financeMap(snap['buyer'])['name']),
      communityName: textOf(financeMap(snap['community'])['name']),
      createdAt: textOf(j['created_at']),
      photoUrl: p['photo_url']?.toString(),
      key: j['idempotency_key']?.toString());
}
