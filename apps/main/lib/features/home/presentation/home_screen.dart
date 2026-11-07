import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../community/domain/entities/community.dart';
import '../../community/presentation/active_community_notifier.dart';
import '../../community/presentation/community_providers.dart';
import '../../community/presentation/widgets/club_hero.dart';
import '../../community/presentation/widgets/community_start_view.dart';
import '../../community/presentation/widgets/community_visuals.dart';
import '../../dues/presentation/dues_providers.dart';
import '../domain/entities/home_banner.dart';
import 'home_providers.dart';
import 'widgets/home_admin_panel_card.dart';
import 'widgets/home_app_version.dart';
import 'widgets/home_banner_slider.dart';
import 'widgets/home_club_card.dart';
import 'widgets/home_club_chooser.dart';
import 'widgets/home_club_sections.dart';
import 'widgets/home_dues_card.dart';
import 'widgets/home_user_header.dart';

/// Beranda berpusat pada komunitas aktif: anggota melihat menu dan kegiatan
/// komunitasnya, pengelola juga melihat yang perlu ditindaklanjuti. Belum
/// tergabung → cari atau daftarkan komunitas; beberapa komunitas tanpa pilihan
/// tersimpan → pilih dulu masuk sebagai anggota yang mana.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Lebar isi di layar lebar agar kartu tidak melar.
  static const maxContentWidth = 760.0;

  Future<void> _openBanner(BuildContext context, HomeBanner banner) async {
    final link = banner.linkUrl;
    if (link == null || link.isEmpty) return;
    if (link.startsWith('/')) {
      // Ditumpuk di atas Beranda: tombol kembali kembali ke sini.
      context.push(link);
      return;
    }
    final uri = Uri.tryParse(link);
    final web = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!web || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan tidak dapat dibuka')),
        );
      }
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    final active = ref.read(activeCommunityProvider).value?.active;
    ref.invalidate(homeBannersProvider);
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
    // Tetap berisi banner lama selama disegarkan; saat memuat pertama kali kosong.
    final banners = ref.watch(homeBannersProvider).value ?? const [];
    final mine = ref.watch(activeCommunityProvider);
    final mineValue = mine.value;

    final bannerSlider = banners.isEmpty
        ? null
        : HomeBannerSlider(
            banners: banners,
            onTap: (b) => _openBanner(context, b),
          );

    final List<Widget> clubSection;
    if (mineValue == null) {
      clubSection = [
        mine.hasError
            ? _ClubLoadError(
                onRetry: () => ref.invalidate(joinedCommunitiesProvider),
              )
            : const _ClubLoading(),
        if (bannerSlider != null) ...[const SizedBox(height: 16), bannerSlider],
      ];
    } else if (mineValue.active case final active?) {
      clubSection = [
        _ActiveClub(
          community: active,
          joined: mineValue.joined,
          banner: bannerSlider,
        ),
      ];
    } else if (mineValue.needsChoice) {
      clubSection = [
        HomeClubChooser(
          communities: mineValue.joined,
          onChoose: (c) =>
              ref.read(activeCommunityProvider.notifier).choose(c.id),
        ),
        if (bannerSlider != null) ...[const SizedBox(height: 16), bannerSlider],
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
          'Anda belum tergabung di komunitas mana pun. Cari komunitas yang '
          'sudah ada atau daftarkan komunitas Anda.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 14),
        // Pilihan cari/daftarkan lebih dulu; banner tidak boleh mendorongnya
        // ke bawah layar.
        CommunityStartView(requests: mineValue.requests),
        if (bannerSlider != null) ...[const SizedBox(height: 20), bannerSlider],
      ];
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side =
                  math.max(16.0, (constraints.maxWidth - maxContentWidth) / 2);
              return ListView(
                padding: EdgeInsets.fromLTRB(side, 12, side, 24),
                children: [
                  if (user != null)
                    HomeUserHeader(
                      user: user,
                      onTap: () => context.go(AppRoutes.profile),
                    ),
                  const SizedBox(height: 10),
                  ...clubSection,
                  if (user != null && user.isSuperAdmin) ...[
                    const SizedBox(height: 24),
                    HomeAdminPanelCard(
                      onTap: () => context.push(AppRoutes.adminPanel),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const HomeAppVersion(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Isi Beranda untuk komunitas aktif.
class _ActiveClub extends ConsumerWidget {
  const _ActiveClub({
    required this.community,
    required this.joined,
    required this.banner,
  });

  final Community community;

  /// Semua komunitas yang diikuti, termasuk [community].
  final List<Community> joined;
  final Widget? banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Angka untuk pengelola baru ada di detail; ringkasan cukup untuk sisanya.
    final detail = ref.watch(communityDetailProvider(community.id)).value;
    final manager = detail != null && detail.canManage ? detail : null;

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
        if (banner != null) ...[const SizedBox(height: 16), banner!],
        const SizedBox(height: 20),
        const HomeSectionTitle('Menu Komunitas'),
        HomeClubMenu(
          onOpenTab: openTab,
          pendingRequests: manager?.pendingMembersCount ?? 0,
        ),
        if (manager != null) ...[
          const SizedBox(height: 20),
          HomeManagerPanel(community: manager, onOpenTab: openTab),
        ],
        const SizedBox(height: 20),
        HomeUpcomingActivities(
          communityId: community.id,
          onSeeAll: () => openTab(ClubTab.activities),
        ),
        const SizedBox(height: 20),
        HomeMoreCommunities(
          onFind: () => context.push(AppRoutes.communities),
          onCreate: () => context.push(AppRoutes.createCommunity),
        ),
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
