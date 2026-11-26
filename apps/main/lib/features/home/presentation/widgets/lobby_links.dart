import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Jalur publik yang tetap tersedia dari setiap pilihan komunitas aktif.
class PublicLobbyLinks extends StatelessWidget {
  const PublicLobbyLinks({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Jelajahi CEO',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                    key: const Key('home-public-directory'),
                    onPressed: () => context.push('/explore'),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Cari komunitas')),
                OutlinedButton.icon(
                    key: const Key('home-public-members'),
                    onPressed: () => context.push('/explore?members=1'),
                    icon: const Icon(Icons.person_search_outlined),
                    label: const Text('Cari anggota & asalnya')),
                OutlinedButton.icon(
                    key: const Key('home-community-rankings'),
                    onPressed: () => context.push(AppRoutes.rankings),
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Ranking komunitas')),
                OutlinedButton.icon(
                    key: const Key('home-public-ads'),
                    onPressed: () => context.push(AppRoutes.memberAds),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Iklan anggota')),
              ]),
            ],
          ),
        ),
      );
}

class CommunityLobbyLinks extends StatelessWidget {
  const CommunityLobbyLinks(
      {super.key, required this.communityId, this.canRecord = false});
  final String communityId;
  final bool canRecord;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: [
          ListTile(
              key: const Key('community-member-rankings'),
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Ranking prestasi anggota'),
              subtitle: const Text('Poin sah, periode dan kategori'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push('${AppRoutes.rankings}?community=$communityId')),
          ListTile(
              key: const Key('community-member-ads'),
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Iklan anggota komunitas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context
                  .push('${AppRoutes.memberAds}?community=$communityId')),
          if (canRecord)
            ListTile(
                key: const Key('community-record-achievement'),
                leading: const Icon(Icons.fact_check_outlined),
                title: const Text('Catat kegiatan & hasil lomba'),
                subtitle: const Text('Referensi bukti dan koreksi tercatat'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.push(AppRoutes.communityAchievements(communityId))),
        ]),
      );
}
