import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'training_providers.dart';

/// Read a WIB wall-clock without depending on the browser/device timezone.
DateTime? trainingWibInput(String value) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$')
      .firstMatch(value.trim());
  if (m == null) return null;
  final parts = [for (var i = 1; i <= 5; i++) int.parse(m.group(i)!)];
  final date = DateTime.utc(parts[0], parts[1], parts[2], parts[3], parts[4]);
  if (date.year != parts[0] ||
      date.month != parts[1] ||
      date.day != parts[2] ||
      date.hour != parts[3] ||
      date.minute != parts[4]) {
    return null;
  }
  return date.subtract(const Duration(hours: 7));
}

String trainingWibEdit(DateTime date) {
  final d = date.toUtc().add(const Duration(hours: 7));
  String z(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${z(d.month)}-${z(d.day)} ${z(d.hour)}:${z(d.minute)}';
}

class TrainingSessionScreen extends ConsumerStatefulWidget {
  const TrainingSessionScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<TrainingSessionScreen> createState() =>
      _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends ConsumerState<TrainingSessionScreen> {
  final _form = GlobalKey<FormState>(), _title = TextEditingController();
  final _start = TextEditingController(text: trainingWibEdit(DateTime.now())),
      _end = TextEditingController(
          text: trainingWibEdit(DateTime.now().add(const Duration(hours: 2))));
  String? _location, _error, _signature;
  String _key = financeRequestId();
  bool _busy = false;
  @override
  void dispose() {
    _title.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final start = trainingWibInput(_start.text)!,
        end = trainingWibInput(_end.text)!;
    if (!end.isAfter(start) ||
        end.difference(start) > const Duration(hours: 24)) {
      setState(() => _error =
          'Sesi harus berakhir setelah waktu mulai dan berdurasi maksimal 24 jam.');
      return;
    }
    final signature = '${_title.text.trim()}:$_location:$start:$end';
    if (_signature != signature) {
      _signature = signature;
      _key = financeRequestId();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(trainingRepositoryProvider)
          .createSession(widget.communityId, {
        'title': _title.text.trim(),
        'location_id': int.parse(_location!),
        'starts_at': start.toIso8601String(),
        'ends_at': end.toIso8601String(),
        'idempotency_key': _key
      });
      if (!mounted) return;
      ref.invalidate(trainingOverviewProvider(widget.communityId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Sesi latihan tersimpan. Absensi dapat dikonfirmasi saat sesi berlangsung.')));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = trainingOverviewProvider(widget.communityId);
    return Scaffold(
        appBar: AppBar(title: const Text('Buat sesi latihan')),
        body: ref.watch(p).when(
            skipLoadingOnRefresh: false,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (o) {
              if (!o.canConfirm) {
                return const FinanceBody(children: [
                  FinanceMessage(
                      'Hanya petugas komunitas atau pengelola berwenang yang dapat membuat sesi.')
                ]);
              }
              final locations =
                  o.locations.where((l) => l.active && l.canConfirm).toList();
              return FinanceBody(children: [
                const FinanceMessage(
                    'Waktu memakai WIB. Check-in dan konfirmasi hanya saat sesi berlangsung. Satu anggota hanya boleh memiliki satu absensi per sesi.'),
                if (locations.isEmpty)
                  const FinanceMessage(
                      'Belum ada lokasi aktif yang dapat Anda kelola. Pendiri dapat mengatur lokasi dan pengelolanya.'),
                Form(
                    key: _form,
                    child: FinanceSection(
                        title: 'Jadwal & lokasi',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                  key: const Key('training-session-title'),
                                  controller: _title,
                                  enabled: !_busy,
                                  maxLength: 150,
                                  decoration: const InputDecoration(
                                      labelText: 'Judul latihan'),
                                  validator: (v) => (v?.trim().isEmpty ?? true)
                                      ? 'Isi judul latihan.'
                                      : null),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                  key: const Key('training-session-location'),
                                  initialValue: _location,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Lokasi komunitas ini'),
                                  items: [
                                    for (final l in locations)
                                      DropdownMenuItem(
                                          value: l.id,
                                          child: Text(l.name,
                                              overflow: TextOverflow.ellipsis))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() => _location = v),
                                  validator: (v) =>
                                      v == null ? 'Pilih lokasi aktif.' : null),
                              const SizedBox(height: 16),
                              for (final (controller, label, key) in [
                                (_start, 'Mulai WIB', 'start'),
                                (_end, 'Selesai WIB', 'end')
                              ])
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: TextFormField(
                                        key: Key('training-session-$key'),
                                        controller: controller,
                                        enabled: !_busy,
                                        keyboardType: TextInputType.datetime,
                                        decoration: InputDecoration(
                                            labelText: label,
                                            helperMaxLines: 3,
                                            helperText:
                                                'YYYY-MM-DD HH:mm · contoh 2026-11-26 16:00'),
                                        validator: (v) => trainingWibInput(
                                                    v ?? '') ==
                                                null
                                            ? 'Isi tanggal dan jam WIB yang valid.'
                                            : null)),
                              if (_error != null)
                                FinanceMessage(_error!, error: true),
                              FilledButton(
                                  key: const Key('training-save-session'),
                                  onPressed:
                                      _busy || locations.isEmpty || !o.active
                                          ? null
                                          : _save,
                                  child: Text(
                                      _busy ? 'Menyimpan…' : 'Simpan sesi')),
                            ]))),
              ]);
            }));
  }
}
