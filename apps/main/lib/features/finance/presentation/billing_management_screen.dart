import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/presentation/community_providers.dart';
import '../../dues/presentation/dues_providers.dart';
import '../domain/finance.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';

class BillingSettingsScreen extends ConsumerStatefulWidget {
  const BillingSettingsScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<BillingSettingsScreen> createState() =>
      _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends ConsumerState<BillingSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _entry = TextEditingController(),
      _bank = TextEditingController(),
      _account = TextEditingController(),
      _name = TextEditingController();
  int _period = 1;
  bool _initialized = false, _saving = false;
  String? _error, _success;
  @override
  void dispose() {
    for (final c in [_amount, _entry, _bank, _account, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(financeRepositoryProvider)
          .saveSettings(widget.communityId, {
        'dues_amount': int.parse(_amount.text),
        'entry_fee': int.parse(_entry.text),
        'period_months': _period,
        'dues_bank_name': _bank.text.trim(),
        'dues_account_number': _account.text.trim(),
        'dues_account_name': _name.text.trim(),
      });
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      invalidateDues(ref.invalidate, widget.communityId);
      setState(() => _success =
          'Pengaturan disimpan. Tarif dan periode baru berlaku pada periode berikutnya; tagihan lama tetap.');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = billingOverviewProvider(widget.communityId);
    final data = ref.watch(p);
    return Scaffold(
        appBar: AppBar(title: const Text('Tarif & rekening komunitas')),
        body: data.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (b) {
              if (!b.canConfigure) {
                return const Center(
                    child:
                        Text('Pengaturan tarif hanya dapat diubah pendiri.'));
              }
              if (!_initialized) {
                _initialized = true;
                _amount.text = '${b.settings.memberAmount}';
                _entry.text = '${b.settings.entryFee}';
                _period = b.settings.periodMonths.clamp(1, 12);
                _bank.text = b.settings.bankName;
                _account.text = b.settings.accountNumber;
                _name.text = b.settings.accountName;
              }
              return Form(
                  key: _form,
                  child: FinanceBody(children: [
                    const FinanceMessage(
                        'Admin, pelatih, dan pendiri bebas iuran anggota mulai periode berikutnya. Tunggakan sebelumnya tetap wajib dilunasi. Pengurus tetap membayar. Pendiri tetap membayar langganan platform Rp100.000 per bulan.'),
                    RupiahField(
                        controller: _amount,
                        label: 'Iuran per periode',
                        zero: true,
                        enabled: !_saving),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                        initialValue: _period,
                        decoration: const InputDecoration(
                            labelText: 'Masa aktif setiap periode'),
                        items: [
                          for (var i = 1; i <= 12; i++)
                            DropdownMenuItem(value: i, child: Text('$i bulan'))
                        ],
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _period = v ?? 1)),
                    const SizedBox(height: 16),
                    RupiahField(
                        controller: _entry,
                        label: 'Uang pendaftaran sekali',
                        zero: true,
                        enabled: !_saving),
                    const SizedBox(height: 24),
                    for (final (controller, label, max) in [
                      (_bank, 'Nama bank', 100),
                      (_account, 'Nomor rekening', 50),
                      (_name, 'Nama pemilik rekening', 150)
                    ]) ...[
                      TextFormField(
                          controller: controller,
                          enabled: !_saving,
                          maxLength: max,
                          decoration: InputDecoration(labelText: label),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? '$label wajib diisi.'
                              : null),
                      const SizedBox(height: 8),
                    ],
                    if (_error != null) FinanceMessage(_error!, error: true),
                    if (_success != null) FinanceMessage(_success!),
                    FilledButton(
                        key: const Key('billing-settings-save'),
                        onPressed: _saving ? null : _save,
                        child:
                            Text(_saving ? 'Menyimpan…' : 'Simpan pengaturan')),
                  ]));
            }));
  }
}

class LifecycleScreen extends ConsumerStatefulWidget {
  const LifecycleScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<LifecycleScreen> createState() => _LifecycleScreenState();
}

class _LifecycleScreenState extends ConsumerState<LifecycleScreen> {
  String? _busy, _error, _success;
  Future<void> _decide(InactiveSubject s, String action) async {
    if (_busy != null) return;
    final reason = TextEditingController();
    final form = GlobalKey<FormState>();
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(action == 'retain'
                    ? 'Pertahankan ${s.name}?'
                    : 'Arsipkan ${s.name}?'),
                content: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(action == 'retain'
                              ? 'Data dipertahankan dan pengingat peninjauan berikutnya tiga bulan lagi. Tunggakan dan masa aktif tetap.'
                              : 'Keanggotaan atau komunitas diarsipkan. Histori uang, pembayaran, dan referensi tetap tersimpan. Akun pengguna tidak dihapus.'),
                          const SizedBox(height: 12),
                          TextFormField(
                              controller: reason,
                              maxLength: 500,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  labelText: 'Alasan keputusan'),
                              validator: (v) => v == null || v.trim().length < 3
                                  ? 'Isi alasan minimal 3 karakter.'
                                  : null),
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Kembali')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(context, true);
                        }
                      },
                      child:
                          Text(action == 'retain' ? 'Pertahankan' : 'Arsipkan'))
                ]));
    final note = reason.text.trim();
    // Dispose after the dialog's reverse transition, not while its field is mounted.
    Future<void>.delayed(const Duration(milliseconds: 350), reason.dispose);
    if (approved != true || !mounted) return;
    setState(() {
      _busy = s.id;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(financeRepositoryProvider)
          .decide(widget.communityId, s, action, note);
      if (!mounted) return;
      invalidateFinance(ref.invalidate);
      ref.invalidate(joinedCommunitiesProvider);
      setState(() => _success = action == 'retain'
          ? 'Keputusan mempertahankan tersimpan.'
          : 'Data diarsipkan; histori transaksi dipertahankan.');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = inactiveSubjectsProvider(widget.communityId);
    return Scaffold(
        appBar: AppBar(title: const Text('Peninjauan masa tidak aktif')),
        body: ref.watch(p).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (items) => FinanceBody(children: [
                  const FinanceMessage(
                      'Setelah tiga bulan tidak aktif, pengelola menerima pengingat. Tidak ada penghapusan otomatis. Pertahankan tidak memberi masa gratis atau menghapus tunggakan.'),
                  if (_error != null) FinanceMessage(_error!, error: true),
                  if (_success != null) FinanceMessage(_success!),
                  if (items.isEmpty)
                    const FinanceMessage(
                        'Belum ada keanggotaan yang perlu ditinjau.'),
                  for (final s in items)
                    FinanceSection(
                        title: s.name,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${s.platform ? 'Komunitas / platform' : 'Anggota · ${s.role}'} · ${s.entitlement.label}'),
                              Text(
                                  'Tidak aktif sejak ${financeDate(s.entitlement.inactiveAt)}'),
                              Text(
                                  'Tunggakan: ${formatRupiah(s.entitlement.arrearsAmount)}'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                  onPressed: () => context.push(
                                      '${AppRoutes.communityBilling(widget.communityId)}?${s.platform ? 'scope=platform' : 'member=${s.id}'}'),
                                  icon: const Icon(Icons.payments_outlined),
                                  label: const Text('Lihat pembayaran')),
                              if (s.reviewDue)
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  OutlinedButton(
                                      onPressed: _busy != null
                                          ? null
                                          : () => _decide(s, 'retain'),
                                      child: const Text('Pertahankan')),
                                  FilledButton.tonal(
                                      style: FilledButton.styleFrom(
                                          minimumSize: const Size(0, 52)),
                                      onPressed: _busy != null
                                          ? null
                                          : () => _decide(s, 'archive'),
                                      child: Text(s.platform
                                          ? 'Arsipkan / hapus komunitas'
                                          : 'Arsipkan / hapus keanggotaan')),
                                ])
                              else
                                const Text(
                                    'Belum waktunya peninjauan tiga bulanan.'),
                            ])),
                ])));
  }
}
