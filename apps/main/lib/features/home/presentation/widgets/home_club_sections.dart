import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/community_providers.dart';
import '../../../community/presentation/widgets/club_activities_tab.dart';
import '../../../community/presentation/widgets/club_hero.dart';
import '../../../community/presentation/widgets/community_visuals.dart';

/// Judul bagian Beranda, dengan aksi opsional di kanan.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: LayoutBuilder(builder: (context, constraints) {
        final stack = action != null &&
            constraints.maxWidth <
                300 * MediaQuery.textScalerOf(context).scale(1);
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              Align(alignment: Alignment.centerRight, child: action)
            ],
          );
        }
        return Row(
          children: [Expanded(child: heading), if (action != null) action!],
        );
      }),
    );
  }
}

/// Aksi ringkas dengan ikon, label singkat dan badge bernilai nyata.
class HomeMenuAction extends StatelessWidget {
  const HomeMenuAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = CommunityColors.gold,
    this.count = 0,
    this.badgeKey,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final int count;
  final Key? badgeKey;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        theme.brightness == Brightness.dark && color.computeLuminance() < .18
            ? Color.lerp(color, Colors.white, .4)!
            : color;
    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Badge(
            key: badgeKey,
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: Icon(icon, size: 21, color: foreground),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500))),
        ]),
      ),
    );
    return Semantics(
      button: true,
      label: count > 0 ? '$count menunggu' : null,
      child: tooltip == null
          ? content
          : Tooltip(message: tooltip!, child: content),
    );
  }
}

/// Grid dengan tinggi alami: teks besar membentuk kolom lebih sedikit.
class HomeActionGrid extends StatelessWidget {
  const HomeActionGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final columns =
            (constraints.maxWidth / (140 * scale)).floor().clamp(1, 4);
        final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
        return Wrap(spacing: 8, runSpacing: 8, children: [
          for (final child in children) SizedBox(width: width, child: child),
        ]);
      });
}

/// Menu komunitas tampil setelah kelompok Komunitas dipilih.
class HomeClubMenu extends StatelessWidget {
  const HomeClubMenu({
    super.key,
    required this.onOpenTab,
    required this.onOpenCard,
    this.pendingRequests = 0,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenCard;
  final int pendingRequests;

  static const cardItem = ('KTA', Icons.badge_rounded, Color(0xFF5C3A02));
  static const items = [
    (ClubTab.info, 'Info', Icons.info_rounded, Color(0xFFBE8815)),
    (ClubTab.members, 'Anggota', Icons.groups_rounded, Color(0xFF1E6FD9)),
    (ClubTab.gallery, 'Galeri', Icons.photo_library_rounded, Color(0xFF178A5B)),
  ];

  @override
  Widget build(BuildContext context) => HomeActionGrid(children: [
        HomeMenuAction(
          key: const Key('home-club-menu-card'),
          label: cardItem.$1,
          tooltip: 'Kartu anggota komunitas',
          icon: cardItem.$2,
          color: cardItem.$3,
          onTap: onOpenCard,
        ),
        for (final (tab, label, icon, color) in items)
          HomeMenuAction(
            key: Key('home-club-menu-$tab'),
            label: label,
            icon: icon,
            color: color,
            onTap: () => onOpenTab(tab),
            badgeKey: tab == ClubTab.members
                ? const Key('home-club-requests-badge')
                : null,
            count: tab == ClubTab.members ? pendingRequests : 0,
          ),
      ]);
}

/// Submenu pengelola; ringkasan tindak lanjut ada pada badge kelompok Kelola.
class HomeManagerPanel extends StatelessWidget {
  const HomeManagerPanel(
      {super.key, required this.community, required this.onOpenTab});
  final CommunityDetail community;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notice = switch (community.status) {
      CommunityStatus.pending => 'Menunggu verifikasi komunitas.',
      CommunityStatus.rejected =>
        'Pengajuan ditolak. Lihat alasan di info komunitas.',
      CommunityStatus.approved => null,
    };
    return Column(
      key: const Key('home-manager-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (notice != null) ...[
          Text(notice,
              key: const Key('home-manager-notice'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
          const SizedBox(height: 12),
        ],
        HomeActionGrid(children: [
          HomeMenuAction(
            key: const Key('home-manage-requests'),
            icon: Icons.person_add_alt_1_rounded,
            label: 'Permintaan',
            tooltip:
                'Permintaan bergabung: ${community.pendingMembersCount} menunggu',
            count: community.pendingMembersCount,
            onTap: () => onOpenTab(ClubTab.members),
          ),
          HomeMenuAction(
            key: const Key('home-manage-activities'),
            icon: Icons.event_available_rounded,
            label: 'Kegiatan',
            onTap: () => onOpenTab(ClubTab.activities),
          ),
          HomeMenuAction(
            key: const Key('home-manage-gallery'),
            icon: Icons.add_photo_alternate_rounded,
            label: 'Galeri',
            onTap: () => onOpenTab(ClubTab.gallery),
          ),
          if (community.duesConfigured) ...[
            HomeMenuAction(
              key: const Key('home-manage-dues-payments'),
              icon: Icons.fact_check_rounded,
              label: 'Verifikasi iuran',
              tooltip:
                  '${community.pendingDuesPaymentsCount} bukti transfer menunggu',
              count: community.pendingDuesPaymentsCount,
              onTap: () =>
                  context.push(AppRoutes.communityDuesPayments(community.id)),
            ),
            HomeMenuAction(
              key: const Key('home-manage-dues-calendar'),
              icon: Icons.calendar_month_rounded,
              label: 'Kalender iuran',
              onTap: () =>
                  context.push(AppRoutes.communityDuesMembers(community.id)),
            ),
          ],
          HomeMenuAction(
            key: const Key('home-manage-dues-settings'),
            icon: Icons.tune_rounded,
            label: 'Atur iuran',
            tooltip: community.duesConfigured
                ? 'Nominal, uang masuk, tanggal mulai dan rekening'
                : 'Iuran belum diatur',
            onTap: () =>
                context.push(AppRoutes.communityDuesSettings(community.id)),
          ),
        ]),
      ],
    );
  }
}

/// Paling banyak tiga kegiatan terdekat komunitas aktif.
class HomeUpcomingActivities extends ConsumerWidget {
  const HomeUpcomingActivities({
    super.key,
    required this.communityId,
    required this.onSeeAll,
  });

  static const limit = 3;

  final String communityId;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final provider = communityActivitiesProvider(communityId);
    final activities = ref.watch(provider);
    final upcoming = activities.value?.upcoming;

    final Widget body;
    if (upcoming != null) {
      body = upcoming.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Belum ada kegiatan terjadwal.',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            )
          : Column(
              children: [
                for (final activity in upcoming.take(limit))
                  InkWell(
                    key: Key('home-activity-${activity.id}'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: onSeeAll,
                    child: ClubActivityTile(activity: activity),
                  ),
              ],
            );
    } else if (activities.hasError) {
      body = Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Kegiatan gagal dimuat.',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ),
          ),
          TextButton(
            key: const Key('home-activities-retry'),
            onPressed: () => ref.invalidate(provider),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    } else {
      // Tempat kosong seukuran satu kegiatan agar isi tidak melompat.
      body = const SizedBox(height: 64);
    }

    return Column(
      key: const Key('home-upcoming-activities'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          'Kegiatan Mendatang',
          action: TextButton(
            key: const Key('home-activities-all'),
            onPressed: onSeeAll,
            child: const Text('Lihat semua'),
          ),
        ),
        body,
      ],
    );
  }
}

/// Pintu ke komunitas lain bagi yang sudah tergabung.
class HomeMoreCommunities extends StatelessWidget {
  const HomeMoreCommunities({
    super.key,
    required this.onFind,
    required this.onCreate,
  });

  final VoidCallback onFind;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final find = OutlinedButton.icon(
      key: const Key('home-more-find'),
      onPressed: onFind,
      icon: const Icon(Icons.travel_explore_rounded),
      label: const Text('Cari Komunitas'),
    );
    final create = OutlinedButton.icon(
      key: const Key('home-more-create'),
      onPressed: onCreate,
      icon: const Icon(Icons.add_business_rounded),
      label: const Text('Daftarkan Baru'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSectionTitle('Komunitas Lain'),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 380
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [find, const SizedBox(height: 8), create],
                )
              : Row(
                  children: [
                    Expanded(child: find),
                    const SizedBox(width: 10),
                    Expanded(child: create),
                  ],
                ),
        ),
      ],
    );
  }
}
