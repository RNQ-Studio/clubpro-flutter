import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import '../data/money_movement_remote_data_source.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/presentation/community_providers.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/money_movement.dart';
import 'money_movement_providers.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.communityId});
  final String? communityId;
  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _pin = TextEditingController();
  late String? _community = widget.communityId;
  int _recipientPage = 1;
  String _query = '', _key = financeRequestId();
  String? _error;
  bool _canEdit = false, _hadUnknown = false;
  bool _confirmed = false, _sending = false, _retryLocked = false;
  TransferRecipient? _recipient;
  MemberTransfer? _sent;
  Timer? _timer;
  @override
  void dispose() {
    _timer?.cancel();
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _edited() {
    if (!_retryLocked) {
      _key = financeRequestId();
      _confirmed = false;
    }
  }

  Future<void> _send() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    final r = _recipient;
    if (r == null || _community == null || !_confirmed) {
      setState(() => _error = 'Pilih dan konfirmasi identitas penerima.');
      return;
    }
    _timer?.cancel();
    setState(() {
      _sending = true;
      _error = null;
      _canEdit = false;
      _retryLocked = true;
    });
    try {
      final sent = await ref.read(moneyMovementRepositoryProvider).transfer({
        'community_id': _community,
        'recipient_identity_id': int.parse(r.identityId),
        'recipient_community_id': int.parse(r.communityId),
        'amount': int.parse(_amount.text),
        'pin': _pin.text,
        'idempotency_key': _key
      });
      if (mounted) {
        invalidateFinance(ref.invalidate);
        invalidateMovements(ref.invalidate);
        setState(() => _sent = sent);
        _pin.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = financeErrorMessage(e);
          _hadUnknown = _hadUnknown || e is! MovementRejectedException;
          _canEdit = e is MovementRejectedException && !_hadUnknown;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    final access = _community == null
        ? null
        : ref.watch(billingOverviewProvider(_community!));
    final canTransfer = access?.value?.entitlement.active == true &&
        access?.value?.platformActive == true;
    return Scaffold(
        appBar: AppBar(title: const Text('Transfer antaranggota')),
        body: sent != null
            ? FinanceBody(children: [
                const Icon(Icons.check_circle_outline, size: 64),
                Text('Transfer saldo berhasil',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text(formatRupiah(sent.amount)),
                Text('Dari ${sent.sender} kepada ${sent.recipient}'),
                SelectableText('Referensi: ${sent.reference}'),
                Text(financeDate(sent.createdAt)),
                const FinanceMessage(
                    'Saldo berpindah sekali tanpa biaya platform. Transfer internal tidak berarti uang berpindah antarbank.'),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kembali ke saldo'))
              ])
            : Form(
                key: _form,
                child: FinanceBody(children: [
                  ref.watch(walletSummaryProvider).when(
                      data: (w) => WalletBalanceCard(wallet: w),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => FinanceError(
                          error: e,
                          retry: () => ref.invalidate(walletSummaryProvider))),
                  const FinanceMessage(
                      'Transfer membutuhkan keanggotaan aktif. Periksa nama dan asal komunitas penerima. Transaksi final tidak menyediakan refund.'),
                  ref.watch(joinedCommunitiesProvider).when(
                      data: (list) => DropdownButtonFormField<String>(
                          key: const Key('transfer-community'),
                          initialValue: list.any((c) => c.id == _community)
                              ? _community
                              : null,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Komunitas pengirim'),
                          items: [
                            for (final c in list)
                              DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name,
                                      overflow: TextOverflow.ellipsis))
                          ],
                          onChanged: _sending || _retryLocked
                              ? null
                              : (v) => setState(() {
                                    _community = v;
                                    _recipientPage = 1;
                                    _recipient = null;
                                    _edited();
                                  }),
                          validator: (v) =>
                              v == null ? 'Pilih komunitas.' : null),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => FinanceError(
                          error: e,
                          retry: () =>
                              ref.invalidate(joinedCommunitiesProvider))),
                  if (access != null)
                    access.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => FinanceError(
                            error: e,
                            retry: () => ref.invalidate(
                                billingOverviewProvider(_community!))),
                        data: (b) => b.entitlement.active && b.platformActive
                            ? const SizedBox.shrink()
                            : FinanceSection(
                                title: 'Transfer belum tersedia',
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                          'Keanggotaan atau langganan komunitas tidak aktif. Saldo dan hak pencairan Anda tetap tersedia.'),
                                      FilledButton(
                                          onPressed: () => context.push(
                                              AppRoutes.communityBilling(
                                                  _community!)),
                                          child: const Text('Buka pembayaran'))
                                    ]))),
                  const SizedBox(height: 16),
                  TextFormField(
                      key: const Key('transfer-search'),
                      enabled: !_sending && !_retryLocked,
                      decoration: const InputDecoration(
                          labelText: 'Cari nama penerima',
                          prefixIcon: Icon(Icons.search)),
                      onChanged: (v) {
                        _timer?.cancel();
                        _timer = Timer(const Duration(milliseconds: 350), () {
                          if (mounted && !_sending && !_retryLocked) {
                            setState(() {
                              _query = v.trim();
                              _recipientPage = 1;
                              _recipient = null;
                              _edited();
                            });
                          }
                        });
                      }),
                  if (_community != null && _query.length >= 2)
                    ref
                        .watch(transferRecipientsProvider(_query, _community!,
                            page: _recipientPage))
                        .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => FinanceError(
                                error: e,
                                retry: () => ref.invalidate(
                                    transferRecipientsProvider(
                                        _query, _community!))),
                            data: (page) => Column(children: [
                                  if (page.items.isEmpty)
                                    const FinanceMessage(
                                        'Penerima aktif tidak ditemukan.'),
                                  for (final r in page.items)
                                    ListTile(
                                        key: Key(
                                            'recipient-${r.identityId}-${r.communityId}'),
                                        selected: _recipient?.identityId ==
                                                r.identityId &&
                                            _recipient?.communityId ==
                                                r.communityId,
                                        leading: Icon(_recipient?.identityId ==
                                                    r.identityId &&
                                                _recipient?.communityId ==
                                                    r.communityId
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off),
                                        title: Text(r.name),
                                        subtitle: Text(
                                            '${r.communityName} · ID ${r.identityId}'),
                                        onTap: _sending || _retryLocked
                                            ? null
                                            : () => setState(() {
                                                  _recipient = r;
                                                  _edited();
                                                })),
                                  FinancePager(
                                      page: page.page,
                                      lastPage: page.lastPage,
                                      onPage: (v) =>
                                          setState(() => _recipientPage = v))
                                ])),
                  if (_query.length < 2)
                    const FinanceMessage(
                        'Ketik minimal dua huruf untuk mencari anggota.'),
                  const SizedBox(height: 16),
                  RupiahField(
                      key: const Key('transfer-amount'),
                      controller: _amount,
                      label: 'Nominal transfer',
                      enabled: !_sending && !_retryLocked,
                      onChanged: (_) => setState(_edited)),
                  const SizedBox(height: 16),
                  TextFormField(
                      key: const Key('transfer-pin'),
                      controller: _pin,
                      enabled: !_sending && !_retryLocked,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      decoration: const InputDecoration(
                          labelText: 'PIN transaksi (6 digit)'),
                      validator: (v) => !RegExp(r'^\d{6}$').hasMatch(v ?? '')
                          ? 'Isi 6 digit PIN.'
                          : null),
                  if (_recipient != null)
                    CheckboxListTile(
                        key: const Key('transfer-confirm'),
                        contentPadding: EdgeInsets.zero,
                        value: _confirmed,
                        onChanged: _sending || _retryLocked
                            ? null
                            : (v) => setState(() => _confirmed = v ?? false),
                        title: Text(
                            'Kirim ${formatRupiah(int.tryParse(_amount.text) ?? 0)} kepada ${_recipient!.name} (${_recipient!.communityName}).')),
                  if (_retryLocked && _sent == null)
                    const FinanceMessage(
                        'Tujuan dan nominal dikunci untuk percobaan ini. Coba lagi memakai referensi permintaan yang sama; periksa riwayat bila koneksi terputus.'),
                  if (_error != null) FinanceMessage(_error!, error: true),
                  if (_canEdit)
                    TextButton(
                        key: const Key('transfer-edit'),
                        onPressed: () => setState(() {
                              _retryLocked = false;
                              _confirmed = false;
                              _key = financeRequestId();
                              _canEdit = false;
                              _error = null;
                            }),
                        child: const Text('Ubah permintaan yang ditolak')),
                  FilledButton(
                      key: const Key('transfer-submit'),
                      onPressed: _sending ||
                              (!_retryLocked && !canTransfer) ||
                              _recipient == null ||
                              !_confirmed
                          ? null
                          : _send,
                      child: Text(_sending
                          ? 'Memproses…'
                          : _retryLocked
                              ? 'Coba lagi dengan aman'
                              : 'Konfirmasi transfer saldo')),
                ])));
  }
}
