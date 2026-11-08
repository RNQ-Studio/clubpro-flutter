import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/entities/user.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import '../domain/entities/member_profile.dart';
import 'widgets/profile_avatar_picker.dart';
import 'widgets/profile_completion_card.dart';

/// Profil anggota: kartu identitas, data diri, pengaturan, dan keluar.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Lebar isi terbesar di layar lebar.
  static const maxWidth = 560.0;

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
            key: const Key('logout-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
    void edit() => context.push(AppRoutes.editProfile);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).checkCurrentUser(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _Centered(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IdentityCard(user: user),
                  if (!completion.isComplete) ...[
                    const SizedBox(height: 16),
                    ProfileCompletionCard(
                      completion: completion,
                      onComplete: edit,
                    ),
                  ],
                  _SectionHeader(
                    'Data Diri',
                    action: TextButton.icon(
                      key: const Key('profile-edit'),
                      onPressed: edit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ubah'),
                    ),
                  ),
                  _Panel(
                    children: [
                      _InfoRow(
                        icon: Icons.wc_rounded,
                        label: 'Jenis kelamin',
                        value: user.gender?.label,
                      ),
                      _InfoRow(
                        icon: Icons.chat_outlined,
                        label: 'Nomor WhatsApp',
                        value: user.phone,
                      ),
                      _InfoRow(
                        icon: Icons.home_outlined,
                        label: 'Domisili',
                        value: user.domicile?.label,
                      ),
                      _InfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Sesuai NIK (KTP)',
                        value: _nikLabel(user),
                      ),
                    ],
                  ),
                  const _SectionHeader('Akun'),
                  _Panel(
                    children: [
                      _MenuRow(
                        key: const Key('profile-settings'),
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan',
                        subtitle: 'Tema, bahasa, dan login biometrik',
                        onTap: () => context.push(AppRoutes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _LogoutButton(onPressed: () => _confirmLogout(context, ref)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _nikLabel(User user) {
    if (user.nikSameAsDomicile && user.nikRegion != null) {
      return '${user.nikRegion!.label} · sama dengan domisili';
    }
    return user.nikRegion?.label;
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ProfileScreen.maxWidth),
          child: child,
        ),
      );
}

/// Foto (bisa diganti), nama, email, dan status kelengkapan profil.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completion = user.completion;
    return _Panel(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Row(
            children: [
              const ProfileAvatarPicker(radius: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      key: const Key('profile-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CompletionChip(completion: completion),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompletionChip extends StatelessWidget {
  const _CompletionChip({required this.completion});

  final ProfileCompletion completion;

  static const _complete = Color(0xFF178A5B);
  static const _pending = Color(0xFFC98A00);

  @override
  Widget build(BuildContext context) {
    final done = completion.isComplete;
    final color = done ? _complete : _pending;
    return Container(
      key: Key(done ? 'profile-verified' : 'profile-incomplete'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.verified_rounded : Icons.pending_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              done ? 'Profil lengkap' : 'Belum lengkap',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 0, 8),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (action case final action?) action,
          ],
        ),
      ),
    );
  }
}

/// Garis tepi & pemisah tipis, sama dengan kartu lain di app.
Color _hairline(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

/// Kartu berisi baris-baris yang dipisah garis tipis.
class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _hairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              Divider(height: 1, indent: 64, color: _hairline(context)),
            child,
          ],
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tint = Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final empty = value == null || value!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                const SizedBox(height: 2),
                Text(
                  empty ? 'Belum diisi' : value!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: empty ? FontWeight.w400 : FontWeight.w600,
                    color: empty
                        ? muted.withValues(alpha: 0.8)
                        : theme.colorScheme.onSurface,
                    fontStyle: empty ? FontStyle.italic : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconBox(icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        key: const Key('logout'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: error,
          side: BorderSide(color: error.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Keluar dari Akun'),
      ),
    );
  }
}
