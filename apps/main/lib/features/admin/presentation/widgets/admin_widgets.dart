import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/admin_user.dart';

const adminGold = Color(0xFFBE8815);

/// Garis pemisah tipis; `outlineVariant` di tema app terlalu gelap untuk ini.
Color adminHairline(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

/// Waktu aktivitas; data sebelum pencatatan dimulai memang tidak ada.
abstract final class AdminTime {
  static const unknown = 'Belum tercatat';

  /// "5 menit lalu"; lewat seminggu "12 April 2026".
  static String relative(DateTime? time) {
    if (time == null) return unknown;
    final local = time.toLocal();
    return DateTime.now().difference(local).inDays < 7
        ? AppDateUtils.timeAgo(local)
        : AppDateUtils.longDateId(local);
  }

  /// "12 April 2026, 14:30".
  static String full(DateTime? time) {
    if (time == null) return unknown;
    final local = time.toLocal();
    return '${AppDateUtils.longDateId(local)}, '
        '${AppDateUtils.formatTime(local)}';
  }
}

IconData adminDeviceIcon(String? deviceType) => switch (deviceType) {
      'mobile' => Icons.smartphone_rounded,
      'tablet' => Icons.tablet_mac_rounded,
      'desktop' => Icons.laptop_mac_rounded,
      _ => Icons.devices_other_rounded,
    };

class AdminAvatar extends StatelessWidget {
  const AdminAvatar({super.key, required this.user, this.radius = 22});

  final AdminUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = user.avatarUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    final name = user.name.trim();
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      foregroundImage: hasPhoto ? NetworkImage(url) : null,
      // Foto gagal dimuat → inisial tetap tampil.
      onForegroundImageError: hasPhoto ? (_, __) {} : null,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class AdminBadge extends StatelessWidget {
  const AdminBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Penanda peran & status pengguna.
class AdminUserBadges extends StatelessWidget {
  const AdminUserBadges({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (user.isSuperAdmin)
          const AdminBadge(label: 'Super Admin', color: adminGold),
        if (!user.isActive)
          AdminBadge(
            label: 'Nonaktif',
            color: Theme.of(context).colorScheme.error,
          ),
      ],
    );
  }
}

/// Isi layar saat gagal memuat.
class AdminErrorView extends StatelessWidget {
  const AdminErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lisensi DB-IP Lite (CC BY 4.0) mewajibkan tautan ini di halaman yang
/// menampilkan hasilnya.
class AdminLocationCredit extends StatelessWidget {
  const AdminLocationCredit({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text('Lokasi adalah perkiraan dari alamat IP.', style: style),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://db-ip.com'),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              'IP Geolocation by DB-IP',
              style: style?.copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
