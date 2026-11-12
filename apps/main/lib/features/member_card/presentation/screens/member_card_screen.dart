import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/active_community_notifier.dart';
import '../../domain/entities/member_card.dart';
import '../member_card_providers.dart';
import '../widgets/member_card_view.dart';

/// Kartu anggota saya di satu komunitas, dengan masa berlaku menurut iuran
/// bulanan yang lunas. Anggota beberapa komunitas bisa berganti kartu di sini.
class MemberCardScreen extends ConsumerStatefulWidget {
  const MemberCardScreen({super.key, required this.communityId});

  final String communityId;

  /// Lebar isi terbesar di layar lebar.
  static const maxWidth = 480.0;

  @override
  ConsumerState<MemberCardScreen> createState() => _MemberCardScreenState();
}

class _MemberCardScreenState extends ConsumerState<MemberCardScreen> {
  late String _communityId = widget.communityId;

  @override
  Widget build(BuildContext context) {
    final joined =
        ref.watch(activeCommunityProvider).value?.joined ?? const <Community>[];
    final card = ref.watch(memberCardProvider(_communityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Anggota')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(memberCardProvider(_communityId).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: MemberCardScreen.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (joined.length > 1) ...[
                      _CommunitySwitcher(
                        communities: joined,
                        selectedId: _communityId,
                        onSelected: (id) => setState(() => _communityId = id),
                      ),
                      const SizedBox(height: 16),
                    ],
                    switch (card) {
                      AsyncData(:final value) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MemberCardView(card: value),
                            const SizedBox(height: 24),
                            _ValidityPanel(card: value),
                          ],
                        ),
                      AsyncError(:final error) => _ErrorPanel(
                          message: error.toString(),
                          onRetry: () =>
                              ref.invalidate(memberCardProvider(_communityId)),
                        ),
                      _ => const _CardPlaceholder(),
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan komunitas bila anggota lebih dari satu komunitas.
class _CommunitySwitcher extends StatelessWidget {
  const _CommunitySwitcher({
    required this.communities,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Community> communities;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final community in communities) ...[
            ChoiceChip(
              key: Key('member-card-community-${community.id}'),
              label: Text(community.name),
              selected: community.id == selectedId,
              showCheckmark: false,
              onSelected: (_) => onSelected(community.id),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Penjelasan masa berlaku dan langkah berikutnya.
class _ValidityPanel extends StatelessWidget {
  const _ValidityPanel({required this.card});

  final MemberCard card;

  static const _green = Color(0xFF178A5B);
  static const _red = Color(0xFFC62828);
  static const _amber = Color(0xFFC98A00);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validity = card.validity;
    final paidUntil = validity.paidUntil;
    final validUntil = validity.validUntil;
    final communityId = card.community.id;

    final (icon, color, title, message) = switch (validity.status) {
      MemberCardStatus.active => (
          Icons.verified_rounded,
          _green,
          'Kartu aktif',
          'Iuran lunas hingga ${AppDateUtils.monthYearId(paidUntil!)}. '
              'Kartu berlaku sampai ${AppDateUtils.longDateId(validUntil!)}; '
              'bayar iuran bulan berikutnya untuk memperpanjang.',
        ),
      MemberCardStatus.expired => (
          Icons.error_outline_rounded,
          _red,
          'Kartu tidak berlaku',
          'Iuran lunas hingga ${AppDateUtils.monthYearId(paidUntil!)}; '
              'masa berlaku berakhir ${AppDateUtils.longDateId(validUntil!)}. '
              'Lunasi iuran untuk mengaktifkan kembali.',
        ),
      MemberCardStatus.inactive => (
          Icons.hourglass_empty_rounded,
          _amber,
          'Kartu belum aktif',
          'Belum ada iuran bulanan yang lunas. Bayar iuran untuk '
              'mengaktifkan kartu.',
        ),
      MemberCardStatus.noDues => (
          Icons.verified_rounded,
          _green,
          'Kartu aktif',
          '${card.community.name} belum menetapkan iuran bulanan, jadi kartu '
              'berlaku selama Anda menjadi anggota.',
        ),
    };
    final needsPayment = validity.status == MemberCardStatus.expired ||
        validity.status == MemberCardStatus.inactive;

    return Container(
      key: const Key('member-card-validity'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (validity.pendingPayment) ...[
            const SizedBox(height: 12),
            Row(
              key: const Key('member-card-pending'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pembayaran iuran Anda sedang diverifikasi pengurus. Masa '
                    'berlaku diperbarui setelah disetujui.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (validity.status != MemberCardStatus.noDues) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (needsPayment && !validity.pendingPayment) ...[
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('member-card-pay'),
                      onPressed: () =>
                          context.push(AppRoutes.communityDuesPay(communityId)),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Bayar Iuran'),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: OutlinedButton(
                    key: const Key('member-card-dues'),
                    onPressed: () =>
                        context.push(AppRoutes.communityDues(communityId)),
                    child: const Text('Lihat Iuran'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      key: const Key('member-card-error'),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.badge_outlined,
              size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}

/// Tempat kartu selama dimuat, seukuran kartu agar isi tidak melompat.
class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: MemberCardView.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
