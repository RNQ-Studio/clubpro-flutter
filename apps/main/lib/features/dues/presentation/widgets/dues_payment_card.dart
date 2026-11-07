import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../../community/presentation/widgets/club_common.dart';
import '../../../community/presentation/widgets/community_photo_viewer.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import 'dues_visuals.dart';

/// Satu pembayaran iuran: bulan, rincian nominal, bukti transfer, dan statusnya.
class DuesPaymentCard extends StatelessWidget {
  const DuesPaymentCard({
    super.key,
    required this.payment,
    this.showMember = false,
    this.actions,
  });

  final DuesPayment payment;

  /// Untuk pengelola: siapa yang membayar.
  final bool showMember;

  /// Tombol terima/tolak, bila ada.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final proof = payment.proofUrl;
    final created = payment.createdAt?.toLocal();
    final months = payment.months.length;

    return Container(
      key: Key('dues-payment-${payment.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (showMember) ...[
                ClubAvatar(
                  name: payment.userName,
                  url: payment.userAvatarUrl,
                  radius: 18,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showMember
                          ? payment.userName
                          : DuesMonths.range(payment.months),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (created != null)
                      Text(
                        'Dikirim ${AppDateUtils.longDateId(created)}, '
                        '${AppDateUtils.formatTime(created)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    DuesPaymentStatusChip(status: payment.status),
                  ],
                ),
              ),
              if (proof != null) ...[
                const SizedBox(width: 12),
                _ProofThumb(url: proof, paymentId: payment.id),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showMember)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          DuesMonths.range(payment.months),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _Line(
                      label: 'Iuran $months bulan × '
                          '${formatRupiah(payment.monthlyAmount)}',
                      value: formatRupiah(payment.monthlyAmount * months),
                    ),
                    if (payment.entryFee > 0)
                      _Line(
                        label: 'Uang masuk',
                        value: formatRupiah(payment.entryFee),
                      ),
                    Divider(height: 14, color: communityHairline(context)),
                    _Line(
                      label: 'Total',
                      value: formatRupiah(payment.totalAmount),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (payment.note case final note? when note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Catatan: $note',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
          if (payment.status == DuesPaymentStatus.rejected &&
              payment.reviewNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Alasan ditolak: ${payment.reviewNote}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
          if (payment.status != DuesPaymentStatus.pending &&
              payment.reviewedBy != null) ...[
            const SizedBox(height: 6),
            Text(
              '${payment.status.label} oleh ${payment.reviewedBy}',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 12),
            actions!,
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          fontSize: bold ? 14 : null,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      // Lebar penuh agar nilai rata kanan; turun ke baris baru bila sempit.
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          children: [
            Text(label, style: style),
            Text(value, style: style),
          ],
        ),
      ),
    );
  }
}

class _ProofThumb extends StatelessWidget {
  const _ProofThumb({required this.url, required this.paymentId});

  final String url;
  final String paymentId;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Lihat bukti transfer',
      child: InkWell(
        key: Key('dues-proof-$paymentId'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => showCommunityPhotoViewer(context, [url], 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 64,
            height: 80,
            child: CommunityNetworkImage(url: url),
          ),
        ),
      ),
    );
  }
}
