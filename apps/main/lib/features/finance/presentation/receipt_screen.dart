import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/presentation/community_providers.dart';
import '../../member_card/presentation/member_card_providers.dart';
import '../../dues/presentation/dues_providers.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../domain/finance.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, this.communityId, this.manage = false});
  final String? communityId;
  final bool manage;
  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  String _status = '';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final p = paymentReceiptsProvider(
        communityId: widget.communityId,
        status: _status,
        page: _page,
        manage: widget.manage);
    return Scaffold(
        appBar: AppBar(
            title: Text(
                widget.manage ? 'Verifikasi pembayaran' : 'Riwayat pengajuan'),
            actions: [
              IconButton(
                  tooltip: 'Segarkan status dan tautan bukti',
                  onPressed: () => ref.invalidate(p),
                  icon: const Icon(Icons.refresh)),
            ]),
        body: FinanceBody(children: [
          if (widget.manage && widget.communityId != null) ...[
            OutlinedButton.icon(
                onPressed: () => context
                    .push('${AppRoutes.topup}?community=${widget.communityId}'),
                icon: const Icon(Icons.add),
                label: const Text('Ajukan top up untuk anggota')),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status pengajuan'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua status')),
                DropdownMenuItem(
                    value: 'pending', child: Text('Menunggu verifikasi')),
                DropdownMenuItem(
                    value: 'verified', child: Text('Terverifikasi')),
                DropdownMenuItem(value: 'rejected', child: Text('Ditolak'))
              ],
              onChanged: (v) => setState(() {
                    _status = v ?? '';
                    _page = 1;
                  })),
          const SizedBox(height: 16),
          if (widget.communityId != null)
            TextButton.icon(
              onPressed: () => context
                  .push(AppRoutes.communityDuesPayments(widget.communityId!)),
              icon: const Icon(Icons.history),
              label: const Text('Bukti iuran lama'),
            ),
          ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (data) => Column(children: [
                    if (data.items.isEmpty)
                      const FinanceMessage(
                          'Belum ada pengajuan pada filter ini.'),
                    for (final r in data.items)
                      FinanceSection(
                          title:
                              '${r.purpose == 'topup' ? 'Top up' : r.purpose == 'platform' ? 'Langganan komunitas' : r.purpose == 'legacy_dues' ? 'Histori iuran' : 'Iuran anggota'} · ${receiptStatus(r.status)}',
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                    'Diajukan ${formatRupiah(r.claimedAmount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                if (r.verifiedAmount != null)
                                  Text(
                                      'Diverifikasi ${formatRupiah(r.verifiedAmount!)}'),
                                if (r.beneficiaryName.isNotEmpty)
                                  Text('Pemilik: ${r.beneficiaryName}'),
                                Text('Referensi bank: ${r.reference}'),
                                if (r.verifiedReference.isNotEmpty)
                                  Text(
                                      'Referensi terverifikasi: ${r.verifiedReference}'),
                                if (r.collector.accountNumber.isNotEmpty)
                                  Text(
                                      'Tujuan saat pengajuan: ${r.collector.bankName} ${r.collector.accountNumber} a.n. ${r.collector.accountName}'),
                                Text(
                                    'Tanggal pengajuan: ${financeDate(r.createdAt)}'),
                                SelectableText('ID: ${r.id}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                if (r.note.isNotEmpty)
                                  Text('Catatan: ${r.note}'),
                                if (r.reviewedBy.isNotEmpty)
                                  Text(
                                      'Diperiksa ${r.reviewedBy} · ${financeDate(r.reviewedAt)}'),
                                if (r.reviewNote.isNotEmpty)
                                  Text('Catatan petugas: ${r.reviewNote}'),
                                const SizedBox(height: 10),
                                if (r.proofUrl != null)
                                  OutlinedButton.icon(
                                      onPressed: () => openPaymentProof(
                                          context, r.proofUrl!),
                                      icon: const Icon(Icons.image_outlined),
                                      label: const Text('Buka bukti privat')),
                                if (r.canReview && r.status == 'pending')
                                  FilledButton.icon(
                                      key: Key('receipt-review-${r.id}'),
                                      onPressed: () => showModalBottomSheet<
                                              void>(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) =>
                                              ReceiptReviewSheet(receipt: r)),
                                      icon:
                                          const Icon(Icons.fact_check_outlined),
                                      label: const Text(
                                          'Periksa & verifikasi nominal')),
                              ])),
                    FinancePager(
                        page: data.page,
                        lastPage: data.lastPage,
                        onPage: (v) => setState(() => _page = v)),
                  ])),
        ]));
  }
}

class ReceiptReviewSheet extends ConsumerStatefulWidget {
  const ReceiptReviewSheet({super.key, required this.receipt});
  final PaymentReceipt receipt;
  @override
  ConsumerState<ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends ConsumerState<ReceiptReviewSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount =
      TextEditingController(text: '${widget.receipt.claimedAmount}');
  late final _reference = TextEditingController(text: widget.receipt.reference);
  final _note = TextEditingController();
  late final _key = financeRequestId();
  String? _error;
  bool _busy = false, _checked = false;
  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _act(bool approve) async {
    if (_busy) return;
    if (approve && (!(_form.currentState?.validate() ?? false) || !_checked)) {
      if (!_checked) {
        setState(() => _error =
            'Pastikan bukti, penerima, dan nominal yang benar-benar diterima sudah diperiksa.');
      }
      return;
    }
    if (!approve && _note.text.trim().length < 3) {
      setState(() => _error = 'Isi alasan penolakan minimal 3 karakter.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(financeRepositoryProvider);
      if (approve) {
        await repo.verifyReceipt(widget.receipt.id, {
          'community_id': widget.receipt.communityId,
          'verified_amount': int.parse(_amount.text),
          'bank_reference': _reference.text.trim(),
          'idempotency_key': _key,
          'note': _note.text.trim(),
        });
      } else {
        await repo.rejectReceipt(widget.receipt.communityId, widget.receipt.id,
            _note.text.trim(), _key);
      }
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      invalidateDues(ref.invalidate, widget.receipt.communityId);
      ref.invalidate(memberCardProvider(widget.receipt.communityId));
      ref.invalidate(joinedCommunitiesProvider);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                  key: _form,
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Verifikasi penerimaan',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            '${widget.receipt.beneficiaryName} · diajukan ${formatRupiah(widget.receipt.claimedAmount)}'),
                        if (widget.receipt.collector.accountNumber.isNotEmpty)
                          Text(
                              'Tujuan saat pengajuan: ${widget.receipt.collector.bankName} ${widget.receipt.collector.accountNumber} a.n. ${widget.receipt.collector.accountName}'),
                        if (widget.receipt.proofUrl != null)
                          TextButton.icon(
                              onPressed: () => openPaymentProof(
                                  context, widget.receipt.proofUrl!),
                              icon: const Icon(Icons.image_outlined),
                              label: const Text('Buka bukti privat')),
                        const SizedBox(height: 12),
                        RupiahField(
                            controller: _amount,
                            label: 'Nominal yang benar-benar diterima',
                            enabled: !_busy),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: _reference,
                            enabled: !_busy,
                            maxLength: 150,
                            decoration: const InputDecoration(
                                labelText: 'Referensi transfer bank'),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Isi referensi transfer.'
                                : null),
                        TextFormField(
                            controller: _note,
                            enabled: !_busy,
                            maxLength: 500,
                            maxLines: 2,
                            decoration: const InputDecoration(
                                labelText:
                                    'Catatan pemeriksaan / alasan penolakan')),
                        CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _checked,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _checked = v ?? false),
                            title: const Text(
                                'Bukti dan dana masuk sudah diperiksa'),
                            subtitle: const Text(
                                'Konfirmasi ini mencatat keputusan petugas. Aplikasi tidak melakukan transfer bank.')),
                        if (_error != null)
                          FinanceMessage(_error!, error: true),
                        FilledButton(
                            key: const Key('receipt-verify'),
                            onPressed: _busy ? null : () => _act(true),
                            child: Text(_busy
                                ? 'Memproses…'
                                : 'Verifikasi nominal & catat penerimaan')),
                        TextButton(
                            onPressed: _busy ? null : () => _act(false),
                            child: const Text('Tolak dengan alasan')),
                      ])))));
}
