import '../data/money_movement_remote_data_source.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/domain/entities/community_draft.dart';
import '../../community/presentation/community_providers.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/money_movement.dart';
import 'money_movement_providers.dart';
import 'movement_sharing.dart';

class PayoutDetailScreen extends ConsumerStatefulWidget {
  const PayoutDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<PayoutDetailScreen> createState() => _PayoutDetailScreenState();
}

class _PayoutDetailScreenState extends ConsumerState<PayoutDetailScreen> {
  bool _reveal = false, _sharing = false;
  String? _error, _message;
  void _refresh() {
    invalidateMovements(ref.invalidate);
    invalidateFinance(ref.invalidate);
  }

  Future<void> _composer(Payout p, PayoutPart part) async {
    final uri = payoutWhatsAppUri(p, part);
    if (uri == null) {
      setState(() => _error =
          'Nomor WhatsApp pendiri belum tersedia atau tidak valid. Hubungi pengelola melalui kontak komunitas.');
      return;
    }
    try {
      final opened = await ref.read(movementSharingProvider).openComposer(uri);
      if (mounted) {
        setState(() => _message = opened
            ? 'Composer WhatsApp dibuka. Periksa pesan lalu kirim sendiri; aplikasi belum membuktikan pesan terkirim.'
            : 'WhatsApp belum dapat dibuka. Periksa aplikasi atau pengaturan browser.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'WhatsApp belum dapat dibuka. Periksa aplikasi atau pengaturan browser.');
      }
    }
  }

  Future<void> _memberComposer(Payout p) async {
    final uri = payoutMemberWhatsAppUri(p);
    if (uri == null) {
      setState(() => _error =
          'Nomor WhatsApp anggota belum tersedia atau tidak valid. Bukti dapat dibagikan melalui dialog berbagi.');
      return;
    }
    try {
      final opened = await ref.read(movementSharingProvider).openComposer(uri);
      if (mounted) {
        setState(() => _message = opened
            ? 'Composer untuk anggota dibuka. Periksa penerima dan kirim sendiri; belum ada bukti pesan terkirim.'
            : 'WhatsApp belum dapat dibuka.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'WhatsApp belum dapat dibuka.');
    }
  }

  Future<void> _proof(Payout p, PayoutPart part, PayoutFragment f,
      {bool share = false}) async {
    final url = f.proofUrl;
    if (url == null) {
      setState(() => _error = 'Bukti belum tersedia. Muat ulang detail.');
      return;
    }
    setState(() {
      _sharing = true;
      _error = null;
      _message = null;
    });
    try {
      final file = await ref.read(moneyMovementRepositoryProvider).proof(url);
      if (!mounted) return;
      if (share) {
        final box = context.findRenderObject() as RenderBox?;
        await ref.read(movementSharingProvider).shareProof(
            file,
            payoutProofShareText(p, part, f),
            box == null
                ? const Rect.fromLTWH(0, 0, 500, 500)
                : box.localToGlobal(Offset.zero) & box.size);
        if (mounted) {
          setState(() => _message =
              'Dialog berbagi atau unduhan bukti disiapkan. Pilih WhatsApp dan anggota tujuan; jika file diunduh, lampirkan sendiri. Ini bukan konfirmasi pesan terkirim.');
        }
      } else {
        await showDialog<void>(
            context: context,
            builder: (c) => Dialog(
                    child: SafeArea(
                        child: SingleChildScrollView(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Bukti ${p.reference} · ${f.reference}')),
                      Image.memory(file.bytes,
                          fit: BoxFit.contain,
                          errorBuilder: (_, e, s) =>
                              const Text('Gambar tidak dapat ditampilkan.')),
                      TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Tutup'))
                    ])))));
      }
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _action(Payout p, PayoutPart part, String action,
      {PayoutFragment? fragment}) async {
    final done = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PayoutActionDialog(
            payout: p, part: part, action: action, fragment: fragment));
    if (done == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = payoutDetailProvider(widget.id);
    return Scaffold(
        appBar: AppBar(title: const Text('Detail pencairan'), actions: [
          IconButton(
              tooltip: 'Muat ulang status',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh))
        ]),
        body: ref.watch(provider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                FinanceError(error: e, retry: () => ref.invalidate(provider)),
            data: (p) => FinanceBody(children: [
                  FinanceSection(
                      title: '${p.reference} · ${payoutStatusLabel(p.status)}',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(p.memberName,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('Diminta ${formatRupiah(p.amount)}',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            Text('Terverifikasi ${formatRupiah(p.verified)}'),
                            Text('Masih ditahan ${formatRupiah(p.remaining)}'),
                            Text(
                                'Dilepas ke saldo ${formatRupiah(p.released)}'),
                            Text('Dibuat ${financeDate(p.createdAt)}'),
                            const SizedBox(height: 12),
                            Text(
                                '${p.destination.bankName} ${_reveal ? p.destination.accountNumber : p.destination.maskedNumber}'),
                            Text('a.n. ${p.destination.accountName}'),
                            if (p.destination.accountNumber.isNotEmpty)
                              TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _reveal = !_reveal),
                                  icon: Icon(_reveal
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  label: Text(_reveal
                                      ? 'Sembunyikan tujuan privat'
                                      : 'Periksa nomor tujuan privat')),
                            const Text(
                                'Snapshot tujuan tetap. Perubahan rekening utama tidak mengubah permintaan ini.')
                          ])),
                  if ((p.status == 'uncertain' && p.remaining > 0) ||
                      p.parts.any((part) =>
                          part.status == 'uncertain' && part.remaining > 0))
                    const FinanceSection(
                        title: 'Hasil belum pasti',
                        child: Text(
                            'Sisa saldo tetap ditahan. Periksa bukti dan status bersama pendiri/admin. Jangan melakukan transfer bank ulang sebelum hasil transaksi sebelumnya dipastikan.')),
                  if (p.status == 'uncertain' && p.remaining == 0)
                    const FinanceMessage(
                        'Pencairan selesai sebagian. Nominal terverifikasi tetap final; bagian yang dipastikan belum terkirim sudah dilepas ke saldo tersedia. Ini bukan berhasil penuh.'),
                  if (_error != null) FinanceMessage(_error!, error: true),
                  if (p.parts.any((part) => part.canManage))
                    OutlinedButton.icon(
                        onPressed: () => _memberComposer(p),
                        icon: const Icon(Icons.chat_outlined),
                        label: Text('Siapkan pesan untuk ${p.memberName}')),
                  if (_message != null) FinanceMessage(_message!),
                  for (final part in p.parts)
                    FinanceSection(
                        title:
                            '${part.communityName} · ${payoutStatusLabel(part.status)}',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (part.sourceAccount != null && part.canManage)
                                Text(
                                    'Rekening sumber tersimpan: ${part.sourceAccount!.bankName} ${part.sourceAccount!.maskedNumber} a.n. ${part.sourceAccount!.accountName}. Rekening sumber mengikuti penerimaan asli, meski pengaturan kolektor berubah.'),
                              Text(
                                  'Bagian sumber dana ${formatRupiah(part.amount)}'),
                              Text(
                                  'Terverifikasi ${formatRupiah(part.verified)} · ditahan ${formatRupiah(part.remaining)} · dilepas ${formatRupiah(part.released)}'),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                  onPressed: _sharing
                                      ? null
                                      : () => _composer(p, part),
                                  icon: const Icon(Icons.chat_outlined),
                                  label: const Text(
                                      'Siapkan pesan untuk pendiri')),
                              if (normalizedWhatsAppPhone(part.founderPhone) ==
                                  null)
                                const FinanceMessage(
                                    'Nomor WhatsApp pendiri belum tersedia atau tidak valid.'),
                              if (part.canManage && !part.finalStatus) ...[
                                const Divider(height: 24),
                                const Text(
                                    'Transfer bank dilakukan di luar aplikasi. Bukti diunggah dan nominal diinput petugas; unggah saja tidak menyelesaikan pencairan.'),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  if (part.status == 'requested')
                                    OutlinedButton(
                                        onPressed: () =>
                                            _action(p, part, 'process'),
                                        child: const Text('Mulai proses')),
                                  if (part.status != 'uncertain')
                                    OutlinedButton(
                                        onPressed: () =>
                                            _action(p, part, 'uncertain'),
                                        child:
                                            const Text('Tandai belum pasti')),
                                  if (part.remaining > 0 &&
                                      ['processing', 'uncertain']
                                          .contains(part.status))
                                    FilledButton.icon(
                                        key: Key('proof-add-${part.id}'),
                                        onPressed: () => context
                                                .push(AppRoutes.payoutProof(
                                                    p.id, part.id))
                                                .then((_) {
                                              if (mounted) _refresh();
                                            }),
                                        icon: const Icon(Icons.upload_file),
                                        label: const Text(
                                            'Unggah & input nominal'))
                                ]),
                              ],
                              if (part.fragments.isEmpty)
                                const FinanceMessage(
                                    'Belum ada bukti transfer pada bagian ini.'),
                              for (final f in part.fragments)
                                Card(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow,
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                  '${formatRupiah(f.amount)} · ${f.status == 'verified' ? 'Terverifikasi' : f.status == 'rejected' ? 'Ditolak: dipastikan belum terkirim' : 'Menunggu verifikasi'}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium),
                                              Text('Referensi ${f.reference}'),
                                              Text(f.note),
                                              Text(
                                                  'Diunggah ${financeDate(f.createdAt)}'),
                                              if (f.verifiedAt != null)
                                                Text(
                                                    'Verifikasi ${financeDate(f.verifiedAt)} · ${f.verifiedBy}'),
                                              Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    OutlinedButton(
                                                        onPressed: _sharing
                                                            ? null
                                                            : () => _proof(
                                                                p, part, f),
                                                        child: const Text(
                                                            'Lihat bukti privat')),
                                                    if (part.canManage)
                                                      OutlinedButton.icon(
                                                          onPressed: _sharing
                                                              ? null
                                                              : () => _proof(
                                                                  p, part, f,
                                                                  share: true),
                                                          icon: const Icon(Icons
                                                              .share_outlined),
                                                          label: const Text(
                                                              'Bagikan bukti')),
                                                    if (part.canManage &&
                                                        f.status == 'pending' &&
                                                        !part.finalStatus)
                                                      OutlinedButton(
                                                          onPressed: () => context
                                                              .push(AppRoutes
                                                                  .payoutFragment(
                                                                      p.id,
                                                                      part.id,
                                                                      f.id)),
                                                          child: const Text(
                                                              'Koreksi isian bukti')),
                                                    if (part.canManage &&
                                                        f.status == 'pending' &&
                                                        !part.finalStatus)
                                                      FilledButton(
                                                          key: Key(
                                                              'verify-${f.id}'),
                                                          onPressed: () =>
                                                              _action(p, part,
                                                                  'verify',
                                                                  fragment: f),
                                                          child: const Text(
                                                              'Periksa & verifikasi nominal'))
                                                  ])
                                            ]))),
                              if (!part.finalStatus &&
                                  part.verified == 0 &&
                                  (part.canManage ||
                                      (p.canCancel &&
                                          part.status == 'requested' &&
                                          part.fragments.isEmpty)))
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  if (part.canManage)
                                    TextButton(
                                        onPressed: () =>
                                            _action(p, part, 'fail'),
                                        child: const Text(
                                            'Gagal: dipastikan belum terkirim')),
                                  TextButton(
                                      onPressed: () =>
                                          _action(p, part, 'cancel'),
                                      child: const Text(
                                          'Batalkan: belum terkirim'))
                                ]),
                              const SizedBox(height: 12),
                              const Text('Jejak status',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              for (final e in part.events)
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                        '${payoutStatusLabel(e.status)} · ${e.actor}\n${financeDate(e.at)}\n${e.note}')),
                            ])),
                  const FinanceMessage(
                      'Nominal terverifikasi tetap final. Setiap bagian menampilkan dana yang masih ditahan atau sudah dilepas setelah dipastikan belum terkirim. Pencairan final tidak menyediakan refund. Berbagi bukti tidak mengeksekusi transfer bank.'),
                ])));
  }
}

class PayoutActionDialog extends ConsumerStatefulWidget {
  const PayoutActionDialog(
      {super.key,
      required this.payout,
      required this.part,
      required this.action,
      this.fragment});
  final Payout payout;
  final PayoutPart part;
  final String action;
  final PayoutFragment? fragment;
  @override
  ConsumerState<PayoutActionDialog> createState() => _PayoutActionDialogState();
}

class _PayoutActionDialogState extends ConsumerState<PayoutActionDialog> {
  final _note = TextEditingController();
  final _key = financeRequestId();
  bool _ack = false, _sending = false, _locked = false;
  String? _error;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final isRelease = ['fail', 'cancel'].contains(widget.action);
    if ((isRelease || widget.action == 'verify') && !_ack) {
      setState(() => _error = 'Konfirmasi pemeriksaan terlebih dahulu.');
      return;
    }
    if (widget.action != 'verify' && _note.text.trim().isEmpty) {
      setState(() => _error = 'Isi alasan atau catatan tindakan.');
      return;
    }
    setState(() {
      _sending = true;
      _locked = true;
      _error = null;
    });
    try {
      await ref.read(moneyMovementRepositoryProvider).partAction(
          widget.part.id,
          widget.action,
          {
            'expected_version': widget.part.version,
            'idempotency_key': _key,
            if (widget.action != 'verify') 'note': _note.text.trim(),
            if (isRelease) 'confirmed_unsent': true
          },
          fragmentId: widget.fragment?.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = ['fail', 'cancel'].contains(widget.action);
    final verify = widget.action == 'verify';
    final title = switch (widget.action) {
      'process' => 'Mulai proses pencairan',
      'uncertain' => 'Tandai hasil belum pasti',
      'verify' => 'Verifikasi transfer aktual',
      'fail' => 'Gagal definitif',
      _ => 'Batalkan pencairan'
    };
    return PopScope(
        canPop: !_sending,
        child: AlertDialog(
            title: Text(title),
            content: SafeArea(
                child: SingleChildScrollView(
                    child: SizedBox(
                        width: 460,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${widget.payout.reference}\n${widget.payout.destination.bankName} ${widget.payout.destination.maskedNumber}\na.n. ${widget.payout.destination.accountName}'),
                              if (verify) ...[
                                const SizedBox(height: 12),
                                Text(
                                    'Nominal aktual ${formatRupiah(widget.fragment!.amount)}'),
                                Text('Referensi ${widget.fragment!.reference}'),
                                Text(
                                    'Sisa ditahan ${formatRupiah(widget.part.remaining)}'),
                                const Text(
                                    'Verifikasi memfinalkan nominal ini tepat sekali; jika parsial, sisa tetap belum pasti.')
                              ],
                              if (!verify)
                                TextField(
                                    key: const Key('payout-action-note'),
                                    controller: _note,
                                    enabled: !_sending && !_locked,
                                    maxLength: 500,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                        labelText: 'Alasan / catatan')),
                              if (release || verify)
                                CheckboxListTile(
                                    key: const Key('payout-action-ack'),
                                    contentPadding: EdgeInsets.zero,
                                    value: _ack,
                                    onChanged: _sending || _locked
                                        ? null
                                        : (v) =>
                                            setState(() => _ack = v ?? false),
                                    title: Text(release
                                        ? 'Saya memastikan belum ada uang terkirim dan tidak ada hasil transfer yang belum pasti.'
                                        : 'Saya sudah memeriksa bukti, nominal, referensi, dan tujuan transfer aktual.')),
                              if (_error != null)
                                FinanceMessage(_error!, error: true)
                            ])))),
            actions: [
              TextButton(
                  onPressed: _sending ? null : () => Navigator.pop(context),
                  child: const Text('Tutup')),
              FilledButton(
                  key: const Key('payout-action-submit'),
                  onPressed: _sending ? null : _send,
                  child: Text(_sending ? 'Menyimpan…' : 'Simpan tindakan'))
            ]));
  }
}

class PayoutProofScreen extends ConsumerStatefulWidget {
  const PayoutProofScreen(
      {super.key, required this.payout, required this.part, this.fragment});
  final Payout payout;
  final PayoutPart part;
  final PayoutFragment? fragment;
  @override
  ConsumerState<PayoutProofScreen> createState() => _PayoutProofScreenState();
}

class _PayoutProofScreenState extends ConsumerState<PayoutProofScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(),
      _reference = TextEditingController(),
      _note = TextEditingController();
  String _key = financeRequestId();
  CommunityImage? _image;
  String? _asset, _error;
  bool _ack = false,
      _sending = false,
      _locked = false,
      _canEdit = false,
      _hadUnknown = false,
      _businessSubmitted = false,
      _reveal = false;
  @override
  void initState() {
    super.initState();
    final f = widget.fragment;
    if (f != null) {
      _amount.text = '${f.amount}';
      _reference.text = f.reference;
      _note.text = f.note;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final imgs = await ref.read(communityImagePickerProvider).pickPhotos(1);
      if (imgs.isNotEmpty && mounted) {
        final i = imgs.single;
        if (i.bytes.length > 5 * 1024 * 1024) {
          setState(() => _error = 'Ukuran bukti maksimal 5 MB.');
          return;
        }
        setState(() {
          _image = i;
          _asset = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Bukti belum dapat dipilih. Coba lagi.');
      }
    }
  }

  Future<void> _send() async {
    if (_sending || !(_form.currentState?.validate() ?? false)) return;
    if ((_image == null && widget.fragment == null) || !_ack) {
      setState(() => _error = 'Pilih gambar bukti dan konfirmasi tujuan.');
      return;
    }
    _businessSubmitted = false;
    setState(() {
      _sending = true;
      _locked = true;
      _error = null;
    });
    try {
      final fields = <String, Object?>{
        'expected_version': widget.part.version,
        'amount': int.parse(_amount.text),
        'bank_reference': _reference.text.trim(),
        'account_number': widget.payout.destination.accountNumber,
        'account_name': widget.payout.destination.accountName,
        'note': _note.text.trim(),
        'idempotency_key': _key
      };
      if (widget.fragment == null) {
        _asset ??= await ref
            .read(communityRepositoryProvider)
            .uploadImage(_image!, category: 'payout-proof');
        fields['proof_asset_id'] = _asset;
        _businessSubmitted = true;
        await ref
            .read(moneyMovementRepositoryProvider)
            .partAction(widget.part.id, 'proofs', fields);
      } else {
        _businessSubmitted = true;
        await ref
            .read(moneyMovementRepositoryProvider)
            .editPendingFragment(widget.part.id, widget.fragment!.id, fields);
      }
      if (mounted) {
        invalidateMovements(ref.invalidate);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = financeErrorMessage(e);
          _hadUnknown = _hadUnknown ||
              (_businessSubmitted && e is! MovementRejectedException);
          _canEdit = !_hadUnknown &&
              (!_businessSubmitted || e is MovementRejectedException);
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Bukti & nominal aktual')),
      body: Form(
          key: _form,
          child: FinanceBody(children: [
            FinanceSection(
                title: widget.payout.reference,
                child: Text(
                    '${widget.part.communityName}\n${widget.payout.destination.bankName} ${widget.payout.destination.maskedNumber}\na.n. ${widget.payout.destination.accountName}\nSisa ditahan ${formatRupiah(widget.part.remaining)}')),
            TextButton(
                onPressed: () => setState(() => _reveal = !_reveal),
                child: Text(_reveal
                    ? 'Sembunyikan nomor privat'
                    : 'Periksa nomor tujuan privat')),
            if (_reveal)
              SelectableText(widget.payout.destination.accountNumber),
            const FinanceMessage(
                'Transfer bank dilakukan di luar aplikasi. Input nominal dari pemeriksaan Anda, bukan hasil pembacaan gambar otomatis. Menyimpan bukti belum memfinalkan uang; verifikasi menjadi langkah terpisah.'),
            RupiahField(
                key: const Key('proof-amount'),
                controller: _amount,
                label: 'Nominal yang benar-benar ditransfer',
                enabled: !_sending && !_locked),
            const SizedBox(height: 16),
            TextFormField(
                key: const Key('proof-reference'),
                controller: _reference,
                enabled: !_sending && !_locked,
                maxLength: 150,
                decoration: const InputDecoration(
                    labelText: 'Referensi transfer bank unik'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Isi referensi transfer.'
                    : null),
            TextFormField(
                key: const Key('proof-note'),
                controller: _note,
                enabled: !_sending && !_locked,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Alasan / catatan pemeriksaan'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Isi catatan pemeriksaan.'
                    : null),
            if (widget.fragment == null)
              OutlinedButton.icon(
                  key: const Key('payout-pick-proof'),
                  onPressed: _sending || _locked ? null : _pick,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_image == null
                      ? 'Pilih gambar bukti (maks. 5 MB)'
                      : 'Bukti dipilih: ${_image!.filename}')),
            if (_image != null)
              ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Image.memory(_image!.bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) =>
                          const Text('Pratinjau gambar tidak tersedia.'))),
            CheckboxListTile(
                key: const Key('proof-destination-ack'),
                contentPadding: EdgeInsets.zero,
                value: _ack,
                onChanged: _sending || _locked
                    ? null
                    : (v) => setState(() => _ack = v ?? false),
                title: const Text(
                    'Tujuan transfer aktual sama dengan snapshot bank, nomor, dan nama penerima di atas.')),
            if (_locked)
              const FinanceMessage(
                  'Retry memakai bukti dan referensi permintaan yang sama agar tidak membuat fragment ganda.'),
            if (_error != null) FinanceMessage(_error!, error: true),
            if (_canEdit)
              TextButton(
                  onPressed: () => setState(() {
                        _locked = false;
                        _key = financeRequestId();
                        _canEdit = false;
                        _error = null;
                      }),
                  child: const Text('Koreksi isian yang ditolak')),
            FilledButton(
                key: const Key('payout-proof-submit'),
                onPressed: _sending ? null : _send,
                child: Text(_sending
                    ? 'Menyimpan bukti…'
                    : _locked
                        ? 'Coba simpan lagi dengan aman'
                        : 'Simpan bukti untuk diverifikasi')),
          ])));
}

class PayoutProofRouteScreen extends ConsumerWidget {
  const PayoutProofRouteScreen(
      {super.key, required this.id, required this.partId, this.fragmentId});
  final String id, partId;
  final String? fragmentId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = payoutDetailProvider(id);
    return ref.watch(provider).when(
        loading: () => Scaffold(
            appBar: AppBar(title: const Text('Bukti pencairan')),
            body: const Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Bukti pencairan')),
            body:
                FinanceError(error: e, retry: () => ref.invalidate(provider))),
        data: (p) {
          final part = p.parts.where((part) => part.id == partId).firstOrNull;
          final fragment =
              part?.fragments.where((f) => f.id == fragmentId).firstOrNull;
          if (part == null ||
              !part.canManage ||
              part.finalStatus ||
              (fragmentId != null &&
                  (fragment == null || fragment.status != 'pending'))) {
            return Scaffold(
                appBar: AppBar(title: const Text('Bukti pencairan')),
                body: const FinanceMessage(
                    'Bagian permintaan tidak tersedia untuk tindakan ini. Muat ulang detail pencairan.'));
          }
          return PayoutProofScreen(
              key: ValueKey('$id:$partId:${part.version}:$fragmentId'),
              payout: p,
              part: part,
              fragment: fragment);
        });
  }
}
