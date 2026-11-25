import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/domain/entities/community_draft.dart';
import '../../community/presentation/community_providers.dart';
import '../../directory/presentation/directory_providers.dart';
import '../domain/finance.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';

/// A receipt is an assertion of transfer; it never credits money by itself.
class TopupScreen extends ConsumerStatefulWidget {
  const TopupScreen(
      {super.key, this.communityId, this.scope, this.targetMemberId});
  final String? communityId, scope, targetMemberId;
  @override
  ConsumerState<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends ConsumerState<TopupScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _reference = TextEditingController(),
      _note = TextEditingController();
  late String? _community = widget.communityId;
  String? _beneficiary, _error;
  String _memberSearch = '';
  bool _sending = false, _onBehalf = false, _creditExcess = false;
  CommunityImage? _proof;
  String? _assetId;
  late final _key = financeRequestId();
  PaymentReceipt? _sent;
  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final images = await ref.read(communityImagePickerProvider).pickPhotos(1);
      if (images.isEmpty || !mounted) return;
      setState(() {
        _proof = images.single;
        _assetId = null;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _send() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    if (_community == null) {
      setState(() => _error = 'Pilih komunitas penerima transfer.');
      return;
    }
    if (_proof == null) {
      setState(() => _error = 'Pilih foto bukti transfer terlebih dahulu.');
      return;
    }
    if (_onBehalf && _beneficiary == null) {
      setState(() => _error = 'Pilih anggota pemilik saldo.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      _assetId ??= await ref
          .read(communityRepositoryProvider)
          .uploadImage(_proof!, category: 'dues-proof');
      final result = await ref.read(financeRepositoryProvider).submitReceipt({
        'community_id': _community,
        'claimed_amount': int.parse(_amount.text),
        'proof_asset_id': _assetId,
        'bank_reference': _reference.text.trim(),
        'note': _note.text.trim(),
        'idempotency_key': _key,
        if (_onBehalf) 'beneficiary_user_id': int.parse(_beneficiary!),
        if (widget.scope != null) 'scope': widget.scope,
        if (widget.scope != null) 'credit_excess': _creditExcess,
        if (widget.targetMemberId != null)
          'target_member_id': int.parse(widget.targetMemberId!),
        if (widget.scope != null)
          'invoice_ids': ref
              .read(billingOverviewProvider(_community!,
                  scope: widget.scope!, targetMemberId: widget.targetMemberId))
              .requireValue
              .invoices
              .where((i) => i.outstanding > 0)
              .map((i) => i.id)
              .toList(),
      });
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      setState(() => _sent = result);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    final scope = widget.scope;
    final billing = _community == null
        ? null
        : ref.watch(billingOverviewProvider(_community!,
            scope: scope ?? 'member', targetMemberId: widget.targetMemberId));
    final overview = billing?.value;
    if (sent != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Bukti diajukan')),
          body: FinanceBody(children: [
            const Icon(Icons.fact_check_outlined, size: 64),
            const SizedBox(height: 16),
            Text(receiptStatus(sent.status),
                style: Theme.of(context).textTheme.headlineSmall),
            const FinanceMessage(
                'Bukti sudah diterima. Saldo dan masa aktif hanya berubah setelah petugas memverifikasi nominal dan alokasi pembayarannya.'),
            SelectableText('ID pengajuan: ${sent.id}'),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => context.push(widget.targetMemberId == null
                    ? '${AppRoutes.paymentReceipts}?community=$_community'
                    : AppRoutes.paymentReceipts),
                child: const Text('Lihat status & riwayat')),
            TextButton(
                onPressed: () => context.go(scope == null
                    ? AppRoutes.wallet
                    : '${AppRoutes.communityBilling(_community!)}?scope=$scope${widget.targetMemberId == null ? '' : '&member=${widget.targetMemberId}'}'),
                child: const Text('Kembali ke ringkasan')),
          ]));
    }
    return Scaffold(
        appBar: AppBar(
            title:
                Text(scope == null ? 'Top up saldo' : 'Bayar lewat transfer')),
        body: Form(
            key: _form,
            child: FinanceBody(children: [
              if (widget.communityId == null)
                ref.watch(joinedCommunitiesProvider).when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => FinanceError(
                        error: e,
                        retry: () => ref.invalidate(joinedCommunitiesProvider)),
                    data: (list) => list.isEmpty
                        ? const FinanceMessage(
                            'Bergabung atau buat komunitas untuk memilih rekening penerima top up.')
                        : DropdownButtonFormField<String>(
                            initialValue: _community,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                labelText: 'Komunitas penerima transfer'),
                            items: [
                              for (final c in list)
                                DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name,
                                        overflow: TextOverflow.ellipsis))
                            ],
                            onChanged: _sending
                                ? null
                                : (v) => setState(() {
                                      _community = v;
                                      _beneficiary = null;
                                      _onBehalf = false;
                                    }),
                            validator: (v) =>
                                v == null ? 'Pilih komunitas.' : null)),
              const SizedBox(height: 16),
              if (billing != null)
                billing.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => FinanceError(
                        error: e,
                        retry: () => ref.invalidate(billingOverviewProvider(
                            _community!,
                            scope: scope ?? 'member',
                            targetMemberId: widget.targetMemberId))),
                    data: (b) => BankInstructions(settings: b.settings)),
              if (scope != null && overview != null) ...[
                EntitlementCard(overview: overview),
                const FinanceMessage(
                    'Nominal yang diverifikasi dialokasikan ke tagihan tertua. Pembayaran sebagian tetap menyisakan tunggakan dan belum mengaktifkan akses.'),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _creditExcess,
                    onChanged: _sending
                        ? null
                        : (v) => setState(() => _creditExcess = v ?? false),
                    title: const Text('Masukkan kelebihan ke saldo saya'),
                    subtitle: const Text(
                        'Jika nominal melebihi tagihan, sisanya dikreditkan sekali ke saldo. Tanpa pilihan ini, penerimaan berlebih ditolak.')),
              ],
              if (scope == null && (overview?.canManage ?? false)) ...[
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ajukan untuk anggota'),
                    subtitle: const Text(
                        'Bukti transfer tetap wajib; nominal diverifikasi melalui pengajuan yang sama.'),
                    value: _onBehalf,
                    onChanged:
                        _sending ? null : (v) => setState(() => _onBehalf = v)),
                if (_onBehalf)
                  TextField(
                      enabled: !_sending,
                      decoration:
                          const InputDecoration(labelText: 'Cari nama anggota'),
                      onChanged: (v) => setState(() {
                            _memberSearch = v.trim();
                            _beneficiary = null;
                          })),
                if (_onBehalf)
                  ref
                      .watch(internalMemberResultsProvider(_community!,
                          search: _memberSearch))
                      .when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => FinanceError(
                              error: e,
                              retry: () => ref.invalidate(
                                  internalMemberResultsProvider(_community!,
                                      search: _memberSearch))),
                          data: (members) => DropdownButtonFormField<String>(
                              initialValue: _beneficiary,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                  labelText: 'Pemilik saldo'),
                              items: [
                                for (final m in members)
                                  if (m['user_id'] != null)
                                    DropdownMenuItem(
                                        value: '${m['user_id']}',
                                        child: Text('${m['name']}',
                                            overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: _sending
                                  ? null
                                  : (v) => setState(() => _beneficiary = v),
                              validator: (v) => _onBehalf && v == null
                                  ? 'Pilih anggota.'
                                  : null)),
                const SizedBox(height: 12),
              ],
              RupiahField(
                  controller: _amount,
                  label: 'Nominal transfer yang diajukan',
                  enabled: !_sending),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _reference,
                  enabled: !_sending,
                  maxLength: 150,
                  decoration: const InputDecoration(
                      labelText: 'Referensi transfer / berita bank'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Isi referensi transfer.'
                      : null),
              const SizedBox(height: 8),
              TextFormField(
                  controller: _note,
                  enabled: !_sending,
                  maxLength: 500,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Catatan (opsional)')),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                  key: const Key('receipt-pick-proof'),
                  onPressed: _sending ? null : _pick,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(_proof == null
                      ? 'Pilih foto bukti transfer'
                      : 'Ganti bukti: ${_proof!.filename}')),
              if (_proof != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: Image.memory(_proof!.bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => const Text(
                                'Pratinjau tidak tersedia. File tetap dapat diajukan.')))),
              if (_error != null) FinanceMessage(_error!, error: true),
              const SizedBox(height: 16),
              FilledButton.icon(
                  key: const Key('receipt-submit'),
                  onPressed: _sending ||
                          _community == null ||
                          (scope != null && overview == null)
                      ? null
                      : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(_sending ? 'Mengajukan…' : 'Ajukan verifikasi')),
              const FinanceMessage(
                  'Gunakan satu bukti hanya untuk satu penerimaan. Bukti yang sama tidak dapat menambah saldo sekaligus melunasi iuran untuk kedua kalinya.'),
            ])));
  }
}
