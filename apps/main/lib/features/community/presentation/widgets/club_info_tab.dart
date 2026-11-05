import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import 'club_common.dart';
import 'club_hero.dart';
import 'community_visuals.dart';

class ClubInfoTab extends ConsumerWidget {
  const ClubInfoTab({super.key, required this.community});

  final CommunityDetail community;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmClubAction(
      context,
      title: 'Keluar dari komunitas?',
      message: 'Anda perlu meminta bergabung lagi untuk kembali ke '
          '${community.name}.',
      action: 'Keluar',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final left = await runClubAction(
      context,
      () => ref.read(communityRepositoryProvider).leave(community.id),
      success: 'Anda keluar dari ${community.name}',
    );
    if (!left || !context.mounted) return;
    ref.invalidate(communityDetailProvider(community.id));
    ref.invalidate(joinedCommunitiesProvider);
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final next = ref
        .watch(communityActivitiesProvider(community.id))
        .asData
        ?.value
        .upcoming
        .firstOrNull;

    return ClubTabScroll(
      storageKey: 'club-info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (community.status != CommunityStatus.approved) ...[
            _StatusNotice(
              status: community.status,
              note: community.reviewNote,
            ),
            const SizedBox(height: 12),
          ],
          if (community.canManage && community.pendingMembersCount > 0) ...[
            _Shortcut(
              shortcutKey: const Key('club-requests-shortcut'),
              icon: Icons.person_add_alt_1_rounded,
              title: '${community.pendingMembersCount} permintaan bergabung',
              subtitle: 'Terima atau tolak di tab Anggota',
              tab: ClubTab.members,
            ),
            const SizedBox(height: 12),
          ],
          if (next != null) ...[
            _Shortcut(
              shortcutKey: const Key('club-next-activity'),
              icon: Icons.event_available_rounded,
              title: next.title,
              subtitle: '${ClubDates.countdown(next.startsAt.toLocal())} · '
                  '${ClubDates.full(next.startsAt.toLocal())}',
              tab: ClubTab.activities,
            ),
            const SizedBox(height: 12),
          ],
          ClubSection(
            title: 'Tentang Komunitas',
            icon: Icons.info_outline_rounded,
            child: Text(
              community.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          ClubSection(
            title: 'Lokasi',
            icon: Icons.place_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  community.address,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          ClubSection(
            title: 'Kontak',
            icon: Icons.support_agent_rounded,
            child: _Contact(community: community),
          ),
          if (community.isMember && community.myRole != CommunityRole.creator)
            TextButton.icon(
              key: const Key('club-leave'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () => _leave(context, ref),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar dari Komunitas'),
            ),
        ],
      ),
    );
  }
}

/// Pintasan ke tab lain.
class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.shortcutKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tab,
  });

  final Key shortcutKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final int tab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: CommunityColors.gold.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: shortcutKey,
        borderRadius: BorderRadius.circular(14),
        onTap: () => DefaultTabController.of(context).animateTo(tab),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: CommunityColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({required this.status, this.note});

  final CommunityStatus status;

  /// Alasan penolakan dari super admin.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rejected = status == CommunityStatus.rejected;
    final color = rejected ? theme.colorScheme.error : CommunityColors.brown;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            rejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rejected
                      ? 'Pengajuan ini ditolak dan tidak tampil di publik.'
                      : 'Menunggu verifikasi super admin. '
                          'Belum tampil di publik.',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
                if (rejected && note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alasan: $note',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({required this.community});

  final CommunityDetail community;

  /// Nomor lokal "08…" menjadi format internasional yang dipakai wa.me.
  static Uri whatsAppUri(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final international =
        digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
    return Uri.parse('https://wa.me/$international');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = community.contactEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          community.contactName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        SelectableText(
          community.contactPhone,
          style: theme.textTheme.bodySmall,
        ),
        if (email != null)
          SelectableText(email, style: theme.textTheme.bodySmall),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => launchUrl(
                  whatsAppUri(community.contactPhone),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: const Text('WhatsApp'),
              ),
            ),
            if (email != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'mailto', path: email)),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Email'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
