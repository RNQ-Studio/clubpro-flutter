import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../achievements/presentation/achievements_providers.dart';
import '../../../community/domain/entities/community.dart';
import '../../../dues/presentation/widgets/dues_visuals.dart';
import '../../../finance/presentation/finance_providers.dart';

/// Ringkasan privat akun saat ini; komunitas dipilih eksplisit untuk KTA/iuran.
class MemberLobbyCard extends ConsumerWidget {
  const MemberLobbyCard({super.key, this.community});
  final Community? community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();
    final wallet = ref.watch(walletSummaryProvider);
    final points = ref.watch(myAchievementsProvider());
    final active = community;
    final photo = auth.user.avatarUrl;
    return Card(
      key: ValueKey('member-lobby-${auth.user.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            CircleAvatar(
                child: ClipOval(
                    child: photo == null || photo.isEmpty
                        ? const Icon(Icons.person_outline)
                        : Image.network(photo,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person_outline)))),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Ruang anggota saya',
                    style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 12),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Saldo tersedia'),
              subtitle: wallet.when(
                  skipLoadingOnRefresh: false,
                  data: (w) => Text(formatRupiah(w.available),
                      key: const Key('member-lobby-balance')),
                  loading: () => const Text('Memuat saldo…'),
                  error: (_, __) => TextButton(
                      onPressed: () => ref.invalidate(walletSummaryProvider),
                      child: const Text('Saldo gagal dimuat · Coba lagi'))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.wallet)),
          ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Poin prestasi'),
              subtitle: points.when(
                  skipLoadingOnRefresh: false,
                  data: (p) => Text(
                      '${NumberFormat.decimalPattern('id').format(p.totalPoints)} poin',
                      key: const Key('member-lobby-points')),
                  loading: () => const Text('Memuat poin…'),
                  error: (_, __) => TextButton(
                      onPressed: () => ref.invalidate(myAchievementsProvider),
                      child: const Text('Poin gagal dimuat · Coba lagi'))),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.myAchievements)),
          const Text('Poin prestasi dan saldo rupiah dihitung terpisah.'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
                key: const Key('member-lobby-ads'),
                onPressed: () => context.push(AppRoutes.myAds),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Iklan saya')),
            OutlinedButton.icon(
                key: const Key('member-lobby-topup'),
                onPressed: () => context.push(active == null
                    ? AppRoutes.topup
                    : '${AppRoutes.topup}?community=${active.id}'),
                icon: const Icon(Icons.add_card_outlined),
                label: const Text('Top up')),
            OutlinedButton.icon(
                key: const Key('member-lobby-payouts'),
                onPressed: () => context.push(AppRoutes.payouts),
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pencairan')),
            if (active != null) ...[
              OutlinedButton.icon(
                  key: const Key('member-lobby-card'),
                  onPressed: () =>
                      context.push(AppRoutes.communityCard(active.id)),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('KTA saya')),
              OutlinedButton.icon(
                  key: const Key('member-lobby-dues'),
                  onPressed: () =>
                      context.push(AppRoutes.communityBilling(active.id)),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Iuran & masa aktif')),
              OutlinedButton.icon(
                  key: const Key('member-lobby-packages'),
                  onPressed: () =>
                      context.push(AppRoutes.communityTraining(active.id)),
                  icon: const Icon(Icons.sports_outlined),
                  label: const Text('Paket latihan')),
            ],
            if (auth.user.isSuperAdmin)
              OutlinedButton.icon(
                  key: const Key('member-lobby-point-rules'),
                  onPressed: () => context.push(AppRoutes.achievementRules),
                  icon: const Icon(Icons.tune),
                  label: const Text('Pengaturan poin pusat')),
          ]),
          if (active == null)
            const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                    'Pilih komunitas untuk melihat KTA, iuran dan paket latihan.')),
        ]),
      ),
    );
  }
}
