import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community_draft.dart';
import '../community_form_notifier.dart';
import '../widgets/community_form_steps.dart';
import '../widgets/community_preview_card.dart';
import '../widgets/community_submitted_view.dart';
import '../widgets/community_visuals.dart';

/// Form pengajuan komunitas, lima langkah dengan pratinjau langsung.
class CommunityFormScreen extends ConsumerWidget {
  const CommunityFormScreen({super.key});

  /// Lebar minimum untuk panel pratinjau di samping form.
  static const _previewWidth = 900.0;

  Future<void> _confirmLeave(BuildContext context) async {
    final navigator = Navigator.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tinggalkan form?'),
        content: const Text('Isian yang sudah Anda tulis akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut Mengisi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tinggalkan'),
          ),
        ],
      ),
    );
    if (leave == true) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(communityFormProvider);
    final result = form.result;
    if (form.phase == CommunitySubmitPhase.done && result != null) {
      return CommunitySubmittedView(community: result);
    }

    return PopScope(
      canPop: form.draft.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !form.isSubmitting) _confirmLeave(context);
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _previewWidth;
            return Column(
              children: [
                const _FormHeader(),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1040 : 640),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _StepPane(showPreview: !wide)),
                          if (wide)
                            SizedBox(
                              width: 340,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 20, 16, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pratinjau',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    CommunityPreviewCard(draft: form.draft),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const _FormFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormHeader extends ConsumerWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(communityFormProvider.select((s) => s.step));
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: CommunityColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Tutup',
                        color: Colors.white,
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'Daftarkan Komunitas',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Langkah ${step.index + 1} dari '
                        '${CommunityFormStep.values.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _StepTrack(current: step),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Penanda langkah; langkah yang sudah dilewati bisa dibuka kembali.
class _StepTrack extends ConsumerWidget {
  const _StepTrack({required this.current});

  final CommunityFormStep current;

  static const _icons = {
    CommunityFormStep.identity: Icons.badge_rounded,
    CommunityFormStep.location: Icons.place_rounded,
    CommunityFormStep.contact: Icons.support_agent_rounded,
    CommunityFormStep.story: Icons.auto_stories_rounded,
    CommunityFormStep.review: Icons.fact_check_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(communityFormProvider.notifier);
    final submitting =
        ref.watch(communityFormProvider.select((s) => s.isSubmitting));
    final children = <Widget>[];
    for (final step in CommunityFormStep.values) {
      if (step.index > 0) {
        children.add(
          Expanded(
            child: Padding(
              // Tengah lingkaran penanda setinggi 34.
              padding: const EdgeInsets.only(top: 16),
              child: AnimatedContainer(
                key: Key('community-step-line-${step.name}'),
                duration: const Duration(milliseconds: 220),
                height: 2,
                color: step.index <= current.index
                    ? CommunityColors.goldLight
                    : Colors.white24,
              ),
            ),
          ),
        );
      }
      final done = step.index < current.index;
      final active = step == current;
      children.add(
        InkWell(
          key: Key('community-step-${step.name}'),
          borderRadius: BorderRadius.circular(10),
          onTap: done && !submitting ? () => notifier.goTo(step) : null,
          child: SizedBox(
            width: 54,
            child: Column(
              children: [
                AnimatedContainer(
                  key: Key('community-step-dot-${step.name}'),
                  duration: const Duration(milliseconds: 220),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white
                        : done
                            ? CommunityColors.goldLight
                            : Colors.white12,
                    border: Border.all(
                      color:
                          active || done ? Colors.transparent : Colors.white38,
                    ),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : _icons[step],
                    size: 18,
                    color: active
                        ? CommunityColors.brown
                        : done
                            ? CommunityColors.ink
                            : Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: active || done ? Colors.white : Colors.white60,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }
}

class _StepPane extends ConsumerWidget {
  const _StepPane({required this.showPreview});

  final bool showPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(communityFormProvider.select((s) => s.step));
    final error = ref.watch(communityFormProvider.select((s) => s.error));
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: SingleChildScrollView(
        key: ValueKey(step),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              step.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Container(
                key: const Key('community-form-error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            CommunityFormStepView(showPreview: showPreview),
          ],
        ),
      ),
    );
  }
}

class _FormFooter extends ConsumerWidget {
  const _FormFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(communityFormProvider);
    final notifier = ref.read(communityFormProvider.notifier);
    final theme = Theme.of(context);
    final step = form.step;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: communityHairline(context))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: form.isSubmitting
                  ? _SubmitProgress(form: form)
                  : Row(
                      children: [
                        if (step.index > 0) ...[
                          OutlinedButton(
                            key: const Key('community-back'),
                            onPressed: notifier.back,
                            child: const Text('Kembali'),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton(
                            key: const Key('community-next'),
                            onPressed:
                                step.isLast ? notifier.submit : notifier.next,
                            child: Text(
                              step.isLast ? 'Kirim Pengajuan' : 'Lanjut',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmitProgress extends StatelessWidget {
  const _SubmitProgress({required this.form});

  final CommunityFormState form;

  @override
  Widget build(BuildContext context) {
    final saving = form.phase == CommunitySubmitPhase.saving;
    final total = form.uploadTotal;
    final current = (form.uploadDone + 1).clamp(1, total == 0 ? 1 : total);
    return Column(
      key: const Key('community-submit-progress'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          saving
              ? 'Mengirim pengajuan...'
              : 'Mengunggah foto $current dari $total...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 6,
            color: CommunityColors.gold,
            value: saving || total == 0 ? null : form.uploadDone / total,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
