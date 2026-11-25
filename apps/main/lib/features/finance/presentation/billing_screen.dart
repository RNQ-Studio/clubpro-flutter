import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/presentation/community_providers.dart';
import '../../community/presentation/active_community_notifier.dart';
import '../../dues/presentation/dues_providers.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../member_card/presentation/member_card_providers.dart';
import '../domain/finance.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen(
      {super.key,
      required this.communityId,
      this.scope = 'member',
      this.targetMemberId});
  final String communityId, scope;
  final String? targetMemberId;
  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  late String _scope = widget.scope;
  String _key = financeRequestId();
  String? _quoteSignature;
  bool _paying = false, _confirming = false;
  String? _error, _success;
  Future<void> _pay(BillingOverview overview) async {
    if (_paying || _confirming) return;
    final invoiceIds = overview.invoices
        .where((i) => i.outstanding > 0)
        .map((i) => i.id)
        .toList();
    final expectedAmount = overview.outstanding;
    final signature =
        '$_scope:${widget.targetMemberId}:$expectedAmount:${invoiceIds.join(',')}';
    setState(() => _confirming = true);
    final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Bayar dari saldo?'),
                content: Text(
                    '${formatRupiah(overview.outstanding)} akan dibayarkan untuk seluruh tagihan yang tampil, dimulai dari kewajiban tertua. Pembayaran final tidak menyediakan refund.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Kembali')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Bayar sekarang'))
                ]));
    if (!mounted) return;
    setState(() => _confirming = false);
    if (agreed != true) return;
    if (_quoteSignature != signature) {
      _key = financeRequestId();
      _quoteSignature = signature;
    }
    setState(() {
      _paying = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(financeRepositoryProvider).pay(
          widget.communityId, _scope, _key,
          targetMemberId: widget.targetMemberId,
          invoiceIds: invoiceIds,
          expectedAmount: expectedAmount);
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      invalidateDues(ref.invalidate, widget.communityId);
      ref.invalidate(memberCardProvider(widget.communityId));
      ref.invalidate(joinedCommunitiesProvider);
      ref.invalidate(activeCommunityProvider);
      setState(() {
        _success =
            'Pembayaran berhasil dicatat. Status diperbarui setelah seluruh kewajiban lunas.';
        _key = financeRequestId();
        _quoteSignature = null;
      });
    } catch (e) {
      if (e is FinanceConflictException) {
        ref.invalidate(billingOverviewProvider(widget.communityId,
            scope: _scope, targetMemberId: widget.targetMemberId));
        ref.invalidate(walletSummaryProvider);
        _quoteSignature = null;
      }
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _renew() async {
    if (_paying) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      await ref.read(financeRepositoryProvider).renew(
          widget.communityId, _scope,
          targetMemberId: widget.targetMemberId);
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      setState(() => _success =
          'Tagihan perpanjangan disiapkan. Lanjutkan pembayaran untuk memperpanjang masa aktif.');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = billingOverviewProvider(widget.communityId,
        scope: _scope, targetMemberId: widget.targetMemberId);
    final value = ref.watch(p);
    final wallet = ref.watch(walletSummaryProvider);
    final auth = ref.watch(authProvider);
    final superAdmin = auth is AuthAuthenticated && auth.user.isSuperAdmin;
    return Scaffold(
        appBar: AppBar(title: const Text('Keanggotaan & pembayaran'), actions: [
          IconButton(
              tooltip: 'Segarkan pembayaran',
              onPressed:
                  _paying ? null : () => invalidateFinance(ref.invalidate),
              icon: const Icon(Icons.refresh)),
        ]),
        body: value.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (b) => FinanceBody(children: [
                  if (widget.targetMemberId == null &&
                      (b.canConfigure ||
                          superAdmin ||
                          _scope == 'platform')) ...[
                    SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'member', label: Text('Iuran anggota')),
                          ButtonSegment(
                              value: 'platform', label: Text('Langganan'))
                        ],
                        selected: {
                          _scope
                        },
                        onSelectionChanged: _paying
                            ? null
                            : (v) => setState(() {
                                  _scope = v.single;
                                  _key = financeRequestId();
                                  _error = null;
                                  _success = null;
                                })),
                    const SizedBox(height: 16),
                  ],
                  if (widget.targetMemberId != null)
                    const FinanceMessage(
                        'Pembayaran untuk anggota yang Anda kelola. Saldo yang digunakan adalah saldo Anda sendiri.'),
                  EntitlementCard(overview: b),
                  if (!b.platformActive && _scope == 'member')
                    FinanceMessage(
                        'Langganan komunitas tidak aktif. Pendiri perlu melunasi biaya platform agar kegiatan kembali tersedia.'),
                  if (b.entitlement.active &&
                      b.entitlement.state != 'exempt' &&
                      (_scope == 'platform' || b.settings.memberAmount > 0))
                    OutlinedButton.icon(
                        key: const Key('billing-renew'),
                        onPressed: _paying ? null : _renew,
                        icon: const Icon(Icons.update),
                        label: const Text('Siapkan perpanjangan')),
                  if (b.entitlement.state == 'expired' &&
                      b.entitlement.arrearsAmount > 0)
                    for (final n in b.notices) FinanceMessage(n.message),
                  Text(
                      _scope == 'platform'
                          ? '${formatRupiah(b.settings.platformMonthlyAmount)} per bulan per komunitas, dibayar pendiri kepada platform.'
                          : b.entitlement.state == 'exempt'
                              ? 'Peran Anda bebas iuran komunitas. Langganan platform tetap menjadi kewajiban pendiri.'
                              : '${formatRupiah(b.settings.memberAmount)} per ${b.settings.periodMonths} bulan. Uang pendaftaran ${formatRupiah(b.settings.entryFee)} dibayar sekali.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  const Text(
                      'Tarif dan peran baru berlaku mulai periode berikutnya. Tagihan serta pembayaran lama tetap memakai nominal yang tersimpan.'),
                  const SizedBox(height: 16),
                  if (b.invoices.isEmpty)
                    const FinanceMessage(
                        'Belum ada tagihan. Hari masa gratis tidak ditagih.'),
                  for (final i in b.invoices)
                    FinanceSection(
                        title: i.label,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${financeDate(i.periodStart)} sampai sebelum ${financeDate(i.periodEnd)} WIB'),
                              const SizedBox(height: 8),
                              Text(i.legacyNominalUnrecorded
                                  ? 'Nominal histori tidak tercatat; hak bulan lunas tetap dipertahankan.'
                                  : 'Tagihan ${formatRupiah(i.amount)} · terbayar ${formatRupiah(i.paidAmount)}'),
                              if (i.hasProrationDetails)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Tarif proporsional: ${i.coveredDays} dari ${i.nominalDays} hari · tarif normal ${formatRupiah(i.nominalAmount!)}.',
                                    key: Key('billing-proration-${i.id}'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              Text(
                                  i.outstanding > 0
                                      ? 'Sisa ${formatRupiah(i.outstanding)}'
                                      : i.status == 'void'
                                          ? 'Dibatalkan'
                                          : 'Lunas',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: i.outstanding > 0
                                          ? Theme.of(context).colorScheme.error
                                          : Colors.green.shade700)),
                              const SizedBox(height: 6),
                              SelectableText('Referensi: ${i.id}',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ])),
                  if (b.outstanding > 0)
                    FinanceSection(
                        title: 'Lunasi kewajiban',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  'Total yang dibayar: ${formatRupiah(b.outstanding)}',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 10),
                              wallet.when(
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, _) => FinanceError(
                                      error: e,
                                      retry: () => ref
                                          .invalidate(walletSummaryProvider)),
                                  data: (w) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                                'Saldo tersedia: ${formatRupiah(w.available)}'),
                                            if (w.available <
                                                b.outstanding) ...[
                                              const FinanceMessage(
                                                  'Saldo belum cukup. Top up terlebih dahulu atau ajukan bukti transfer. Tagihan tetap belum lunas.'),
                                              FilledButton.icon(
                                                  key: const Key(
                                                      'billing-topup'),
                                                  onPressed: _paying ||
                                                          _confirming
                                                      ? null
                                                      : () => context.push(widget
                                                                  .targetMemberId ==
                                                              null
                                                          ? '${AppRoutes.topup}?community=${widget.communityId}'
                                                          : AppRoutes.topup),
                                                  icon: const Icon(Icons.add),
                                                  label: const Text(
                                                      'Top up saldo')),
                                            ] else
                                              FilledButton.icon(
                                                  key: const Key(
                                                      'billing-pay-wallet'),
                                                  onPressed: _paying
                                                      ? null
                                                      : () => _pay(b),
                                                  icon: _paying
                                                      ? const SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2))
                                                      : const Icon(Icons
                                                          .account_balance_wallet_outlined),
                                                  label: Text(_paying
                                                      ? 'Memproses…'
                                                      : 'Bayar dari saldo')),
                                          ])),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                  key: const Key('billing-pay-transfer'),
                                  onPressed: _paying
                                      ? null
                                      : () => context.push(
                                          '${AppRoutes.topup}?community=${widget.communityId}&scope=$_scope${widget.targetMemberId == null ? '' : '&member=${widget.targetMemberId}'}'),
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Ajukan bukti transfer')),
                              const SizedBox(height: 8),
                              Text(b.entitlement.state == 'archived'
                                  ? 'Data diarsipkan. Pelunasan kewajiban lama tetap dicatat, tetapi tidak membatalkan keputusan pengarsipan atau moderasi.'
                                  : 'Pembayaran penuh memperbarui hak akses dan KTA secara otomatis. Tidak ada persetujuan keanggotaan kedua.'),
                            ])),
                  if (_error != null) FinanceMessage(_error!, error: true),
                  if (_success != null) FinanceMessage(_success!),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton(
                        onPressed: () => context.push(
                            '${AppRoutes.paymentReceipts}?community=${widget.communityId}'),
                        child: const Text('Riwayat bukti')),
                    OutlinedButton(
                        onPressed: () => context.push(AppRoutes.wallet),
                        child: const Text('Saldo & transaksi')),
                    OutlinedButton(
                        onPressed: () => context
                            .push(AppRoutes.communityCard(widget.communityId)),
                        child: const Text('Kartu anggota')),
                    if (b.entitlement.billingScheme == 'legacy_calendar')
                      OutlinedButton(
                          onPressed: () => context.push(
                              '${AppRoutes.communityDues(widget.communityId)}/calendar'),
                          child: const Text('Kalender iuran lama')),
                  ]),
                  if (b.canManage || superAdmin) ...[
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.account_balance_outlined),
                        title: Text(_scope == 'platform' && superAdmin
                            ? 'Pendapatan iuran platform'
                            : 'Dana komunitas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                            '${AppRoutes.wallet}?scope=${_scope == 'platform' && superAdmin ? 'platform' : 'community'}&community=${widget.communityId}')),
                    const SizedBox(height: 24),
                    Text('Pengelolaan',
                        style: Theme.of(context).textTheme.titleLarge),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fact_check_outlined),
                        title: const Text('Verifikasi bukti pembayaran'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                            '${AppRoutes.paymentReceipts}?community=${widget.communityId}&manage=1')),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Keanggotaan tidak aktif'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                            AppRoutes.communityLifecycle(widget.communityId))),
                    if (b.canConfigure)
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.tune),
                          title: const Text('Tarif & rekening komunitas'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push(
                              AppRoutes.communityBillingSettings(
                                  widget.communityId))),
                  ],
                ])));
  }
}

/// Resolves the ID of the requested community, independently of the home selection.
class BillingAccessGate extends ConsumerWidget {
  const BillingAccessGate(
      {super.key, required this.communityId, required this.child});
  final String communityId;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityDetailProvider(communityId));
    return community.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
            appBar: AppBar(),
            body: FinanceError(
                error: e,
                retry: () =>
                    ref.invalidate(communityDetailProvider(communityId)))),
        data: (c) {
          if (!c.isMember && !c.isJoinPending) return child;
          final p = billingOverviewProvider(communityId);
          return ref.watch(p).when(
              loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator())),
              error: (e, _) => Scaffold(
                  appBar: AppBar(),
                  body: FinanceError(error: e, retry: () => ref.invalidate(p))),
              data: (b) => b.entitlement.active && b.platformActive
                  ? child
                  : Scaffold(
                      appBar:
                          AppBar(title: const Text('Keanggotaan tidak aktif')),
                      body: FinanceBody(children: [
                        EntitlementCard(
                            overview: b,
                            onPay: () => context
                                .push(AppRoutes.communityBilling(communityId))),
                        if (!b.platformActive)
                          const FinanceMessage(
                              'Langganan komunitas tidak aktif. Pendiri dapat membuka pembayaran langganan.'),
                        FinanceEntryCard(communityId: communityId),
                        if (c.myRole?.apiValue == 'creator')
                          OutlinedButton(
                              onPressed: () => context.push(
                                  '${AppRoutes.communityBilling(communityId)}?scope=platform'),
                              child: const Text('Bayar langganan komunitas')),
                        OutlinedButton(
                            onPressed: () => context.go('/'),
                            child: const Text('Pilih komunitas lain')),
                        OutlinedButton(
                            onPressed: () => context
                                .push(AppRoutes.communityCard(communityId)),
                            child: const Text('Lihat status KTA')),
                      ])));
        });
  }
}
