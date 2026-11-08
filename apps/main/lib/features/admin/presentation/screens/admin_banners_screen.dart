import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/admin_banner.dart';
import '../admin_banner_providers.dart';
import '../widgets/admin_banner_widgets.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Paid Promotion: urutan di sini sama dengan urutan slide popup Beranda.
class AdminBannersScreen extends StatelessWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminGate(child: _AdminBannersView());
}

class _AdminBannersView extends ConsumerWidget {
  const _AdminBannersView();

  static const _maxWidth = 840.0;

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    int from,
    int to,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(adminBannersProvider.notifier).move(from, to);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _editInterval(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    final hours = await showPromotionIntervalDialog(context, current);
    if (hours == null || hours == current || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await ref.read(adminBannersProvider.notifier).setInterval(hours);
      message = 'Popup tampil setiap ${promotionIntervalLabel(hours)}';
    } catch (e) {
      message = e.toString();
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(adminBannersProvider);
    final hasBanners = banners.asData?.value.banners.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paid Promotion'),
        leading: context.canPop()
            ? null
            : BackButton(onPressed: () => context.go(AppRoutes.adminPanel)),
      ),
      floatingActionButton: hasBanners
          ? FloatingActionButton.extended(
              key: const Key('admin-banner-add'),
              onPressed: () => context.push(AppRoutes.adminBannerNew),
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: const Text('Tambah Promosi'),
            )
          : null,
      body: banners.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AdminErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminBannersProvider),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(adminBannersProvider.notifier).refresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Daftar tetap bisa digulir dari tepi layar lebar.
              final side =
                  math.max(16.0, (constraints.maxWidth - _maxWidth) / 2);
              final interval = _IntervalCard(
                hours: state.summary.intervalHours,
                onEdit: () =>
                    _editInterval(context, ref, state.summary.intervalHours),
              );
              if (state.banners.isEmpty) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(side, 12, side, 24),
                  children: [
                    interval,
                    const SizedBox(height: 36),
                    const _EmptyBanners(),
                  ],
                );
              }
              final overLimit = state.overLimitIds;
              return ReorderableListView.builder(
                key: const Key('admin-banner-list'),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.fromLTRB(side, 0, side, 96),
                header: _Intro(state: state, interval: interval),
                itemCount: state.banners.length,
                onReorder: (from, to) =>
                    _move(context, ref, from, to > from ? to - 1 : to),
                itemBuilder: (context, i) {
                  final banner = state.banners[i];
                  return _BannerRow(
                    key: ValueKey(banner.id),
                    index: i,
                    banner: banner,
                    overLimit: overLimit.contains(banner.id),
                    canDrag: !state.isSavingOrder,
                    onTap: () => context.push(AppRoutes.adminBanner(banner.id)),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Jeda tampil popup, berlaku untuk semua promosi.
class _IntervalCard extends StatelessWidget {
  const _IntervalCard({required this.hours, required this.onEdit});

  final int hours;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('admin-promotion-interval'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: adminGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: adminGold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: adminGold),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popup tampil setiap ${promotionIntervalLabel(hours)}',
                  key: const Key('admin-promotion-interval-label'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Muncul saat Beranda dibuka, lalu lagi sesudah jeda ini, '
                  'per pengguna di tiap perangkat.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('admin-promotion-interval-edit'),
            onPressed: onEdit,
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.state, required this.interval});

  final AdminBannersState state;
  final Widget interval;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final summary = state.summary;
    final hidden = state.overLimitIds.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          interval,
          const SizedBox(height: 16),
          Text(
            '${summary.total} promosi · ${summary.live} tayang di popup '
            'Beranda',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.drag_indicator_rounded, size: 18, color: muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Seret untuk mengubah urutan slide. Ketuk promosi untuk '
                  'mengubah gambar, tombol, atau aksinya.',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
          if (state.isSavingOrder) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (hidden > 0) ...[
            const SizedBox(height: 10),
            Container(
              key: const Key('admin-banner-limit'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: adminGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: adminGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Popup hanya menampilkan ${summary.maxVisible} promosi '
                      'tayang teratas. $hidden promosi di bawahnya belum '
                      'terlihat.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    super.key,
    required this.index,
    required this.banner,
    required this.overLimit,
    required this.canDrag,
    required this.onTap,
  });

  final int index;
  final AdminBanner banner;
  final bool overLimit;
  final bool canDrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasTitle = banner.title.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: Key('admin-banner-${banner.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: adminHairline(context)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AdminBannerThumb(
                  url: banner.imageUrl,
                  // Ponsel: judul butuh ruang lebih.
                  width: MediaQuery.sizeOf(context).width < 480 ? 52 : 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasTitle ? banner.title : 'Tanpa judul',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontStyle: hasTitle ? null : FontStyle.italic,
                          color: hasTitle ? null : muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          AdminBadge(
                            label: banner.status.label,
                            color: banner.status.color(context),
                          ),
                          if (overLimit)
                            const AdminBadge(
                              label: 'Lewat batas popup',
                              color: adminGold,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            banner.linkType == AdminBannerLinkType.whatsapp
                                ? Icons.chat_outlined
                                : Icons.touch_app_outlined,
                            size: 14,
                            color: muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              switch (banner.button) {
                                final label? =>
                                  '"$label" · ${banner.linkLabel}',
                                null => 'Tanpa tombol',
                              },
                              key: Key('admin-banner-action-${banner.id}'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: index,
                  enabled: canDrag,
                  child: Padding(
                    key: Key('admin-banner-handle-${banner.id}'),
                    padding: const EdgeInsets.all(10),
                    child: MouseRegion(
                      cursor: canDrag
                          ? SystemMouseCursors.grab
                          : SystemMouseCursors.basic,
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: canDrag ? muted : muted.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBanners extends StatelessWidget {
  const _EmptyBanners();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: adminGold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.view_carousel_rounded,
              size: 40, color: adminGold),
        ),
        const SizedBox(height: 16),
        Text(
          'Belum ada promosi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Selama belum ada promosi yang tayang, popup tidak muncul di '
          'Beranda.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('admin-banner-add'),
          onPressed: () => context.push(AppRoutes.adminBannerNew),
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Tambah Promosi'),
        ),
      ],
    );
  }
}
