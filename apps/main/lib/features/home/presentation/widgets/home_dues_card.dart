import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/presentation/widgets/community_visuals.dart';
import '../../../dues/domain/entities/dues.dart';
import '../../../dues/presentation/dues_providers.dart';
import '../../../dues/presentation/widgets/dues_visuals.dart';

/// Status iuran ringkas; rincian periode tetap tersedia dari kartu.
class HomeDuesCard extends ConsumerWidget {
  const HomeDuesCard({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(duesOverviewProvider(communityId, null)).value;
    final me = overview?.me;
    if (overview == null || !overview.settings.configured || me == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final headline = duesHeadline(context, me.calendar);
    final pending = me.calendar.months
        .where((m) => m.status == DuesMonthStatus.pending)
        .length;
    final rate = formatRupiah(overview.settings.monthlyAmount ?? 0);
    final description = '${headline.text}. $rate per bulan; '
        'jatuh tempo tanggal ${overview.settings.dueDay}.';
    final status = me.calendar.arrearsCount > 0
        ? 'Tunggakan ${me.calendar.arrearsCount} bln'
        : me.calendar.paidUntil != null
            ? 'Lunas'
            : 'Tanpa tunggakan';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: communityHairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('home-dues-card'),
          onTap: () => context.push(AppRoutes.communityDues(communityId)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Tooltip(
                  message: headline.text,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: headline.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(headline.icon, size: 20, color: headline.color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Iuran',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                      Tooltip(
                        message: description,
                        child: Semantics(
                          label: description,
                          excludeSemantics: true,
                          child: Text(
                            status,
                            key: const Key('home-dues-headline'),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: headline.color,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 8,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tooltip(
                            message: '$rate per bulan; jatuh tempo tanggal '
                                '${overview.settings.dueDay}',
                            child: Text('$rate/bln',
                                style: theme.textTheme.bodySmall),
                          ),
                          if (pending > 0)
                            Tooltip(
                              message: '$pending bulan menunggu verifikasi',
                              child: Semantics(
                                label: '$pending bulan menunggu verifikasi',
                                excludeSemantics: true,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_top_rounded,
                                        size: 13,
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? CommunityColors.goldLight
                                                : CommunityColors.brown),
                                    const SizedBox(width: 3),
                                    Text('$pending',
                                        style: theme.textTheme.labelSmall),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('home-dues-pay'),
                  onPressed: () =>
                      context.push(AppRoutes.communityDuesPay(communityId)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? CommunityColors.goldLight
                            : CommunityColors.brown,
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? CommunityColors.ink
                            : Colors.white,
                  ),
                  child: const Text('Bayar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
