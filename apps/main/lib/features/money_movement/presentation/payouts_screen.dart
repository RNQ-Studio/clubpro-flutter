import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/money_movement.dart';
import 'money_movement_providers.dart';

class PayoutsScreen extends ConsumerStatefulWidget {
  const PayoutsScreen({super.key, this.communityId, this.manage = false});
  final String? communityId;
  final bool manage;
  @override
  ConsumerState<PayoutsScreen> createState() => _PayoutsScreenState();
}

class _PayoutsScreenState extends ConsumerState<PayoutsScreen> {
  String _status = '', _query = '';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final p = payoutsProvider(
        communityId: widget.communityId,
        manage: widget.manage,
        status: _status,
        query: _query,
        page: _page);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.manage ? 'Kelola pencairan' : 'Pencairan saya'),
            actions: [
              IconButton(
                  tooltip: 'Segarkan pencairan',
                  onPressed: () => invalidateMovements(ref.invalidate),
                  icon: const Icon(Icons.refresh))
            ]),
        body: FinanceBody(children: [
          if (!widget.manage)
            FilledButton.icon(
                onPressed: () => context.push(AppRoutes.newPayout),
                icon: const Icon(Icons.account_balance_outlined),
                label: const Text('Ajukan pencairan')),
          if (widget.manage)
            FinanceMessage(widget.communityId == null
                ? 'Daftar hanya memuat bagian sumber platform yang menjadi kewenangan super-admin.'
                : 'Daftar hanya memuat bagian permintaan yang ditugaskan kepada komunitas Anda. Nominal komunitas lain tidak ditampilkan.'),
          if (widget.manage)
            ref
                .watch(payoutReconciliationProvider(
                    widget.communityId ?? 'platform'))
                .when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => FinanceError(
                        error: e,
                        retry: () => ref.invalidate(
                            payoutReconciliationProvider(
                                widget.communityId ?? 'platform'))),
                    data: (r) => FinanceSection(
                        title: 'Rekonsiliasi pencairan',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  r.balanced
                                      ? 'Tercatat seimbang'
                                      : 'Perlu pemeriksaan rekonsiliasi',
                                  style: TextStyle(
                                      color: r.balanced
                                          ? Colors.green.shade700
                                          : Theme.of(context)
                                              .colorScheme
                                              .error)),
                              Text('Diminta ${formatRupiah(r.requested)}'),
                              Text('Terverifikasi ${formatRupiah(r.verified)}'),
                              Text('Masih ditahan ${formatRupiah(r.held)}'),
                              Text('Dilepas ${formatRupiah(r.released)}'),
                              const Text(
                                  'Saldo virtual dan likuiditas bank berbeda. Rekonsiliasi ini berasal dari catatan aplikasi.')
                            ]))),
          const SizedBox(height: 16),
          TextField(
              key: const Key('payout-search'),
              decoration: const InputDecoration(
                  labelText: 'Cari referensi / anggota',
                  prefixIcon: Icon(Icons.search)),
              onSubmitted: (v) => setState(() {
                    _query = v.trim();
                    _page = 1;
                  })),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status pencairan'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Semua status')),
                for (final status in [
                  'requested',
                  'processing',
                  'uncertain',
                  'succeeded',
                  'failed',
                  'cancelled'
                ])
                  DropdownMenuItem(
                      value: status, child: Text(payoutStatusLabel(status)))
              ],
              onChanged: (v) => setState(() {
                    _status = v ?? '';
                    _page = 1;
                  })),
          const SizedBox(height: 16),
          ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (data) => Column(children: [
                    if (data.items.isEmpty)
                      const FinanceMessage(
                          'Belum ada pencairan pada filter ini.'),
                    for (final item in data.items)
                      Card(
                          child: InkWell(
                              key: Key('payout-${item.id}'),
                              onTap: () =>
                                  context.push(AppRoutes.payout(item.id)),
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(
                                                  '${item.reference} · ${payoutStatusLabel(item.status)}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium)),
                                          const Icon(Icons.chevron_right)
                                        ]),
                                        if (widget.manage)
                                          Text(item.memberName),
                                        const SizedBox(height: 8),
                                        Text(
                                            'Diminta ${formatRupiah(item.amount)}'),
                                        Text(
                                            'Terverifikasi ${formatRupiah(item.verified)} · ditahan ${formatRupiah(item.remaining)}'),
                                        Text(
                                            'Dilepas ${formatRupiah(item.released)}'),
                                        Text(
                                            '${item.destination.bankName} ${item.destination.maskedNumber}'),
                                        Text(financeDate(item.createdAt))
                                      ])))),
                    FinancePager(
                        page: data.page,
                        lastPage: data.lastPage,
                        onPage: (v) => setState(() => _page = v)),
                  ])),
        ]));
  }
}

class TransferHistoryScreen extends ConsumerStatefulWidget {
  const TransferHistoryScreen({super.key});
  @override
  ConsumerState<TransferHistoryScreen> createState() =>
      _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends ConsumerState<TransferHistoryScreen> {
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final p = memberTransfersProvider(page: _page);
    return Scaffold(
        appBar: AppBar(title: const Text('Riwayat transfer saldo'), actions: [
          IconButton(
              tooltip: 'Segarkan transfer',
              onPressed: () => ref.invalidate(memberTransfersProvider),
              icon: const Icon(Icons.refresh))
        ]),
        body: FinanceBody(children: [
          FilledButton.icon(
              onPressed: () => context.push(AppRoutes.newTransfer),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfer antaranggota')),
          const FinanceMessage(
              'Riwayat pengirim dan penerima berasal dari transaksi ledger yang sama. Tidak ada biaya platform tambahan.'),
          ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (page) => Column(children: [
                    if (page.items.isEmpty)
                      const FinanceMessage('Belum ada transfer saldo.'),
                    for (final t in page.items)
                      FinanceSection(
                          title:
                              '${t.direction == 'in' ? 'Masuk' : 'Keluar'} · ${formatRupiah(t.amount)}',
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Dari ${t.sender} kepada ${t.recipient}'),
                                Text('Berhasil · ${financeDate(t.createdAt)}'),
                                SelectableText('Referensi: ${t.reference}')
                              ])),
                    FinancePager(
                        page: page.page,
                        lastPage: page.lastPage,
                        onPage: (v) => setState(() => _page = v))
                  ]))
        ]));
  }
}
