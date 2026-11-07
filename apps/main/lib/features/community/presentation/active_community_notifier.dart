import 'package:features_shared/features_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/stores/prefs_active_community_store.dart';
import '../domain/entities/community.dart';
import '../domain/repositories/active_community_store.dart';
import 'community_providers.dart';

part 'active_community_notifier.g.dart';

@Riverpod(keepAlive: true)
ActiveCommunityStore activeCommunityStore(Ref ref) =>
    PrefsActiveCommunityStore();

/// Komunitas pengguna yang login, untuk Beranda.
class MyCommunities {
  const MyCommunities({
    this.joined = const [],
    this.requests = const [],
    this.active,
  });

  /// Diikuti sebagai anggota aktif, termasuk pengajuan sendiri yang belum
  /// diverifikasi.
  final List<Community> joined;

  /// Permintaan bergabung yang belum diterima pengurus.
  final List<Community> requests;

  /// Komunitas yang sedang dibuka di Beranda.
  final Community? active;

  /// Anggota beberapa komunitas yang belum memilih masuk sebagai anggota mana.
  bool get needsChoice => active == null && joined.isNotEmpty;
}

/// Komunitas aktif di Beranda. Satu komunitas → langsung aktif; beberapa →
/// pilihan terakhir pengguna (disimpan per akun di perangkat), atau belum ada
/// sampai pengguna memilih.
@Riverpod(retry: noRetry)
class ActiveCommunityNotifier extends _$ActiveCommunityNotifier {
  @override
  Future<MyCommunities> build() async {
    final userId = ref.watch(_userIdProvider);
    final all = await ref.watch(joinedCommunitiesProvider.future);
    final joined = [
      for (final c in all)
        if (!c.isJoinRequest) c,
    ];
    final requests = [
      for (final c in all)
        if (c.isJoinRequest) c,
    ];

    Community? active;
    if (joined.length == 1) {
      active = joined.single;
    } else if (joined.isNotEmpty && userId != null) {
      final saved = await _saved(userId);
      active = joined.where((c) => c.id == saved).firstOrNull;
    }
    return MyCommunities(joined: joined, requests: requests, active: active);
  }

  /// Penyimpanan yang tidak tersedia (mis. diblokir peramban) sama dengan
  /// belum pernah memilih.
  Future<String?> _saved(String userId) async {
    try {
      return await ref.read(activeCommunityStoreProvider).read(userId);
    } catch (_) {
      return null;
    }
  }

  /// Masuk sebagai anggota [communityId]; diingat untuk kunjungan berikutnya.
  Future<void> choose(String communityId) async {
    final current = state.value;
    final chosen =
        current?.joined.where((c) => c.id == communityId).firstOrNull;
    if (current == null || chosen == null) return;

    state = AsyncData(MyCommunities(
      joined: current.joined,
      requests: current.requests,
      active: chosen,
    ));
    final userId = ref.read(_userIdProvider);
    if (userId == null) return;
    try {
      await ref.read(activeCommunityStoreProvider).write(userId, communityId);
    } catch (_) {
      // Tetap aktif untuk sesi ini walau tidak bisa diingat.
    }
  }
}

/// Hanya berubah saat akun berganti, bukan setiap profil disegarkan.
@riverpod
String? _userId(Ref ref) => ref.watch(
      authProvider.select(
        (state) => state is AuthAuthenticated ? state.user.id : null,
      ),
    );
