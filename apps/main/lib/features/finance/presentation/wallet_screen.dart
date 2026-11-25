import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key, this.scope = 'identity', this.communityId});
  final String scope;
  final String? communityId;
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _direction = '';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final summaryProvider = widget.scope == 'identity'
        ? walletSummaryProvider
        : fundSummaryProvider(widget.scope, widget.communityId);
    final summary = ref.watch(summaryProvider);
    final p = walletTransactionsProvider(
        scope: widget.scope,
        communityId: widget.communityId,
        direction: _direction,
        page: _page);
    final history = ref.watch(p);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.scope == 'platform'
                ? 'Pendapatan platform'
                : widget.scope == 'community'
                    ? 'Dana komunitas'
                    : 'Saldo & riwayat'),
            actions: [
              IconButton(
                  tooltip: 'Segarkan saldo',
                  onPressed: () => invalidateFinance(ref.invalidate),
                  icon: const Icon(Icons.refresh)),
            ]),
        body: FinanceBody(children: [
          summary.when(
              data: (w) => WalletBalanceCard(
                  wallet: w,
                  personal: widget.scope == 'identity',
                  title: widget.scope == 'platform'
                      ? 'Pendapatan iuran aplikasi'
                      : widget.scope == 'community'
                          ? 'Saldo komunitas'
                          : 'Saldo uang digital'),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => FinanceError(
                  error: e, retry: () => ref.invalidate(summaryProvider))),
          if (widget.scope == 'identity')
            Wrap(spacing: 10, runSpacing: 10, children: [
              FilledButton.icon(
                  key: const Key('wallet-topup'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  onPressed: () => context.push(AppRoutes.topup),
                  icon: const Icon(Icons.add),
                  label: const Text('Top up')),
              OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.paymentReceipts),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Riwayat pengajuan')),
            ]),
          TextButton.icon(
              onPressed: () => context.push(AppRoutes.billingNotices),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Pengingat pembayaran')),
          const SizedBox(height: 24),
          Text('Riwayat transaksi',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                    initialValue: _direction,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Arus dana'),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Semua arus')),
                      DropdownMenuItem(value: 'in', child: Text('Masuk')),
                      DropdownMenuItem(value: 'out', child: Text('Keluar')),
                    ],
                    onChanged: (v) => setState(() {
                          _direction = v ?? '';
                          _page = 1;
                        }))),
          ]),
          const SizedBox(height: 12),
          history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (data) => Column(children: [
                    if (data.items.isEmpty)
                      const FinanceMessage(
                          'Belum ada transaksi pada filter ini.'),
                    for (final item in data.items)
                      Card(
                          child: InkWell(
                              onTap: () => context.push(
                                  '${AppRoutes.walletTransaction(item.id)}?scope=${widget.scope}${widget.communityId == null ? '' : '&community=${widget.communityId}'}'),
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  operationLabel(item.kind),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                          const Icon(Icons.chevron_right)
                                        ]),
                                        const SizedBox(height: 8),
                                        Text(
                                            '${item.amount > 0 ? '+' : ''}${formatRupiah(item.amount)}',
                                            style: TextStyle(
                                                color: item.amount > 0
                                                    ? Colors.green.shade700
                                                    : null,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Text(financeDate(item.createdAt)),
                                        Text(item.reference.isEmpty
                                            ? item.id
                                            : item.reference),
                                      ])))),
                    FinancePager(
                        page: data.page,
                        lastPage: data.lastPage,
                        onPage: (v) => setState(() => _page = v)),
                  ])),
        ]));
  }
}

class WalletTransactionScreen extends ConsumerWidget {
  const WalletTransactionScreen(
      {super.key, required this.id, this.scope = 'identity', this.communityId});
  final String scope;
  final String? communityId;
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p =
        walletTransactionProvider(id, scope: scope, communityId: communityId);
    return Scaffold(
        appBar: AppBar(title: const Text('Detail transaksi')),
        body: ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (t) => FinanceBody(children: [
                FinanceSection(
                    title: operationLabel(t.kind),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(formatRupiah(t.amount),
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 16),
                          SelectableText('ID: ${t.id}'),
                          Text('Tanggal: ${financeDate(t.createdAt)}'),
                          Text('Referensi: ${t.reference}'),
                          Text('Pelaku: ${t.actor}'),
                          if (t.communityName.isNotEmpty)
                            Text('Konteks komunitas: ${t.communityName}'),
                          const SizedBox(height: 16),
                          const Text('Mutasi akun Anda',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          for (final p in t.postings)
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(p.account),
                                trailing: Text(formatRupiah(p.amount))),
                          const Text(
                              'Transaksi final tidak menyediakan refund. Koreksi teknis tercatat sebagai transaksi terpisah.'),
                        ]))
              ]),
            ));
  }
}
