import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'marketplace_providers.dart';
import 'marketplace_widgets.dart';

class MarketOrdersScreen extends ConsumerStatefulWidget {
  const MarketOrdersScreen({super.key});
  @override
  ConsumerState<MarketOrdersScreen> createState() => _MarketOrdersScreenState();
}

class _MarketOrdersScreenState extends ConsumerState<MarketOrdersScreen> {
  String _direction = 'purchases';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final provider = marketOrdersProvider(direction: _direction, page: _page);
    return Scaffold(
        appBar: AppBar(title: const Text('Transaksi marketplace'), actions: [
          IconButton(
              onPressed: () => ref.invalidate(provider),
              tooltip: 'Segarkan',
              icon: const Icon(Icons.refresh))
        ]),
        body: FinanceBody(children: [
          SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'purchases', label: Text('Pembelian')),
                ButtonSegment(value: 'sales', label: Text('Penjualan'))
              ],
              selected: {
                _direction
              },
              onSelectionChanged: (v) => setState(() {
                    _direction = v.first;
                    _page = 1;
                  })),
          const SizedBox(height: 16),
          ref.watch(provider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => MarketFailure(
                  error: e, retry: () => ref.invalidate(provider)),
              data: (page) => Column(children: [
                    if (page.items.isEmpty)
                      const FinanceMessage('Belum ada transaksi.'),
                    for (final o in page.items)
                      Card(
                          child: ListTile(
                              key: Key('order-${o.id}'),
                              title: Text(o.name),
                              subtitle: Text(
                                  '${o.quantity} barang · ${formatRupiah(o.total)}\n${financeDate(o.createdAt)} · Berhasil'),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push(AppRoutes.marketOrder(o.id)))),
                    FinancePager(
                        page: page.page,
                        lastPage: page.lastPage,
                        onPage: (v) => setState(() => _page = v))
                  ]))
        ]));
  }
}

class MarketOrderScreen extends ConsumerWidget {
  const MarketOrderScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = marketOrderProvider(id);
    return Scaffold(
        appBar: AppBar(title: const Text('Detail transaksi')),
        body: ref.watch(provider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                MarketFailure(error: e, retry: () => ref.invalidate(provider)),
            data: (order) =>
                FinanceBody(children: [MarketOrderBody(order: order)])));
  }
}
