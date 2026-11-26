import 'dart:convert';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import '../domain/marketplace.dart';
import 'marketplace_providers.dart';
import 'marketplace_widgets.dart';

class MarketCheckoutScreen extends ConsumerStatefulWidget {
  const MarketCheckoutScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<MarketCheckoutScreen> createState() =>
      _MarketCheckoutScreenState();
}

class _MarketCheckoutScreenState extends ConsumerState<MarketCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1'),
      _pin = TextEditingController();
  MarketQuote? _quote;
  MarketOrder? _order;
  String? _error;
  Map<String, Object?>? _pending;
  bool _busy = false,
      _loading = true,
      _storageReady = false,
      _confirmed = false,
      _unknown = false,
      _canEdit = false;
  String get _storageKey {
    final auth = ref.read(authProvider);
    return 'market_checkout_${auth is AuthAuthenticated ? auth.user.id : 'guest'}_${widget.id}';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_restore);
  }

  @override
  void dispose() {
    _quantity.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      final raw = await ref.read(storageServiceProvider).read(_storageKey);
      if (raw != null) {
        final j = Map<String, Object?>.from(jsonDecode(raw) as Map);
        if (j['product_id'] != widget.id ||
            j['idempotency_key'] is! String ||
            j['quantity'] is! int ||
            j['expected_unit_price'] is! int ||
            j['expected_version'] is! int ||
            j['acknowledged'] != true) {
          throw const MarketRejected(
              'Referensi pembayaran tersimpan belum dapat dibaca. Periksa riwayat; jangan membuat pembayaran baru.');
        }
        if (j['product_id'] == widget.id && j['idempotency_key'] is String) {
          _storageReady = true;
          _pending = j;
          _unknown = true;
          _confirmed = true;
          _quantity.text = '${j['quantity']}';
          final old = await ref
              .read(marketplaceRepositoryProvider)
              .orderByKey('${j['idempotency_key']}');
          if (old != null) {
            await _success(old);
            return;
          }
        }
      }
      _storageReady = true;
      if (_pending == null) await _loadQuote();
    } catch (e) {
      if (mounted) setState(() => _error = marketError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadQuote() async {
    if (_pending != null) return;
    final n = int.tryParse(_quantity.text);
    if (n == null || n < 1 || n > 999999) {
      setState(() => _error = 'Isi jumlah 1–999999.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _quote = null;
      _confirmed = false;
    });
    try {
      final q =
          await ref.read(marketplaceRepositoryProvider).quote(widget.id, n);
      if (mounted) setState(() => _quote = q);
    } catch (e) {
      if (mounted) setState(() => _error = marketError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _success(MarketOrder o) async {
    invalidateFinance(ref.invalidate);
    invalidateMarketplace(ref.invalidate);
    if (mounted) {
      setState(() {
        _order = o;
        _pending = null;
        _pin.clear();
      });
    }
    try {
      await ref.read(storageServiceProvider).delete(_storageKey);
    } catch (_) {/* A stored key replays this same completed order safely. */}
  }

  Future<void> _pay() async {
    if (_busy || !(_form.currentState?.validate() ?? false) || !_confirmed) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _canEdit = false;
    });
    bool sent = false;
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      if (_pending != null) {
        final old = await repo.orderByKey('${_pending!['idempotency_key']}');
        if (old != null) {
          await _success(old);
          return;
        }
      } else {
        final q = _quote;
        if (q == null) return;
        _pending = {
          'product_id': widget.id,
          'quantity': q.quantity,
          'expected_version': q.version,
          'expected_unit_price': q.unitPrice,
          'idempotency_key': financeRequestId(),
          'acknowledged': true,
          '_name': q.product.name,
          '_seller': q.product.sellerName,
          '_community': q.product.communityName
        };
      }
      await ref
          .read(storageServiceProvider)
          .write(_storageKey, jsonEncode(_pending));
      sent = true;
      final o = await repo.buy({
        for (final entry in _pending!.entries)
          if (!entry.key.startsWith('_')) entry.key: entry.value,
        'pin': _pin.text
      });
      await _success(o);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = marketError(e);
          _unknown = _unknown || (sent && e is! MarketRejected);
          _canEdit = (e is MarketRejected || !sent) && !_unknown;
        });
        if (_canEdit) {
          try {
            await ref.read(storageServiceProvider).delete(_storageKey);
          } catch (_) {}
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit() {
    setState(() {
      _pending = null;
      _quote = null;
      _unknown = false;
      _confirmed = false;
      _canEdit = false;
      _error = null;
      _pin.clear();
    });
    _loadQuote();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote, pending = _pending;
    return PopScope(
        canPop: !_busy,
        child: Scaffold(
            appBar: AppBar(title: const Text('Konfirmasi pembelian')),
            body: _loading
                ? const Center(child: CircularProgressIndicator())
                : !_storageReady
                    ? MarketFailure(
                        error: MarketRejected(_error ??
                            'Riwayat permintaan belum dapat dibaca. Coba lagi.'),
                        retry: _restore)
                    : _order != null
                        ? FinanceBody(
                            children: [MarketOrderBody(order: _order!)])
                        : Form(
                            key: _form,
                            child: FinanceBody(children: [
                              if (q != null) ...[
                                MarketPhoto(url: q.product.photoUrl),
                                Text(q.product.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall),
                                Text('Penjual: ${q.product.sellerName}'),
                                Text('Komunitas: ${q.product.communityName}')
                              ],
                              TextFormField(
                                  key: const Key('checkout-quantity'),
                                  controller: _quantity,
                                  enabled: !_busy && pending == null,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6)
                                  ],
                                  decoration: const InputDecoration(
                                      labelText: 'Jumlah barang'),
                                  onChanged: (_) => setState(() {
                                        _quote = null;
                                        _confirmed = false;
                                      }),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    return n == null || n < 1 || n > 999999
                                        ? 'Isi jumlah 1–999999.'
                                        : null;
                                  }),
                              if (pending == null)
                                OutlinedButton(
                                    key: const Key('checkout-quote'),
                                    onPressed: _busy ? null : _loadQuote,
                                    child: const Text(
                                        'Periksa harga, stok & saldo')),
                              if (q != null) ...[
                                FinanceSection(
                                    title: 'Ringkasan pembayaran',
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                              '${q.quantity} × ${formatRupiah(q.unitPrice)}'),
                                          Text('Total ${formatRupiah(q.total)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          Text(
                                              'Saldo tersedia ${formatRupiah(q.balance)}'),
                                          if (q.balance < q.total)
                                            const FinanceMessage(
                                                'Saldo kurang. Tambah saldo sebelum membeli.',
                                                error: true)
                                        ]))
                              ],
                              if (pending != null) ...[
                                if (pending['_name'] != null)
                                  Text('${pending['_name']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                if (pending['_seller'] != null)
                                  Text('Penjual: ${pending['_seller']}'),
                                if (pending['_community'] != null)
                                  Text('Komunitas: ${pending['_community']}'),
                                SelectableText(
                                    'Referensi permintaan: ${pending['idempotency_key']}'),
                                Text(
                                    'Jumlah ${pending['quantity']} × ${formatRupiah(pending['expected_unit_price'] as int)}'),
                                const FinanceMessage(
                                    'Permintaan dikunci. Periksa hasil dahulu; percobaan berikut memakai referensi dan data yang sama, termasuk setelah halaman dimuat ulang.')
                              ],
                              const FinanceMessage(
                                  'Pembelian sah yang berhasil bersifat final tanpa refund. Kegagalan sebelum final tidak mendebit saldo. Tidak ada komisi platform.'),
                              TextButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => context.push(
                                          '/account/pin?from=${encodeLoginReturn(AppRoutes.marketCheckout(widget.id))}'),
                                  icon: const Icon(Icons.pin_outlined),
                                  label: const Text(
                                      'Atur / pulihkan PIN transaksi')),
                              TextFormField(
                                  key: const Key('checkout-pin'),
                                  controller: _pin,
                                  enabled: !_busy,
                                  obscureText: true,
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6)
                                  ],
                                  decoration: const InputDecoration(
                                      labelText: 'PIN transaksi (6 digit)'),
                                  validator: (v) =>
                                      RegExp(r'^\d{6}$').hasMatch(v ?? '')
                                          ? null
                                          : 'Isi 6 digit PIN.'),
                              CheckboxListTile(
                                  key: const Key('checkout-confirm'),
                                  contentPadding: EdgeInsets.zero,
                                  value: _confirmed,
                                  onChanged: _busy || pending != null
                                      ? null
                                      : (v) => setState(
                                          () => _confirmed = v ?? false),
                                  title: const Text(
                                      'Saya sudah memeriksa penjual, jumlah dan total; setuju pembelian final tanpa refund.')),
                              if (_error != null)
                                FinanceMessage(_error!, error: true),
                              if (_canEdit)
                                TextButton(
                                    key: const Key('checkout-edit'),
                                    onPressed: _busy ? null : _edit,
                                    child: const Text(
                                        'Perbarui permintaan yang ditolak')),
                              FilledButton(
                                  key: const Key('checkout-pay'),
                                  onPressed: _busy ||
                                          !_confirmed ||
                                          (pending == null &&
                                              (q == null ||
                                                  q.balance < q.total))
                                      ? null
                                      : _pay,
                                  child: Text(_busy
                                      ? 'Memeriksa transaksi…'
                                      : pending != null
                                          ? 'Periksa hasil & coba lagi dengan aman'
                                          : 'Bayar dengan saldo'))
                            ]))));
  }
}
