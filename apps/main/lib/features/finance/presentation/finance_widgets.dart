import 'dart:math';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../domain/finance.dart';

String financeErrorMessage(Object error) => error is AppException
    ? error.message
    : error is FinanceConflictException
        ? error.message
        : error is FinanceDataException
            ? error.toString()
            : 'Tindakan belum berhasil. Muat ulang lalu coba lagi.';

String financeRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

String financeDate(String? value) {
  if (value == null || value.isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final timestamp = value.contains('T') || value.contains(' ');
  final date =
      timestamp ? parsed.toUtc().add(const Duration(hours: 7)) : parsed;
  final day =
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  return timestamp
      ? '$day ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} WIB'
      : day;
}

String operationLabel(String value) => switch (value) {
      'incoming_receipt' => 'Penerimaan terverifikasi',
      'topup' || 'topup_credit' => 'Top up terverifikasi',
      'dues' || 'member_payment' || 'billing_member' => 'Pembayaran iuran',
      'platform' ||
      'platform_payment' ||
      'billing_platform' =>
        'Langganan komunitas',
      'reserve' => 'Dana dicadangkan',
      'release' => 'Cadangan dilepas',
      _ when value.startsWith('billing_pay:') => 'Pembayaran kewajiban',
      _ => value.replaceAll('_', ' '),
    };
String receiptStatus(String value) => switch (value) {
      'legacy_verified' => 'Histori terverifikasi',
      'legacy_pending' => 'Histori menunggu verifikasi',
      'legacy_rejected' => 'Histori ditolak',
      'verified' => 'Terverifikasi',
      'rejected' => 'Ditolak',
      'pending' => 'Menunggu verifikasi',
      _ => 'Status belum dikenali',
    };
String? positiveRupiah(String? value,
    {int max = 1000000000, bool zero = false}) {
  final amount = int.tryParse(value?.trim() ?? '');
  if (amount == null || amount < (zero ? 0 : 1) || amount > max) {
    return 'Isi rupiah utuh ${zero ? '0' : '1'}–${formatRupiah(max)}.';
  }
  return null;
}

class FinanceBody extends StatelessWidget {
  const FinanceBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
      child: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: children))));
}

class FinanceError extends StatelessWidget {
  const FinanceError({super.key, required this.error, required this.retry});
  final Object error;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_outlined, size: 36),
                const SizedBox(height: 12),
                Text(financeErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: retry, child: const Text('Coba Lagi')),
              ]))));
}

class FinanceMessage extends StatelessWidget {
  const FinanceMessage(this.message, {super.key, this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          key: error ? const Key('finance-error') : null,
          style: TextStyle(
              color: error ? Theme.of(context).colorScheme.error : null)));
}

class FinanceSection extends StatelessWidget {
  const FinanceSection({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child
          ])));
}

class RupiahField extends StatelessWidget {
  const RupiahField(
      {super.key,
      required this.controller,
      required this.label,
      this.zero = false,
      this.enabled = true,
      this.onChanged});
  final TextEditingController controller;
  final String label;
  final bool zero, enabled;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10)
      ],
      validator: (v) => positiveRupiah(v, zero: zero),
      onChanged: onChanged,
      decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rp ',
          helperText: 'Rupiah utuh, tanpa titik atau koma'));
}

class BankInstructions extends StatelessWidget {
  const BankInstructions({super.key, required this.settings});
  final BillingSettings settings;
  @override
  Widget build(BuildContext context) => FinanceSection(
      title: 'Tujuan transfer',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (settings.accountNumber.isEmpty)
          const Text(
              'Rekening belum diatur. Pengelola dapat mengaturnya di Pengaturan Iuran.')
        else ...[
          Text(settings.bankName),
          const SizedBox(height: 4),
          SelectableText(settings.accountNumber,
              style: Theme.of(context).textTheme.titleLarge),
          Text('a.n. ${settings.accountName}'),
          TextButton.icon(
              onPressed: () => Clipboard.setData(
                  ClipboardData(text: settings.accountNumber)),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Salin nomor rekening')),
        ],
        const SizedBox(height: 8),
        const Text(
            'Transfer dilakukan di luar aplikasi. Unggah bukti dan referensi; saldo atau tagihan berubah setelah nominal diverifikasi petugas yang berwenang.'),
      ]));
}

class EntitlementCard extends StatelessWidget {
  const EntitlementCard({super.key, required this.overview, this.onPay});
  final BillingOverview overview;
  final VoidCallback? onPay;
  @override
  Widget build(BuildContext context) {
    final e = overview.entitlement;
    return FinanceSection(
        title: overview.scope == 'platform'
            ? 'Langganan komunitas'
            : 'Keanggotaan Anda',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(e.active ? Icons.verified_outlined : Icons.lock_clock_outlined,
                color: e.active
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
                child: Text(e.label,
                    key: const Key('billing-status'),
                    style: Theme.of(context).textTheme.titleLarge))
          ]),
          const SizedBox(height: 8),
          if (e.state == 'trial')
            Text(
                'Gratis 7 hari: ${financeDate(e.trialStart)} sampai sebelum ${financeDate(e.trialEnd)} WIB. Masa gratis hanya sekali.'),
          if (e.validUntil != null && e.state != 'trial')
            Text('Berlaku sampai sebelum ${financeDate(e.validUntil)} WIB.'),
          if (e.state == 'archived')
            const Text(
                'Data diarsipkan. Pelunasan kewajiban lama tidak membatalkan keputusan pengarsipan atau moderasi.'),
          if (!e.active && e.state != 'archived')
            const Text(
                'Akses kegiatan komunitas dibatasi. Anda tetap dapat masuk, melihat kewajiban, top up, dan membayar. Komunitas lain tetap dapat dipilih.'),
          const SizedBox(height: 10),
          Text('Kewajiban saat ini: ${formatRupiah(e.arrearsAmount)}',
              key: const Key('billing-arrears'),
              style: Theme.of(context).textTheme.titleMedium),
          if (onPay != null)
            Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton(
                    onPressed: onPay, child: const Text('Lihat pembayaran'))),
        ]));
  }
}

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard(
      {super.key,
      required this.wallet,
      this.title = 'Saldo uang digital',
      this.personal = true});
  final WalletSummary wallet;
  final String title;
  final bool personal;
  @override
  Widget build(BuildContext context) => FinanceSection(
      title: title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatRupiah(wallet.available),
                key: const Key('wallet-available'),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold))),
        Text(personal ? 'Tersedia untuk pembayaran' : 'Saldo tercatat'),
        if (personal) ...[
          const Divider(height: 28),
          Wrap(spacing: 24, runSpacing: 12, children: [
            _balance('Cadangan paket', wallet.packageReserve),
            _balance('Ditahan pencairan', wallet.payoutHold),
            _balance('Total milik Anda', wallet.total),
          ]),
          const SizedBox(height: 12),
          const Text(
              'Cadangan dan dana ditahan termasuk total, tetapi tidak dapat dibelanjakan. Saldo rupiah terpisah dari poin prestasi.'),
        ] else
          const FinanceMessage(
              'Dana ini terpisah dari saldo pribadi. Riwayat memuat penerimaan dan sumber transaksi sesuai kewenangan.'),
      ]));
  Widget _balance(String label, int amount) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label),
        Text(formatRupiah(amount),
            style: const TextStyle(fontWeight: FontWeight.w600))
      ]);
}

class FinancePager extends StatelessWidget {
  const FinancePager(
      {super.key,
      required this.page,
      required this.lastPage,
      required this.onPage});
  final int page, lastPage;
  final ValueChanged<int> onPage;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconButton(
            tooltip: 'Halaman sebelumnya',
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left)),
        Text('$page / $lastPage'),
        IconButton(
            tooltip: 'Halaman berikutnya',
            onPressed: page < lastPage ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right)),
      ]);
}

Future<void> openPaymentProof(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return;
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Bukti belum dapat dibuka. Muat ulang untuk memperbarui tautan.')));
  }
}

class FinanceEntryCard extends StatelessWidget {
  const FinanceEntryCard({super.key, this.communityId, this.platform = false});
  final String? communityId;
  final bool platform;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          key: const Key('finance-entry'),
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: Text(communityId == null
              ? 'Saldo & top up'
              : 'Keanggotaan & pembayaran'),
          subtitle: Text(communityId == null
              ? 'Saldo tersedia, dana terikat, dan riwayat'
              : 'Masa aktif, tunggakan, iuran, dan top up'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(communityId == null
              ? AppRoutes.wallet
              : '${AppRoutes.communityBilling(communityId!)}${platform ? '?scope=platform' : ''}')));
}
