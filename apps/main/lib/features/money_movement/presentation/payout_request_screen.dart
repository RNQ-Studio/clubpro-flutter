import '../data/money_movement_remote_data_source.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/presentation/community_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'money_movement_providers.dart';

class PayoutRequestScreen extends ConsumerStatefulWidget {
  const PayoutRequestScreen({super.key, this.communityId});
  final String? communityId;
  @override
  ConsumerState<PayoutRequestScreen> createState() =>
      _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends ConsumerState<PayoutRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _pin = TextEditingController();
  late String? _community = widget.communityId;
  String _key = financeRequestId();
  String? _error;
  bool _canEdit = false, _hadUnknown = false;
  bool _ack = false, _sending = false, _locked = false;
  @override
  void dispose() {
    _amount.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    final bank = ref.read(primaryBankAccountProvider).value;
    if (bank == null || _community == null || !_ack) {
      setState(() =>
          _error = 'Lengkapi rekening, komunitas, dan konfirmasi tujuan.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _canEdit = false;
      _locked = true;
    });
    try {
      final p = await ref.read(moneyMovementRepositoryProvider).requestPayout({
        'community_id': _community,
        'amount': int.parse(_amount.text),
        'bank_account_version': bank.version,
        'pin': _pin.text,
        'acknowledged': true,
        'idempotency_key': _key
      });
      if (mounted) {
        _pin.clear();
        invalidateFinance(ref.invalidate);
        invalidateMovements(ref.invalidate);
        context.go(AppRoutes.payout(p.id));
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
    final bank = ref.watch(primaryBankAccountProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Ajukan pencairan')),
        body: Form(
            key: _form,
            child: FinanceBody(children: [
              ref.watch(walletSummaryProvider).when(
                  data: (w) => WalletBalanceCard(wallet: w),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => FinanceError(
                      error: e,
                      retry: () => ref.invalidate(walletSummaryProvider))),
              const FinanceMessage(
                  'Pencairan bank diproses pendiri/admin di luar aplikasi. Pengajuan menahan saldo tersedia; cadangan paket tidak dapat dicairkan. Keanggotaan berakhir tidak menghapus hak pencairan saldo Anda.'),
              bank.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => FinanceError(
                      error: e,
                      retry: () => ref.invalidate(primaryBankAccountProvider)),
                  data: (a) => a == null
                      ? FinanceSection(
                          title: 'Rekening belum tersedia',
                          child: FilledButton(
                              onPressed: () =>
                                  context.push(AppRoutes.primaryBank),
                              child: const Text('Daftarkan rekening utama')))
                      : FinanceSection(
                          title: 'Tujuan pencairan',
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('${a.bankName} ${a.maskedNumber}'),
                                Text('a.n. ${a.accountName}'),
                                const Text(
                                    'Tujuan ini disnapshot saat pengajuan; perubahan rekening berikutnya tidak mengubah permintaan berjalan.'),
                                TextButton(
                                    onPressed: _sending || _locked
                                        ? null
                                        : () =>
                                            context.push(AppRoutes.primaryBank),
                                    child: const Text('Ubah rekening'))
                              ]))),
              ref.watch(joinedCommunitiesProvider).when(
                  data: (list) => DropdownButtonFormField<String>(
                      key: const Key('payout-community'),
                      initialValue: list.any((c) => c.id == _community)
                          ? _community
                          : null,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Konteks komunitas'),
                      items: [
                        for (final c in list)
                          DropdownMenuItem(
                              value: c.id,
                              child:
                                  Text(c.name, overflow: TextOverflow.ellipsis))
                      ],
                      onChanged: _sending || _locked
                          ? null
                          : (v) => setState(() {
                                _community = v;
                                _key = financeRequestId();
                              }),
                      validator: (v) => v == null ? 'Pilih komunitas.' : null),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => FinanceError(
                      error: e,
                      retry: () => ref.invalidate(joinedCommunitiesProvider))),
              const SizedBox(height: 16),
              RupiahField(
                  key: const Key('payout-amount'),
                  controller: _amount,
                  label: 'Nominal pencairan',
                  enabled: !_sending && !_locked,
                  onChanged: (_) => _key = financeRequestId()),
              const SizedBox(height: 16),
              TextFormField(
                  key: const Key('payout-pin'),
                  controller: _pin,
                  enabled: !_sending && !_locked,
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
              CheckboxListTile(
                  key: const Key('payout-ack'),
                  contentPadding: EdgeInsets.zero,
                  value: _ack,
                  onChanged: _sending || _locked
                      ? null
                      : (v) => setState(() => _ack = v ?? false),
                  title: const Text(
                      'Saya sudah memeriksa bank, nomor, dan nama penerima. Kesalahan data rekening menjadi tanggung jawab saya.')),
              if (_locked)
                const FinanceMessage(
                    'Percobaan berikut memakai permintaan yang sama. Jangan mengajukan pencairan baru saat hasil aplikasi belum diketahui; periksa riwayat terlebih dahulu.'),
              if (_error != null) FinanceMessage(_error!, error: true),
              if (_canEdit)
                TextButton(
                    key: const Key('payout-edit'),
                    onPressed: () => setState(() {
                          _locked = false;
                          _key = financeRequestId();
                          _canEdit = false;
                          _error = null;
                        }),
                    child: const Text('Ubah permintaan yang ditolak')),
              FilledButton(
                  key: const Key('payout-submit'),
                  onPressed:
                      _sending || !_ack || bank.value == null ? null : _send,
                  child: Text(_sending
                      ? 'Mengajukan…'
                      : _locked
                          ? 'Coba lagi dengan aman'
                          : 'Konfirmasi & tahan saldo')),
            ])));
  }
}
