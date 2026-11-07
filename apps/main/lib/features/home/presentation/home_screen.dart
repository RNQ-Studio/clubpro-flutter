import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../community/presentation/community_providers.dart';
import '../domain/entities/home_banner.dart';
import 'home_providers.dart';
import 'widgets/home_admin_panel_card.dart';
import 'widgets/home_app_version.dart';
import 'widgets/home_banner_slider.dart';
import 'widgets/home_community_card.dart';
import 'widgets/home_menu_grid.dart';
import 'widgets/home_my_communities.dart';
import 'widgets/home_user_header.dart';

/// Beranda: info anggota, komunitas saya, banner (bila ada), dan menu utama.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Tetap berisi banner lama selama disegarkan; saat memuat pertama kali kosong.
    final banners = ref.watch(homeBannersProvider).value ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeBannersProvider);
            ref.invalidate(joinedCommunitiesProvider);
            await ref.read(authProvider.notifier).checkCurrentUser();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (authState is AuthAuthenticated)
                HomeUserHeader(
                  user: authState.user,
                  onTap: () => context.go(AppRoutes.profile),
                ),
              const SizedBox(height: 10),
              const HomeMyCommunities(),
              const SizedBox(height: 12),
              if (banners.isNotEmpty) ...[
                HomeBannerSlider(
                  banners: banners,
                  onTap: (b) => _openBanner(context, b),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Text(
                'Menu Utama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              HomeCommunityCard(
                onTap: () => context.go(AppRoutes.communities),
              ),
              const SizedBox(height: 18),
              HomeMenuGrid(onTap: (menu) => showComingSoonSheet(context, menu)),
              if (authState is AuthAuthenticated &&
                  authState.user.isSuperAdmin) ...[
                const SizedBox(height: 20),
                HomeAdminPanelCard(
                  onTap: () => context.push(AppRoutes.adminPanel),
                ),
              ],
              const SizedBox(height: 28),
              const HomeAppVersion(),
            ],
          ),
        ),
      ),
    );
  }
}
