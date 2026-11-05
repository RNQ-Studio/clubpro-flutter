import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/community.dart';
import '../community_providers.dart';
import '../widgets/community_photo_viewer.dart';
import '../widgets/community_visuals.dart';

class CommunityDetailScreen extends ConsumerWidget {
  const CommunityDetailScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = communityDetailProvider(communityId);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Komunitas')),
      body: ref.watch(provider).when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => CommunityErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (community) => RefreshIndicator(
              onRefresh: () => ref.refresh(provider.future),
              child: _DetailBody(community: community),
            ),
          ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.community});

  final CommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Hero(community: community),
                const SizedBox(height: 16),
                if (community.status != CommunityStatus.approved) ...[
                  _StatusNotice(
                    status: community.status,
                    note: community.reviewNote,
                  ),
                  const SizedBox(height: 16),
                ],
                _Section(
                  title: 'Tentang Komunitas',
                  icon: Icons.info_outline_rounded,
                  child: Text(
                    community.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
                _Section(
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Kontak',
                  icon: Icons.support_agent_rounded,
                  child: _Contact(community: community),
                ),
                if (community.photoUrls.isNotEmpty)
                  _Section(
                    title: 'Foto',
                    icon: Icons.photo_library_outlined,
                    child: _Gallery(urls: community.photoUrls),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.community});

  final CommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: CommunityColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
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
              size: 76,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  community.shortName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(communityTypeIcon(community.type),
                        size: 15, color: CommunityColors.goldLight),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        community.typeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: CommunityColors.gold),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
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

class _Gallery extends StatelessWidget {
  const _Gallery({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) => CommunityPhotoGrid(urls: urls);
}
