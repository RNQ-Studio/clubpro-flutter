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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Menu komunitas aktif; tiap menu membuka halaman komunitas di tabnya.
class HomeClubMenu extends StatelessWidget {
  const HomeClubMenu({
    super.key,
    required this.onOpenTab,
    required this.onOpenCard,
    this.pendingRequests = 0,
  });

  final ValueChanged<int> onOpenTab;

  /// Kartu Anggota saya di komunitas ini.
  final VoidCallback onOpenCard;

  /// Penanda di menu Anggota; hanya terisi untuk pengelola.
  final int pendingRequests;

  /// Kartu Anggota tampil paling depan; bukan tab detail komunitas.
  static const cardItem = (
    'Kartu Anggota',
    Icons.badge_rounded,
    Color(0xFF5C3A02),
  );

  static const items = [
    (ClubTab.info, 'Info', Icons.info_rounded, Color(0xFFBE8815)),
    (ClubTab.members, 'Anggota', Icons.groups_rounded, Color(0xFF1E6FD9)),
    (
      ClubTab.activities,
      'Kegiatan',
      Icons.event_note_rounded,
      Color(0xFFE8710A)
    ),
    (ClubTab.gallery, 'Galeri', Icons.photo_library_rounded, Color(0xFF178A5B)),
  ];

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(height: 1.2, letterSpacing: 0);
    Widget item({
      required Key key,
      required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      Key? badgeKey,
      int badge = 0,
    }) =>
        Expanded(
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Badge(
                    key: badgeKey,
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ],
              ),
            ),
          ),
        );

    final (cardLabel, cardIcon, cardColor) = cardItem;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(
          key: const Key('home-club-menu-card'),
          label: cardLabel,
          icon: cardIcon,
          color: cardColor,
          onTap: onOpenCard,
        ),
        for (final (tab, label, icon, color) in items)
          item(
            key: Key('home-club-menu-$tab'),
            label: label,
            icon: icon,
            color: color,
            onTap: () => onOpenTab(tab),
            badgeKey: tab == ClubTab.members
                ? const Key('home-club-requests-badge')
                : null,
            badge: tab == ClubTab.members ? pendingRequests : 0,
          ),
      ],
    );
  }
}

/// Sisi pengelola (creator/admin): yang perlu ditindaklanjuti di komunitas ini.
class HomeManagerPanel extends StatelessWidget {
  const HomeManagerPanel({
    super.key,
    required this.community,
    required this.onOpenTab,
  });

  final CommunityDetail community;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final role = community.myRole ?? CommunityRole.admin;
    final requests = community.pendingMembersCount;
    final upcoming = community.upcomingActivitiesCount;
    final photos = community.photos.length;
    final duesPayments = community.pendingDuesPaymentsCount;
    final notice = switch (community.status) {
      CommunityStatus.pending => 'Menunggu verifikasi: komunitas belum bisa '
          'ditemukan dan diikuti anggota lain.',
      CommunityStatus.rejected => 'Pengajuan ditolak. Lihat alasannya di '
          'halaman komunitas.',
      CommunityStatus.approved => null,
    };

    return Container(
      key: const Key('home-manager-panel'),
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CommunityColors.gold.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    role == CommunityRole.creator
                        ? Icons.workspace_premium_rounded
                        : Icons.shield_rounded,
                    color: CommunityColors.gold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Komunitas',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Anda ${role.label} di komunitas ini',
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (notice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 8, 0),
              child: Text(
                notice,
                key: const Key('home-manager-notice'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: community.status == CommunityStatus.rejected
                      ? theme.colorScheme.error
                      : CommunityColors.brown,
                ),
              ),
            ),
          const SizedBox(height: 6),
          _ManageRow(
            rowKey: const Key('home-manage-requests'),
            icon: Icons.person_add_alt_1_rounded,
            title: 'Permintaan bergabung',
            subtitle: requests > 0
                ? '$requests menunggu persetujuan'
                : 'Tidak ada yang menunggu',
            count: requests,
            onTap: () => onOpenTab(ClubTab.members),
          ),
          _ManageRow(
            rowKey: const Key('home-manage-activities'),
            icon: Icons.event_available_rounded,
            title: 'Kegiatan',
            subtitle: upcoming > 0
                ? '$upcoming kegiatan mendatang'
                : 'Belum ada kegiatan terjadwal',
            onTap: () => onOpenTab(ClubTab.activities),
          ),
          _ManageRow(
            rowKey: const Key('home-manage-gallery'),
            icon: Icons.add_photo_alternate_rounded,
            title: 'Galeri',
            subtitle: photos > 0 ? '$photos foto' : 'Belum ada foto',
            onTap: () => onOpenTab(ClubTab.gallery),
          ),
          if (community.duesConfigured) ...[
            _ManageRow(
              rowKey: const Key('home-manage-dues-payments'),
              icon: Icons.fact_check_rounded,
              title: 'Verifikasi iuran',
              subtitle: duesPayments > 0
                  ? '$duesPayments bukti transfer menunggu'
                  : 'Tidak ada yang menunggu',
              count: duesPayments,
              onTap: () =>
                  context.push(AppRoutes.communityDuesPayments(community.id)),
            ),
            _ManageRow(
              rowKey: const Key('home-manage-dues-calendar'),
              icon: Icons.calendar_month_rounded,
              title: 'Kalender iuran',
              subtitle: 'Bulan yang lunas dan tunggakan tiap anggota',
              onTap: () =>
                  context.push(AppRoutes.communityDuesMembers(community.id)),
            ),
          ],
          _ManageRow(
            rowKey: const Key('home-manage-dues-settings'),
            icon: Icons.tune_rounded,
            title: 'Pengaturan iuran',
            subtitle: community.duesConfigured
                ? 'Nominal, uang masuk, tanggal mulai, rekening'
                : 'Belum diatur — atur agar anggota bisa membayar',
            onTap: () =>
                context.push(AppRoutes.communityDuesSettings(community.id)),
          ),
        ],
      ),
    );
  }
}

class _ManageRow extends StatelessWidget {
  const _ManageRow({
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count = 0,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return InkWell(
      key: rowKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: CommunityColors.brown),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
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
