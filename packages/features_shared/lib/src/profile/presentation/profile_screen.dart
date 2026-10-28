import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import 'widgets/profile_avatar_picker.dart';
import 'widgets/profile_completion_card.dart';

/// Profil anggota: data diri, petunjuk kelengkapan / penanda profil lengkap,
/// pengaturan, dan keluar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
            'Anda perlu masuk lagi dengan Google untuk membuka aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;
    final completion = user.completion;
    final theme = Theme.of(context);
    void edit() => context.push(AppRoutes.editProfile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Ubah data diri',
            icon: const Icon(Icons.edit_outlined),
            onPressed: edit,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).checkCurrentUser(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Center(child: ProfileAvatarPicker(radius: 52)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (completion.isComplete) ...[
                  const SizedBox(width: 6),
                  const Tooltip(
                    message: 'Profil lengkap',
                    child: Icon(Icons.verified_rounded,
                        key: Key('profile-verified-icon'),
                        color: Color(0xFF178A5B),
                        size: 22),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            ProfileCompletionCard(
              completion: completion,
              onComplete: completion.isComplete ? null : edit,
            ),
            _DetailsSection(
              title: 'Data Pribadi',
              icon: Icons.badge_outlined,
              rows: [
                ('Jenis kelamin', user.gender?.label),
                ('Tempat, tanggal lahir', _birth(user)),
                ('Nomor HP / WhatsApp', user.phone),
                ('Alamat', user.address),
              ],
            ),
            _DetailsSection(
              title: 'Kesehatan & Kontak Darurat',
              icon: Icons.health_and_safety_outlined,
              rows: [
                ('Golongan darah', user.bloodType?.label),
                ('Kontak darurat', _emergency(user)),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Pengaturan'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    key: const Key('logout'),
                    leading: Icon(Icons.logout_rounded,
                        color: theme.colorScheme.error),
                    title: Text(
                      'Keluar',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _birth(User user) {
    final date = user.birthDate == null
        ? null
        : AppDateUtils.longDateId(user.birthDate!);
    final parts = [user.birthPlace, date]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _emergency(User user) {
    final parts = [user.emergencyContactName, user.emergencyContactPhone]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
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
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final (label, value) in rows)
                    ListTile(
                      dense: true,
                      title: Text(
                        label,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      subtitle: Text(
                        (value == null || value.trim().isEmpty)
                            ? 'Belum diisi'
                            : value,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: (value == null || value.trim().isEmpty)
                              ? muted.withValues(alpha: 0.7)
                              : theme.colorScheme.onSurface,
                          fontStyle: (value == null || value.trim().isEmpty)
                              ? FontStyle.italic
                              : null,
                        ),
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
