import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin_community_providers.dart';
import '../widgets/admin_banner_widgets.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Admin Panel: menu fitur khusus super admin.
class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminGate(child: _AdminPanelView());
}

class _AdminPanelView extends ConsumerWidget {
  const _AdminPanelView();

  /// Lebar minimum untuk menu berdampingan.
  static const _twoColumnWidth = 640.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(adminSummaryProvider).asData?.value;
    final pending = summary?.communities.pending ?? 0;

    final users = _AdminMenuCard(
      menuKey: const Key('admin-menu-users'),
      icon: Icons.manage_accounts_rounded,
      color: const Color(0xFF1E6FD9),
      title: 'Kelola User',
      description: 'Lihat pengguna terdaftar dan atur akses super admin',
      stat: summary == null ? null : '${summary.totalUsers} pengguna',
      onTap: () => context.push(AppRoutes.adminUsers),
    );
    final communities = _AdminMenuCard(
      menuKey: const Key('admin-menu-communities'),
      icon: Icons.diversity_3_rounded,
      color: adminGold,
      title: 'Kelola Komunitas',
      description: 'Periksa data komunitas dan verifikasi pengajuannya',
      stat: summary == null ? null : '${summary.communities.total} komunitas',
      badge: pending > 0 ? '$pending menunggu verifikasi' : null,
      onTap: () => context.push(AppRoutes.adminCommunities),
    );
    final bannerSummary = summary?.banners;
    final banners = _AdminMenuCard(
      menuKey: const Key('admin-menu-banners'),
      icon: Icons.campaign_rounded,
      color: const Color(0xFFE8710A),
      title: 'Paid Promotion',
      description: 'Popup promosi di Beranda: gambar, tombol WhatsApp atau '
          'tautan, dan jeda tampilnya',
      stat: bannerSummary == null
          ? null
          : '${bannerSummary.total} promosi · ${bannerSummary.live} tayang · '
              'tiap ${promotionIntervalLabel(bannerSummary.intervalHours)}',
      onTap: () => context.push(AppRoutes.adminBanners),
    );
    final menus = [users, communities, banners];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        // Dibuka lewat tautan langsung: tidak ada halaman sebelumnya.
        leading: context.canPop()
            ? null
            : BackButton(onPressed: () => context.go('/')),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminSummaryProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < _twoColumnWidth) {
                      return Column(
                        children: [
                          for (final (i, menu) in menus.indexed) ...[
                            if (i > 0) const SizedBox(height: 12),
                            menu,
                          ],
                        ],
                      );
                    }
                    // Dua kolom; menu ganjil terakhir selebar satu kolom.
                    return Column(
                      children: [
                        for (var i = 0; i < menus.length; i += 2) ...[
                          if (i > 0) const SizedBox(height: 12),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: menus[i]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: i + 1 < menus.length
                                      ? menus[i + 1]
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.menuKey,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
    this.stat,
    this.badge,
  });

  final Key menuKey;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? stat;

  /// Hal yang menunggu tindakan.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: menuKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: adminHairline(context)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    if (stat != null || badge != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (stat != null)
                            Text(
                              stat!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (badge != null)
                            AdminBadge(label: badge!, color: adminGold),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}
