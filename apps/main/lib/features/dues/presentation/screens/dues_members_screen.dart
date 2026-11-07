import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/presentation/widgets/club_common.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import '../dues_providers.dart';
import '../widgets/dues_visuals.dart';

/// Kalender iuran semua anggota (pengelola): bulan yang lunas dan tunggakan
/// tiap anggota dalam satu tahun.
class DuesMembersScreen extends ConsumerStatefulWidget {
  const DuesMembersScreen({super.key, required this.communityId});

  final String communityId;

  @override
  ConsumerState<DuesMembersScreen> createState() => _DuesMembersScreenState();
}

class _DuesMembersScreenState extends ConsumerState<DuesMembersScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _year = DateTime.now().year;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {}); // Tombol hapus mengikuti isi kolom.
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => setState(() => _search = value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = membersDuesProvider(widget.communityId, _year, _search);
    final members = ref.watch(provider);
    final value = members.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Iuran Anggota')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('dues-members-search'),
                        controller: _searchController,
                        onChanged: _onSearch,
                        decoration: InputDecoration(
                          hintText: 'Cari nama anggota',
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _debounce?.cancel();
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                    DuesYearSwitcher(
                      year: _year,
                      onChanged: (year) => setState(() => _year = year),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DuesLegend(),
                ),
              ),
              Expanded(
                child: value == null
                    ? members.hasError
                        ? CommunityErrorView(
                            message: members.error.toString(),
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
                        child: value.items.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 60),
                                  Text(
                                    _search.isEmpty
                                        ? 'Belum ada anggota aktif.'
                                        : 'Tidak ada anggota bernama '
                                            '"$_search".',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 32),
                                itemCount: value.items.length + 1,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index == value.items.length) {
                                    return _MoreFooter(
                                      state: value,
                                      onMore:
                                          ref.read(provider.notifier).loadMore,
                                    );
                                  }
                                  final member = value.items[index];
                                  return _MemberRow(
                                    member: member,
                                    onTap: () => context.push(
                                      '${AppRoutes.communityDuesMember(widget.communityId, member.userId)}'
                                      '?year=$_year',
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreFooter extends StatelessWidget {
  const _MoreFooter({required this.state, required this.onMore});

  final PagedState<MemberDues> state;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (state.loadMoreError case final error?) {
      return Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(onPressed: onMore, child: const Text('Coba Lagi')),
        ],
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return Center(
      child: state.isLoadingMore
          ? const CircularProgressIndicator()
          : TextButton(
              key: const Key('dues-members-more'),
              onPressed: onMore,
              child: const Text('Muat lebih banyak'),
            ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.onTap});

  final MemberDues member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendar = member.calendar;
    final arrears = calendar.arrearsCount;

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: communityHairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('dues-member-${member.userId}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClubAvatar(
                    name: member.name,
                    url: member.avatarUrl,
                    radius: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _ArrearsChip(arrears: arrears),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MiniYear(months: calendar.months),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrearsChip extends StatelessWidget {
  const _ArrearsChip({required this.arrears});

  final int arrears;

  @override
  Widget build(BuildContext context) {
    final color = arrears > 0
        ? Theme.of(context).colorScheme.error
        : CommunityColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        arrears > 0 ? 'Menunggak $arrears bln' : 'Lancar',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// 12 kotak kecil, satu per bulan.
class _MiniYear extends StatelessWidget {
  const _MiniYear({required this.months});

  final List<DuesMonth> months;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final month in months)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Tooltip(
                message: '${DuesMonths.long(month.month)}: '
                    '${month.status.label}',
                child: Column(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        // Belum jatuh tempo: kotak bergaris; di luar masa
                        // iuran: abu pucat; lainnya: warna statusnya.
                        color: switch (month.status) {
                          DuesMonthStatus.upcoming => null,
                          DuesMonthStatus.none => communityHairline(context),
                          _ => duesMonthStyle(context, month.status)
                              .color
                              .withValues(alpha: 0.85),
                        },
                        border: month.status == DuesMonthStatus.upcoming
                            ? Border.all(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                                width: 1.5,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DuesMonths.short(month.month).substring(0, 1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kalender satu anggota: ubah status tiap bulan dan uang masuk secara manual.
class DuesMemberScreen extends ConsumerStatefulWidget {
  const DuesMemberScreen({
    super.key,
    required this.communityId,
    required this.userId,
    this.initialYear,
  });

  final String communityId;
  final String userId;
  final int? initialYear;

  @override
  ConsumerState<DuesMemberScreen> createState() => _DuesMemberScreenState();
}

class _DuesMemberScreenState extends ConsumerState<DuesMemberScreen> {
  late int _year = widget.initialYear ?? DateTime.now().year;
  bool _busy = false;

  Future<void> _change(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runClubAction(context, action, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    invalidateDues(ref.invalidate, widget.communityId);
  }

  Future<void> _openMonth(MemberDues member, DuesMonth month) async {
    final paid = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => _MonthSheet(month: month, member: member),
    );
    if (paid == null || !mounted) return;
    await _change(
      () => ref.read(duesRepositoryProvider).setMonth(
            widget.communityId,
            widget.userId,
            month.month,
            paid: paid,
          ),
      '${DuesMonths.long(month.month)} ditandai '
      '${paid ? 'lunas' : 'belum lunas'}',
    );
  }

  Future<void> _toggleEntryFee(MemberDues member, bool paid) async {
    final confirmed = await confirmClubAction(
      context,
      title: paid ? 'Tandai uang masuk lunas?' : 'Batalkan pelunasan?',
      message: paid
          ? 'Uang masuk ${member.name} dicatat lunas, mis. dibayar tunai.'
          : 'Uang masuk ${member.name} kembali belum lunas dan ikut ditagih '
              'di pembayaran berikutnya.',
      action: paid ? 'Tandai Lunas' : 'Batalkan',
      destructive: !paid,
    );
    if (!confirmed || !mounted) return;
    await _change(
      () => ref
          .read(duesRepositoryProvider)
          .setEntryFee(widget.communityId, widget.userId, paid: paid),
      paid ? 'Uang masuk ditandai lunas' : 'Uang masuk ditandai belum lunas',
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        memberDuesProvider(widget.communityId, widget.userId, _year);
    final detail = ref.watch(provider);
    final value = detail.value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(value?.member.name ?? 'Iuran Anggota')),
      body: value == null
          ? detail.hasError
              ? CommunityErrorView(
                  message: detail.error.toString(),
                  onRetry: () => ref.invalidate(provider),
                )
              : const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _MemberHeader(detail: value),
                    if (value.settings.entryFee > 0) ...[
                      const SizedBox(height: 12),
                      SwitchListTile(
                        key: const Key('dues-entry-fee'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Uang masuk ${formatRupiah(value.settings.entryFee)}',
                        ),
                        subtitle: Text(
                          value.member.calendar.entryFeePaid
                              ? 'Lunas'
                              : value.member.entryFeeDue == 0
                                  ? 'Sedang diajukan dalam pembayaran'
                                  : 'Belum lunas',
                        ),
                        value: value.member.calendar.entryFeePaid,
                        onChanged: _busy
                            ? null
                            : (paid) => _toggleEntryFee(value.member, paid),
                      ),
                    ],
                    const SizedBox(height: 12),
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
                        DuesYearSwitcher(
                          year: _year,
                          onChanged: (year) => setState(() => _year = year),
                        ),
                      ],
                    ),
                    Text(
                      'Ketuk bulan untuk menandai lunas atau belum lunas, '
                      'mis. bila dibayar tunai.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      absorbing: _busy,
                      child: DuesYearGrid(
                        months: value.member.calendar.months,
                        onTap: (month) => _openMonth(value.member, month),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const DuesLegend(),
                    const SizedBox(height: 24),
                    Text(
                      'Riwayat Pembayaran',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (value.payments.isEmpty)
                      Text(
                        'Belum ada pembayaran lewat transfer.',
                        style: theme.textTheme.bodySmall,
                      )
                    else
                      for (final payment in value.payments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PaymentEntry(
                            communityId: widget.communityId,
                            payment: payment,
                          ),
                        ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PaymentEntry extends StatelessWidget {
  const _PaymentEntry({required this.communityId, required this.payment});

  final String communityId;
  final DuesPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = payment.createdAt?.toLocal();
    final pending = payment.status == DuesPaymentStatus.pending;
    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: communityHairline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('dues-member-payment-${payment.id}'),
        onTap: pending
            ? () => context.push(AppRoutes.communityDuesPayments(communityId))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DuesMonths.range(payment.months),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        formatRupiah(payment.totalAmount),
                        if (created != null) AppDateUtils.longDateId(created),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    DuesPaymentStatusChip(status: payment.status),
                  ],
                ),
              ),
              if (pending) const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({required this.detail});

  final MemberDuesDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = detail.member;
    final headline = duesHeadline(context, member.calendar);
    final joined = member.joinedAt?.toLocal();
    final from = member.calendar.billableFrom;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Row(
        children: [
          ClubAvatar(name: member.name, url: member.avatarUrl, radius: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (member.role.canManage) ...[
                      const SizedBox(width: 6),
                      ClubRoleBadge(role: member.role),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  headline.text,
                  key: const Key('dues-member-headline'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: headline.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  [
                    if (joined != null)
                      'Bergabung ${AppDateUtils.longDateId(joined)}',
                    if (from != null) 'ditagih sejak ${DuesMonths.long(from)}',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

/// Ubah status satu bulan. Mengembalikan true (lunas) / false (belum lunas).
class _MonthSheet extends StatelessWidget {
  const _MonthSheet({required this.month, required this.member});

  final DuesMonth month;
  final MemberDues member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = duesMonthStyle(context, month.status);
    final pending = month.status == DuesMonthStatus.pending;
    final paid = month.status.isPaid;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${DuesMonths.long(month.month)} · ${member.name}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(style.icon, size: 18, color: style.color),
                const SizedBox(width: 6),
                Text(month.status.label, style: TextStyle(color: style.color)),
              ],
            ),
            const SizedBox(height: 16),
            if (pending)
              Text(
                'Bulan ini ada di pembayaran yang menunggu verifikasi. Terima '
                'atau tolak pembayarannya di Verifikasi Pembayaran.',
                style: theme.textTheme.bodySmall,
              )
            else if (paid)
              OutlinedButton(
                key: const Key('dues-month-unpaid'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tandai Belum Lunas'),
              )
            else
              FilledButton(
                key: const Key('dues-month-paid'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tandai Lunas'),
              ),
          ],
        ),
      ),
    );
  }
}
