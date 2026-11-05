import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/community.dart';
import 'community_visuals.dart';

/// Tanggal dalam bahasa Indonesia, tanpa bergantung pada data locale intl.
abstract final class ClubDates {
  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGU',
    'SEP',
    'OKT',
    'NOV',
    'DES',
  ];

  /// "NOV".
  static String month(DateTime date) => _months[date.month - 1];

  /// "Sabtu, 12 November 2026".
  static String full(DateTime date) =>
      '${_days[date.weekday - 1]}, ${AppDateUtils.longDateId(date)}';

  /// "Hari ini", "Besok", "3 hari lagi".
  static String countdown(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    return switch (days) {
      <= 0 => 'Hari ini',
      1 => 'Besok',
      _ => '$days hari lagi',
    };
  }
}

/// Isi satu tab: menggulir bersama header klub.
class ClubTabScroll extends StatelessWidget {
  const ClubTabScroll({
    super.key,
    required this.storageKey,
    required this.child,
  });

  final String storageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Builder(
        builder: (context) => CustomScrollView(
          key: PageStorageKey(storageKey),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu berjudul di dalam tab.
class ClubSection extends StatelessWidget {
  const ClubSection({
    super.key,
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
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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

/// Judul kelompok di dalam tab.
class ClubGroupTitle extends StatelessWidget {
  const ClubGroupTitle(this.title, {super.key, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lencana peran; anggota biasa tidak perlu ditandai.
class ClubRoleBadge extends StatelessWidget {
  const ClubRoleBadge({super.key, required this.role});

  final CommunityRole role;

  @override
  Widget build(BuildContext context) {
    final creator = role == CommunityRole.creator;
    final color = creator ? CommunityColors.gold : const Color(0xFF1E6FD9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            creator ? Icons.workspace_premium_rounded : Icons.shield_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              role.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: creator ? CommunityColors.brown : color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto anggota; gagal dimuat atau belum ada → inisial.
class ClubAvatar extends StatelessWidget {
  const ClubAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 22,
  });

  final String name;
  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trimmed = name.trim();
    final initial = CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );

    final photo = url;
    if (photo == null || photo.isEmpty) return initial;
    return ClipOval(
      child: SizedBox.square(
        dimension: radius * 2,
        child: CommunityNetworkImage(url: photo, fallback: initial),
      ),
    );
  }
}

/// Ajakan di tab yang masih kosong.
class ClubEmptyState extends StatelessWidget {
  const ClubEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: CommunityColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: CommunityColors.gold),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Jalankan aksi dan tampilkan hasilnya; pesan galat dari server tampil apa adanya.
Future<bool> runClubAction(
  BuildContext context,
  Future<void> Function() action, {
  required String success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void show(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
  try {
    await action();
    show(success);
    return true;
  } catch (e) {
    show(e.toString());
    return false;
  }
}

Future<bool> confirmClubAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('club-confirm'),
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
