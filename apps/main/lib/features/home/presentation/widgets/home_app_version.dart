import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../home_providers.dart';

/// Versi yang sedang berjalan, dan tombol untuk memuat versi terbaru.
class HomeAppVersion extends ConsumerStatefulWidget {
  const HomeAppVersion({super.key});

  /// Nomor build web, ditanam saat build oleh `tool/deploy_web.sh`.
  static const _buildNumber = String.fromEnvironment('APP_BUILD_NUMBER');

  static String label(PackageInfo info) {
    final build = _buildNumber.isEmpty ? info.buildNumber : _buildNumber;
    return 'v${info.version}+$build';
  }

  @override
  ConsumerState<HomeAppVersion> createState() => _HomeAppVersionState();
}

class _HomeAppVersionState extends ConsumerState<HomeAppVersion> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(appRefresherProvider)?.refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengambil versi terbaru. Periksa koneksi Anda lalu coba lagi.',
          ),
        ),
      );
    } finally {
      // Sukses berarti halaman sedang dimuat ulang.
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final canRefresh = ref.watch(appRefresherProvider) != null;

    return Column(
      children: [
        FutureBuilder<PackageInfo>(
          future: _info,
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) return const SizedBox.shrink();
            return Text(
              HomeAppVersion.label(info),
              key: const Key('home-app-version'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            );
          },
        ),
        if (canRefresh) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('home-refresh-app'),
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_refreshing ? 'Memperbarui...' : 'Perbarui Aplikasi'),
          ),
        ],
      ],
    );
  }
}
