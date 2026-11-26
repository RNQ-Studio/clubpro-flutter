import 'dart:async';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'marketplace_providers.dart';
import 'marketplace_widgets.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen(
      {super.key, this.communityId, this.sellerId, this.mine = false});
  final String? communityId, sellerId;
  final bool mine;
  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  String _search = '';
  int _page = 1;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = marketProductsProvider(
        communityId: widget.communityId,
        sellerId: widget.sellerId,
        search: _search,
        page: _page,
        mine: widget.mine);
    final auth = ref.watch(authProvider);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.mine
                ? 'Lapak saya'
                : widget.sellerId != null
                    ? 'Profil & lapak penjual'
                    : widget.communityId != null
                        ? 'Jualan komunitas'
                        : 'Marketplace'),
            actions: [
              IconButton(
                  tooltip: 'Segarkan',
                  onPressed: () => ref.invalidate(provider),
                  icon: const Icon(Icons.refresh))
            ]),
        body: FinanceBody(children: [
          Text(
              widget.mine
                  ? 'Maksimal lima barang aktif di seluruh komunitas'
                  : 'Temukan barang dari anggota komunitas',
              style: Theme.of(context).textTheme.headlineSmall),
          if (auth is AuthAuthenticated)
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (!widget.mine)
                OutlinedButton(
                    onPressed: () => context.push(AppRoutes.myMarketProducts),
                    child: const Text('Lapak saya')),
              OutlinedButton(
                  onPressed: () => context.push(AppRoutes.marketOrders),
                  child: const Text('Riwayat transaksi')),
              if (widget.mine)
                FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.newMarketProduct),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah barang'))
            ]),
          const SizedBox(height: 16),
          TextField(
              key: const Key('market-search'),
              decoration: const InputDecoration(
                  labelText: 'Cari nama atau deskripsi barang',
                  prefixIcon: Icon(Icons.search)),
              onChanged: (v) {
                _timer?.cancel();
                _timer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _search = v.trim();
                      _page = 1;
                    });
                  }
                });
              }),
          const SizedBox(height: 16),
          ref.watch(provider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => MarketFailure(
                  error: e, retry: () => ref.invalidate(provider)),
              data: (page) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.mine)
                          FinanceMessage(
                              '${page.activeCount} / ${page.maxActive} barang aktif. Menonaktifkan satu barang membuka kuota.'),
                        if (widget.sellerId != null && page.items.isNotEmpty)
                          FinanceSection(
                              title: page.items.first.sellerName,
                              child: Text(
                                  'Penjual anggota ${page.items.first.communityName}. Data pribadi dan keuangan tidak ditampilkan.')),
                        if (page.items.isEmpty)
                          const FinanceMessage(
                              'Belum ada barang yang sesuai. Coba pencarian lain atau segarkan katalog.'),
                        for (final p in page.items)
                          MarketProductCard(
                              key: Key('product-${p.id}'),
                              product: p,
                              edit: widget.mine),
                        FinancePager(
                            page: page.page,
                            lastPage: page.lastPage,
                            onPage: (v) => setState(() => _page = v))
                      ]))
        ]));
  }
}
