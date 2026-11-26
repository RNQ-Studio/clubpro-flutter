import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dues/presentation/widgets/dues_visuals.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'marketplace_providers.dart';
import 'marketplace_widgets.dart';

class MarketProductScreen extends ConsumerWidget {
  const MarketProductScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = marketProductProvider(id);
    return Scaffold(
        appBar: AppBar(title: const Text('Detail barang')),
        body: ref.watch(provider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) =>
                MarketFailure(error: e, retry: () => ref.invalidate(provider)),
            data: (p) => FinanceBody(children: [
                  MarketPhoto(url: p.photoUrl, height: 260),
                  const SizedBox(height: 16),
                  Text(p.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(formatRupiah(p.price),
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text('Stok tersedia: ${p.stock}'),
                  Text(p.description),
                  const SizedBox(height: 16),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.sellerName),
                      subtitle: Text('Komunitas asal: ${p.communityName}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(AppRoutes.marketSeller(p.sellerId))),
                  OutlinedButton(
                      onPressed: () =>
                          context.push('/explore/communities/${p.communityId}'),
                      child: const Text('Lihat komunitas / tawaran bergabung')),
                  const FinanceMessage(
                      'Bergabung dengan komunitas penjual bersifat pilihan. Anda dapat membeli dengan akun dan saldo yang memenuhi syarat tanpa bergabung.'),
                  if (!p.canBuy)
                    FinanceMessage(
                        p.unavailableReason.isEmpty
                            ? 'Barang belum dapat dibeli.'
                            : p.unavailableReason,
                        error: true),
                  FilledButton(
                      key: const Key('market-buy'),
                      onPressed: p.canBuy
                          ? () {
                              final target = AppRoutes.marketCheckout(id);
                              context.push(ref.read(authProvider)
                                      is AuthAuthenticated
                                  ? target
                                  : '/login?from=${encodeLoginReturn(target)}');
                            }
                          : null,
                      child: Text(ref.watch(authProvider) is AuthAuthenticated
                          ? 'Beli dengan saldo'
                          : 'Masuk untuk membeli'))
                ])));
  }
}
