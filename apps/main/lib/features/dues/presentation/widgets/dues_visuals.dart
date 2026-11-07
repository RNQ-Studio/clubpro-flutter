import 'package:flutter/material.dart';

import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';

/// "Rp50.000" — tanpa bergantung pada data locale intl.
String formatRupiah(int amount) {
  final digits = amount.abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write('.');
    grouped.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}Rp$grouped';
}

abstract final class DuesMonths {
  static const _short = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  static const _long = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// "Mar".
  static String short(DateTime month) => _short[month.month - 1];

  /// "Maret 2026".
  static String long(DateTime month) =>
      '${_long[month.month - 1]} ${month.year}';

  /// "Mar–Mei 2026", "Des 2026–Jan 2027", atau "Mar 2026" untuk satu bulan.
  static String range(List<DateTime> months) {
    if (months.isEmpty) return '-';
    final first = months.first;
    final last = months.last;
    if (months.length == 1) return '${short(first)} ${first.year}';
    return first.year == last.year
        ? '${short(first)}–${short(last)} ${last.year}'
        : '${short(first)} ${first.year}–${short(last)} ${last.year}';
  }
}

/// Warna & ikon tiap status bulan, dipakai kalender dan legendanya.
({Color color, Color background, IconData icon}) duesMonthStyle(
  BuildContext context,
  DuesMonthStatus status,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    DuesMonthStatus.paid => (
        color: CommunityColors.success,
        background: CommunityColors.success.withValues(alpha: 0.14),
        icon: Icons.check_circle_rounded,
      ),
    DuesMonthStatus.pending => (
        color: CommunityColors.brown,
        background: CommunityColors.goldLight.withValues(alpha: 0.22),
        icon: Icons.hourglass_top_rounded,
      ),
    DuesMonthStatus.overdue => (
        color: scheme.error,
        background: scheme.error.withValues(alpha: 0.12),
        icon: Icons.error_rounded,
      ),
    DuesMonthStatus.due => (
        color: const Color(0xFF1E6FD9),
        background: const Color(0xFF1E6FD9).withValues(alpha: 0.12),
        icon: Icons.schedule_rounded,
      ),
    DuesMonthStatus.upcoming => (
        color: scheme.onSurfaceVariant,
        background: scheme.onSurface.withValues(alpha: 0.05),
        icon: Icons.radio_button_unchecked_rounded,
      ),
    DuesMonthStatus.none => (
        color: scheme.onSurface.withValues(alpha: 0.3),
        background: Colors.transparent,
        icon: Icons.remove_rounded,
      ),
  };
}

/// Kalender satu tahun: 12 kotak bulan berwarna sesuai statusnya.
class DuesYearGrid extends StatelessWidget {
  const DuesYearGrid({super.key, required this.months, this.onTap});

  final List<DuesMonth> months;

  /// Null = hanya dilihat.
  final ValueChanged<DuesMonth>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 6 : 4;
        final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final month in months)
              SizedBox(
                width: width,
                child: _MonthCell(
                  month: month,
                  onTap: onTap == null ? null : () => onTap!(month),
                  theme: theme,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({required this.month, required this.theme, this.onTap});

  final DuesMonth month;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = duesMonthStyle(context, month.status);
    final none = month.status == DuesMonthStatus.none;
    return Semantics(
      label: '${DuesMonths.long(month.month)}: ${month.status.label}',
      child: Material(
        color: style.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: none
              ? BorderSide(color: communityHairline(context))
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('dues-month-${month.month.year}-${month.month.month}'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(
              children: [
                Text(
                  DuesMonths.short(month.month),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: none ? style.color : null,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(style.icon, size: 20, color: style.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keterangan warna kalender.
class DuesLegend extends StatelessWidget {
  const DuesLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final status in DuesMonthStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                duesMonthStyle(context, status).icon,
                size: 14,
                color: duesMonthStyle(context, status).color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(status.label, style: theme.textTheme.labelSmall),
              ),
            ],
          ),
      ],
    );
  }
}

/// Pemilih tahun kalender: ‹ 2026 ›.
class DuesYearSwitcher extends StatelessWidget {
  const DuesYearSwitcher({
    super.key,
    required this.year,
    required this.onChanged,
  });

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('dues-year-prev'),
          visualDensity: VisualDensity.compact,
          tooltip: 'Tahun sebelumnya',
          onPressed: year > 2000 ? () => onChanged(year - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text(
          '$year',
          key: const Key('dues-year'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        IconButton(
          key: const Key('dues-year-next'),
          visualDensity: VisualDensity.compact,
          tooltip: 'Tahun berikutnya',
          onPressed: year < 2099 ? () => onChanged(year + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Status pembayaran sebagai label kecil berwarna.
class DuesPaymentStatusChip extends StatelessWidget {
  const DuesPaymentStatusChip({super.key, required this.status});

  final DuesPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      DuesPaymentStatus.pending => CommunityColors.brown,
      DuesPaymentStatus.approved => CommunityColors.success,
      DuesPaymentStatus.rejected => scheme.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Ringkasan status iuran: menunggak N bulan, lunas sampai, atau belum ada.
({String text, Color color, IconData icon}) duesHeadline(
  BuildContext context,
  DuesCalendar calendar,
) {
  if (calendar.arrearsCount > 0) {
    return (
      text: 'Menunggak ${calendar.arrearsCount} bulan',
      color: Theme.of(context).colorScheme.error,
      icon: Icons.error_rounded,
    );
  }
  final paidUntil = calendar.paidUntil;
  if (paidUntil != null) {
    return (
      text: 'Lunas sampai ${DuesMonths.long(paidUntil)}',
      color: CommunityColors.success,
      icon: Icons.verified_rounded,
    );
  }
  return (
    text: 'Tidak ada tunggakan',
    color: CommunityColors.success,
    icon: Icons.check_circle_rounded,
  );
}
