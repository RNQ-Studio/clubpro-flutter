import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/domain/finance.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/training.dart';
import 'training_providers.dart';

class TrainingSettingsScreen extends ConsumerStatefulWidget {
  const TrainingSettingsScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<TrainingSettingsScreen> createState() =>
      _TrainingSettingsScreenState();
}

class _TrainingSettingsScreenState
    extends ConsumerState<TrainingSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _prices = {
    for (final n in [7, 14, 21]) n: TextEditingController()
  };
  int? _version;
  bool _enabled = false, _busy = false, _stale = false;
  String? _error, _success;
  @override
  void dispose() {
    for (final c in _prices.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _stale || !_form.currentState!.validate()) return;
    final p7 = int.parse(_prices[7]!.text),
        p14 = int.parse(_prices[14]!.text),
        p21 = int.parse(_prices[21]!.text);
    if (p14 * 7 >= p7 * 14 || p21 * 14 >= p14 * 21) {
      setState(() => _error =
          'Biaya per sesi paket 14 harus lebih murah dari 7, dan paket 21 lebih murah dari 14.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await ref
          .read(trainingRepositoryProvider)
          .saveCatalog(widget.communityId, {
        'expected_version': _version,
        'enabled': _enabled,
        'packages': [
          for (final n in [7, 14, 21])
            {'sessions': n, 'price': int.parse(_prices[n]!.text)}
        ]
      });
      if (!mounted) return;
      _version = null;
      ref.invalidate(trainingOverviewProvider(widget.communityId));
      setState(() => _success =
          'Katalog tersimpan. Pembelian lama tetap memakai harga dan kuota aslinya.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = financeErrorMessage(e);
          _stale = e is FinanceConflictException;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = trainingOverviewProvider(widget.communityId);
    return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan latihan')),
        body: ref.watch(p).when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (o) {
              if (!o.canConfigure) {
                return const FinanceBody(children: [
                  FinanceMessage(
                      'Hanya pendiri komunitas yang dapat mengubah harga, penerima dan nominal pembagian.')
                ]);
              }
              if (_version == null) {
                _version = o.catalog.version;
                _enabled = o.catalog.enabled;
                for (final n in [7, 14, 21]) {
                  _prices[n]!.text = o.catalog.packages
                          .where((p) => p.sessions == n)
                          .firstOrNull
                          ?.price
                          .toString() ??
                      '';
                }
              }
              return FinanceBody(children: [
                const FinanceMessage(
                    'Pendiri menetapkan harga dan pembagian nominal. Admin tidak dapat mengganti aturan ini. Harga paket baru tidak mengubah pembelian lama.'),
                FinanceSection(
                    title: 'Katalog paket 7 / 14 / 21',
                    child: Form(
                        key: _form,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Aktifkan penjualan paket'),
                                  value: _enabled,
                                  onChanged: _busy || _stale
                                      ? null
                                      : (v) => setState(() => _enabled = v)),
                              for (final n in [7, 14, 21])
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: RupiahField(
                                        key: Key('training-price-$n'),
                                        controller: _prices[n]!,
                                        label: 'Harga paket $n latihan',
                                        enabled: !_busy && !_stale)),
                              const Text(
                                  'Paket lebih besar harus lebih murah per sesi. Alokasi N−1 sesi dibulatkan ke bawah; sisa rupiah masuk sesi terakhir. Paket tanpa kedaluwarsa.'),
                              if (_error != null)
                                FinanceMessage(_error!, error: true),
                              if (_success != null) FinanceMessage(_success!),
                              if (_stale)
                                OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _version = null;
                                        _stale = false;
                                        _error = null;
                                      });
                                      ref.invalidate(p);
                                    },
                                    child: const Text(
                                        'Muat ulang aturan terbaru')),
                              const SizedBox(height: 16),
                              FilledButton(
                                  key: const Key('training-save-catalog'),
                                  onPressed: _busy || _stale ? null : _save,
                                  child: Text(
                                      _busy ? 'Menyimpan…' : 'Simpan katalog')),
                            ]))),
                FinanceSection(
                    title: 'Lokasi & pembagian per sesi',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                              'Pilih penerima dari komunitas ini dengan nominal rupiah. Total pembagian tidak boleh melebihi nilai sesi termurah, termasuk paket lama yang masih tersisa. Sisa masuk kas komunitas; penerima yang tidak dipilih memperoleh Rp0.'),
                          const SizedBox(height: 12),
                          for (final l in o.locations)
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(l.name),
                                subtitle: Text(
                                    '${l.active ? 'Aktif' : 'Nonaktif'} · pembagian ${formatRupiah(l.splitTotal)} per sesi'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _busy
                                    ? null
                                    : () => context.push(
                                        AppRoutes.trainingLocation(
                                            widget.communityId, l.id))),
                          OutlinedButton.icon(
                              key: const Key('training-add-location'),
                              onPressed: _busy
                                  ? null
                                  : () => context.push(
                                      AppRoutes.trainingNewLocation(
                                          widget.communityId)),
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('Tambah lokasi')),
                        ])),
              ]);
            }));
  }
}

class TrainingLocationScreen extends ConsumerStatefulWidget {
  const TrainingLocationScreen(
      {super.key, required this.communityId, this.locationId});
  final String communityId;
  final String? locationId;
  @override
  ConsumerState<TrainingLocationScreen> createState() =>
      _TrainingLocationScreenState();
}

class _TrainingLocationScreenState
    extends ConsumerState<TrainingLocationScreen> {
  final _form = GlobalKey<FormState>(),
      _name = TextEditingController(),
      _address = TextEditingController();
  final _splitControllers = <String, TextEditingController>{};
  final _managerIds = <String>{}, _recipientIds = <String>{};
  final _removedNames = <String>[];
  bool _initialized = false, _active = true, _busy = false, _stale = false;
  int _version = 0;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    for (final c in _splitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initialize(TrainingOverview o, TrainingLocation? location) {
    _initialized = true;
    _name.text = location?.name ?? '';
    _address.text = location?.address ?? '';
    _active = location?.active ?? true;
    _version = location?.version ?? 0;
    final validManagers =
        o.members.where((m) => m.canManage).map((m) => m.id).toSet();
    final validRecipients = o.members.map((m) => m.id).toSet();
    _removedNames.clear();
    for (final id in location?.managerIds ?? <String>[]) {
      if (!validManagers.contains(id)) _removedNames.add('Pengelola #$id');
    }
    for (final split in location?.splits ?? <TrainingSplit>[]) {
      if (!validRecipients.contains(split.memberId)) {
        _removedNames.add(split.name);
      }
    }
    _managerIds
      ..clear()
      ..addAll((location?.managerIds ?? []).where(validManagers.contains));
    _recipientIds
      ..clear()
      ..addAll((location?.splits ?? [])
          .map((s) => s.memberId)
          .where(validRecipients.contains));
    for (final m in o.members) {
      _splitControllers.putIfAbsent(m.id, TextEditingController.new).text =
          location?.splits
                  .where((s) => s.memberId == m.id)
                  .firstOrNull
                  ?.amount
                  .toString() ??
              '0';
    }
  }

  Future<void> _save() async {
    if (_busy || _stale || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(trainingRepositoryProvider)
          .saveLocation(widget.communityId, widget.locationId, {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'active': _active,
        'manager_member_ids': [for (final id in _managerIds) int.parse(id)],
        'splits': [
          for (final id in _recipientIds)
            {
              'member_id': int.parse(id),
              'amount': int.parse(_splitControllers[id]!.text)
            }
        ],
        if (widget.locationId != null) 'expected_version': _version
      });
      if (!mounted) return;
      ref.invalidate(trainingOverviewProvider(widget.communityId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Lokasi dan pembagian tersimpan untuk konfirmasi berikutnya.')));
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = financeErrorMessage(e);
          _stale = e is FinanceConflictException;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = trainingOverviewProvider(widget.communityId);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.locationId == null
                ? 'Tambah lokasi latihan'
                : 'Lokasi & pembagian')),
        body: ref.watch(p).when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (o) {
              if (!o.canConfigure) {
                return const FinanceBody(children: [
                  FinanceMessage(
                      'Hanya pendiri komunitas yang dapat mengatur lokasi dan pembagian.')
                ]);
              }
              final l = o.locations
                  .where((l) => l.id == widget.locationId)
                  .firstOrNull;
              if (widget.locationId != null && l == null) {
                return const FinanceBody(children: [
                  FinanceMessage(
                      'Lokasi tidak ditemukan. Kembali lalu muat ulang.')
                ]);
              }
              if (!_initialized) _initialize(o, l);
              final recipients = o.members;
              return FinanceBody(children: [
                if (_removedNames.isNotEmpty)
                  FinanceMessage(
                      'Penugasan tidak lagi memenuhi syarat dan akan dihapus saat Anda menyimpan: ${_removedNames.join(', ')}. Histori sebelumnya tetap tersimpan.'),
                Form(
                    key: _form,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FinanceSection(
                              title: 'Lokasi latihan',
                              child: Column(children: [
                                TextFormField(
                                    key: const Key('training-location-name'),
                                    controller: _name,
                                    enabled: !_busy && !_stale,
                                    maxLength: 150,
                                    decoration: const InputDecoration(
                                        labelText: 'Nama lokasi'),
                                    validator: (v) =>
                                        (v?.trim().isEmpty ?? true)
                                            ? 'Isi nama lokasi.'
                                            : null),
                                TextFormField(
                                    key: const Key('training-location-address'),
                                    controller: _address,
                                    enabled: !_busy && !_stale,
                                    maxLength: 500,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                        labelText: 'Alamat lokasi')),
                                SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Lokasi aktif'),
                                    value: _active,
                                    onChanged: _busy || _stale
                                        ? null
                                        : (v) => setState(() => _active = v)),
                              ])),
                          FinanceSection(
                              title: 'Pengelola lokasi',
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                        'Penugasan khusus komunitas ini; hanya pendiri, admin, pengurus atau pelatih aktif. Pengelola dapat membuat sesi, mengonfirmasi dan melihat pendapatan lokasi sesuai izin.'),
                                    for (final m
                                        in recipients.where((m) => m.canManage))
                                      CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(m.name),
                                          value: _managerIds.contains(m.id),
                                          onChanged: _busy || _stale
                                              ? null
                                              : (v) => setState(() {
                                                    if (v == true) {
                                                      _managerIds.add(m.id);
                                                    } else {
                                                      _managerIds.remove(m.id);
                                                    }
                                                  })),
                                  ])),
                          FinanceSection(
                              title: 'Penerima & nominal per sesi',
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                        'Pembagian menggunakan nominal, tanpa persentase atau komisi platform. Penerima tidak dipilih mendapat Rp0. Sisa nilai sesi masuk kas komunitas. Histori yang sudah dikonfirmasi tidak berubah.'),
                                    for (final m in recipients) ...[
                                      CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          key:
                                              Key('training-recipient-${m.id}'),
                                          title: Text(m.name),
                                          value: _recipientIds.contains(m.id),
                                          onChanged: _busy || _stale
                                              ? null
                                              : (v) => setState(() {
                                                    if (v == true) {
                                                      _recipientIds.add(m.id);
                                                    } else {
                                                      _recipientIds
                                                          .remove(m.id);
                                                    }
                                                  })),
                                      if (_recipientIds.contains(m.id))
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: RupiahField(
                                                key: Key(
                                                    'training-split-${m.id}'),
                                                controller:
                                                    _splitControllers[m.id]!,
                                                label: 'Bagian ${m.name}',
                                                zero: true,
                                                enabled: !_busy && !_stale)),
                                    ],
                                    if (recipients.isEmpty)
                                      const FinanceMessage(
                                          'Belum ada anggota aktif yang dapat ditugaskan sebagai penerima.'),
                                  ])),
                          if (_error != null)
                            FinanceMessage(_error!, error: true),
                          if (_stale)
                            OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _initialized = false;
                                    _stale = false;
                                    _error = null;
                                  });
                                  ref.invalidate(p);
                                },
                                child: const Text('Muat ulang aturan terbaru')),
                          FilledButton(
                              key: const Key('training-save-location'),
                              onPressed: _busy || _stale ? null : _save,
                              child: Text(_busy
                                  ? 'Menyimpan…'
                                  : 'Simpan lokasi & pembagian')),
                        ]))
              ]);
            }));
  }
}
