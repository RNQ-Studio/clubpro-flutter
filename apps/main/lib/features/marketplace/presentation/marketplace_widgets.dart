import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../community/domain/entities/community_draft.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/marketplace.dart';

String marketError(Object e) => e is MarketRejected
    ? e.message
    : e is CommunityImageException
        ? e.message
        : financeErrorMessage(e);

class MarketFailure extends StatelessWidget {
  const MarketFailure({super.key, required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => FinanceError(
      error: error is MarketRejected
          ? ServerException((error as MarketRejected).message)
          : error,
      retry: retry);
}

class MarketPhoto extends StatelessWidget {
  const MarketPhoto({super.key, this.url, this.height = 180});
  final String? url;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
          height: height,
          width: double.infinity,
          child: url == null || url!.isEmpty
              ? _placeholder()
              : Image.network(url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => _placeholder(),
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : const Center(child: CircularProgressIndicator()))));
  Widget _placeholder() => const ColoredBox(
      color: Color(0xffedf1ef),
      child: Center(
          child: Icon(Icons.inventory_2_outlined,
              size: 42, semanticLabel: 'Foto produk belum tersedia')));
}

class MarketProductCard extends StatelessWidget {
  const MarketProductCard(
      {super.key, required this.product, this.edit = false});
  final MarketProduct product;
  final bool edit;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
          onTap: () => context.push(
              edit
                  ? AppRoutes.editMarketProduct(product.id)
                  : AppRoutes.marketProduct(product.id),
              extra: edit ? product : null),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MarketPhoto(url: product.photoUrl),
                    const SizedBox(height: 12),
                    Text(product.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(formatRupiah(product.price),
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('${product.sellerName} · ${product.communityName}'),
                    Text(
                        '${product.active ? 'Aktif' : 'Nonaktif'} · Stok ${product.stock}'),
                    if (!product.canBuy && product.unavailableReason.isNotEmpty)
                      Text(product.unavailableReason.isEmpty
                          ? 'Belum dapat dibeli'
                          : product.unavailableReason),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Text(edit ? 'Kelola produk' : 'Lihat produk',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary)))
                  ]))));
}

class MarketplaceEntry extends StatelessWidget {
  const MarketplaceEntry(
      {super.key, this.communityId, this.sellerId, this.mine = false});
  final String? communityId, sellerId;
  final bool mine;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          key: Key(mine
              ? 'market-entry-mine'
              : communityId != null
                  ? 'market-entry-community'
                  : sellerId != null
                      ? 'market-entry-seller'
                      : 'market-entry-main'),
          leading: const Icon(Icons.storefront_outlined),
          title: Text(mine
              ? 'Lapak saya'
              : sellerId != null
                  ? 'Lapak anggota'
                  : communityId != null
                      ? 'Jualan anggota komunitas'
                      : 'Marketplace semua komunitas'),
          subtitle: Text(mine
              ? 'Kelola maksimal lima barang aktif'
              : 'Cari barang dan bayar dengan saldo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(mine
              ? AppRoutes.myMarketProducts
              : AppRoutes.marketCatalogue(
                  communityId: communityId, sellerId: sellerId))));
}

class MarketOrderBody extends StatelessWidget {
  const MarketOrderBody({super.key, required this.order});
  final MarketOrder order;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
        Text('Pembelian berhasil',
            style: Theme.of(context).textTheme.headlineSmall),
        SelectableText('Referensi: ${order.id}'),
        Text(financeDate(order.createdAt)),
        const SizedBox(height: 16),
        MarketPhoto(url: order.photoUrl),
        Text(order.name, style: Theme.of(context).textTheme.titleLarge),
        Text(order.description),
        Text('Penjual: ${order.sellerName}'),
        Text('Pembeli: ${order.buyerName}'),
        Text('Komunitas asal: ${order.communityName}'),
        Text('${order.quantity} × ${formatRupiah(order.unitPrice)}'),
        Text('Total ${formatRupiah(order.total)}',
            style: Theme.of(context).textTheme.titleLarge),
        const FinanceMessage(
            'Pembayaran final telah dikonfirmasi. Tidak tersedia refund untuk pembelian yang sah.'),
        OutlinedButton(
            onPressed: () => context.push(AppRoutes.marketOrders),
            child: const Text('Riwayat pembelian & penjualan'))
      ]);
}
