import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import 'member_profile_form.dart';

/// Validasi lalu kirim isian yang berubah. `true` bila tersimpan (atau tidak
/// ada perubahan); pesan gagal ditampilkan sebagai SnackBar.
Future<bool> saveMemberProfile(
  BuildContext context,
  WidgetRef ref,
  MemberProfileFormState? form,
) async {
  if (form == null || !form.validate()) return false;

  final changes = form.changes();
  if (changes.isEmpty) return true;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(authProvider.notifier).updateProfile(changes);
    messenger.showSnackBar(
      const SnackBar(content: Text('Data diri tersimpan')),
    );
    return true;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Gagal menyimpan: $e')),
    );
    return false;
  }
}
