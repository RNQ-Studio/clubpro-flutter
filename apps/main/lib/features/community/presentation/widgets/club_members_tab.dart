import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import '../../../directory/presentation/member_identity_screen.dart';
import '../../../directory/presentation/internal_members_screen.dart';
import '../community_providers.dart';
import 'club_common.dart';
import 'community_visuals.dart';

class ClubMembersTab extends ConsumerWidget {
  const ClubMembersTab({super.key, required this.community});

  final CommunityDetail community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!community.isMember && !community.canManage) {
      return ClubTabScroll(
        storageKey: 'club-members',
        child: ClubEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Khusus anggota',
          message: community.isJoinPending
              ? 'Daftar anggota terbuka sesudah permintaan Anda diterima.'
              : 'Gabung ke komunitas ini untuk melihat '
                  '${community.membersCount ?? 0} anggotanya.',
        ),
      );
    }

    final provider = communityMembersProvider(community.id);
    return ClubTabScroll(
      storageKey: 'club-members',
      child: ref.watch(provider).when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => ClubEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat anggota',
              message: error.toString(),
              action: FilledButton.tonal(
                onPressed: () => ref.invalidate(provider),
                child: const Text('Coba Lagi'),
              ),
            ),
            data: (state) => _MembersList(community: community, state: state),
          ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  const _MembersList({required this.community, required this.state});

  final CommunityDetail community;
  final CommunityMembersState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final myId = auth is AuthAuthenticated ? auth.user.id : null;

    Widget tile(CommunityMember member) => _MemberTile(
          community: community,
          member: member,
          isSelf: member.userId == myId,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => InternalMembersScreen(community: community))),
            icon: const Icon(Icons.search),
            label: const Text('Cari Anggota / Peran')),
        if (state.requests.isNotEmpty) ...[
          ClubGroupTitle('Permintaan Bergabung', count: state.requests.length),
          for (final request in state.requests)
            _RequestTile(community: community, member: request),
          const SizedBox(height: 14),
        ],
        if (community.myRole?.canRecordMembers ?? false)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              MemberIdentityScreen(communityId: community.id))),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Catat Anggota Manual'))),
        if (state.members.isEmpty)
          const Padding(
              padding: EdgeInsets.all(24), child: Text('Belum ada anggota.')),
        for (final role in CommunityRole.values)
          if (state.members.any((m) => m.role == role)) ...[
            ClubGroupTitle(role.label,
                count: state.members.where((m) => m.role == role).length),
            for (final member in state.members.where((m) => m.role == role))
              tile(member),
            const SizedBox(height: 14),
          ],
        if (state.hasMore)
          TextButton(
            key: const Key('club-members-more'),
            onPressed: state.isLoadingMore
                ? null
                : () => ref
                    .read(communityMembersProvider(community.id).notifier)
                    .loadMore(),
            child: Text(
              state.isLoadingMore ? 'Memuat...' : 'Muat Lebih Banyak',
            ),
          ),
      ],
    );
  }
}

/// Muat ulang detail: daftar anggota ikut mengikutinya.
void _refreshClub(WidgetRef ref, String communityId) {
  ref.invalidate(communityDetailProvider(communityId));
  ref.invalidate(joinedCommunitiesProvider);
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({required this.community, required this.member});

  final CommunityDetail community;
  final CommunityMember member;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _act(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runClubAction(context, action, success: success);
    if (!mounted) return;
    _refreshClub(ref, widget.community.id);
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    final repository = ref.read(communityRepositoryProvider);
    final communityId = widget.community.id;
    final requestedAt = member.requestedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CommunityColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClubAvatar(name: member.name, url: member.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (requestedAt != null)
                  Text(
                    AppDateUtils.longDateId(requestedAt.toLocal()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            key: Key('club-reject-${member.id}'),
            tooltip: 'Tolak',
            onPressed: _busy
                ? null
                : () => _act(
                      () => repository.removeMember(communityId, member.id),
                      'Permintaan ditolak',
                    ),
            icon: const Icon(Icons.close_rounded),
          ),
          IconButton.filled(
            key: Key('club-approve-${member.id}'),
            tooltip: 'Terima',
            style: IconButton.styleFrom(
              backgroundColor: CommunityColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: _busy
                ? null
                : () => _act(
                      () => repository.approveMember(communityId, member.id),
                      '${member.name} menjadi anggota',
                    ),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
    );
  }
}

enum _MemberAction { promote, officer, coach, demote, remove, identity }

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.community,
    required this.member,
    required this.isSelf,
  });

  final CommunityDetail community;
  final CommunityMember member;
  final bool isSelf;

  /// Tindakan yang tersedia; server menerapkan aturan yang sama.
  List<_MemberAction> get _actions {
    final role = community.myRole;
    final actions = <_MemberAction>[];
    if ((isSelf && role == member.role) ||
        ((role?.canRecordMembers ?? false) &&
            (member.role != CommunityRole.creator &&
                    member.role != CommunityRole.admin ||
                role == CommunityRole.creator ||
                (isSelf && member.role == CommunityRole.admin))))
      actions.add(_MemberAction.identity);
    if (role == null ||
        !role.canManageMembers ||
        member.role == CommunityRole.creator ||
        isSelf ||
        (member.role == CommunityRole.admin && role != CommunityRole.creator))
      return actions;
    if (role == CommunityRole.creator && member.role != CommunityRole.admin)
      actions.add(_MemberAction.promote);
    if (member.role != CommunityRole.officer)
      actions.add(_MemberAction.officer);
    if (member.role != CommunityRole.coach) actions.add(_MemberAction.coach);
    if (member.role != CommunityRole.member) actions.add(_MemberAction.demote);
    actions.add(_MemberAction.remove);
    return actions;
  }

  Future<void> _perform(
    BuildContext context,
    WidgetRef ref,
    _MemberAction action,
  ) async {
    if (action == _MemberAction.identity) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) =>
              MemberIdentityScreen(communityId: community.id, member: member)));
      return;
    }
    final repository = ref.read(communityRepositoryProvider);
    final id = community.id;
    final name = member.name;

    final (confirm, run, success) = switch (action) {
      _MemberAction.promote => (
          confirmClubAction(
            context,
            title: 'Jadikan $name admin?',
            message:
                'Admin dapat mengelola anggota biasa, kegiatan dan galeri. Hanya pendiri dapat mengaktifkan atau mencabut admin.',
            action: 'Jadikan Admin',
          ),
          () => repository.setMemberRole(id, member.id, CommunityRole.admin),
          '$name kini admin',
        ),
      _MemberAction.demote => (
          confirmClubAction(
            context,
            title: 'Cabut akses admin $name?',
            message: '$name kembali menjadi anggota biasa.',
            action: 'Cabut Admin',
            destructive: true,
          ),
          () => repository.setMemberRole(id, member.id, CommunityRole.member),
          'Akses admin $name dicabut',
        ),
      _MemberAction.officer => (
          confirmClubAction(context,
              title: 'Jadikan $name pengurus?',
              message:
                  'Pengurus dapat mengelola kegiatan, galeri dan mencatat anggota manual.',
              action: 'Jadikan Pengurus'),
          () => repository.setMemberRole(id, member.id, CommunityRole.officer),
          'Peran $name diperbarui',
        ),
      _MemberAction.coach => (
          confirmClubAction(context,
              title: 'Jadikan $name pelatih?',
              message:
                  'Pelatih dapat membaca daftar anggota terbatas dalam komunitas.',
              action: 'Jadikan Pelatih'),
          () => repository.setMemberRole(id, member.id, CommunityRole.coach),
          'Peran $name diperbarui',
        ),
      _MemberAction.identity => throw StateError('Handled before confirmation'),
      _MemberAction.remove => (
          confirmClubAction(
            context,
            title: 'Keluarkan $name?',
            message: '$name perlu meminta bergabung lagi untuk kembali.',
            action: 'Keluarkan',
            destructive: true,
          ),
          () => repository.removeMember(id, member.id),
          '$name dikeluarkan',
        ),
    };

    if (!await confirm || !context.mounted) return;
    await runClubAction(context, run, success: success);
    if (context.mounted) _refreshClub(ref, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actions = _actions;
    final joinedAt = member.joinedAt;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('club-member-${member.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: member.userId.isNotEmpty
            ? () => context.push(AppRoutes.member(member.userId))
            : (community.myRole?.canRecordMembers ?? false)
                ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => MemberIdentityScreen(
                        communityId: community.id, member: member)))
                : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          child: Row(
            children: [
              ClubAvatar(name: member.name, url: member.avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isSelf ? '${member.name} (Anda)' : member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (member.role != CommunityRole.member) ...[
                          const SizedBox(width: 6),
                          ClubRoleBadge(role: member.role),
                        ],
                      ],
                    ),
                    if (joinedAt != null)
                      Text(
                        'Bergabung '
                        '${AppDateUtils.longDateId(joinedAt.toLocal())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                PopupMenuButton<_MemberAction>(
                  key: Key('club-member-menu-${member.id}'),
                  tooltip: 'Kelola anggota',
                  onSelected: (action) => _perform(context, ref, action),
                  itemBuilder: (context) => [
                    for (final action in actions)
                      PopupMenuItem(
                        value: action,
                        child: Text(switch (action) {
                          _MemberAction.promote => 'Jadikan Admin',
                          _MemberAction.demote => 'Cabut Admin',
                          _MemberAction.officer => 'Jadikan Pengurus',
                          _MemberAction.coach => 'Jadikan Pelatih',
                          _MemberAction.identity => 'Kelola Identitas / Wali',
                          _MemberAction.remove => 'Keluarkan',
                        }),
                      ),
                  ],
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
