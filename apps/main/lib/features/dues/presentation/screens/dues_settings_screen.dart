import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import '../dues_providers.dart';
import '../widgets/dues_visuals.dart';

/// Pengaturan iuran oleh creator/admin: nominal per bulan, uang masuk, tanggal
/// mulai (sekaligus jatuh tempo bulanan), dan rekening tujuan transfer.
class DuesSettingsScreen extends ConsumerWidget {
  const DuesSettingsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = duesOverviewProvider(communityId, null);
    final overview = ref.watch(provider);
    final value = overview.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Iuran')),
      body: value == null
          ? overview.hasError
              ? CommunityErrorView(
                  message: overview.error.toString(),
                  onRetry: () => ref.invalidate(provider),
                )
              : const Center(child: CircularProgressIndicator())
          : !value.canManage
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Hanya creator dan admin komunitas yang bisa mengatur '
                      'iuran.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _SettingsForm(
                  communityId: communityId,
                  settings: value.settings,
                ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.communityId, required this.settings});

  final String communityId;
  final DuesSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: _grouped(widget.settings.monthlyAmount),
  );
  late final _entryFee = TextEditingController(
    text: widget.settings.configured ? _grouped(widget.settings.entryFee) : '',
  );
  late final _bank = TextEditingController(text: widget.settings.bankName);
  late final _account =
      TextEditingController(text: widget.settings.accountNumber);
  late final _accountName =
      TextEditingController(text: widget.settings.accountName);
  late DateTime? _startDate = widget.settings.startDate;
  bool _saving = false;

  /// Galat dari server per isian.
  final _serverErrors = <String, String>{};
  String? _error;

  static String _grouped(int? amount) =>
      amount == null ? '' : formatRupiah(amount).substring(2);

  static int? _parse(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  @override
  void dispose() {
    for (final c in [_amount, _entryFee, _bank, _account, _accountName]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime(now.year, now.month, 1),
      firstDate: DateTime(2000),
      lastDate: DateTime(2099, 12, 31),
      helpText: 'Tanggal mulai iuran',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _serverErrors.remove('dues_start_date');
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _serverErrors.clear();
      _error = null;
    });
    final valid = _formKey.currentState!.validate();
    final start = _startDate;
    if (!valid || start == null) {
      if (start == null) {
        setState(() =>
            _serverErrors['dues_start_date'] = 'Pilih tanggal mulai iuran.');
      }
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(duesRepositoryProvider).saveSettings(
            widget.communityId,
            DuesSettingsInput(
              monthlyAmount: _parse(_amount.text)!,
              entryFee: _parse(_entryFee.text) ?? 0,
              startDate: start,
              bankName: _bank.text,
              accountNumber: _account.text,
              accountName: _accountName.text,
            ),
          );
      if (!mounted) return;
      invalidateDues(ref.invalidate, widget.communityId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan iuran disimpan')),
      );
      Navigator.of(context).maybePop();
    } on DuesFieldException catch (e) {
      if (mounted) setState(() => _serverErrors[e.field] = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = _startDate;
    final muted = theme.colorScheme.onSurfaceVariant;

    InputDecoration money(String label, String field, {String? helper}) =>
        InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          helperText: helper,
          helperMaxLines: 3,
          errorText: _serverErrors[field],
          errorMaxLines: 3,
        );

    return Form(
      key: _formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Nominal',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('dues-settings-amount'),
                controller: _amount,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                decoration: money('Iuran per bulan', 'dues_amount'),
                validator: (text) {
                  final value = _parse(text ?? '');
                  if (value == null) return 'Iuran per bulan wajib diisi.';
                  if (value < 1000) return 'Iuran per bulan minimal Rp1.000.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('dues-settings-entry-fee'),
                controller: _entryFee,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                decoration: money(
                  'Uang masuk',
                  'entry_fee',
                  helper: 'Dibayar sekali bersama iuran pertama. Kosongkan '
                      'bila tidak ada.',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mulai iuran',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                key: const Key('dues-settings-start'),
                onTap: _saving ? null : _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal mulai',
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                    errorText: _serverErrors['dues_start_date'],
                  ),
                  child: Text(
                    start == null
                        ? 'Pilih tanggal'
                        : AppDateUtils.longDateId(start),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                start == null
                    ? 'Bulan tanggal ini menjadi tagihan pertama, dan '
                        'tanggalnya menjadi jatuh tempo setiap bulan.'
                    : 'Tagihan pertama ${DuesMonths.long(start)}; jatuh '
                        'tempo setiap tanggal ${start.day}'
                        '${start.day > 28 ? ' (atau hari terakhir bulan yang '
                            'lebih pendek)' : ''}. Anggota yang bergabung '
                        'sesudahnya ditagih mulai bulan bergabung.',
                key: const Key('dues-settings-start-help'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const SizedBox(height: 20),
              Text(
                'Rekening tujuan transfer',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('dues-settings-bank'),
                controller: _bank,
                enabled: !_saving,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Nama bank',
                  hintText: 'Mis. BCA, BRI, Mandiri',
                  errorText: _serverErrors['dues_bank_name'],
                ),
                validator: (text) => (text ?? '').trim().length < 2
                    ? 'Nama bank wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('dues-settings-account'),
                controller: _account,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Nomor rekening',
                  errorText: _serverErrors['dues_account_number'],
                ),
                validator: (text) {
                  final length = (text ?? '').length;
                  return length < 5 || length > 30
                      ? 'Nomor rekening hanya angka, 5–30 digit.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('dues-settings-account-name'),
                controller: _accountName,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Atas nama',
                  errorText: _serverErrors['dues_account_name'],
                ),
                validator: (text) => (text ?? '').trim().length < 2
                    ? 'Nama pemilik rekening wajib diisi.'
                    : null,
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('dues-settings-save'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('Simpan'),
              ),
              const SizedBox(height: 8),
              Text(
                'Perubahan nominal berlaku untuk pembayaran berikutnya; '
                'pembayaran yang sudah dikirim tetap memakai nominal lamanya.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CommunityColors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Angka rupiah dengan titik ribuan saat diketik: "50000" → "50.000".
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    // Batas wajar agar tidak melampaui int: 100 juta per isian.
    final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final capped = trimmed.length > 9 ? trimmed.substring(0, 9) : trimmed;
    final text = formatRupiah(int.parse(capped)).substring(2);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
