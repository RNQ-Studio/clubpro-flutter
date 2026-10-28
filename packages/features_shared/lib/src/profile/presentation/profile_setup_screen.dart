import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import 'member_profile_form.dart';
import 'save_member_profile.dart';
import 'widgets/profile_completion_card.dart';

/// Ditampilkan tepat sesudah login bila data diri belum lengkap. Boleh diisi
/// sebagian atau dilewati; sisanya dilengkapi dari halaman Profil.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.doneLocation = '/'});

  final String doneLocation;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<MemberProfileFormState>();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await saveMemberProfile(context, ref, _formKey.currentState);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved) context.go(widget.doneLocation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Data Diri'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const Key('skip-profile-setup'),
            onPressed: _saving ? null : () => context.go(widget.doneLocation),
            child: const Text('Nanti saja'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Text(
            'Halo, ${user.name.split(' ').first}!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Isi data diri Anda sebagai anggota komunitas. Tidak '
            'harus lengkap sekarang — isian yang sudah diisi tetap tersimpan '
            'dan bisa dilengkapi nanti di halaman Profil.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ProfileCompletionCard(completion: user.completion),
          const SizedBox(height: 20),
          MemberProfileForm(key: _formKey, user: user),
        ],
      ),
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _save),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          key: const Key('save-profile'),
          onPressed: saving ? null : onSave,
          child: saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : const Text('Simpan'),
        ),
      ),
    );
  }
}
