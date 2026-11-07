import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/presentation/community_providers.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import '../dues_providers.dart';
import '../widgets/dues_payment_card.dart';
import '../widgets/dues_visuals.dart';

/// Iuran saya di satu komunitas: status, kalender, riwayat, dan tombol bayar.
/// Pengelola juga mendapat pintu ke verifikasi, kalender anggota, dan pengaturan.
class DuesScreen extends ConsumerStatefulWidget {
  const DuesScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends ConsumerState<DuesScreen> {
  /// Null = tahun berjalan menurut server.
  int? _year;

  @override
  Widget build(BuildContext context) {
    final provider = duesOverviewProvider(widget.communityId, _year);
    final overview = ref.watch(provider);
    final name =
        ref.watch(communityDetailProvider(widget.communityId)).value?.name;
    final value = overview.value;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Iuran'),
            if (name != null)
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: value == null
          ? overview.hasError
              ? CommunityErrorView(
                  message: overview.error.toString(),
                  onRetry: () => ref.invalidate(provider),
                )
              : const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(provider);
                try {
                  await ref.read(provider.future);
                } catch (_) {
                  // Galatnya tampil di layar.
                }
              },
              child: _DuesBody(
                communityId: widget.communityId,
                overview: value,
                onYear: (year) => setState(() => _year = year),
              ),
            ),
    );
  }
}

class _DuesBody extends StatelessWidget {
  const _DuesBody({
    required this.communityId,
    required this.overview,
    required this.onYear,
  });

  final String communityId;
  final DuesOverview overview;
  final ValueChanged<int> onYear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = overview.settings;
    final me = overview.me;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (overview.canManage) ...[
              _ManagerTools(
                communityId: communityId,
                pendingCount: overview.pendingPaymentsCount ?? 0,
                configured: settings.configured,
              ),
              const SizedBox(height: 16),
            ],
            if (!settings.configured)
              _NotConfigured(
                canManage: overview.canManage,
                onSetUp: () =>
                    context.push(AppRoutes.communityDuesSettings(communityId)),
              )
            else if (me != null) ...[
              _MySummary(
                settings: settings,
                me: me,
                onPay: () =>
                    context.push(AppRoutes.communityDuesPay(communityId)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kalender Iuran',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DuesYearSwitcher(year: overview.year, onChanged: onYear),
                ],
              ),
              const SizedBox(height: 4),
              DuesYearGrid(months: me.calendar.months),
              const SizedBox(height: 10),
              const DuesLegend(),
            ],
            if (me != null) ...[
              const SizedBox(height: 24),
              Text(
                'Riwayat Pembayaran',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (overview.payments.isEmpty)
                Text(
                  'Belum ada pembayaran.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final payment in overview.payments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DuesPaymentCard(payment: payment),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MySummary extends StatelessWidget {
  const _MySummary({
    required this.settings,
    required this.me,
    required this.onPay,
  });

  final DuesSettings settings;
  final MyDues me;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = duesHeadline(context, me.calendar);
    final pending = me.calendar.months
        .where((m) => m.status == DuesMonthStatus.pending)
        .length;

    return Container(
      key: const Key('dues-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(headline.icon, color: headline.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headline.text,
                  key: const Key('dues-headline'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: headline.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatRupiah(settings.monthlyAmount ?? 0)} per bulan · jatuh '
            'tempo setiap tanggal ${settings.dueDay}',
            style: theme.textTheme.bodySmall,
          ),
          if (me.entryFeeDue > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Uang masuk ${formatRupiah(me.entryFeeDue)} ikut dibayar di '
                'pembayaran berikutnya.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CommunityColors.brown,
                ),
              ),
            ),
          if (pending > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$pending bulan menunggu verifikasi pengurus.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: CommunityColors.brown,
                ),
              ),
            ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('dues-pay'),
            onPressed: onPay,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Bayar Iuran'),
          ),
        ],
      ),
    );
  }
}

class _NotConfigured extends StatelessWidget {
  const _NotConfigured({required this.canManage, required this.onSetUp});

  final bool canManage;
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('dues-not-configured'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CommunityColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            size: 40,
            color: CommunityColors.gold,
          ),
          const SizedBox(height: 10),
          Text(
            'Iuran belum diatur',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canManage
                ? 'Atur nominal per bulan, uang masuk, tanggal mulai, dan '
                    'rekening tujuan agar anggota bisa membayar.'
                : 'Pengurus belum mengatur iuran komunitas ini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: 14),
            FilledButton(
              key: const Key('dues-set-up'),
              onPressed: onSetUp,
              child: const Text('Atur Iuran'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pintu pengelola: verifikasi, kalender anggota, pengaturan.
class _ManagerTools extends StatelessWidget {
  const _ManagerTools({
    required this.communityId,
    required this.pendingCount,
    required this.configured,
  });

  final String communityId;
  final int pendingCount;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile({
      required Key key,
      required IconData icon,
      required String title,
      required String subtitle,
      required String location,
      int count = 0,
    }) =>
        ListTile(
          key: key,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: CommunityColors.brown),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (count > 0)
                Badge(
                  label: Text('$count'),
                  backgroundColor: theme.colorScheme.error,
                ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          onTap: () => context.push(location),
        );

    return Container(
      key: const Key('dues-manager-tools'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CommunityColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              'Kelola Iuran',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (configured) ...[
            tile(
              key: const Key('dues-tool-payments'),
              icon: Icons.fact_check_rounded,
              title: 'Verifikasi Pembayaran',
              subtitle: pendingCount > 0
                  ? '$pendingCount bukti transfer menunggu'
                  : 'Tidak ada yang menunggu',
              location: AppRoutes.communityDuesPayments(communityId),
              count: pendingCount,
            ),
            tile(
              key: const Key('dues-tool-calendar'),
              icon: Icons.calendar_month_rounded,
              title: 'Kalender Iuran Anggota',
              subtitle: 'Bulan yang lunas dan tunggakan tiap anggota',
              location: AppRoutes.communityDuesMembers(communityId),
            ),
          ],
          tile(
            key: const Key('dues-tool-settings'),
            icon: Icons.tune_rounded,
            title: 'Pengaturan Iuran',
            subtitle: configured
                ? 'Nominal, uang masuk, tanggal mulai, rekening'
                : 'Belum diatur',
            location: AppRoutes.communityDuesSettings(communityId),
          ),
        ],
      ),
    );
  }
}
