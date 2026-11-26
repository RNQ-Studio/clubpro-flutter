import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';

import '../../../community/presentation/widgets/community_visuals.dart';

/// Sapaan singkat sekaligus pintu masuk Profil. Titik merah menandai data diri
/// yang belum lengkap; rincian akun tersedia di halaman Profil.
class HomeUserHeader extends StatelessWidget {
  const HomeUserHeader({super.key, required this.user, this.onTap, this.now});

  final User user;
  final VoidCallback? onTap;

  /// Untuk test; bawaan jam perangkat.
  final DateTime? now;

  static String greeting(DateTime time) {
    final h = time.hour;
    if (h >= 4 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarForeground = theme.brightness == Brightness.dark
        ? const Color(0xFFF0D18A)
        : CommunityColors.brown;
    final avatarUrl = user.avatarUrl;
    final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
    final initial =
        user.name.trim().isEmpty ? '?' : user.name.trim()[0].toUpperCase();

    return InkWell(
      key: const Key('home-user-header'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Badge(
              key: const Key('home-profile-badge'),
              isLabelVisible: !user.completion.isComplete,
              smallSize: 10,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: CommunityColors.gold.withValues(alpha: 0.12),
                foregroundImage: hasPhoto ? NetworkImage(avatarUrl) : null,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: avatarForeground,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${greeting(now ?? DateTime.now())},',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            if (user.completion.isComplete)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: 'Profil lengkap',
                  child: Icon(Icons.verified_rounded,
                      color: CommunityColors.success, size: 18),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
