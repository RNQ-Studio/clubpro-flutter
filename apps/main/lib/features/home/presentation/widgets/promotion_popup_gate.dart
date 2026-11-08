import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home_providers.dart';
import 'promotion_popup.dart';

/// Menampilkan popup Paid Promotion di atas Beranda bila ada promosi tayang dan
/// sudah lewat jedanya sejak terakhir tampil untuk akun ini di perangkat ini.
/// Diperiksa saat Beranda dibuka, saat promosi selesai dimuat, dan saat app
/// kembali ke depan.
class PromotionPopupGate extends ConsumerStatefulWidget {
  const PromotionPopupGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PromotionPopupGate> createState() => _PromotionPopupGateState();
}

class _PromotionPopupGateState extends ConsumerState<PromotionPopupGate>
    with WidgetsBindingObserver {
  /// Satu pemeriksaan sekaligus; popup tidak pernah ditumpuk.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  /// Beranda tertutup halaman lain atau dialog → tunggu kesempatan berikutnya.
  bool get _onTop => mounted && (ModalRoute.of(context)?.isCurrent ?? true);

  Future<void> _check() async {
    if (_busy || !_onTop) return;
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final userId = auth.user.id;

    _busy = true;
    try {
      final promotions = await ref.read(homePromotionsProvider.future);
      if (promotions.banners.isEmpty || !_onTop) return;
      final store = ref.read(promotionPopupStoreProvider);
      final now = DateTime.now();
      if (!promotions.isDue(await store.lastShown(userId), now) || !_onTop) {
        return;
      }
      // Dicatat saat tampil: ditutup dengan cara apa pun tetap terhitung.
      await store.markShown(userId, now);
      if (!mounted || !_onTop) return;
      final chosen = await showPromotionPopup(context, promotions.banners);
      if (chosen != null && mounted) {
        await openPromotionLink(context, chosen.linkUrl);
      }
    } catch (_) {
      // Popup promosi tidak boleh mengganggu Beranda.
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homePromotionsProvider, (_, next) {
      if (next.hasValue) _check();
    });
    return widget.child;
  }
}
