import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/presentation/community_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../../marketplace/domain/marketplace.dart';
import '../../marketplace/presentation/marketplace_providers.dart';
import '../../marketplace/presentation/marketplace_widgets.dart';
import '../domain/achievements.dart';
import 'achievements_providers.dart';

class MemberAdsScreen extends ConsumerStatefulWidget {
  const MemberAdsScreen(
      {super.key, this.mine = false, this.communityId, this.sellerId});
  final bool mine;
  final String? communityId, sellerId;
  @override
  ConsumerState<MemberAdsScreen> createState() => _MemberAdsScreenState();
}

class _MemberAdsScreenState extends ConsumerState<MemberAdsScreen> {
  String _search = '';
  int _page = 1;
  @override
  Widget build(BuildContext context) {
    final p = memberAdsProvider(
        mine: widget.mine,
        communityId: widget.communityId,
        sellerId: widget.sellerId,
        search: _search,
        page: _page);
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.mine ? 'Iklan saya' : 'Iklan anggota'),
            actions: [
              IconButton(
                  tooltip: 'Muat ulang',
                  onPressed: () => ref.invalidate(p),
                  icon: const Icon(Icons.refresh))
            ]),
        body: FinanceBody(children: [
          const FinanceMessage(
              'Ruang promosi anggota, tanpa biaya iklan tambahan. Tautan produk menuju katalog yang dapat diperiksa.'),
          if (widget.mine)
            FilledButton.icon(
                onPressed: () => context.push(AppRoutes.newAd),
                icon: const Icon(Icons.add),
                label: const Text('Buat iklan')),
          const SizedBox(height: 12),
          TextField(
              decoration: const InputDecoration(
                  labelText: 'Cari iklan', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() {
                    _search = v;
                    _page = 1;
                  })),
          const SizedBox(height: 16),
          ref.watch(p).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  FinanceError(error: e, retry: () => ref.invalidate(p)),
              data: (d) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.mine)
                          Text('${d.activeCount} / ${d.maxActive} iklan aktif'),
                        if (d.items.isEmpty)
                          const FinanceMessage('Belum ada iklan yang sesuai.'),
                        for (final ad in d.items)
                          MemberAdCard(ad: ad, edit: widget.mine),
                        FinancePager(
                            page: d.page,
                            lastPage: d.lastPage,
                            onPage: (v) => setState(() => _page = v))
                      ]))
        ]));
  }
}

class MemberAdCard extends StatelessWidget {
  const MemberAdCard({super.key, required this.ad, this.edit = false});
  final MemberAd ad;
  final bool edit;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (ad.photoUrl != null) MarketPhoto(url: ad.photoUrl),
            const SizedBox(height: 8),
            Text(ad.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(ad.body),
            const SizedBox(height: 8),
            Text('${ad.sellerName} · ${ad.communityName}'),
            if (edit) Text(ad.active ? 'Aktif' : 'Nonaktif'),
            const SizedBox(height: 12),
            OutlinedButton(
                onPressed: () => context.push(edit
                    ? AppRoutes.editAd(ad.id)
                    : ad.productId != null
                        ? AppRoutes.marketProduct(ad.productId!)
                        : AppRoutes.marketSeller(ad.sellerId)),
                child: Text(edit
                    ? 'Kelola iklan'
                    : ad.productId != null
                        ? 'Lihat produk'
                        : 'Lihat lapak anggota'))
          ])));
}

class MemberAdFormScreen extends ConsumerStatefulWidget {
  const MemberAdFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<MemberAdFormScreen> createState() => _MemberAdFormScreenState();
}

class _MemberAdFormScreenState extends ConsumerState<MemberAdFormScreen> {
  final _form = GlobalKey<FormState>(),
      _title = TextEditingController(),
      _body = TextEditingController();
  String? _community, _asset, _url, _product, _error;
  Uint8List? _preview;
  MarketImage? _image;
  int? _version;
  bool _active = true, _busy = false, _loading = false;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loading = true;
      Future.microtask(_load);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ad = await ref.read(achievementsRepositoryProvider).ad(widget.id!);
      if (!mounted) return;
      setState(() {
        _title.text = ad.title;
        _body.text = ad.body;
        _community = ad.communityId;
        _asset = ad.photoAssetId;
        _url = ad.photoUrl;
        _product = ad.productId;
        _version = ad.version;
        _active = ad.active;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    if (_busy) return;
    try {
      final images = await ref.read(communityImagePickerProvider).pickPhotos(1);
      if (images.isEmpty || !mounted) return;
      final i = images.first;
      setState(() {
        _image = MarketImage(i.bytes, i.filename, i.mimeType);
        _preview = i.bytes;
        _asset = null;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    }
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_image != null) {
        _asset ??=
            await ref.read(marketplaceRepositoryProvider).uploadImage(_image!);
      }
      await ref.read(achievementsRepositoryProvider).saveAd({
        'community_id': int.parse(_community!),
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'photo_asset_id': _asset,
        'target_product_id': _product,
        'is_active': _active,
        if (_version != null) 'expected_version': _version
      }, id: widget.id);
      ref.invalidate(memberAdsProvider);
      if (mounted) context.go(AppRoutes.myAds);
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
                title: const Text('Hapus iklan?'),
                content: const Text('Iklan akan berhenti ditampilkan.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Hapus iklan'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(achievementsRepositoryProvider)
          .deleteAd(widget.id!, _version!);
      ref.invalidate(memberAdsProvider);
      if (mounted) context.go(AppRoutes.myAds);
    } catch (e) {
      if (mounted) setState(() => _error = financeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
          appBar: AppBar(
              title: Text(widget.id == null
                  ? 'Buat iklan anggota'
                  : 'Kelola iklan anggota')),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : widget.id != null && _version == null
                  ? FinanceError(
                      error: ServerException(
                          _error ?? 'Iklan belum dapat dimuat.'),
                      retry: _load)
                  : Form(
                      key: _form,
                      child: FinanceBody(children: [
                        const FinanceMessage(
                            'Iklan anggota terpisah dari banner aplikasi dan kuota barang. Maksimal iklan aktif mengikuti pengaturan pusat. Tidak ada biaya tambahan.'),
                        ref.watch(joinedCommunitiesProvider).when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => FinanceError(
                                error: e,
                                retry: () =>
                                    ref.invalidate(joinedCommunitiesProvider)),
                            data: (list) => DropdownButtonFormField<String>(
                                initialValue: _community,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Komunitas asal'),
                                items: [
                                  if (_community != null &&
                                      !list.any((c) => c.id == _community))
                                    DropdownMenuItem(
                                        value: _community,
                                        child: const Text(
                                            'Komunitas asal tersimpan')),
                                  for (final c in list)
                                    DropdownMenuItem(
                                        value: c.id,
                                        child: Text(c.name,
                                            overflow: TextOverflow.ellipsis))
                                ],
                                onChanged: _busy
                                    ? null
                                    : (v) => setState(() {
                                          _community = v;
                                          _product = null;
                                        }),
                                validator: (v) => v == null
                                    ? 'Pilih komunitas asal.'
                                    : null)),
                        const SizedBox(height: 12),
                        TextFormField(
                            key: const Key('ad-title'),
                            controller: _title,
                            enabled: !_busy,
                            maxLength: 120,
                            decoration:
                                const InputDecoration(labelText: 'Judul iklan'),
                            validator: (v) => (v ?? '').trim().length < 3
                                ? 'Isi judul minimal 3 karakter.'
                                : null),
                        TextFormField(
                            key: const Key('ad-body'),
                            controller: _body,
                            enabled: !_busy,
                            minLines: 3,
                            maxLines: 8,
                            maxLength: 2000,
                            decoration:
                                const InputDecoration(labelText: 'Isi iklan'),
                            validator: (v) => (v ?? '').trim().length < 3
                                ? 'Isi informasi iklan.'
                                : null),
                        if (_preview != null)
                          Image.memory(_preview!,
                              height: 180, fit: BoxFit.contain)
                        else if (_url != null && _asset != null)
                          MarketPhoto(url: _url),
                        Wrap(spacing: 12, children: [
                          OutlinedButton.icon(
                              onPressed: _busy ? null : _pick,
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: const Text('Pilih gambar opsional')),
                          if (_asset != null || _image != null)
                            TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => setState(() {
                                          _asset = null;
                                          _image = null;
                                          _preview = null;
                                          _url = null;
                                        }),
                                child: const Text('Hapus gambar'))
                        ]),
                        const Text(
                            'JPG/PNG/WebP maksimal 5 MB. Gambar milik akun sendiri.'),
                        const SizedBox(height: 12),
                        if (_community != null)
                          ref.watch(marketProductsProvider(mine: true)).when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, s) => FinanceError(
                                  error: e,
                                  retry: () =>
                                      ref.invalidate(marketProductsProvider)),
                              data: (d) => DropdownButtonFormField<String>(
                                  key: ValueKey('ad-product-$_community'),
                                  initialValue: _product ?? '',
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Tautan produk sendiri (opsional)'),
                                  items: [
                                    const DropdownMenuItem(
                                        value: '',
                                        child: Text(
                                            'Informasi / arahkan ke lapak')),
                                    if (_product != null &&
                                        !d.items.any((p) =>
                                            p.id == _product &&
                                            p.communityId == _community))
                                      DropdownMenuItem(
                                          value: _product,
                                          child:
                                              const Text('Produk tersimpan')),
                                    for (final p in d.items.where(
                                        (p) => p.communityId == _community))
                                      DropdownMenuItem(
                                          value: p.id,
                                          child: Text(p.name,
                                              overflow: TextOverflow.ellipsis))
                                  ],
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() =>
                                          _product = v!.isEmpty ? null : v))),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Iklan aktif'),
                            subtitle: const Text(
                                'Penayangan mengikuti status komunitas dan keanggotaan yang sah.'),
                            value: _active,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _active = v)),
                        if (_error != null)
                          FinanceMessage(_error!, error: true),
                        const SizedBox(height: 16),
                        FilledButton(
                            key: const Key('ad-save'),
                            onPressed: _busy ? null : _save,
                            child: Text(_busy ? 'Menyimpan…' : 'Simpan iklan')),
                        if (widget.id != null)
                          TextButton(
                              onPressed: _busy ? null : _delete,
                              child: const Text('Hapus iklan'))
                      ]))));
}
