import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../community/presentation/widgets/club_common.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/dues.dart';
import '../dues_providers.dart';
import '../widgets/dues_payment_card.dart';
import '../widgets/dues_visuals.dart';

/// Verifikasi bukti transfer oleh creator/admin: terima → bulannya lunas; tolak
/// (wajib alasan) → bulannya kembali belum lunas.
class DuesPaymentsScreen extends StatelessWidget {
  const DuesPaymentsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Verifikasi Pembayaran'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Menunggu'), Tab(text: 'Riwayat')],
          ),
        ),
        body: TabBarView(
          children: [
            _PaymentsList(
              communityId: communityId,
              status: DuesPaymentStatus.pending,
            ),
            _PaymentsList(communityId: communityId, status: null),
          ],
        ),
      ),
    );
  }
}

class _PaymentsList extends ConsumerWidget {
  const _PaymentsList({required this.communityId, required this.status});

  final String communityId;
  final DuesPaymentStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = duesPaymentsProvider(communityId, status);
    final payments = ref.watch(provider);
    final value = payments.value;
    final theme = Theme.of(context);

    if (value == null) {
      return payments.hasError
          ? CommunityErrorView(
              message: payments.error.toString(),
              onRetry: () => ref.invalidate(provider),
            )
          : const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(provider);
        try {
          await ref.read(provider.future);
        } catch (_) {
          // Galatnya tampil di layar.
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: value.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 80),
                    Icon(
                      status == DuesPaymentStatus.pending
                          ? Icons.task_alt_rounded
                          : Icons.receipt_long_rounded,
                      size: 48,
                      color: CommunityColors.gold,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status == DuesPaymentStatus.pending
                          ? 'Tidak ada bukti transfer yang menunggu.'
                          : 'Belum ada pembayaran iuran.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: value.items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == value.items.length) {
                      return _Footer(state: value, provider: provider);
                    }
                    final payment = value.items[index];
                    return DuesPaymentCard(
                      payment: payment,
                      showMember: true,
                      actions: payment.status == DuesPaymentStatus.pending
                          ? _ReviewActions(
                              communityId: communityId,
                              payment: payment,
                            )
                          : null,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state, required this.provider});

  final PagedState<DuesPayment> state;
  final DuesPaymentsNotifierProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loadMoreError case final error?) {
      return Column(
        children: [
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: ref.read(provider.notifier).loadMore,
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }
    if (!state.hasMore) return const SizedBox.shrink();
    return Center(
      child: state.isLoadingMore
          ? const CircularProgressIndicator()
          : TextButton(
              key: const Key('dues-payments-more'),
              onPressed: ref.read(provider.notifier).loadMore,
              child: const Text('Muat lebih banyak'),
            ),
    );
  }
}

class _ReviewActions extends ConsumerStatefulWidget {
  const _ReviewActions({required this.communityId, required this.payment});

  final String communityId;
  final DuesPayment payment;

  @override
  ConsumerState<_ReviewActions> createState() => _ReviewActionsState();
}

class _ReviewActionsState extends ConsumerState<_ReviewActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    await runClubAction(context, action, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    // Juga saat gagal: mungkin sudah diputuskan pengelola lain (409).
    invalidateDues(ref.invalidate, widget.communityId);
  }

  Future<void> _approve() async {
    final payment = widget.payment;
    final confirmed = await confirmClubAction(
      context,
      title: 'Terima pembayaran?',
      message: 'Pastikan ${formatRupiah(payment.totalAmount)} dari '
          '${payment.userName} sudah masuk ke rekening komunitas. Iuran '
          '${DuesMonths.range(payment.months)} akan ditandai lunas.',
      action: 'Terima',
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => ref
          .read(duesRepositoryProvider)
          .approve(widget.communityId, payment.id),
      'Pembayaran ${payment.userName} diterima',
    );
  }

  Future<void> _reject() async {
    final note = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectDialog(),
    );
    if (note == null || !mounted) return;
    await _run(
      () => ref
          .read(duesRepositoryProvider)
          .reject(widget.communityId, widget.payment.id, note),
      'Pembayaran ${widget.payment.userName} ditolak',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: Key('dues-reject-${widget.payment.id}'),
            onPressed: _busy ? null : _reject,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Tolak'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            key: Key('dues-approve-${widget.payment.id}'),
            onPressed: _busy ? null : _approve,
            child: const Text('Terima'),
          ),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final note = _note.text.trim();
    if (note.length < 5) {
      setState(() => _error = 'Tulis alasan minimal 5 karakter agar anggota '
          'tahu yang harus diperbaiki.');
      return;
    }
    Navigator.pop(context, note);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak pembayaran?'),
      content: TextField(
        key: const Key('dues-reject-note'),
        controller: _note,
        autofocus: true,
        maxLength: 500,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Alasan penolakan',
          hintText: 'Mis. nominal kurang, bukti tidak terbaca',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('dues-reject-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _submit,
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
