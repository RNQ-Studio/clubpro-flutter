import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/money_movement.dart';
import 'money_movement_providers.dart';

class PrimaryBankScreen extends ConsumerWidget {
  const PrimaryBankScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('Rekening utama'), actions: [
        IconButton(
            tooltip: 'Muat ulang rekening',
            onPressed: () => ref.invalidate(primaryBankAccountProvider),
            icon: const Icon(Icons.refresh))
      ]),
      body: ref.watch(primaryBankAccountProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => FinanceError(
              error: e,
              retry: () => ref.invalidate(primaryBankAccountProvider)),
          data: (a) => PrimaryBankForm(account: a)));
}

class PrimaryBankForm extends ConsumerStatefulWidget {
  const PrimaryBankForm({super.key, this.account});
  final PrimaryBankAccount? account;
  @override
  ConsumerState<PrimaryBankForm> createState() => _PrimaryBankFormState();
}

class _PrimaryBankFormState extends ConsumerState<PrimaryBankForm> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.account?.bankCode),
      _bank = TextEditingController(text: widget.account?.bankName),
      _number = TextEditingController(text: widget.account?.accountNumber),
      _name = TextEditingController(text: widget.account?.accountName);
  bool _ack = false, _sending = false, _show = false;
  String? _error, _success;
  @override
  void dispose() {
    _code.dispose();
    _bank.dispose();
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    if (!_ack) {
      setState(() => _error = 'Konfirmasi kebenaran rekening terlebih dahulu.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(moneyMovementRepositoryProvider).savePrimaryAccount({
        'bank_code': _code.text.trim(),
        'bank_name': _bank.text.trim(),
        'account_number': _number.text.trim(),
        'account_name': _name.text.trim(),
        'expected_version': widget.account?.version ?? 0,
        'acknowledged': true
      });
      if (mounted) {
        ref.invalidate(primaryBankAccountProvider);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rekening utama tersimpan.')));
        setState(() => _success =
            'Rekening utama tersimpan. Tujuan pencairan yang sudah dibuat tetap memakai snapshot lama.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
      key: _form,
      child: FinanceBody(children: [
        const FinanceMessage(
            'Rekening boleh atas nama pihak lain. Pastikan bank, nomor, dan nama penerima benar; kesalahan data rekening menjadi tanggung jawab Anda.'),
        if (widget.account != null)
          FinanceSection(
              title: 'Rekening tersimpan',
              child: Text(
                  '${widget.account!.bankName} ${widget.account!.maskedNumber}\na.n. ${widget.account!.accountName}')),
        TextFormField(
            key: const Key('bank-code'),
            controller: _code,
            enabled: !_sending,
            maxLength: 30,
            decoration: const InputDecoration(labelText: 'Kode bank'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Isi kode bank.' : null),
        TextFormField(
            key: const Key('bank-name'),
            controller: _bank,
            enabled: !_sending,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nama bank'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Isi nama bank.' : null),
        TextFormField(
            key: const Key('bank-number'),
            controller: _number,
            enabled: !_sending,
            obscureText: !_show,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(34)
            ],
            decoration: InputDecoration(
                labelText: 'Nomor rekening',
                helperText: 'Angka nol di awal tetap disimpan.',
                suffixIcon: IconButton(
                    tooltip: _show ? 'Sembunyikan nomor' : 'Tampilkan nomor',
                    onPressed: () => setState(() => _show = !_show),
                    icon:
                        Icon(_show ? Icons.visibility_off : Icons.visibility))),
            validator: (v) => !RegExp(r'^[0-9]{5,34}$').hasMatch(v ?? '')
                ? 'Isi 5–34 digit nomor rekening.'
                : null),
        const SizedBox(height: 16),
        TextFormField(
            key: const Key('bank-owner'),
            controller: _name,
            enabled: !_sending,
            maxLength: 150,
            decoration: const InputDecoration(
                labelText: 'Nama penerima sesuai rekening'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Isi nama penerima.' : null),
        CheckboxListTile(
            key: const Key('bank-ack'),
            contentPadding: EdgeInsets.zero,
            value: _ack,
            onChanged:
                _sending ? null : (v) => setState(() => _ack = v ?? false),
            title: const Text(
                'Saya bertanggung jawab atas kebenaran tujuan rekening ini.')),
        if (_error != null) FinanceMessage(_error!, error: true),
        if (_success != null) FinanceMessage(_success!),
        FilledButton(
            key: const Key('bank-save'),
            onPressed: _sending ? null : _save,
            child: Text(_sending ? 'Menyimpan…' : 'Simpan rekening utama')),
        const FinanceMessage(
            'Data rekening bersifat privat. Daftar dan pesan memakai nomor tersamarkan. Perubahan ini tidak mengalihkan pencairan yang sedang berjalan.'),
      ]));
}
