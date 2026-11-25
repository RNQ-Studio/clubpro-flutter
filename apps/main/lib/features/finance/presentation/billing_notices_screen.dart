import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/finance.dart';
import 'finance_providers.dart';
import 'finance_widgets.dart';

class BillingNoticesScreen extends ConsumerStatefulWidget {
  const BillingNoticesScreen({super.key});
  @override
  ConsumerState<BillingNoticesScreen> createState() =>
      _BillingNoticesScreenState();
}

class _BillingNoticesScreenState extends ConsumerState<BillingNoticesScreen> {
  String? _busy, _error;
  Future<void> _open(BillingNotice notice, {bool navigate = true}) async {
    if (_busy != null) return;
    setState(() {
      _busy = notice.id;
      _error = null;
    });
    try {
      if (notice.readAt == null) {
        await ref.read(financeRepositoryProvider).readNotice(notice.id);
      }
      if (!mounted) return;
      ref.invalidate(billingNoticeFeedProvider);
      if (navigate && notice.communityId.isNotEmpty) {
        await context.push(notice.type == 'inactive_review'
            ? AppRoutes.communityLifecycle(notice.communityId)
            : '${AppRoutes.communityBilling(notice.communityId)}?scope=${notice.subjectKind == 'platform' ? 'platform' : 'member'}${notice.memberId == null || notice.subjectKind == 'platform' ? '' : '&member=${notice.memberId}'}');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Pengingat pembayaran'), actions: [
        IconButton(
            tooltip: 'Segarkan pengingat',
            onPressed: () => ref.invalidate(billingNoticeFeedProvider),
            icon: const Icon(Icons.refresh)),
      ]),
      body: ref.watch(billingNoticeFeedProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => FinanceError(
              error: e, retry: () => ref.invalidate(billingNoticeFeedProvider)),
          data: (feed) => FinanceBody(children: [
                Text('${feed.unreadCount} belum dibaca',
                    style: Theme.of(context).textTheme.titleMedium),
                const FinanceMessage(
                    'Pengingat H-3 dan peninjauan tiga bulan tidak aktif mengikuti waktu WIB. Data tidak dihapus otomatis.'),
                if (_error != null) FinanceMessage(_error!, error: true),
                if (feed.items.isEmpty)
                  const FinanceMessage('Belum ada pengingat pembayaran.'),
                for (final n in feed.items)
                  FinanceSection(
                      title: n.type == 'inactive_review'
                          ? 'Peninjauan keanggotaan'
                          : 'Masa aktif segera berakhir',
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(n.message),
                            const SizedBox(height: 8),
                            Text(financeDate(n.createdAt)),
                            if (n.readAt == null)
                              const Text('Belum dibaca',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            FilledButton(
                                key: Key('notice-open-${n.id}'),
                                onPressed:
                                    _busy != null ? null : () => _open(n),
                                child: Text(n.type == 'inactive_review'
                                    ? 'Tinjau: pertahankan / arsipkan'
                                    : 'Lihat kewajiban & pembayaran')),
                            if (n.readAt == null)
                              TextButton(
                                  onPressed: _busy != null
                                      ? null
                                      : () => _open(n, navigate: false),
                                  child: const Text('Tandai dibaca')),
                          ])),
              ])));
}
