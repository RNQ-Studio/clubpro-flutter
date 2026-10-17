import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';

/// Info singkat anggota yang login: foto, nama, email.
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
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              foregroundImage: hasPhoto ? NetworkImage(avatarUrl) : null,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (user.completion.isComplete)
              const Tooltip(
                message: 'Profil lengkap',
                child: Icon(Icons.verified_rounded, color: Color(0xFF178A5B)),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
