import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import '../widgets/club_activities_tab.dart';
import '../widgets/club_gallery_tab.dart';
import '../widgets/club_hero.dart';
import '../widgets/club_info_tab.dart';
import '../widgets/club_members_tab.dart';
import '../widgets/community_visuals.dart';

/// Halaman klub: sampul dan tab Info, Anggota, Galeri, Kegiatan.
class CommunityDetailScreen extends ConsumerWidget {
  const CommunityDetailScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = communityDetailProvider(communityId);
    return ref.watch(provider).when(
          loading: () => Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: CommunityErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(provider),
            ),
          ),
          data: (community) => _ClubView(community: community),
        );
  }
}

class _ClubView extends ConsumerWidget {
  const _ClubView({required this.community});

  /// Tinggi sampul pada skala teks normal.
  static const _heroHeight = 340.0;

  final CommunityDetail community;

  void _refresh(WidgetRef ref) {
    ref.invalidate(communityDetailProvider(community.id));
    ref.invalidate(communityActivitiesProvider(community.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final requests = community.pendingMembersCount;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                forceElevated: innerBoxIsScrolled,
                expandedHeight: _heroHeight * scale,
                backgroundColor: CommunityColors.ink,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    key: const Key('club-refresh'),
                    tooltip: 'Segarkan',
                    onPressed: () => _refresh(ref),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final collapsed =
                        constraints.maxHeight < _heroHeight * scale * 0.55;
                    final heroHeight =
                        _heroHeight * scale + MediaQuery.paddingOf(context).top;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        IgnorePointer(
                          ignoring: collapsed,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 150),
                            opacity: collapsed ? 0 : 1,
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                              maxHeight: heroHeight,
                              minHeight: heroHeight,
                              child: ClubHero(community: community),
                            ),
                          ),
                        ),
                        if (collapsed)
                          SafeArea(
                            bottom: false,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(56, 16, 56, 0),
                                child: Text(
                                  community.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(ClubHero.tabBarHeight),
                  child: TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: CommunityColors.goldLight,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent,
                    tabs: [
                      const Tab(text: 'Info'),
                      Tab(
                        child: Badge(
                          key: const Key('club-requests-badge'),
                          isLabelVisible: requests > 0,
                          label: Text('$requests'),
                          offset: const Offset(14, -6),
                          child: const Text('Anggota'),
                        ),
                      ),
                      const Tab(text: 'Galeri'),
                      const Tab(text: 'Kegiatan'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              ClubInfoTab(community: community),
              ClubMembersTab(community: community),
              ClubGalleryTab(community: community),
              ClubActivitiesTab(community: community),
            ],
          ),
        ),
      ),
    );
  }
}
