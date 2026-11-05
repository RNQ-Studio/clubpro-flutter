import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import 'club_common.dart';
import 'community_visuals.dart';

/// Indeks tab klub.
abstract final class ClubTab {
  static const info = 0;
  static const members = 1;
  static const gallery = 2;
  static const activities = 3;
}

/// Sampul klub: foto pertama sebagai latar, logo, nama, angka, dan tombol gabung.
class ClubHero extends StatelessWidget {
  const ClubHero({super.key, required this.community});

  /// Tinggi area tab di bawah sampul.
  static const tabBarHeight = 48.0;

  final CommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cover = community.photos.firstOrNull;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: CommunityColors.heroGradient),
        ),
        if (cover != null)
          CommunityNetworkImage(url: cover.url, fallback: const SizedBox()),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x66000000), Color(0xDD1A1408)],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                tabBarHeight + 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CommunityLogo(
                          name: community.name,
                          url: community.logoUrl,
                          size: 70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${community.shortName} · ${community.typeLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              community.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          statKey: const Key('club-stat-members'),
                          icon: Icons.groups_rounded,
                          value: community.membersCount ?? 0,
                          label: 'Anggota',
                          tab: ClubTab.members,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          statKey: const Key('club-stat-gallery'),
                          icon: Icons.photo_library_rounded,
                          value: community.photos.length,
                          label: 'Foto',
                          tab: ClubTab.gallery,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Stat(
                          statKey: const Key('club-stat-activities'),
                          icon: Icons.event_rounded,
                          value: community.upcomingActivitiesCount,
                          label: 'Kegiatan',
                          tab: ClubTab.activities,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClubMembershipAction(community: community),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Angka yang bisa diketuk untuk membuka tabnya.
class _Stat extends StatelessWidget {
  const _Stat({
    required this.statKey,
    required this.icon,
    required this.value,
    required this.label,
    required this.tab,
  });

  final Key statKey;
  final IconData icon;
  final int value;
  final String label;
  final int tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: statKey,
        borderRadius: BorderRadius.circular(12),
        onTap: () => DefaultTabController.of(context).animateTo(tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: CommunityColors.goldLight),
              const SizedBox(width: 5),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keadaan keanggotaan pengguna yang login dan tindakan berikutnya.
class ClubMembershipAction extends ConsumerStatefulWidget {
  const ClubMembershipAction({super.key, required this.community});

  final CommunityDetail community;

  @override
  ConsumerState<ClubMembershipAction> createState() =>
      _ClubMembershipActionState();
}

class _ClubMembershipActionState extends ConsumerState<ClubMembershipAction> {
  bool _busy = false;

  CommunityDetail get _community => widget.community;

  void _refresh() {
    ref.invalidate(communityDetailProvider(_community.id));
    ref.invalidate(joinedCommunitiesProvider);
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runClubAction(context, action, success: success);
    if (!mounted) return;
    _refresh();
    setState(() => _busy = false);
  }

  Future<void> _join() => _run(
        () => ref.read(communityRepositoryProvider).join(_community.id),
        'Permintaan bergabung terkirim',
      );

  Future<void> _cancel() async {
    final confirmed = await confirmClubAction(
      context,
      title: 'Batalkan permintaan?',
      message: 'Permintaan bergabung ke ${_community.name} akan dibatalkan.',
      action: 'Batalkan',
      destructive: true,
    );
    if (!confirmed) return;
    await _run(
      () => ref.read(communityRepositoryProvider).leave(_community.id),
      'Permintaan dibatalkan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final community = _community;
    final role = community.myRole;

    if (community.status != CommunityStatus.approved) {
      return Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: CommunityStatusBadge(status: community.status),
        ),
      );
    }

    if (community.isMember && role != null) {
      return Row(
        children: [
          Icon(
            role.canManage
                ? Icons.workspace_premium_rounded
                : Icons.check_circle_rounded,
            size: 18,
            color: CommunityColors.goldLight,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              role.canManage
                  ? 'Anda ${role.label} komunitas ini'
                  : 'Anda anggota komunitas ini',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ],
      );
    }

    if (community.isJoinPending) {
      return OutlinedButton.icon(
        key: const Key('club-cancel-join'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white70),
        ),
        onPressed: _busy ? null : _cancel,
        icon: const Icon(Icons.hourglass_top_rounded, size: 18),
        label: const Text('Menunggu Persetujuan'),
      );
    }

    return FilledButton.icon(
      key: const Key('club-join'),
      style: FilledButton.styleFrom(
        backgroundColor: CommunityColors.goldLight,
        foregroundColor: CommunityColors.ink,
      ),
      onPressed: _busy || !community.canJoin ? null : _join,
      icon: const Icon(Icons.group_add_rounded, size: 20),
      label: const Text('Gabung Komunitas'),
    );
  }
}
