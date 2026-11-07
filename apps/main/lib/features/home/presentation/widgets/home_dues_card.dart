import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/presentation/widgets/community_visuals.dart';
import '../../../dues/domain/entities/dues.dart';
import '../../../dues/presentation/dues_providers.dart';
import '../../../dues/presentation/widgets/dues_visuals.dart';

/// Iuran saya di komunitas aktif: status dan tombol bayar. Tidak tampil bila
/// iuran belum diatur atau gagal dimuat, agar Beranda tetap rapi.
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

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: communityHairline(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('home-dues-card'),
          onTap: () => context.push(AppRoutes.communityDues(communityId)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: headline.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: headline.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Iuran Saya',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        headline.text,
                        key: const Key('home-dues-headline'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: headline.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        pending > 0
                            ? '$pending bulan menunggu verifikasi'
                            : '${formatRupiah(overview.settings.monthlyAmount ?? 0)}'
                                '/bulan · jatuh tempo tgl '
                                '${overview.settings.dueDay}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('home-dues-pay'),
                  onPressed: () =>
                      context.push(AppRoutes.communityDuesPay(communityId)),
                  // Tema app memberi tombol lebar penuh; di dalam Row harus
                  // selebar isinya.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: CommunityColors.brown,
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
