import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/presentation/community_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/marketplace.dart';
import 'marketplace_providers.dart';
import 'marketplace_widgets.dart';

class MarketProductFormScreen extends ConsumerStatefulWidget {
  const MarketProductFormScreen({super.key, this.id});
  final String? id;
  @override
  ConsumerState<MarketProductFormScreen> createState() =>
      _MarketProductFormScreenState();
}

class _MarketProductFormScreenState
    extends ConsumerState<MarketProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _description = TextEditingController(),
      _price = TextEditingController(),
      _stock = TextEditingController(text: '1');
  String? _community, _asset, _photoUrl, _error;
  Uint8List? _preview;
  MarketImage? _image;
  bool _active = true, _busy = false, _loading = false;
  int? _version;
  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loading = true;
      Future.microtask(_load);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p =
          await ref.read(marketplaceRepositoryProvider).ownProduct(widget.id!);
      if (!mounted) return;
      setState(() {
        _name.text = p.name;
        _description.text = p.description;
        _price.text = '${p.price}';
        _stock.text = '${p.stock}';
        _community = p.communityId;
        _asset = p.photoAssetId;
        _photoUrl = p.photoUrl;
        _active = p.active;
        _version = p.version;
        _preview = null;
        _image = null;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = marketError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_busy) return;
    try {
      final picked = await ref.read(communityImagePickerProvider).pickPhotos(1);
      if (picked.isEmpty) return;
      final f = picked.first;
      final bytes = f.bytes;
      final mime = f.mimeType;
      if (mounted) {
        setState(() {
          _preview = bytes;
          _image = MarketImage(bytes, f.filename, mime);
          _asset = null;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = marketError(e));
    }
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    if (_asset == null && _image == null) {
      setState(() => _error = 'Tambahkan foto barang.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      _asset ??= await repo.uploadImage(_image!);
      await repo.saveProduct({
        'community_id': int.parse(_community!),
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'price': int.parse(_price.text),
        'stock': int.parse(_stock.text),
        'is_active': _active,
        'photo_asset_id': _asset,
        if (_version != null) 'expected_version': _version
      }, id: widget.id);
      invalidateMarketplace(ref.invalidate);
      if (mounted) context.go(AppRoutes.myMarketProducts);
    } catch (e) {
      if (mounted) setState(() => _error = marketError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
          appBar: AppBar(
              title: Text(widget.id == null ? 'Tambah barang' : 'Edit barang')),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : widget.id != null && _version == null
                  ? MarketFailure(
                      error: MarketRejected(
                          _error ?? 'Barang belum dapat dimuat.'),
                      retry: _load)
                  : Form(
                      key: _form,
                      child: FinanceBody(children: [
                        const FinanceMessage(
                            'Kuota maksimal lima barang aktif berlaku untuk seluruh komunitas. Foto dan harga transaksi yang sudah final tetap tersimpan.'),
                        ref.watch(joinedCommunitiesProvider).when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, s) => MarketFailure(
                                error: e,
                                retry: () =>
                                    ref.invalidate(joinedCommunitiesProvider)),
                            data: (list) => DropdownButtonFormField<String>(
                                key: const Key('product-community'),
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
                                    : (v) => setState(() => _community = v),
                                validator: (v) => v == null
                                    ? 'Pilih komunitas asal.'
                                    : null)),
                        const SizedBox(height: 16),
                        TextFormField(
                            key: const Key('product-name'),
                            controller: _name,
                            enabled: !_busy,
                            maxLength: 150,
                            decoration:
                                const InputDecoration(labelText: 'Nama barang'),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Isi nama barang.'
                                : null),
                        TextFormField(
                            key: const Key('product-description'),
                            controller: _description,
                            enabled: !_busy,
                            maxLength: 3000,
                            minLines: 3,
                            maxLines: 6,
                            decoration:
                                const InputDecoration(labelText: 'Deskripsi'),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Isi deskripsi barang.'
                                : null),
                        RupiahField(
                            key: const Key('product-price'),
                            controller: _price,
                            label: 'Harga per barang',
                            enabled: !_busy),
                        const SizedBox(height: 16),
                        TextFormField(
                            key: const Key('product-stock'),
                            controller: _stock,
                            enabled: !_busy,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6)
                            ],
                            decoration: const InputDecoration(
                                labelText: 'Stok tersedia'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              return n == null || n < 0 || n > 999999
                                  ? 'Isi stok 0–999999.'
                                  : null;
                            }),
                        const SizedBox(height: 16),
                        if (_preview != null)
                          Image.memory(_preview!,
                              height: 180,
                              errorBuilder: (_, e, s) => const Text(
                                  'Foto tidak dapat ditampilkan. Pilih foto lain.'))
                        else
                          MarketPhoto(url: _photoUrl),
                        OutlinedButton.icon(
                            key: const Key('product-photo'),
                            onPressed: _busy ? null : _pick,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: Text(_asset != null || _image != null
                                ? 'Ganti foto barang'
                                : 'Pilih foto barang')),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _active,
                            onChanged: _busy
                                ? null
                                : (v) => setState(() => _active = v),
                            title: const Text('Barang aktif'),
                            subtitle: const Text(
                                'Barang nonaktif tidak tampil di katalog publik.')),
                        if (_error != null)
                          FinanceMessage(_error!, error: true),
                        if (widget.id != null)
                          TextButton(
                              onPressed: _busy ? null : _load,
                              child: const Text('Muat ulang data terbaru')),
                        FilledButton(
                            key: const Key('product-save'),
                            onPressed: _busy ? null : _save,
                            child: Text(_busy ? 'Menyimpan…' : 'Simpan barang'))
                      ]))));
}
