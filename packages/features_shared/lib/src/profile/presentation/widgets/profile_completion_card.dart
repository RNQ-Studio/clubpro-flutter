import 'package:flutter/material.dart';

import '../../domain/entities/member_profile.dart';

/// Petunjuk melengkapi profil (bila belum lengkap) atau penanda apresiasi
/// (bila sudah lengkap).
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({
    super.key,
    required this.completion,
    this.onComplete,
  });

  final ProfileCompletion completion;

  /// Aksi tombol "Lengkapi Profil"; null = tombol disembunyikan.
  final VoidCallback? onComplete;

  static const _complete = Color(0xFF178A5B);
  static const _pending = Color(0xFFC98A00);

  @override
  Widget build(BuildContext context) =>
      completion.isComplete ? _buildComplete(context) : _buildPending(context);

  Widget _buildComplete(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('profile-complete-badge'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _complete.withValues(alpha: 0.14),
            _complete.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _complete.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: _complete,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Lengkap',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _complete,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terima kasih! Data diri Anda sudah lengkap dan memudahkan '
                  'pengurus komunitas mendata anggota.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shown = completion.missing.take(4).toList();
    final more = completion.missing.length - shown.length;

    return Container(
      key: const Key('profile-incomplete-hint'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pending.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _pending.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_ind_outlined, color: _pending),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Profil ${completion.percent}% lengkap',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${completion.completed}/${completion.total}',
                style: theme.textTheme.labelLarge?.copyWith(color: _pending),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completion.ratio,
              minHeight: 8,
              color: _pending,
              backgroundColor: _pending.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lengkapi data diri agar pengurus komunitas dapat mendata dan '
            'menghubungi Anda. Yang belum diisi:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final field in shown) _Tag(field.label),
              if (more > 0) _Tag('+$more lainnya'),
            ],
          ),
          if (onComplete != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Lengkapi Profil'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
