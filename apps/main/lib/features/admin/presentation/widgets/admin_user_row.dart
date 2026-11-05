import 'package:flutter/material.dart';

import '../../domain/entities/admin_user.dart';
import 'admin_widgets.dart';

/// Lebar minimum untuk tampilan kolom; di bawahnya baris menjadi bertumpuk.
const adminTableMinWidth = 720.0;

/// Judul kolom di atas [AdminUserRow] pada tampilan lebar.
class AdminUserTableHeader extends StatelessWidget {
  const AdminUserTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    // Lebar kolom & jaraknya sama dengan baris di [AdminUserRow].
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('Pengguna', style: style)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text('Perangkat', style: style)),
          const SizedBox(width: 12),
          Expanded(flex: 4, child: Text('Lokasi', style: style)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text('Terakhir Akses', style: style)),
        ],
      ),
    );
  }
}

class AdminUserRow extends StatelessWidget {
  const AdminUserRow({super.key, required this.user, required this.onTap});

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: Key('admin-user-${user.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final identity = _Identity(user: user);
            final device = user.latestDevice;
            if (constraints.maxWidth < adminTableMinWidth - 32) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  identity,
                  const SizedBox(height: 8),
                  _Fact(
                    icon: Icons.schedule_rounded,
                    text: 'Akses ${AdminTime.relative(user.lastSeenAt)}',
                  ),
                  if (device != null) ...[
                    const SizedBox(height: 2),
                    _Fact(
                      icon: adminDeviceIcon(device.deviceType),
                      text: device.label,
                    ),
                  ],
                  if (device?.location != null) ...[
                    const SizedBox(height: 2),
                    _Fact(
                      icon: Icons.place_outlined,
                      text: device!.location!,
                    ),
                  ],
                ],
              );
            }
            final muted = theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            );
            return Row(
              children: [
                Expanded(flex: 5, child: identity),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: device == null
                      ? Text('-', style: muted)
                      : _Fact(
                          key: const Key('admin-device-cell'),
                          icon: adminDeviceIcon(device.deviceType),
                          text: device.label,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    device?.location ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    AdminTime.relative(user.lastSeenAt),
                    style: muted,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AdminAvatar(user: user),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (user.isSuperAdmin || !user.isActive) ...[
                const SizedBox(height: 4),
                AdminUserBadges(user: user),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
