import 'package:core/core.dart';
import 'package:intl/intl.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/achievements.dart';
import 'achievements_providers.dart';

String achievementPoints(int value) =>
    NumberFormat.decimalPattern('id').format(value);

String achievementType(String value) => switch (value) {
      'training_attendance' => 'Latihan terkonfirmasi',
      'training_purchase' => 'Pembelian paket',
      'participation' => 'Partisipasi kegiatan/lomba',
      'champion' => 'Juara',
      _ => value.contains('correction') ? 'Koreksi prestasi' : value
    };
String achievementGender(String value) => switch (value) {
      'male' => 'Laki-laki',
      'female' => 'Perempuan',
      _ => 'Belum lengkap'
    };

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen(
      {super.key,
      this.communityId,
      this.initialPeriod = 'month',
      this.initialMonth,
      this.initialAsOf,
      this.initialGender,
      this.initialAgeGroup});
  final String? communityId,
      initialMonth,
      initialAsOf,
      initialGender,
      initialAgeGroup;
  final String initialPeriod;
  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  late String _period = ['month', 'all'].contains(widget.initialPeriod)
      ? widget.initialPeriod
      : 'month';
  late final _month = TextEditingController(
          text: widget.initialMonth ?? _today().substring(0, 7)),
      _asOf = TextEditingController(text: widget.initialAsOf ?? _today());
  late String? _gender =
          ['male', 'female', 'unknown'].contains(widget.initialGender)
              ? widget.initialGender
              : null,
      _age = widget.initialAgeGroup;
  int _page = 1;
  static String _today() => DateTime.now()
      .toUtc()
      .add(const Duration(hours: 7))
      .toIso8601String()
      .substring(0, 10);
  @override
  void dispose() {
    _month.dispose();
    _asOf.dispose();
    super.dispose();
  }

  void _apply() {
    final month = _month.text.trim(), asOf = _asOf.text.trim();
    if ((_period == 'month' &&
            !RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) ||
        (_period == 'all' && DateTime.tryParse(asOf) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Isi bulan YYYY-MM atau tanggal acuan YYYY-MM-DD yang valid.')));
      return;
    }
    context.go(Uri(path: AppRoutes.rankings, queryParameters: {
      if (widget.communityId != null) 'community': widget.communityId!,
      'period': _period,
      if (_period == 'month') 'month': month,
      if (_period == 'all') 'as_of': asOf,
      if (_gender != null) 'gender': _gender!,
      if (_age != null) 'age_group': _age!
    }).toString());
    setState(() => _page = 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = rankingsProvider(
        scope: widget.communityId == null ? 'communities' : 'members',
        communityId: widget.communityId,
        period: _period,
        month: _period == 'month' ? _month.text : null,
        asOf: _period == 'all' ? _asOf.text : null,
        gender: _gender,
        ageGroup: _age,
        page: _page);
    final rules = ref.watch(achievementRulesProvider());
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.communityId == null
                ? 'Ranking komunitas'
                : 'Ranking prestasi anggota'),
            actions: [
              IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: () => ref.invalidate(p),
                  icon: const Icon(Icons.refresh))
            ]),
        body: FinanceBody(children: [
          const FinanceMessage(
              'Poin prestasi terpisah dari saldo rupiah. Seri poin mendapat peringkat sama. Poin dihitung sekali pada komunitas asal kegiatan.'),
          Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Periode'),
                    items: const [
                      DropdownMenuItem(
                          value: 'month', child: Text('Bulanan (WIB)')),
                      DropdownMenuItem(value: 'all', child: Text('Semua waktu'))
                    ],
                    onChanged: (v) {
                      setState(() => _period = v!);
                      _apply();
                    })),
            SizedBox(
                width: 220,
                child: TextField(
                    controller: _period == 'month' ? _month : _asOf,
                    decoration: InputDecoration(
                        labelText: _period == 'month'
                            ? 'Bulan (YYYY-MM)'
                            : 'Acuan usia (YYYY-MM-DD)'),
                    onSubmitted: (_) => _apply())),
            SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                    initialValue: _gender ?? '',
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Jenis kelamin'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Semua')),
                      for (final v in ['male', 'female', 'unknown'])
                        DropdownMenuItem(
                            value: v, child: Text(achievementGender(v)))
                    ],
                    onChanged: (v) {
                      setState(() => _gender = v!.isEmpty ? null : v);
                      _apply();
                    })),
            SizedBox(
                width: 220,
                child: rules.when(
                    data: (r) => DropdownButtonFormField<String>(
                        initialValue: r.ageGroups.containsKey(_age) ? _age : '',
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Kategori usia'),
                        items: [
                          const DropdownMenuItem(
                              value: '', child: Text('Semua usia')),
                          for (final e in r.ageGroups.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value))
                        ],
                        onChanged: (v) {
                          setState(() => _age = v!.isEmpty ? null : v);
                          _apply();
                        }),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => FinanceError(
                        error: e,
                        retry: () =>
                            ref.invalidate(achievementRulesProvider())))),
            OutlinedButton(onPressed: _apply, child: const Text('Terapkan'))
          ]),
          const SizedBox(height: 16),
          ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (d) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            'Usia per ${financeDate(d.asOf)} · Aturan v${d.ruleVersion}'),
                        const SizedBox(height: 8),
                        if (d.items.isEmpty)
                          const FinanceMessage(
                              'Belum ada poin sah untuk filter ini.'),
                        for (final row in d.items)
                          Card(
                              child: ListTile(
                                  leading:
                                      CircleAvatar(child: Text('${row.rank}')),
                                  title: Text(row.name),
                                  subtitle: Text([
                                    if (row.communityName.isNotEmpty)
                                      row.communityName,
                                    if (row.gender.isNotEmpty)
                                      achievementGender(row.gender),
                                    if (row.ageGroup.isNotEmpty)
                                      rules.value?.ageGroups[row.ageGroup] ??
                                          row.ageGroup
                                  ].join(' · ')),
                                  trailing: Text(
                                      '${achievementPoints(row.points)}\npoin',
                                      textAlign: TextAlign.right),
                                  onTap: widget.communityId == null &&
                                          row.id.isNotEmpty
                                      ? () => context.push(
                                          '/explore/communities/${row.id}')
                                      : null)),
                        FinancePager(
                            page: d.page,
                            lastPage: d.lastPage,
                            onPage: (v) => setState(() => _page = v))
                      ]))
        ]));
  }
}

class MyAchievementsScreen extends ConsumerStatefulWidget {
  const MyAchievementsScreen({super.key});
  @override
  ConsumerState<MyAchievementsScreen> createState() =>
      _MyAchievementsScreenState();
}

class _MyAchievementsScreenState extends ConsumerState<MyAchievementsScreen> {
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final p = myAchievementsProvider(page: _page);
    return Scaffold(
        appBar: AppBar(title: const Text('Prestasi saya'), actions: [
          IconButton(
              tooltip: 'Muat ulang',
              onPressed: () => ref.invalidate(p),
              icon: const Icon(Icons.refresh))
        ]),
        body: ref.watch(p).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                FinanceError(error: e, retry: () => ref.invalidate(p)),
            data: (d) => FinanceBody(children: [
                  FinanceSection(
                      title: 'Total poin prestasi',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${achievementPoints(d.totalPoints)} poin',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const Text(
                                'Seluruh komunitas, dihitung sekali per sumber sah. Poin ini tidak dapat dicairkan atau dibelanjakan.')
                          ])),
                  if (d.items.isEmpty)
                    const FinanceMessage(
                        'Belum ada poin prestasi. Latihan sah, paket berhasil dan kegiatan tercatat akan tampil di sini.'),
                  for (final r in d.items)
                    Card(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(achievementType(r.type),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  Text(
                                      '${r.points > 0 ? '+' : ''}${achievementPoints(r.points)} poin · ${r.communityName}'),
                                  Text(
                                      '${financeDate(r.occurredAt)} · Aturan v${r.ruleVersion}'),
                                  SelectableText('Sumber: ${r.reference}'),
                                  if (r.actor.isNotEmpty)
                                    Text('Pencatat: ${r.actor}')
                                ]))),
                  FinancePager(
                      page: d.page,
                      lastPage: d.lastPage,
                      onPage: (v) => setState(() => _page = v))
                ])));
  }
}

class AchievementRulesScreen extends ConsumerStatefulWidget {
  const AchievementRulesScreen({super.key});
  @override
  ConsumerState<AchievementRulesScreen> createState() =>
      _AchievementRulesScreenState();
}

class _AchievementRulesScreenState
    extends ConsumerState<AchievementRulesScreen> {
  final _form = GlobalKey<FormState>();
  final _points = <String, TextEditingController>{},
      _reason = TextEditingController(),
      _ages = TextEditingController();
  int? _version;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    for (final c in _points.values) {
      c.dispose();
    }
    _ages.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(achievementsRepositoryProvider).saveRules({
        'expected_version': _version,
        'points': {
          for (final e in _points.entries) e.key: int.parse(e.value.text)
        },
        'age_boundaries':
            _ages.text.split(',').map((s) => int.parse(s.trim())).toList(),
        'reason': _reason.text.trim()
      });
      ref.invalidate(achievementRulesProvider);
      invalidateAchievements(ref.invalidate);
      _version = null;
      _reason.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Aturan pusat tersimpan. Event lama tetap memakai versi semula.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated || !auth.user.isSuperAdmin) {
      return Scaffold(
          appBar: AppBar(title: const Text('Aturan poin pusat')),
          body: const Center(child: Text('Khusus pengelola aplikasi.')));
    }
    final p = achievementRulesProvider(admin: true);
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar: AppBar(title: const Text('Aturan poin pusat')),
            body: ref.watch(p).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    FinanceError(error: e, retry: () => ref.invalidate(p)),
                data: (r) {
                  if (_version != r.version) {
                    _version = r.version;
                    for (final e in r.points.entries) {
                      _points
                          .putIfAbsent(e.key, TextEditingController.new)
                          .text = '${e.value}';
                    }
                    _ages.text = r.ageBoundaries.join(',');
                  }
                  return Form(
                      key: _form,
                      child: FinanceBody(children: [
                        Text('Versi ${r.version}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const FinanceMessage(
                            'Berlaku prospektif di seluruh komunitas. Setiap sumber menyimpan versi; perubahan ini tidak menghitung ulang atau menggandakan poin lama. Nilai awal adalah default operasional yang dapat diubah.'),
                        for (final e in _points.entries)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                  controller: e.value,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                      labelText:
                                          'Poin ${achievementType(e.key)}'),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    return n == null || n < 0 || n > 1000000
                                        ? 'Isi 0–1.000.000 poin utuh.'
                                        : null;
                                  })),
                        TextFormField(
                            controller: _ages,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                                labelText: 'Batas usia dipisah koma',
                                helperText:
                                    'Contoh 12,16,19,36,51. Unknown tetap terpisah.'),
                            validator: (v) {
                              final values = (v ?? '')
                                  .split(',')
                                  .map((s) => int.tryParse(s.trim()))
                                  .toList();
                              if (values.length != 5 ||
                                  values.any(
                                      (x) => x == null || x < 1 || x > 150)) {
                                return 'Isi lima batas usia 1–150.';
                              }
                              for (var i = 1; i < values.length; i++) {
                                if (values[i]! <= values[i - 1]!) {
                                  return 'Batas usia harus meningkat.';
                                }
                              }
                              return null;
                            }),
                        const SizedBox(height: 12),
                        TextFormField(
                            controller: _reason,
                            enabled: !_busy,
                            decoration: const InputDecoration(
                                labelText: 'Alasan perubahan'),
                            minLines: 2,
                            maxLines: 4,
                            validator: (v) => (v ?? '').trim().length < 10
                                ? 'Tuliskan alasan minimal 10 karakter.'
                                : null),
                        if (_error != null)
                          FinanceMessage(_error!, error: true),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: _busy ? null : _save,
                            child: Text(
                                _busy ? 'Menyimpan…' : 'Simpan versi baru')),
                        const SizedBox(height: 20),
                        Text('Riwayat perubahan',
                            style: Theme.of(context).textTheme.titleLarge),
                        for (final h in r.history)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                      'Versi ${h['version']} · ${financeDate(h['effective_at']?.toString())}\nAktor ${h['changed_by']} · ${h['reason']}\n${h['points'] is Map ? (h['points'] as Map).entries.map((e) => '${achievementType('${e.key}')}: ${e.value} poin').join(' · ') : ''}\nBatas usia: ${(h['age_boundaries'] as List? ?? []).join(', ')} tahun')))
                      ]));
                })));
  }
}

class CommunityAchievementsScreen extends ConsumerStatefulWidget {
  const CommunityAchievementsScreen({super.key, required this.communityId});
  final String communityId;
  @override
  ConsumerState<CommunityAchievementsScreen> createState() =>
      _CommunityAchievementsScreenState();
}

class _CommunityAchievementsScreenState
    extends ConsumerState<CommunityAchievementsScreen> {
  final _form = GlobalKey<FormState>(),
      _title = TextEditingController(),
      _reference = TextEditingController(),
      _date = TextEditingController(
          text: DateTime.now()
              .toUtc()
              .add(const Duration(hours: 7))
              .toIso8601String()
              .substring(0, 10));
  String? _member, _error;
  String _type = 'participation', _key = financeRequestId(), _search = '';
  bool _busy = false;
  int _page = 1, _memberPage = 1;
  @override
  void dispose() {
    _title.dispose();
    _reference.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(achievementsRepositoryProvider)
          .create(widget.communityId, {
        'member_id': int.parse(_member!),
        'type': _type,
        'title': _title.text.trim(),
        'reference': _reference.text.trim(),
        'occurred_at': _date.text.trim(),
        'idempotency_key': _key
      });
      invalidateAchievements(ref.invalidate);
      _key = financeRequestId();
      _title.clear();
      _reference.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Prestasi sah tercatat. Ranking diperbarui.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _correct(AchievementRow row) async {
    var draft = '';
    final reason = await showDialog<String>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Koreksi prestasi'),
                content: SingleChildScrollView(
                    child: TextField(
                        onChanged: (v) => draft = v,
                        decoration: const InputDecoration(
                            labelText: 'Alasan koreksi minimal 10 karakter'),
                        minLines: 2,
                        maxLines: 4)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () {
                        if (draft.trim().length >= 10) {
                          Navigator.pop(dialog, draft.trim());
                        }
                      },
                      child: const Text('Koreksi dan batalkan poin'))
                ]));
    if (reason == null || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(achievementsRepositoryProvider)
          .correct(widget.communityId, row.id, row.version, reason);
      invalidateAchievements(ref.invalidate);
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = communityAchievementsProvider(widget.communityId, page: _page);
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar: AppBar(title: const Text('Pencatatan prestasi'), actions: [
              IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: _busy ? null : () => ref.invalidate(p),
                  icon: const Icon(Icons.refresh))
            ]),
            body: ref.watch(p).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    FinanceError(error: e, retry: () => ref.invalidate(p)),
                data: (d) => FinanceBody(children: [
                      const FinanceMessage(
                          'Latihan dan pembelian paket final dicatat otomatis. Catat partisipasi/juara dengan referensi kegiatan yang sah. Koreksi menambah catatan pembalik tanpa mengubah sejarah.'),
                      if (_error != null) FinanceMessage(_error!, error: true),
                      if (d.canManage)
                        Form(
                            key: _form,
                            child: FinanceSection(
                                title: 'Catat kegiatan / juara',
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                          enabled: !_busy,
                                          decoration: const InputDecoration(
                                              labelText: 'Cari anggota aktif'),
                                          onChanged: (v) => setState(() {
                                                _search = v;
                                                _member = null;
                                                _memberPage = 1;
                                              })),
                                      ref
                                          .watch(achievementMembersProvider(
                                              widget.communityId,
                                              search: _search,
                                              page: _memberPage))
                                          .when(
                                              loading: () =>
                                                  const LinearProgressIndicator(),
                                              error: (e, s) => FinanceError(
                                                  error: e,
                                                  retry: () => ref.invalidate(
                                                      achievementMembersProvider)),
                                              data: (items) =>
                                                  Column(children: [
                                                    DropdownButtonFormField<
                                                            String>(
                                                        key: ValueKey(
                                                            'member-$_search-$_memberPage'),
                                                        initialValue: items.any(
                                                                (x) =>
                                                                    '${x['id']}' ==
                                                                    _member)
                                                            ? _member
                                                            : null,
                                                        isExpanded: true,
                                                        decoration:
                                                            const InputDecoration(
                                                                labelText:
                                                                    'Anggota penerima poin'),
                                                        items: [
                                                          for (final m in items)
                                                            DropdownMenuItem(
                                                                value:
                                                                    '${m['id']}',
                                                                child: Text(
                                                                    '${m['name']}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis))
                                                        ],
                                                        onChanged: _busy
                                                            ? null
                                                            : (v) => setState(
                                                                () => _member =
                                                                    v),
                                                        validator: (_) =>
                                                            _member == null
                                                                ? 'Pilih anggota.'
                                                                : null),
                                                    Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          TextButton(
                                                              onPressed: _memberPage >
                                                                          1 &&
                                                                      !_busy
                                                                  ? () =>
                                                                      setState(
                                                                          () {
                                                                        _memberPage--;
                                                                        _member =
                                                                            null;
                                                                      })
                                                                  : null,
                                                              child: const Text(
                                                                  'Sebelumnya')),
                                                          Text(
                                                              'Hal $_memberPage'),
                                                          TextButton(
                                                              onPressed: items.length >=
                                                                          20 &&
                                                                      !_busy
                                                                  ? () =>
                                                                      setState(
                                                                          () {
                                                                        _memberPage++;
                                                                        _member =
                                                                            null;
                                                                      })
                                                                  : null,
                                                              child: const Text(
                                                                  'Berikutnya'))
                                                        ])
                                                  ])),
                                      DropdownButtonFormField<String>(
                                          initialValue: _type,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                              labelText: 'Jenis prestasi'),
                                          items: [
                                            for (final v in [
                                              'participation',
                                              'champion'
                                            ])
                                              DropdownMenuItem(
                                                  value: v,
                                                  child:
                                                      Text(achievementType(v)))
                                          ],
                                          onChanged: _busy
                                              ? null
                                              : (v) =>
                                                  setState(() => _type = v!)),
                                      TextFormField(
                                          controller: _title,
                                          enabled: !_busy,
                                          maxLength: 120,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Nama kegiatan/lomba dan hasil'),
                                          validator: (v) =>
                                              (v ?? '').trim().length < 3
                                                  ? 'Isi nama kegiatan.'
                                                  : null),
                                      TextFormField(
                                          controller: _reference,
                                          enabled: !_busy,
                                          minLines: 2,
                                          maxLines: 4,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Referensi bukti / nomor hasil'),
                                          validator: (v) => (v ?? '')
                                                      .trim()
                                                      .length <
                                                  3
                                              ? 'Isi referensi yang dapat diaudit.'
                                              : null),
                                      TextFormField(
                                          controller: _date,
                                          enabled: !_busy,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Tanggal kegiatan YYYY-MM-DD'),
                                          validator: (v) =>
                                              DateTime.tryParse(v ?? '') == null
                                                  ? 'Isi tanggal valid.'
                                                  : null),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                          key: const Key('achievement-create'),
                                          onPressed: _busy ? null : _save,
                                          child: Text(_busy
                                              ? 'Mencatat…'
                                              : 'Catat prestasi'))
                                    ]))),
                      Text('Riwayat kegiatan',
                          style: Theme.of(context).textTheme.titleLarge),
                      if (d.items.isEmpty)
                        const FinanceMessage(
                            'Belum ada kegiatan/lomba tercatat.'),
                      for (final row in d.items)
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(row.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      Text(
                                          '${achievementType(row.type)} · ${achievementPoints(row.points)} poin · ${row.status == 'corrected' ? 'Dikoreksi' : 'Sah'}'),
                                      Text(financeDate(row.occurredAt)),
                                      SelectableText(
                                          'Referensi: ${row.reference}'),
                                      Text(
                                          'Aktor ${row.actor} · Versi ${row.version}'),
                                      if (row.correctedAt.isNotEmpty)
                                        Text(
                                            'Koreksi ${financeDate(row.correctedAt)}: ${row.correctionReason}'),
                                      if (d.canCorrect &&
                                          row.status != 'corrected')
                                        OutlinedButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _correct(row),
                                            child:
                                                const Text('Koreksi prestasi'))
                                    ]))),
                      FinancePager(
                          page: d.page,
                          lastPage: d.lastPage,
                          onPage: (v) => setState(() => _page = v))
                    ]))));
  }
}
