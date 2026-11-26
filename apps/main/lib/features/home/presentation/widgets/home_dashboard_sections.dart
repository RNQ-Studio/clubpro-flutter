import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../achievements/presentation/achievements_providers.dart';
import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../../dues/presentation/widgets/dues_visuals.dart';
import '../../../finance/presentation/finance_providers.dart';

/// A consistent surface keeps the dashboard calm across light and dark themes.
class HomeSurface extends StatelessWidget {
  const HomeSurface({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: communityHairline(context)),
        ),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      );
}

/// Money and achievements are separate, with honest loading and retry states.
class HomeAccountSummary extends ConsumerWidget {
  const HomeAccountSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    final points = ref.watch(myAchievementsProvider());
    return HomeSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Ringkasan saya',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
        const SizedBox(height: 14),
        _SummaryMetric(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Saldo tersedia',
          onTap: () => context.push(AppRoutes.wallet),
          value: wallet.when(
            skipLoadingOnRefresh: false,
            data: (w) => Text(formatRupiah(w.available),
                key: const Key('member-lobby-balance')),
            loading: () => const Text('Memuat saldo…'),
            error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(walletSummaryProvider),
                child: const Text('Saldo gagal dimuat · Coba lagi')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: communityHairline(context)),
        ),
        _SummaryMetric(
          icon: Icons.emoji_events_outlined,
          label: 'Poin prestasi',
          onTap: () => context.push(AppRoutes.myAchievements),
          value: points.when(
            skipLoadingOnRefresh: false,
            data: (p) => Text(
                '${NumberFormat.decimalPattern('id').format(p.totalPoints)} poin',
                key: const Key('member-lobby-points')),
            loading: () => const Text('Memuat poin…'),
            error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(myAchievementsProvider),
                child: const Text('Poin gagal dimuat · Coba lagi')),
          ),
        ),
      ]),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CommunityColors.gold.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CommunityColors.gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    const SizedBox(height: 3),
                    DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      child: value,
                    ),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ]),
        ),
      );
}

/// Secondary destinations are revealed by purpose instead of one long menu.
class HomeMenuGroups extends StatelessWidget {
  const HomeMenuGroups(
      {super.key, this.community, this.detail, this.restricted = false});
  final Community? community;
  final CommunityDetail? detail;
  final bool restricted;

  @override
  Widget build(BuildContext context) {
    final active = community;
    final canRecord = detail != null &&
        detail!.isMember &&
        (detail!.myRole?.canManage == true ||
            detail!.myRole == CommunityRole.coach) &&
        !restricted;
    return HomeSurface(
      padding: 0,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
          child: Text('Semua menu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ),
        if (active != null)
          HomeMenuGroup(
            key: ValueKey('home-menu-community-${active.id}'),
            tileKey: const Key('home-menu-community'),
            icon: Icons.groups_outlined,
            title: 'Aktivitas komunitas',
            subtitle: 'Latihan, prestasi & komunitas',
            children: [
              _MenuLink(
                  'training-entry',
                  'Paket & latihan',
                  Icons.sports_outlined,
                  AppRoutes.communityTraining(active.id)),
              _MenuLink(
                  'community-member-rankings',
                  'Ranking prestasi anggota',
                  Icons.emoji_events_outlined,
                  '${AppRoutes.rankings}?community=${active.id}'),
              _MenuLink(
                  'community-member-ads',
                  'Iklan anggota komunitas',
                  Icons.campaign_outlined,
                  '${AppRoutes.memberAds}?community=${active.id}'),
              if (canRecord)
                _MenuLink(
                    'community-record-achievement',
                    'Catat kegiatan & hasil lomba',
                    Icons.fact_check_outlined,
                    AppRoutes.communityAchievements(active.id)),
              _MenuLink(
                  'market-entry-community',
                  'Jualan anggota komunitas',
                  Icons.storefront_outlined,
                  AppRoutes.marketCatalogue(communityId: active.id)),
              const _MenuLink('home-more-find', 'Cari komunitas lain',
                  Icons.travel_explore_rounded, AppRoutes.communities),
              const _MenuLink('home-more-create', 'Daftarkan komunitas',
                  Icons.add_business_outlined, AppRoutes.createCommunity),
            ],
          ),
        HomeMenuGroup(
          key: ValueKey('home-menu-finance-${active?.id}'),
          tileKey: const Key('home-menu-finance'),
          icon: Icons.account_balance_wallet_outlined,
          title: 'Keuangan',
          subtitle: 'Top up, pembayaran & pencairan',
          children: [
            _MenuLink(
                'member-lobby-topup',
                'Top up saldo',
                Icons.add_card_outlined,
                active == null
                    ? AppRoutes.topup
                    : '${AppRoutes.topup}?community=${active.id}'),
            if (active != null) ...[
              _MenuLink(
                  'finance-entry',
                  'Iuran & keanggotaan',
                  Icons.receipt_long_outlined,
                  AppRoutes.communityBilling(active.id)),
              if ((detail?.myRole ?? active.myRole) == CommunityRole.creator)
                _MenuLink(
                    'home-platform-billing',
                    'Langganan komunitas',
                    Icons.business_outlined,
                    '${AppRoutes.communityBilling(active.id)}?scope=platform'),
            ],
            const _MenuLink('member-lobby-payouts', 'Pencairan',
                Icons.payments_outlined, AppRoutes.payouts),
          ],
        ),
        const HomeMenuGroup(
          tileKey: Key('home-menu-market'),
          icon: Icons.storefront_outlined,
          title: 'Jual beli',
          subtitle: 'Marketplace, lapak & iklan saya',
          children: [
            _MenuLink('market-entry-main', 'Marketplace semua komunitas',
                Icons.shopping_bag_outlined, AppRoutes.marketProducts),
            _MenuLink('market-entry-mine', 'Lapak saya',
                Icons.storefront_outlined, AppRoutes.myMarketProducts),
            _MenuLink('member-lobby-ads', 'Iklan saya', Icons.campaign_outlined,
                AppRoutes.myAds),
          ],
        ),
        const HomeMenuGroup(
          tileKey: Key('home-menu-explore'),
          icon: Icons.explore_outlined,
          title: 'Jelajahi',
          subtitle: 'Komunitas, anggota & ranking',
          children: [
            _MenuLink('home-public-directory', 'Cari komunitas',
                Icons.travel_explore_outlined, '/explore'),
            _MenuLink('home-public-members', 'Cari anggota & asalnya',
                Icons.person_search_outlined, '/explore?members=1'),
            _MenuLink('home-community-rankings', 'Ranking komunitas',
                Icons.emoji_events_outlined, AppRoutes.rankings),
            _MenuLink('home-public-ads', 'Iklan anggota',
                Icons.campaign_outlined, AppRoutes.memberAds),
          ],
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class HomeMenuGroup extends StatelessWidget {
  const HomeMenuGroup(
      {super.key,
      required this.tileKey,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.children});
  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: tileKey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          leading:
              Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle:
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          children: children,
        ),
      );
}

class _MenuLink extends StatelessWidget {
  const _MenuLink(this.id, this.label, this.icon, this.location);
  final String id, label, location;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
        key: Key(id),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, size: 20),
        title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () => context.push(location),
      );
}
