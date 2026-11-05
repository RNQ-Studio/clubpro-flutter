import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/community.dart';
import 'community_visuals.dart';

/// Layar sesudah pengajuan terkirim.
class CommunitySubmittedView extends StatelessWidget {
  const CommunitySubmittedView({super.key, required this.community});

  final CommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          gradient: CommunityColors.heroGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pengajuan Terkirim!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${community.name} sedang menunggu verifikasi super admin.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _Timeline(),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('community-submitted-done'),
                    onPressed: () => context.go(AppRoutes.communities),
                    child: const Text('Lihat Pengajuan Saya'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: communityHairline(context)),
      ),
      child: const Column(
        children: [
          _TimelineRow(
            icon: Icons.check_rounded,
            color: CommunityColors.success,
            title: 'Pengajuan terkirim',
            subtitle: 'Data komunitas Anda sudah kami terima',
            connected: true,
          ),
          _TimelineRow(
            icon: Icons.hourglass_top_rounded,
            color: CommunityColors.gold,
            title: 'Verifikasi super admin',
            subtitle: 'Sedang menunggu pemeriksaan',
            connected: true,
          ),
          _TimelineRow(
            icon: Icons.public_rounded,
            color: Colors.grey,
            title: 'Tampil di daftar Komunitas',
            subtitle: 'Sesudah disetujui, semua anggota bisa melihatnya',
            connected: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.connected,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (connected)
                Expanded(
                  child: Container(
                    width: 2,
                    color: communityHairline(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
