import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../active_community_notifier.dart';
import '../community_providers.dart';
import '../widgets/community_start_view.dart';

/// Langkah sesudah Lengkapi Data Diri: cari komunitas yang ada atau daftarkan
/// komunitas baru. Yang sudah tergabung di komunitas langsung ke Beranda.
class CommunityStartScreen extends ConsumerStatefulWidget {
  const CommunityStartScreen({super.key});

  @override
  ConsumerState<CommunityStartScreen> createState() =>
      _CommunityStartScreenState();
}

class _CommunityStartScreenState extends ConsumerState<CommunityStartScreen> {
  @override
  void initState() {
    super.initState();
    // Hanya saat dibuka: komunitas yang baru didaftarkan dari sini tidak boleh
    // menutup layar konfirmasinya.
    ref.read(activeCommunityProvider.future).then((mine) {
      if (mounted && mine.joined.isNotEmpty) context.go('/');
    }, onError: (_) {});
  }

  void _skip() => context.go('/');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final name = authState is AuthAuthenticated
        ? authState.user.name.trim().split(' ').first
        : '';
    final requests =
        ref.watch(activeCommunityProvider).value?.requests ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gabung Komunitas'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const Key('community-start-skip'),
            onPressed: _skip,
            child: const Text('Nanti saja'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(joinedCommunitiesProvider);
          ref.invalidate(recommendedCommunitiesProvider);
          try {
            await ref.read(recommendedCommunitiesProvider.future);
          } catch (_) {
            // Pesan gagalnya tampil di bagian rekomendasi.
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  name.isEmpty
                      ? 'Satu langkah lagi!'
                      : 'Satu langkah lagi, $name!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bergabunglah dengan komunitas yang sudah ada, atau daftarkan '
                  'komunitas Anda dan kelola anggotanya di sini.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                CommunityStartView(requests: requests),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
