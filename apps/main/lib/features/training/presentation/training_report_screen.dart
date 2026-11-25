import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'training_providers.dart';
import 'training_screen.dart';

class TrainingReportScreen extends ConsumerStatefulWidget {
  const TrainingReportScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<TrainingReportScreen> createState() =>
      _TrainingReportScreenState();
}

class _TrainingReportScreenState extends ConsumerState<TrainingReportScreen> {
  final _form = GlobalKey<FormState>(),
      _from = TextEditingController(),
      _to = TextEditingController();
  String? _location,
      _recipient,
      _appliedLocation,
      _appliedRecipient,
      _appliedFrom,
      _appliedTo,
      _filterError;
  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  String? _date(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final text = value.trim(), date = DateTime.tryParse(text);
    return !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
            date == null ||
            date.toIso8601String().substring(0, 10) != text
        ? 'Isi tanggal YYYY-MM-DD yang valid.'
        : null;
  }

  void _apply() {
    if (!_form.currentState!.validate()) return;
    if (_from.text.isNotEmpty &&
        _to.text.isNotEmpty &&
        _from.text.compareTo(_to.text) > 0) {
      setState(() =>
          _filterError = 'Tanggal akhir harus sama atau sesudah tanggal awal.');
      return;
    }
    setState(() {
      _filterError = null;
      _appliedLocation = _location;
      _appliedRecipient = _recipient;
      _appliedFrom = _from.text.trim().isEmpty ? null : _from.text.trim();
      _appliedTo = _to.text.trim().isEmpty ? null : _to.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = trainingReportProvider(widget.communityId,
            locationId: _appliedLocation,
            recipientMemberId: _appliedRecipient,
            from: _appliedFrom,
            to: _appliedTo),
        overview = ref
            .watch(trainingOverviewProvider(widget.communityId))
            .asData
            ?.value;
    return Scaffold(
        appBar: AppBar(title: const Text('Pendapatan latihan'), actions: [
          IconButton(
              tooltip: 'Segarkan laporan',
              onPressed: () => ref.invalidate(p),
              icon: const Icon(Icons.refresh))
        ]),
        body: ref.watch(p).when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (r) => FinanceBody(children: [
                  FinanceSection(
                      title: 'Filter pendapatan',
                      child: Form(
                          key: _form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(r.scope == 'community'
                                    ? 'Seluruh komunitas'
                                    : r.scope == 'managed_locations'
                                        ? 'Hanya lokasi yang Anda kelola'
                                        : 'Hanya pendapatan Anda'),
                                const SizedBox(height: 12),
                                if (overview != null &&
                                    r.scope != 'recipient') ...[
                                  DropdownButtonFormField<String>(
                                      key:
                                          const Key('training-report-location'),
                                      initialValue: _location,
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                          labelText: 'Lokasi'),
                                      items: [
                                        const DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                                'Semua lokasi sesuai izin')),
                                        for (final l in overview.locations)
                                          DropdownMenuItem(
                                              value: l.id,
                                              child: Text(l.name,
                                                  overflow:
                                                      TextOverflow.ellipsis))
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _location = v)),
                                  const SizedBox(height: 12),
                                  if (r.scope == 'community') ...[
                                    DropdownButtonFormField<String>(
                                        key: const Key(
                                            'training-report-recipient'),
                                        initialValue: _recipient,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText: 'Penerima'),
                                        items: [
                                          const DropdownMenuItem(
                                              value: null,
                                              child: Text('Semua penerima')),
                                          for (final m in overview.members)
                                            DropdownMenuItem(
                                                value: m.id,
                                                child: Text(m.name,
                                                    overflow:
                                                        TextOverflow.ellipsis))
                                        ],
                                        onChanged: (v) =>
                                            setState(() => _recipient = v)),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                                for (final (c, label, key) in [
                                  (_from, 'Dari tanggal WIB', 'from'),
                                  (_to, 'Sampai tanggal WIB', 'to')
                                ])
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                          key: Key('training-report-$key'),
                                          controller: c,
                                          decoration: InputDecoration(
                                              labelText: label,
                                              helperText:
                                                  'YYYY-MM-DD · kosong untuk semua tanggal'),
                                          validator: _date)),
                                if (_filterError != null)
                                  FinanceMessage(_filterError!, error: true),
                                OutlinedButton(
                                    key: const Key('training-apply-report'),
                                    onPressed: _apply,
                                    child: const Text('Terapkan filter')),
                              ]))),
                  if (r.purchasedAmount != null &&
                      r.reservedAmount != null) ...[
                    FinanceSection(
                        title: 'Rekonsiliasi seluruh paket',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                  'Posisi seluruh paket komunitas. Filter rincian pendapatan tidak mengubah total rekonsiliasi paket.'),
                              const SizedBox(height: 8),
                              Text(
                                  'Harga dibayar: ${formatRupiah(r.purchasedAmount!)}'),
                              Text(
                                  'Dana masih terikat: ${formatRupiah(r.reservedAmount!)}'),
                              Text(
                                  'Hasil dialokasikan: ${formatRupiah(r.allocatedAmount)}'),
                              Text(
                                  r.balanced == true
                                      ? 'Seimbang: harga dibayar = cadangan + hasil dialokasikan'
                                      : 'Ada selisih yang perlu diperiksa',
                                  key: const Key('training-report-balanced'),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: r.balanced == true
                                          ? Colors.green.shade700
                                          : Theme.of(context)
                                              .colorScheme
                                              .error)),
                              if (r.purchasedSessions != null)
                                Text(
                                    'Jatah dibeli ${r.purchasedSessions} · terpakai ${r.usedSessions} · tersisa ${r.remainingSessions}'),
                              const SizedBox(height: 8),
                              const Text(
                                  'Cadangan belum menjadi pendapatan penerima dan tidak dapat dibelanjakan. Koreksi teknis dipulihkan ke cadangan; jurnal awal tetap tersimpan.'),
                            ])),
                  ] else
                    FinanceSection(
                        title: 'Pendapatan sesuai akses',
                        child: Text(formatRupiah(r.allocatedAmount),
                            style: Theme.of(context).textTheme.headlineSmall)),
                  FinanceSection(
                      title: 'Pendapatan pada filter ini',
                      child: Text(
                          '${formatRupiah(r.filteredAllocatedAmount)} · ${r.filteredAttendanceCount} kehadiran')),
                  if (r.scope != 'recipient')
                    FinanceSection(
                        title: 'Per lokasi',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (r.locations.isEmpty)
                                const Text(
                                    'Belum ada pendapatan lokasi pada filter ini.'),
                              for (final l in r.locations)
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(l.name),
                                    subtitle: Text(
                                        '${l.attendances} kehadiran · ${formatRupiah(l.amount)}')),
                            ])),
                  FinanceSection(
                      title: 'Per penerima',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (r.recipients.isEmpty)
                              const Text(
                                  'Belum ada pembagian pada filter ini.'),
                            for (final recipient in r.recipients)
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(recipient.name),
                                  subtitle:
                                      Text(formatRupiah(recipient.amount))),
                          ])),
                  Text('Rincian kehadiran & transaksi',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (r.scope == 'recipient') ...[
                    const FinanceMessage(
                        'Rincian atlet hanya tersedia bagi petugas berwenang. Riwayat kredit Anda tersedia di Saldo.'),
                    TextButton(
                        onPressed: () => context.push(AppRoutes.wallet),
                        child: const Text('Lihat riwayat saldo')),
                  ] else if (r.attendances.isEmpty)
                    const FinanceMessage('Belum ada absensi pada filter ini.'),
                  for (final a in r.attendances)
                    AttendanceCard(
                        attendance: a,
                        onTap: () => showDialog<void>(
                            context: context,
                            builder: (_) => AttendanceDialog(attendance: a))),
                  if (r.purchases.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Rekonsiliasi per pembelian',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    for (final p in r.purchases) PurchaseCard(purchase: p)
                  ],
                ])));
  }
}
