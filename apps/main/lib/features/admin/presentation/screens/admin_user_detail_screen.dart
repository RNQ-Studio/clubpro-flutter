import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_user.dart';
import '../admin_providers.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Data lengkap satu pengguna, dan pengaturan aksesnya.
class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) =>
      AdminGate(child: _DetailView(userId: userId));
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.userId});

  final String userId;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  bool _busy = false;

  AdminUserDetailNotifierProvider get _provider =>
      adminUserDetailProvider(widget.userId);

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      _showMessage(success);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setSuperAdmin(AdminUserDetail user, bool enabled) async {
    final confirmed = await _confirm(
      title:
          enabled ? 'Berikan akses super admin?' : 'Cabut akses super admin?',
      message: enabled
          ? '${user.name} akan bisa melihat data semua pengguna, mengelola '
              'akun, dan memberi akses super admin ke orang lain.'
          : '${user.name} tidak akan bisa membuka Admin Panel lagi.',
      action: enabled ? 'Berikan Akses' : 'Cabut Akses',
      destructive: !enabled,
    );
    if (!confirmed) return;
    await _run(
      () => ref.read(_provider.notifier).setSuperAdmin(enabled: enabled),
      enabled ? 'Akses super admin diberikan' : 'Akses super admin dicabut',
    );
  }

  Future<void> _setActive(AdminUserDetail user, bool active) async {
    final confirmed = await _confirm(
      title: active ? 'Aktifkan akun ini?' : 'Nonaktifkan akun ini?',
      message: active
          ? '${user.name} akan bisa masuk kembali.'
          : '${user.name} langsung keluar dari semua perangkat dan tidak bisa '
              'masuk sampai akunnya diaktifkan kembali.',
      action: active ? 'Aktifkan' : 'Nonaktifkan',
      destructive: !active,
    );
    if (!confirmed) return;
    await _run(
      () => ref.read(_provider.notifier).setActive(active: active),
      active ? 'Akun diaktifkan' : 'Akun dinonaktifkan',
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(_provider);
    final auth = ref.watch(authProvider);
    final myId = auth is AuthAuthenticated ? auth.user.id : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengguna')),
      body: detail.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AdminErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(_provider),
        ),
        data: (user) => RefreshIndicator(
          onRefresh: () => ref.refresh(_provider.future),
          child: _DetailBody(
            user: user,
            isSelf: user.id == myId,
            busy: _busy,
            onSuperAdminChanged: (value) => _setSuperAdmin(user, value),
            onActiveChanged: (value) => _setActive(user, value),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.onSuperAdminChanged,
    required this.onActiveChanged,
  });

  /// Lebar minimum untuk dua kolom.
  static const _twoColumnWidth = 820.0;

  final AdminUserDetail user;
  final bool isSelf;
  final bool busy;
  final ValueChanged<bool> onSuperAdminChanged;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    final access = _AccessSection(
      user: user,
      isSelf: isSelf,
      busy: busy,
      onSuperAdminChanged: onSuperAdminChanged,
      onActiveChanged: onActiveChanged,
    );
    final activity = _ActivitySection(user: user);
    final devices = _DevicesSection(user: user);
    final profile = _ProfileSection(user: user);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= _twoColumnWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(user: user),
                    const SizedBox(height: 16),
                    if (twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(children: [access, activity]),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(children: [devices, profile]),
                          ),
                        ],
                      )
                    else ...[
                      access,
                      activity,
                      devices,
                      profile,
                    ],
                    const AdminLocationCredit(),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        AdminAvatar(user: user, radius: 44),
        const SizedBox(height: 10),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (user.isSuperAdmin || !user.isActive) ...[
          const SizedBox(height: 8),
          AdminUserBadges(user: user),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: adminHairline(context)),
      ),
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
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null || value!.trim().isEmpty ? '-' : value!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _AccessSection extends StatelessWidget {
  const _AccessSection({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.onSuperAdminChanged,
    required this.onActiveChanged,
  });

  final AdminUserDetail user;
  final bool isSelf;
  final bool busy;
  final ValueChanged<bool> onSuperAdminChanged;
  final ValueChanged<bool> onActiveChanged;

  /// Alasan sakelar super admin terkunci; server menolak hal yang sama.
  String? get _superAdminLock {
    if (user.isSuperAdmin) {
      return isSelf ? 'Anda tidak bisa mencabut akses Anda sendiri' : null;
    }
    if (!user.isActive) return 'Aktifkan akun ini terlebih dahulu';
    if (user.emailVerifiedAt == null) {
      return 'Email belum terverifikasi. Minta pengguna masuk dengan Google';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lock = _superAdminLock;
    return _Section(
      title: 'Akses',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        SwitchListTile(
          key: const Key('admin-super-admin-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Super Admin'),
          subtitle: Text(
              lock ?? 'Bisa membuka Admin Panel dan mengelola semua pengguna'),
          value: user.isSuperAdmin,
          onChanged: busy || lock != null ? null : onSuperAdminChanged,
        ),
        SwitchListTile(
          key: const Key('admin-active-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Akun Aktif'),
          subtitle: Text(isSelf
              ? 'Anda tidak bisa menonaktifkan akun Anda sendiri'
              : 'Akun nonaktif tidak bisa masuk ke aplikasi'),
          value: user.isActive,
          onChanged: busy || isSelf ? null : onActiveChanged,
        ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.user});

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Aktivitas',
      icon: Icons.history_rounded,
      children: [
        _InfoRow('Terakhir akses', AdminTime.full(user.lastSeenAt)),
        _InfoRow('Terakhir login', AdminTime.full(user.lastLoginAt)),
        _InfoRow('Terdaftar', AdminTime.full(user.createdAt)),
        _InfoRow('Metode login', user.usesGoogle ? 'Google' : 'Email & sandi'),
        _InfoRow(
          'Email terverifikasi',
          user.emailVerifiedAt == null
              ? 'Belum'
              : AdminTime.full(user.emailVerifiedAt),
        ),
        _InfoRow(
          'Nomor HP terverifikasi',
          user.phoneVerifiedAt == null
              ? 'Belum'
              : AdminTime.full(user.phoneVerifiedAt),
        ),
      ],
    );
  }
}

class _DevicesSection extends StatelessWidget {
  const _DevicesSection({required this.user});

  final AdminUserDetail user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devices = user.devices;
    return _Section(
      title: 'Perangkat & Lokasi (${devices.length})',
      icon: Icons.devices_rounded,
      children: [
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              AdminTime.unknown,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final (i, device) in devices.indexed) ...[
          if (i > 0) Divider(height: 20, color: adminHairline(context)),
          _DeviceTile(device: device),
        ],
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device});

  final AdminDevice device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(adminDeviceIcon(device.deviceType),
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                device.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _InfoRow('Lokasi', device.location),
        _InfoRow('Alamat IP', device.ipAddress),
        _InfoRow('Terakhir aktif', AdminTime.full(device.lastActiveAt)),
        if (device.appVersion != null)
          _InfoRow('Versi aplikasi', device.appVersion),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.user});

  final AdminUserDetail user;

  String? get _birth {
    final date = user.birthDate;
    final parts = [
      if (user.birthPlace != null) user.birthPlace!,
      if (date != null) AppDateUtils.longDateId(date),
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? get _emergencyContact {
    final parts = [
      if (user.emergencyContactName != null) user.emergencyContactName!,
      if (user.emergencyContactPhone != null) user.emergencyContactPhone!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final completion = user.completion;
    return _Section(
      title: 'Data Diri',
      icon: Icons.badge_outlined,
      children: [
        _InfoRow('Nomor HP', user.phone),
        _InfoRow('Jenis kelamin', user.gender?.label),
        _InfoRow('Tempat, tanggal lahir', _birth),
        _InfoRow('Alamat', user.address),
        _InfoRow('Golongan darah', user.bloodType?.label),
        _InfoRow('Kontak darurat', _emergencyContact),
        if (completion != null)
          _InfoRow(
            'Kelengkapan profil',
            '${completion.completed} dari ${completion.total} isian',
          ),
      ],
    );
  }
}
