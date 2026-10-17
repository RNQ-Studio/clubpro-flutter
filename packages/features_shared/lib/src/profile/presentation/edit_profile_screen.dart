import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import 'member_profile_form.dart';
import 'save_member_profile.dart';

/// Ubah data diri anggota dari halaman Profil.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<MemberProfileFormState>();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await saveMemberProfile(context, ref, _formKey.currentState);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Data Diri'),
        actions: [
          TextButton(
            key: const Key('save-profile'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          MemberProfileForm(key: _formKey, user: authState.user),
        ],
      ),
    );
  }
}
