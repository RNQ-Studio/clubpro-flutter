import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../community/domain/entities/community.dart';
import '../../community/presentation/active_community_notifier.dart';
import '../../community/presentation/community_providers.dart';
import '../../community/presentation/widgets/club_hero.dart';
import '../../community/presentation/widgets/community_start_view.dart';
import '../../community/presentation/widgets/community_visuals.dart';
import '../../dues/presentation/dues_providers.dart';
import '../../finance/presentation/finance_widgets.dart';
import 'home_providers.dart';
import '../../achievements/presentation/achievements_providers.dart';
import '../../finance/presentation/finance_providers.dart';
import 'widgets/home_app_version.dart';
import 'widgets/home_club_card.dart';
import 'widgets/home_club_chooser.dart';
import 'widgets/home_dues_card.dart';
import 'widgets/home_dashboard_sections.dart';
import 'widgets/home_user_header.dart';
import 'widgets/promotion_popup_gate.dart';

/// Beranda berpusat pada komunitas aktif: anggota melihat menu dan kegiatan
/// komunitasnya, pengelola juga melihat yang perlu ditindaklanjuti. Belum
/// tergabung → cari atau daftarkan komunitas; beberapa komunitas tanpa pilihan
/// tersimpan → pilih dulu masuk sebagai anggota yang mana. Paid Promotion
/// tampil sebagai popup di atasnya tiap sekian jam ([PromotionPopupGate]).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Lebar isi di layar lebar agar kartu tidak melar.
  static const maxContentWidth = 1120.0;

  Future<void> _refresh(WidgetRef ref) async {
    final active = ref.read(activeCommunityProvider).value?.active;
    ref.invalidate(walletSummaryProvider);
    ref.invalidate(myAchievementsProvider);
    ref.invalidate(memberAdsProvider);
    ref.invalidate(rankingsProvider);
    ref.invalidate(homePromotionsProvider);
    ref.invalidate(joinedCommunitiesProvider);
    ref.invalidate(recommendedCommunitiesProvider);
    if (active != null) {
      ref.invalidate(communityDetailProvider(active.id));
      ref.invalidate(communityActivitiesProvider(active.id));
      ref.invalidate(duesOverviewProvider(active.id, null));
    }
    await ref.read(authProvider.notifier).checkCurrentUser();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final mine = ref.watch(activeCommunityProvider);
    final mineValue = mine.value;
    final active = mineValue?.active;
    final detail = active == null
        ? null
        : ref.watch(communityDetailProvider(active.id)).value;
    final restricted =
        (detail?.entitlementActive ?? active?.entitlementActive) == false ||
            (detail?.platformActive ?? active?.platformActive) == false;

    final List<Widget> clubSection;
    if (mineValue == null) {
      clubSection = [
        mine.hasError
            ? _ClubLoadError(
                onRetry: () => ref.invalidate(joinedCommunitiesProvider),
              )
            : const _ClubLoading(),
      ];
    } else if (mineValue.active case final active?) {
      clubSection = [
        _ActiveClub(community: active, joined: mineValue.joined),
      ];
    } else if (mineValue.needsChoice) {
      clubSection = [
        HomeClubChooser(
          communities: mineValue.joined,
          onChoose: (c) =>
              ref.read(activeCommunityProvider.notifier).choose(c.id),
        ),
      ];
    } else {
      clubSection = [
        Text(
          'Mulai bersama komunitas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cari atau buat komunitas untuk memulai.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 14),
        CommunityStartView(requests: mineValue.requests),
      ];
    }

    return PromotionPopupGate(
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.max(
                    16.0, (constraints.maxWidth - maxContentWidth) / 2);
                final primary = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: clubSection,
                );
                final wide = constraints.maxWidth >= 980 &&
                    MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                return ListView(
                  key: const Key('home-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(side, 12, side, 20),
                  children: [
                    if (user != null)
                      Row(children: [
                        Expanded(
                          child: HomeUserHeader(
                            user: user,
                            onTap: () => context.go(AppRoutes.profile),
                          ),
                        ),
                        IconButton.outlined(
                          key: const Key('home-billing-notices'),
                          tooltip: 'Pengingat pembayaran',
                          onPressed: () =>
                              context.push(AppRoutes.billingNotices),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                      ]),
                    const SizedBox(height: 14),
                    if (wide)
                      Row(
                        key: const Key('home-desktop-columns'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: primary),
                          if (user != null) ...[
                            const SizedBox(width: 12),
                            const Expanded(
                                flex: 5, child: HomeAccountSummary()),
                          ],
                        ],
                      )
                    else ...[
                      primary,
                      if (user != null) ...[
                        const SizedBox(height: 12),
                        const HomeAccountSummary(),
                      ],
                    ],
                    const SizedBox(height: 16),
                    HomeMenuGroups(
                      community: active,
                      detail: detail,
                      restricted: restricted,
                      isSuperAdmin: user?.isSuperAdmin == true,
                    ),
                    const SizedBox(height: 18),
                    const HomeAppVersion(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Isi Beranda untuk komunitas aktif.
class _ActiveClub extends ConsumerWidget {
  const _ActiveClub({required this.community, required this.joined});

  final Community community;

  /// Semua komunitas yang diikuti, termasuk [community].
  final List<Community> joined;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Angka untuk pengelola baru ada di detail; ringkasan cukup untuk sisanya.
    final detail = ref.watch(communityDetailProvider(community.id)).value;
    final restricted =
        (detail?.entitlementActive ?? community.entitlementActive) == false ||
            (detail?.platformActive ?? community.platformActive) == false;

    void openTab(int tab) => context.push(ClubTab.location(community.id, tab));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeClubCard(
          community: community,
          onOpen: () => openTab(ClubTab.info),
          onSwitch: joined.length > 1
              ? () => showHomeClubSwitcher(
                    context,
                    communities: joined,
                    active: community,
                    onChoose: (c) =>
                        ref.read(activeCommunityProvider.notifier).choose(c.id),
                  )
              : null,
        ),
        HomeDuesCard(communityId: community.id),
        if (restricted) ...[
          const FinanceMessage(
              'Akses dibatasi. Selesaikan pembayaran untuk aktif kembali.'),
          FilledButton.icon(
            key: const Key('home-restricted-billing'),
            style: FilledButton.styleFrom(
              backgroundColor: CommunityColors.brown,
              foregroundColor: Colors.white,
            ),
            onPressed: () => context.push(
                '${AppRoutes.communityBilling(community.id)}${(detail?.myRole ?? community.myRole) == CommunityRole.creator ? '?scope=platform' : ''}'),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Pembayaran'),
          ),
          OutlinedButton(
              key: const Key('home-restricted-card'),
              onPressed: () =>
                  context.push(AppRoutes.communityCard(community.id)),
              child: const Text('Status KTA')),
        ],
      ],
    );
  }
}

/// Tempat kartu komunitas selama dimuat, agar isi tidak melompat.
class _ClubLoading extends StatelessWidget {
  const _ClubLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('home-club-loading'),
      height: 132,
      decoration: BoxDecoration(
        color: communityHairline(context),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _ClubLoadError extends StatelessWidget {
  const _ClubLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('home-club-error'),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Komunitas Anda gagal dimuat. Periksa koneksi lalu coba lagi.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(
            key: const Key('home-club-retry'),
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
