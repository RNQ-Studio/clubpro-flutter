import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/domain/entities/community_draft.dart';
import '../../../community/presentation/community_providers.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import '../dues_providers.dart';
import '../widgets/dues_visuals.dart';

/// Bayar iuran: transfer ke rekening komunitas, pilih jumlah bulan, lalu unggah
/// bukti transfernya. Bulan yang dibayar dimulai dari tunggakan paling awal.
class DuesPayScreen extends ConsumerStatefulWidget {
  const DuesPayScreen({super.key, required this.communityId});

  final String communityId;

  static const maxMonths = 12;

  @override
  ConsumerState<DuesPayScreen> createState() => _DuesPayScreenState();
}

class _DuesPayScreenState extends ConsumerState<DuesPayScreen> {
  final _note = TextEditingController();
  int _months = 1;
  CommunityImage? _proof;
  bool _sending = false;
  String? _error;
  DuesPayment? _sent;

  /// Jumlah bulan baru disesuaikan dengan tunggakan sekali, saat data tiba.
  bool _initialized = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    try {
      final picked = await ref.read(communityImagePickerProvider).pickPhotos(1);
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _proof = picked.single;
        _error = null;
      });
    } on CommunityImageException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _send() async {
    final proof = _proof;
    if (proof == null) {
      setState(() => _error = 'Unggah foto bukti transfer terlebih dahulu.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final assetId = await ref
          .read(communityRepositoryProvider)
          .uploadImage(proof, category: 'dues-proof');
      final payment = await ref.read(duesRepositoryProvider).pay(
            widget.communityId,
            monthsCount: _months,
            proofAssetId: assetId,
            note: _note.text,
          );
      if (!mounted) return;
      invalidateDues(ref.invalidate, widget.communityId);
      setState(() => _sent = payment);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = duesOverviewProvider(widget.communityId, null);
    final overview = ref.watch(provider);
    final value = overview.value;
    final sent = _sent;

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar Iuran')),
      body: sent != null
          ? _SentView(payment: sent)
          : value == null
              ? overview.hasError
                  ? CommunityErrorView(
                      message: overview.error.toString(),
                      onRetry: () => ref.invalidate(provider),
                    )
                  : const Center(child: CircularProgressIndicator())
              : _form(context, value),
      bottomNavigationBar: sent != null ||
              value?.me == null ||
              !(value?.settings.configured ?? false)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dekat tombol agar terlihat tanpa menggulir.
                    if (_error case final error?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          error,
                          key: const Key('dues-pay-error'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      key: const Key('dues-send'),
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox.square(
                              dimension: 22,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          : Text(
                              'Kirim Bukti Transfer · '
                              '${formatRupiah(_total(value!))}',
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  int _total(DuesOverview overview) =>
      (overview.settings.monthlyAmount ?? 0) * _months +
      (overview.me?.entryFeeDue ?? 0);

  Widget _form(BuildContext context, DuesOverview overview) {
    final theme = Theme.of(context);
    final settings = overview.settings;
    final me = overview.me;
    if (!settings.configured || me == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            !settings.configured
                ? 'Iuran komunitas ini belum diatur pengurus.'
                : 'Hanya anggota komunitas ini yang bisa membayar iuran.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (!_initialized) {
      _initialized = true;
      // Langsung menutup semua tunggakan bila ada.
      _months = me.calendar.arrearsCount.clamp(1, DuesPayScreen.maxMonths);
    }
    final months = me.nextUnpaidMonths.take(_months).toList();
    final monthly = settings.monthlyAmount ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _BankCard(settings: settings),
            const SizedBox(height: 20),
            Text(
              'Bayar untuk berapa bulan?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(
                  key: const Key('dues-months-minus'),
                  onPressed: _months > 1 && !_sending
                      ? () => setState(() => _months--)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$_months bulan',
                    key: const Key('dues-months-count'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  key: const Key('dues-months-plus'),
                  onPressed: _months < DuesPayScreen.maxMonths && !_sending
                      ? () => setState(() => _months++)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('dues-months-covered'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final month in months)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${DuesMonths.short(month)} ${month.year}'),
                  ),
              ],
            ),
            if (me.calendar.arrearsCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Tunggakan dibayar lebih dulu, mulai dari bulan paling awal.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _Breakdown(
              months: _months,
              monthly: monthly,
              entryFee: me.entryFeeDue,
            ),
            const SizedBox(height: 20),
            Text(
              'Bukti transfer',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _ProofField(
              proof: _proof,
              onPick: _sending ? null : _pickProof,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('dues-note'),
              controller: _note,
              enabled: !_sending,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Mis. transfer dari rekening atas nama orang lain',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.settings});

  final DuesSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = settings.accountNumber ?? '';
    return Container(
      key: const Key('dues-bank'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CommunityColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer ke rekening ${settings.bankName ?? ''}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: CommunityColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  number,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              IconButton(
                key: const Key('dues-copy-account'),
                tooltip: 'Salin nomor rekening',
                color: Colors.white,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: number));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nomor rekening disalin')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          Text(
            'a.n. ${settings.accountName ?? ''}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.months,
    required this.monthly,
    required this.entryFee,
  });

  final int months;
  final int monthly;
  final int entryFee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget line(String label, String value, {bool total = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: total
                      ? theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)
                      : theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                value,
                key: total ? const Key('dues-total') : null,
                style: total
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CommunityColors.brown,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        children: [
          line(
            'Iuran $months × ${formatRupiah(monthly)}',
            formatRupiah(months * monthly),
          ),
          if (entryFee > 0) line('Uang masuk (sekali)', formatRupiah(entryFee)),
          Divider(height: 16, color: communityHairline(context)),
          line(
            'Total transfer',
            formatRupiah(months * monthly + entryFee),
            total: true,
          ),
        ],
      ),
    );
  }
}

class _ProofField extends StatelessWidget {
  const _ProofField({required this.proof, required this.onPick});

  final CommunityImage? proof;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = proof;
    if (image == null) {
      return InkWell(
        key: const Key('dues-proof-pick'),
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: CommunityColors.gold.withValues(alpha: 0.7),
            radius: 14,
          ),
          child: SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_rounded,
                    size: 32,
                    color: CommunityColors.gold,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Unggah foto bukti transfer',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'JPG, PNG, atau WebP, maksimal 5 MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            image.bytes,
            key: const Key('dues-proof-preview'),
            width: 96,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                image.filename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const Key('dues-proof-change'),
                onPressed: onPick,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Ganti foto'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.payment});

  final DuesPayment payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const Key('dues-sent'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: CommunityColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: CommunityColors.success,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bukti transfer terkirim',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Iuran ${DuesMonths.range(payment.months)} sebesar '
              '${formatRupiah(payment.totalAmount)} menunggu verifikasi '
              'pengurus. Statusnya otomatis menjadi lunas begitu diterima.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('dues-sent-back'),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Kembali ke Iuran'),
            ),
          ],
        ),
      ),
    );
  }
}
