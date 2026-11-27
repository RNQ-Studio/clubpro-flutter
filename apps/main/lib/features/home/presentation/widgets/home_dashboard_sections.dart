import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../achievements/presentation/achievements_providers.dart';
import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/club_hero.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../../dues/presentation/widgets/dues_visuals.dart';
import '../../../finance/presentation/finance_providers.dart';
import 'home_club_sections.dart';

class HomeSurface extends StatelessWidget {
  const HomeSurface({super.key, required this.child, this.padding = 16});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: communityHairline(context)),
        ),
        child: Padding(padding: EdgeInsets.all(padding), child: child),
      );
}

/// Saldo dan poin tetap terpisah, tanpa judul dan uraian berulang.
class HomeAccountSummary extends ConsumerWidget {
  const HomeAccountSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletSummaryProvider);
    final points = ref.watch(myAchievementsProvider());
    final metrics = [
      _SummaryMetric(
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF16835C),
        label: 'Saldo',
        tooltip: 'Saldo tersedia',
        onTap: () => context.push(AppRoutes.wallet),
        value: wallet.when(
          skipLoadingOnRefresh: false,
          data: (w) => Text(formatRupiah(w.available),
              key: const Key('member-lobby-balance')),
          loading: () => const Text('…', semanticsLabel: 'Memuat saldo'),
          error: (_, __) => _MetricRetry(
            key: const Key('home-wallet-retry'),
            message: 'Saldo gagal dimuat',
            onRetry: () => ref.invalidate(walletSummaryProvider),
          ),
        ),
      ),
      _SummaryMetric(
        icon: Icons.emoji_events_outlined,
        color: CommunityColors.gold,
        label: 'Poin',
        tooltip: 'Poin prestasi',
        onTap: () => context.push(AppRoutes.myAchievements),
        value: points.when(
          skipLoadingOnRefresh: false,
          data: (p) => Text(
              '${NumberFormat.decimalPattern('id').format(p.totalPoints)} poin',
              key: const Key('member-lobby-points')),
          loading: () => const Text('…', semanticsLabel: 'Memuat poin'),
          error: (_, __) => _MetricRetry(
            key: const Key('home-points-retry'),
            message: 'Poin gagal dimuat',
            onRetry: () => ref.invalidate(myAchievementsProvider),
          ),
        ),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      return constraints.maxWidth >= 300 * scale
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: metrics[0]),
              const SizedBox(width: 10),
              Expanded(child: metrics[1]),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              metrics[0],
              const SizedBox(height: 10),
              metrics[1],
            ]);
    });
  }
}

class _MetricRetry extends StatelessWidget {
  const _MetricRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: message,
        child: TextButton.icon(
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
              alignment: Alignment.centerLeft),
          onPressed: onRetry,
          icon: Icon(Icons.refresh_rounded,
              size: 18, color: Theme.of(context).colorScheme.error),
          label: const Text('Coba lagi'),
        ),
      );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric(
      {required this.icon,
      required this.color,
      required this.label,
      required this.tooltip,
      required this.value,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String label, tooltip;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, .25)!
        : color;
    return HomeSurface(
      padding: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Tooltip(
                  message: tooltip, child: Icon(icon, color: accent, size: 19)),
              const SizedBox(width: 7),
              Expanded(
                  child: Text(label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ]),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
              child: value,
            ),
          ]),
        ),
      ),
    );
  }
}

/// Satu pilihan kelompok membuka satu panel submenu di bawah grid.
class HomeMenuGroups extends StatefulWidget {
  const HomeMenuGroups(
      {super.key,
      this.community,
      this.detail,
      this.restricted = false,
      this.isSuperAdmin = false});
  final Community? community;
  final CommunityDetail? detail;
  final bool restricted, isSuperAdmin;

  @override
  State<HomeMenuGroups> createState() => _HomeMenuGroupsState();
}

class _HomeMenuGroupsState extends State<HomeMenuGroups> {
  String? _open;

  @override
  void didUpdateWidget(covariant HomeMenuGroups oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.community?.id != widget.community?.id ||
        oldWidget.restricted != widget.restricted ||
        oldWidget.detail?.canManage != widget.detail?.canManage ||
        oldWidget.detail?.myRole != widget.detail?.myRole ||
        oldWidget.isSuperAdmin != widget.isSuperAdmin) {
      _open = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.community;
    final detail = widget.detail;
    final enabled = active != null && !widget.restricted;
    final canRecord = detail != null &&
        detail.isMember &&
        (detail.myRole?.canManage == true ||
            detail.myRole == CommunityRole.coach) &&
        !widget.restricted;
    final manager = enabled && detail?.canManage == true ? detail : null;
    const blue = Color(0xFF2867BB);
    const orange = Color(0xFFB86114);
    const green = Color(0xFF16835C);
    const purple = Color(0xFF8450B6);
    const teal = Color(0xFF21838C);
    HomeMenuAction link(String id, String label, IconData icon, String location,
            Color color,
            {String? tooltip}) =>
        HomeMenuAction(
          key: Key(id),
          label: label,
          icon: icon,
          color: color,
          tooltip: tooltip,
          onTap: () => context.push(location),
        );
    void openTab(int tab) => context.push(ClubTab.location(active!.id, tab));

    final groups = <_MenuCategory>[
      if (enabled)
        _MenuCategory('community', 'Komunitas', Icons.groups_rounded, blue, [
          HomeClubMenu(
            onOpenTab: openTab,
            onOpenCard: () => context.push(AppRoutes.communityCard(active.id)),
            pendingRequests: manager?.pendingMembersCount ?? 0,
          ),
        ]),
      if (enabled)
        _MenuCategory(
            'activity', 'Aktivitas', Icons.event_note_rounded, orange, [
          HomeActionGrid(children: [
            link(
                'home-club-menu-${ClubTab.activities}',
                'Kegiatan',
                Icons.event_note_rounded,
                ClubTab.location(active.id, ClubTab.activities),
                orange),
            link('training-entry', 'Paket latihan', Icons.sports_outlined,
                AppRoutes.communityTraining(active.id), orange),
            link('member-lobby-achievements', 'Prestasi saya',
                Icons.military_tech_outlined, AppRoutes.myAchievements, orange),
            link(
                'community-member-rankings',
                'Peringkat',
                Icons.emoji_events_outlined,
                '${AppRoutes.rankings}?community=${active.id}',
                orange,
                tooltip: 'Peringkat anggota komunitas'),
            if (canRecord)
              link(
                  'community-record-achievement',
                  'Catat prestasi',
                  Icons.fact_check_outlined,
                  AppRoutes.communityAchievements(active.id),
                  orange),
          ]),
          const SizedBox(height: 18),
          HomeUpcomingActivities(
              communityId: active.id,
              onSeeAll: () => openTab(ClubTab.activities)),
        ]),
      _MenuCategory(
          'finance',
          'Keuangan',
          Icons.account_balance_wallet_rounded,
          green,
          [
            HomeActionGrid(children: [
              link(
                  'home-wallet',
                  'Saldo',
                  Icons.account_balance_wallet_outlined,
                  AppRoutes.wallet,
                  green),
              link(
                  'member-lobby-topup',
                  'Top up',
                  Icons.add_card_outlined,
                  active == null
                      ? AppRoutes.topup
                      : '${AppRoutes.topup}?community=${active.id}',
                  green),
              if (active != null) ...[
                link('finance-entry', 'Iuran', Icons.receipt_long_outlined,
                    AppRoutes.communityBilling(active.id), green),
                if ((detail?.myRole ?? active.myRole) == CommunityRole.creator)
                  link(
                      'home-platform-billing',
                      'Langganan',
                      Icons.business_outlined,
                      '${AppRoutes.communityBilling(active.id)}?scope=platform',
                      green,
                      tooltip: 'Langganan aplikasi komunitas'),
              ],
              link('member-lobby-payouts', 'Pencairan', Icons.payments_outlined,
                  AppRoutes.payouts, green),
            ]),
          ],
          attention: widget.restricted),
      _MenuCategory('market', 'Jual beli', Icons.storefront_rounded, purple, [
        HomeActionGrid(children: [
          link('market-entry-main', 'Marketplace', Icons.shopping_bag_outlined,
              AppRoutes.marketProducts, purple),
          link('market-entry-mine', 'Lapak saya', Icons.storefront_outlined,
              AppRoutes.myMarketProducts, purple),
          link('member-lobby-ads', 'Iklan saya', Icons.campaign_outlined,
              AppRoutes.myAds, purple),
          if (enabled) ...[
            link(
                'market-entry-community',
                'Jualan anggota',
                Icons.groups_outlined,
                AppRoutes.marketCatalogue(communityId: active.id),
                purple,
                tooltip: 'Jualan anggota komunitas aktif'),
            link(
                'community-member-ads',
                'Iklan komunitas',
                Icons.campaign_outlined,
                '${AppRoutes.memberAds}?community=${active.id}',
                purple),
          ],
        ]),
      ]),
      _MenuCategory('explore', 'Jelajahi', Icons.explore_rounded, teal, [
        HomeActionGrid(children: [
          link('home-public-directory', 'Komunitas',
              Icons.travel_explore_outlined, '/explore', teal,
              tooltip: 'Direktori komunitas publik'),
          link('home-public-members', 'Anggota', Icons.person_search_outlined,
              '/explore?members=1', teal),
          link('home-community-rankings', 'Peringkat',
              Icons.emoji_events_outlined, AppRoutes.rankings, teal,
              tooltip: 'Peringkat semua komunitas'),
          link('home-public-ads', 'Iklan', Icons.campaign_outlined,
              AppRoutes.memberAds, teal),
          link('home-more-find', 'Gabung', Icons.group_add_outlined,
              AppRoutes.communities, teal,
              tooltip: 'Cari komunitas untuk bergabung'),
          link('home-more-create', 'Buat komunitas',
              Icons.add_business_outlined, AppRoutes.createCommunity, teal),
        ]),
      ]),
      if (manager != null)
        _MenuCategory(
            'manage',
            'Kelola',
            Icons.admin_panel_settings_rounded,
            CommunityColors.gold,
            [
              HomeManagerPanel(community: manager, onOpenTab: openTab),
            ],
            count:
                manager.pendingMembersCount + manager.pendingDuesPaymentsCount),
      if (widget.isSuperAdmin)
        _MenuCategory('admin', 'Pusat', Icons.verified_user_rounded,
            const Color(0xFF5963AA), [
          HomeActionGrid(children: [
            link(
                'home-admin-panel',
                'Admin panel',
                Icons.admin_panel_settings_outlined,
                AppRoutes.adminPanel,
                const Color(0xFF5963AA)),
            link('member-lobby-point-rules', 'Atur poin', Icons.tune_rounded,
                AppRoutes.achievementRules, const Color(0xFF5963AA)),
          ]),
        ]),
    ];
    final selected = groups.where((g) => g.id == _open).firstOrNull;
    return HomeSurface(
      key: const Key('home-menu-dashboard'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final maxColumns = constraints.maxWidth >= 680 ? groups.length : 3;
          final columns = math
              .min(maxColumns, (constraints.maxWidth / (84 * scale)).floor())
              .clamp(1, groups.length);
          final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
          return Wrap(spacing: 8, runSpacing: 8, children: [
            for (final group in groups)
              SizedBox(
                  width: width,
                  child: _CategoryTile(
                    key: group.id == 'manage'
                        ? const Key('home-manage-expand')
                        : Key('home-menu-${group.id}'),
                    group: group,
                    selected: selected == group,
                    onTap: () => setState(
                        () => _open = selected == group ? null : group.id),
                  )),
          ]);
        }),
        if (selected != null) ...[
          const SizedBox(height: 16),
          Divider(height: 1, color: communityHairline(context)),
          Padding(
            key: Key('home-submenu-${selected.id}'),
            padding: const EdgeInsets.only(top: 12),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(selected.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700))),
                    IconButton(
                      key: const Key('home-submenu-close'),
                      tooltip: 'Tutup submenu',
                      onPressed: () => setState(() => _open = null),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  ...selected.children,
                ]),
          ),
        ],
      ]),
    );
  }
}

class _MenuCategory {
  const _MenuCategory(this.id, this.title, this.icon, this.color, this.children,
      {this.count = 0, this.attention = false});
  final String id, title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final int count;
  final bool attention;
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile(
      {super.key,
      required this.group,
      required this.selected,
      required this.onTap});
  final _MenuCategory group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.brightness == Brightness.dark
        ? Color.lerp(group.color, Colors.white, .3)!
        : group.color;
    return Semantics(
      button: true,
      selected: selected,
      onTapHint: selected ? 'Tutup submenu' : 'Buka submenu',
      child: Tooltip(
        message: group.count > 0
            ? '${group.title}: ${group.count} menunggu'
            : group.attention
                ? 'Pembayaran perlu diselesaikan'
                : group.title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: .09)
                  : theme.colorScheme.onSurface.withValues(alpha: .025),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? accent : communityHairline(context)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Badge(
                  key: group.id == 'manage'
                      ? const Key('home-manager-pending-badge')
                      : null,
                  isLabelVisible: group.count > 0,
                  label: Text(group.count > 99 ? '99+' : '${group.count}'),
                  child: Icon(group.icon, color: accent, size: 28),
                ),
                const Spacer(),
                Icon(
                    group.attention
                        ? Icons.error_outline_rounded
                        : selected
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                    color: group.attention
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                    size: 16),
              ]),
              const SizedBox(height: 12),
              Text(group.title,
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
            ]),
          ),
        ),
      ),
    );
  }
}
