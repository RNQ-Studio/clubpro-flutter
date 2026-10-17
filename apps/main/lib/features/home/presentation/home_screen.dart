import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/entities/home_banner.dart';
import 'home_providers.dart';
import 'widgets/home_banner_slider.dart';
import 'widgets/home_menu_grid.dart';
import 'widgets/home_user_header.dart';

/// Beranda: info anggota (foto, nama, email), banner slider, menu utama club.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openBanner(BuildContext context, HomeBanner banner) async {
    final link = banner.linkUrl;
    if (link == null || link.isEmpty) return;
    if (link.startsWith('/')) {
      context.go(link);
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
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
    final banners = ref.watch(homeBannersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeBannersProvider);
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
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.zero,
                child: banners.when(
                  data: (items) => HomeBannerSlider(
                    banners: items,
                    onTap: (b) => _openBanner(context, b),
                  ),
                  loading: () => const AspectRatio(
                    aspectRatio: 16 / 8,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => HomeBannerSlider(
                    banners: defaultHomeBanners,
                    onTap: (b) => _openBanner(context, b),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Menu Utama',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              HomeMenuGrid(onTap: (menu) => showComingSoonSheet(context, menu)),
              const SizedBox(height: 28),
              const _AppVersion(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppVersion extends StatelessWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Text(
          '${info.appName} · Versi ${info.version}+${info.buildNumber}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
        );
      },
    );
  }
}
