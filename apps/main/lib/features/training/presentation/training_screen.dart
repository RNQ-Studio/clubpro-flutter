import 'package:core/core.dart';
import '../../achievements/presentation/achievements_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/domain/finance.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/training.dart';
import 'training_providers.dart';

class TrainingEntryCard extends StatelessWidget {
  const TrainingEntryCard({super.key, required this.communityId});
  final String communityId;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          key: const Key('training-entry'),
          leading: const Icon(Icons.sports_outlined),
          title: const Text('Paket & latihan'),
          subtitle: const Text('Jatah, lokasi, absensi dan pendapatan'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.communityTraining(communityId))));
}

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  String _tab = 'packages';
  bool _busy = false, _dialog = false;
  bool get _locked => _busy || _dialog;
  String? _error, _success;
  bool _purchaseFailure = false;
  final Map<String, String> _keys = {};
  String _key(String action) => _keys.putIfAbsent(action, financeRequestId);
  void _refresh() {
    ref.invalidate(trainingOverviewProvider(widget.communityId));
    ref.invalidate(trainingReportProvider);
    invalidateFinance(ref.invalidate);
    invalidateAchievements(ref.invalidate);
  }

  Future<void> _action(
      String action, Future<void> Function(String) send, String success) async {
    if (_locked) return;
    setState(() {
      _busy = true;
      _error = null;
      _purchaseFailure = false;
      _success = null;
    });
    try {
      await send(_key(action));
      if (!mounted) return;
      _keys.remove(action);
      _refresh();
      setState(() => _success = success);
    } catch (e) {
      if (e is FinanceConflictException) _refresh();
      if (mounted) {
        setState(() {
          _error = financeErrorMessage(e);
          _purchaseFailure = action.startsWith('buy:');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(TrainingOverview overview, TrainingPackage package) async {
    if (_locked) return;
    setState(() => _dialog = true);
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text('Beli paket ${package.sessions} latihan?'),
                content: Text(
                    '${formatRupiah(package.price)} dipindahkan sekali dari saldo tersedia ke cadangan paket. Absensi menggunakan cadangan ini tanpa debit saldo kedua. Paket tanpa kedaluwarsa, berlaku di lokasi komunitas ini. Pembelian final tidak menyediakan refund.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Kembali')),
                  FilledButton(
                      key: const Key('training-buy-confirm'),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Beli dari saldo'))
                ]));
    if (!mounted) return;
    setState(() => _dialog = false);
    if (ok != true) return;
    await _action(
        'buy:${overview.catalog.version}:${package.sessions}:${package.price}',
        (key) => ref.read(trainingRepositoryProvider).purchase(
            widget.communityId, package, overview.catalog.version, key),
        'Paket berhasil dibeli. Dana dicadangkan sekali; jatah siap digunakan.');
  }

  Future<void> _confirm(TrainingOverview overview, TrainingSession session,
      {TrainingAttendance? pending}) async {
    if (_locked) return;
    setState(() => _dialog = true);
    String? memberId = pending?.memberId;
    final agreed = await showDialog<bool>(
        context: context,
        builder: (c) => StatefulBuilder(
            builder: (c, set) => AlertDialog(
                    title: const Text('Konfirmasi kehadiran'),
                    content: SizedBox(
                        width: 480,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${session.title} · ${session.locationName}'),
                              const SizedBox(height: 12),
                              if (pending != null)
                                Text(pending.memberName)
                              else
                                DropdownButtonFormField<String>(
                                    key: const Key('training-confirm-member'),
                                    initialValue: memberId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                        labelText: 'Anggota yang hadir'),
                                    items: [
                                      for (final m in overview.members)
                                        DropdownMenuItem(
                                            value: m.id,
                                            child: Text(m.name,
                                                overflow:
                                                    TextOverflow.ellipsis))
                                    ],
                                    onChanged: (v) => set(() => memberId = v)),
                              const SizedBox(height: 12),
                              const Text(
                                  'Satu jatah paket tertua yang masih tersedia akan digunakan. Pembagian memakai aturan lokasi saat konfirmasi. Saldo tersedia atlet tidak dipotong lagi.'),
                            ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Kembali')),
                      FilledButton(
                          key: const Key('training-confirm-submit'),
                          onPressed: memberId == null
                              ? null
                              : () => Navigator.pop(c, true),
                          child: const Text('Konfirmasi hadir'))
                    ])));
    if (!mounted) return;
    setState(() => _dialog = false);
    if (agreed != true || memberId == null) return;
    await _action(
        'confirm:${session.id}:$memberId',
        (key) => ref
            .read(trainingRepositoryProvider)
            .confirm(widget.communityId, session.id, memberId!, key),
        'Kehadiran terkonfirmasi. Satu jatah dan dana cadangan dialokasikan; saldo tersedia atlet tetap.');
  }

  Future<void> _detail(TrainingAttendance attendance, bool canCorrect) async {
    if (_locked) return;
    setState(() => _dialog = true);
    final result = await showDialog<String>(
        context: context,
        builder: (c) =>
            AttendanceDialog(attendance: attendance, canCorrect: canCorrect));
    if (!mounted) return;
    setState(() => _dialog = false);
    if (result == null) return;
    await _action(
        'correct:${attendance.id}:$result',
        (key) => ref
            .read(trainingRepositoryProvider)
            .correct(widget.communityId, attendance.id, result, key),
        'Koreksi teknis tercatat. Jatah dan cadangan paket dipulihkan; histori tetap tersimpan.');
  }

  @override
  Widget build(BuildContext context) {
    final p = trainingOverviewProvider(widget.communityId),
        value = ref.watch(p);
    return Scaffold(
        appBar: AppBar(title: const Text('Paket & latihan'), actions: [
          IconButton(
              tooltip: 'Segarkan latihan',
              onPressed: _locked ? null : _refresh,
              icon: const Icon(Icons.refresh))
        ]),
        body: value.when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (o) => FinanceBody(children: [
                  Text(o.communityName,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final (key, label) in [
                      ('packages', 'Paket'),
                      ('sessions', 'Latihan'),
                      ('history', 'Riwayat'),
                      ('locations', 'Lokasi')
                    ])
                      ChoiceChip(
                          label: Text(label),
                          selected: _tab == key,
                          onSelected:
                              _busy ? null : (_) => setState(() => _tab = key)),
                  ]),
                  if (!o.active) ...[
                    const FinanceMessage(
                        'Keanggotaan atau komunitas belum aktif. Jatah dan dana paket tetap tersimpan; pembelian dan absensi menunggu masa aktif.'),
                    OutlinedButton(
                        onPressed: () => context.push(
                            AppRoutes.communityBilling(widget.communityId)),
                        child: const Text('Keanggotaan & pembayaran')),
                  ],
                  if (_error != null) ...[
                    FinanceMessage(_error!, error: true),
                    if (_purchaseFailure &&
                        _error!.toLowerCase().contains('saldo'))
                      TextButton(
                          onPressed: () => context.push(
                              '${AppRoutes.topup}?community=${widget.communityId}'),
                          child: const Text('Top up saldo'))
                  ],
                  if (_success != null) FinanceMessage(_success!),
                  if (_busy) const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  if (_tab == 'packages') ..._packages(o),
                  if (_tab == 'sessions') ..._sessions(o),
                  if (_tab == 'history') ..._history(o),
                  if (_tab == 'locations') ..._locations(o),
                  if (o.canConfigure || o.canReport) ...[
                    const Divider(height: 32),
                    Wrap(spacing: 12, runSpacing: 8, children: [
                      if (o.canConfigure)
                        OutlinedButton.icon(
                            key: const Key('training-settings'),
                            onPressed: _locked
                                ? null
                                : () => context.push(AppRoutes.trainingSettings(
                                    widget.communityId)),
                            icon: const Icon(Icons.tune),
                            label: const Text('Pengaturan pendiri')),
                      if (o.canReport)
                        OutlinedButton.icon(
                            key: const Key('training-report'),
                            onPressed: _locked
                                ? null
                                : () => context.push(AppRoutes.trainingReport(
                                    widget.communityId)),
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text('Laporan pendapatan')),
                    ])
                  ],
                ])));
  }

  List<Widget> _packages(TrainingOverview o) => [
        const FinanceMessage(
            'Tanpa kedaluwarsa. Paket dibeli paling awal digunakan lebih dulu, hanya di komunitas ini. Harga dan kuota tersimpan saat beli; pembagian lokasi tersimpan saat konfirmasi hadir.'),
        if (!o.catalog.enabled)
          const FinanceMessage('Penjualan paket belum diaktifkan pendiri.'),
        for (final package in o.catalog.packages)
          FinanceSection(
              title: 'Paket ${package.sessions} latihan',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(formatRupiah(package.price),
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                        '${formatRupiah(package.sessionFloor)} per sesi; sesi terakhir ${formatRupiah(package.sessionLast)}.'),
                    const SizedBox(height: 12),
                    FilledButton(
                        key: Key('training-buy-${package.sessions}'),
                        onPressed: _locked || !o.active || !o.catalog.enabled
                            ? null
                            : () => _buy(o, package),
                        child: const Text('Beli paket')),
                  ])),
        Text('Paket milik Anda', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (o.purchases.isEmpty)
          const FinanceMessage(
              'Belum ada paket dibeli. Pilih paket untuk mulai latihan.'),
        for (final p in o.purchases) PurchaseCard(purchase: p),
      ];
  List<Widget> _sessions(TrainingOverview o) => [
        const FinanceMessage(
            'Check-in sendiri hanya permintaan hadir. Pelatih, pengurus, admin atau pengelola berwenang mengonfirmasi saat sesi berlangsung. Konfirmasi mengurangi satu jatah dan membagi cadangan, tanpa debit saldo lagi.'),
        if (o.canConfirm)
          OutlinedButton.icon(
              key: const Key('training-new-session'),
              onPressed: _locked
                  ? null
                  : () => context
                      .push(AppRoutes.trainingNewSession(widget.communityId)),
              icon: const Icon(Icons.add),
              label: const Text('Buat sesi latihan')),
        if (o.sessions.isEmpty)
          const FinanceMessage(
              'Belum ada sesi latihan. Sesi dibuat petugas komunitas.'),
        for (final s in o.sessions) _sessionCard(o, s),
      ];
  Widget _sessionCard(TrainingOverview o, TrainingSession s) {
    final locationActive =
        o.locations.any((l) => l.id == s.locationId && l.active);
    final own = o.attendances
        .where((a) => a.sessionId == s.id && a.memberId == o.selfMemberId)
        .firstOrNull;
    return FinanceSection(
        title: s.title,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(s.locationName),
          Text('${financeDate(s.startsAt)} – ${financeDate(s.endsAt)}'),
          Text(!locationActive
              ? 'Lokasi tidak aktif; absensi tidak tersedia.'
              : s.isOpen
                  ? 'Sesi sedang berlangsung'
                  : 'Check-in dan konfirmasi tersedia selama waktu sesi.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(
                key: Key('training-checkin-${s.id}'),
                onPressed: _locked ||
                        !o.active ||
                        !s.isOpen ||
                        !locationActive ||
                        own != null
                    ? null
                    : () => _action(
                        'checkin:${s.id}',
                        (key) => ref
                            .read(trainingRepositoryProvider)
                            .checkIn(widget.communityId, s.id, key),
                        'Check-in tercatat, menunggu konfirmasi petugas. Jatah dan dana belum berubah.'),
                child: Text(own?.statusLabel ?? 'Check-in saya')),
            if (s.canConfirm)
              FilledButton(
                  key: Key('training-confirm-${s.id}'),
                  onPressed: _locked ||
                          !o.active ||
                          !s.isOpen ||
                          !locationActive ||
                          o.members.isEmpty
                      ? null
                      : () => _confirm(o, s),
                  child: const Text('Konfirmasi anggota')),
          ]),
          for (final a in o.attendances
              .where((a) => a.sessionId == s.id && a.status == 'pending'))
            ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.memberName),
                subtitle: Text(a.statusLabel),
                trailing: s.canConfirm
                    ? TextButton(
                        onPressed:
                            _busy || !s.isOpen || !locationActive || !o.active
                                ? null
                                : () => _confirm(o, s, pending: a),
                        child: const Text('Konfirmasi'))
                    : null),
        ]));
  }

  List<Widget> _history(TrainingOverview o) => [
        const FinanceMessage(
            'Pembelian final tidak menyediakan refund. Koreksi teknis oleh pendiri dipulihkan ke cadangan dan jatah, disertai alasan; histori keuangan dipertahankan.'),
        if (o.attendances.isEmpty)
          const FinanceMessage('Belum ada riwayat absensi.'),
        for (final a in o.attendances)
          AttendanceCard(
              attendance: a,
              onTap: () =>
                  _detail(a, o.canConfigure && a.status == 'confirmed')),
        const SizedBox(height: 12),
        Text('Riwayat pembelian',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (o.purchases.isEmpty)
          const FinanceMessage('Belum ada riwayat pembelian.'),
        for (final p in o.purchases) PurchaseCard(purchase: p),
      ];
  List<Widget> _locations(TrainingOverview o) => [
        const FinanceMessage(
            'Paket berlaku di lokasi aktif komunitas ini. Penerima memakai nominal rupiah per sesi. Sisa alokasi masuk kas komunitas; platform tidak mengambil komisi latihan.'),
        if (o.canConfigure)
          OutlinedButton.icon(
              onPressed: _locked
                  ? null
                  : () => context
                      .push(AppRoutes.trainingNewLocation(widget.communityId)),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Tambah lokasi')),
        if (o.locations.isEmpty)
          const FinanceMessage('Belum ada lokasi latihan.'),
        for (final l in o.locations)
          FinanceSection(
              title: l.name,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.address),
                    Text(l.active ? 'Lokasi aktif' : 'Lokasi dinonaktifkan'),
                    if (l.splits.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final s in l.splits)
                        Text('${s.name}: ${formatRupiah(s.amount)} per sesi'),
                      const Text(
                          'Penerima yang tidak dicantumkan memperoleh Rp0.'),
                    ],
                    if (o.canConfigure)
                      TextButton(
                          onPressed: _locked
                              ? null
                              : () => context.push(AppRoutes.trainingLocation(
                                  widget.communityId, l.id)),
                          child: const Text('Atur lokasi & pembagian')),
                  ])),
      ];
}

class PurchaseCard extends StatelessWidget {
  const PurchaseCard({super.key, required this.purchase});
  final TrainingPurchase purchase;
  @override
  Widget build(BuildContext context) => FinanceSection(
      title:
          'Paket ${purchase.sessions} · sisa ${purchase.remainingSessions} latihan',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dibeli ${financeDate(purchase.createdAt)}'),
        Text('Harga tersimpan ${formatRupiah(purchase.price)}'),
        Text(
            'Terpakai ${purchase.usedSessions} · cadangan tersisa ${formatRupiah(purchase.remainingAmount)}'),
        const SizedBox(height: 6),
        SelectableText('Pembelian: ${purchase.id}',
            style: Theme.of(context).textTheme.bodySmall),
        if (purchase.journalId.isNotEmpty)
          SelectableText('Transaksi: ${purchase.journalId}',
              style: Theme.of(context).textTheme.bodySmall),
      ]));
}

class AttendanceCard extends StatelessWidget {
  const AttendanceCard(
      {super.key, required this.attendance, required this.onTap});
  final TrainingAttendance attendance;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          key: Key('attendance-${attendance.id}'),
          onTap: onTap,
          title: Text('${attendance.memberName} · ${attendance.sessionTitle}'),
          subtitle: Text(
              '${attendance.locationName}\n${financeDate(attendance.confirmedAt.isEmpty ? attendance.createdAt : attendance.confirmedAt)}\n${attendance.statusLabel} · ${formatRupiah(attendance.allocation)}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right)));
}

class AttendanceDialog extends StatefulWidget {
  const AttendanceDialog(
      {super.key, required this.attendance, this.canCorrect = false});
  final TrainingAttendance attendance;
  final bool canCorrect;
  @override
  State<AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  final _reason = TextEditingController(), _form = GlobalKey<FormState>();
  bool _correcting = false;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attendance;
    return AlertDialog(
        title: const Text('Rincian absensi'),
        content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text('${a.memberName} · ${a.sessionTitle}'),
                  Text(a.locationName),
                  Text(a.statusLabel),
                  Text('Diajukan ${financeDate(a.createdAt)}'),
                  if (a.confirmedAt.isNotEmpty)
                    Text(
                        'Dikonfirmasi ${financeDate(a.confirmedAt)} oleh ${a.confirmedBy}'),
                  Text('Alokasi sesi ${formatRupiah(a.allocation)}'),
                  const SizedBox(height: 12),
                  if (a.snapshot.isNotEmpty) ...[
                    const Text('Pembagian tersimpan saat konfirmasi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...snapshotWidgets(a.snapshot),
                  ],
                  const Divider(),
                  SelectableText('Absensi: ${a.id}'),
                  if (a.purchaseId.isNotEmpty)
                    SelectableText('Pembelian: ${a.purchaseId}'),
                  if (a.journalId.isNotEmpty)
                    SelectableText('Transaksi: ${a.journalId}'),
                  if (a.correctionJournalId.isNotEmpty)
                    SelectableText(
                        'Transaksi koreksi: ${a.correctionJournalId}'),
                  if (a.status == 'pending')
                    const Text('Belum ada jatah atau dana yang dipindahkan.'),
                  if (a.correctedAt.isNotEmpty)
                    Text(
                        'Koreksi ${financeDate(a.correctedAt)} oleh ${a.correctedBy}: ${a.correctionReason}'),
                  if (_correcting)
                    Form(
                        key: _form,
                        child: Column(children: [
                          const SizedBox(height: 16),
                          const Text(
                              'Hanya untuk kesalahan teknis. Dana ditarik dari penerima ke cadangan paket dan satu jatah dipulihkan. Jika saldo penerima tidak cukup, seluruh koreksi ditolak tanpa perubahan parsial.'),
                          TextFormField(
                              key: const Key('training-correction-reason'),
                              controller: _reason,
                              maxLength: 1000,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  labelText: 'Alasan koreksi teknis'),
                              validator: (v) => (v?.trim().length ?? 0) < 10
                                  ? 'Jelaskan alasan minimal 10 karakter.'
                                  : null),
                        ])),
                ]))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
          if (widget.canCorrect && !_correcting)
            TextButton(
                key: const Key('training-correct'),
                onPressed: () => setState(() => _correcting = true),
                child: const Text('Koreksi teknis')),
          if (_correcting)
            FilledButton(
                key: const Key('training-correct-submit'),
                onPressed: () {
                  if (_form.currentState!.validate()) {
                    Navigator.pop(context, _reason.text.trim());
                  }
                },
                child: const Text('Catat koreksi'))
        ]);
  }
}

List<Widget> snapshotWidgets(Map<String, Object?> snapshot) {
  final splits =
      snapshot['splits'] ?? snapshot['recipients'] ?? snapshot['allocations'];
  final rows = <Widget>[];
  final purchase = snapshot['purchase'];
  if (purchase is Map &&
      purchase['price'] is int &&
      purchase['sessions'] is int) {
    rows.add(Text(
        'Harga paket tersimpan: ${formatRupiah(purchase['price'] as int)} / ${purchase['sessions']} latihan'));
  }
  if (splits is List) {
    for (final s in splits) {
      if (s is Map) {
        final amount = s['amount'];
        if (amount is int) {
          rows.add(Text(
              '${s['name'] ?? s['recipient_name'] ?? 'Penerima'}: ${formatRupiah(amount)}'));
        }
      }
    }
  }
  final residual = snapshot['residual'] ??
      snapshot['community_amount'] ??
      snapshot['residual_amount'];
  if (residual is int) {
    rows.add(Text('Kas komunitas: ${formatRupiah(residual)}'));
  }
  final version = snapshot['location_version'] ?? snapshot['split_version'];
  if (version != null) rows.add(Text('Versi aturan lokasi: $version'));
  return rows;
}
