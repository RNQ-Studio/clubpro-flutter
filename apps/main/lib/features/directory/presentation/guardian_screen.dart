import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'directory_providers.dart';
import '../../community/presentation/community_providers.dart';
import 'directory_screen.dart';
import 'member_identity_screen.dart';

class GuardianScreen extends ConsumerStatefulWidget {
  const GuardianScreen({super.key});
  @override
  ConsumerState<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends ConsumerState<GuardianScreen> {
  final _id = TextEditingController(), _token = TextEditingController();
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _id.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(directoryRepositoryProvider).sendEmailVerification();
      if (mounted) {
        setState(() => _message =
            'Jika email belum terverifikasi, tautan verifikasi telah dikirim. Buka tautan tersebut lalu klaim undangan.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    if (_busy) return;
    if (_id.text.trim().isEmpty || _token.text.trim().isEmpty) {
      setState(() => _message = 'Isi nomor undangan dan kode dari email.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(directoryRepositoryProvider)
          .claim(_id.text.trim(), _token.text.trim());
      _token.clear();
      ref.invalidate(guardianInvitationsProvider);
      ref.invalidate(guardianDependentsProvider);
      ref.invalidate(joinedCommunitiesProvider);
      if (mounted) {
        setState(() => _message = 'Penautan terverifikasi berhasil.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptInvitation(Map<String, dynamic> invite) async {
    if (_busy) return;
    final account = invite['kind'] == 'account';
    final issuer =
        invite['invited_by_name']?.toString() ?? 'Pengelola komunitas';
    final community =
        invite['community_name']?.toString() ?? 'komunitas terkait';
    final name = invite['member_name']?.toString() ?? 'anggota';
    final consent = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                constraints: const BoxConstraints(maxWidth: 600),
                title: Text(account
                    ? 'Hubungkan akun anggota?'
                    : 'Setujui hubungan wali?'),
                content: Text(account
                    ? '$issuer di $community mengundang Anda menghubungkan akun ini ke identitas $name. Hubungan wali lama pada identitas manual ini akan berakhir. Anda dapat mengundang wali kembali setelah penautan.'
                    : '$issuer di $community mengundang Anda menjadi wali $name. Persetujuan memberi akses data dependent dan status keanggotaan, tanpa mengubah kepemilikan akun login.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Setujui undangan'))
                ]));
    if (consent != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(directoryRepositoryProvider)
          .claim(invite['id'].toString(), '', accept: true);
      ref.invalidate(guardianInvitationsProvider);
      ref.invalidate(guardianDependentsProvider);
      ref.invalidate(joinedCommunitiesProvider);
      if (mounted) {
        setState(() => _message = account
            ? 'Akun terhubung. Hubungan wali dapat diundang kembali oleh pemilik akun.'
            : 'Hubungan wali terverifikasi berhasil disimpan.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitations = ref.watch(guardianInvitationsProvider);
    final inAppOnly = (invitations.asData?.value.isNotEmpty ?? false) &&
        invitations.asData!.value
            .every((i) => i['delivery_method'] == 'in_app');
    return Scaffold(
        appBar: AppBar(title: const Text('Akun dan Hubungan Wali')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      OutlinedButton.icon(
                          onPressed: () => context.push('/account/pin'),
                          icon: const Icon(Icons.pin_outlined),
                          label: const Text('Buat atau Ubah PIN')),
                      const SizedBox(height: 24),
                      Text('Undangan Penautan',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                          'Masuk dengan akun pemilik email yang sudah terverifikasi. Setujui undangan dalam aplikasi, atau gunakan kode bila undangan dikirim melalui email. Undangan berlaku 24 jam dan hanya dapat diklaim sekali.'),
                      invitations.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => DirectoryError(
                              message: e.toString(),
                              retry: () =>
                                  ref.invalidate(guardianInvitationsProvider)),
                          data: (items) => Column(children: [
                                if (items.isEmpty)
                                  const ListTile(
                                      title:
                                          Text('Tidak ada undangan menunggu.')),
                                for (final item in items)
                                  ListTile(
                                      key: Key(
                                          'guardian-invitation-${item['id']}'),
                                      title: Text(
                                          item['member_name']?.toString() ??
                                              'Anggota'),
                                      subtitle: Text(
                                          '${item['kind'] == 'account' ? 'Akun anggota' : 'Wali'} · ${item['community_name'] ?? 'Komunitas'}\nDari ${item['invited_by_name'] ?? 'Pengelola'}'),
                                      trailing: item['delivery_method'] ==
                                              'in_app'
                                          ? TextButton(
                                              onPressed: _busy
                                                  ? null
                                                  : () =>
                                                      _acceptInvitation(item),
                                              child: const Text('Setujui'))
                                          : null,
                                      onTap: item['delivery_method'] == 'in_app'
                                          ? null
                                          : () => setState(() =>
                                              _id.text = item['id'].toString()))
                              ])),
                      TextButton(
                          onPressed: _busy ? null : _verifyEmail,
                          child: const Text('Kirim Tautan Verifikasi Email')),
                      if (_message != null) Text(_message!),
                      if (!inAppOnly) ...[
                        TextField(
                            controller: _id,
                            decoration: const InputDecoration(
                                labelText: 'Nomor undangan')),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _token,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Kode undangan dari email')),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _busy ? null : _claim,
                            child: Text(
                                _busy ? 'Memverifikasi…' : 'Klaim Undangan')),
                      ],
                      const Divider(height: 40),
                      Text('Anggota dalam Perwalian',
                          style: Theme.of(context).textTheme.titleLarge),
                      ref.watch(guardianDependentsProvider).when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => DirectoryError(
                              message: e.toString(),
                              retry: () =>
                                  ref.invalidate(guardianDependentsProvider)),
                          data: (items) => Column(children: [
                                if (items.isEmpty)
                                  const ListTile(
                                      title: Text(
                                          'Belum ada hubungan wali terverifikasi.')),
                                for (final item in items)
                                  ListTile(
                                      leading:
                                          const Icon(Icons.family_restroom),
                                      title: Text(item['name']?.toString() ??
                                          'Anggota'),
                                      subtitle: const Text(
                                          'Data anggota, status dan kartu keanggotaan'),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => context.push(
                                          '/guardians/dependents/${item['id']}'))
                              ])),
                    ])))));
  }
}

class DependentScreen extends ConsumerStatefulWidget {
  const DependentScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<DependentScreen> createState() => _DependentScreenState();
}

class _DependentScreenState extends ConsumerState<DependentScreen> {
  final _name = TextEditingController(), _birth = TextEditingController();
  String? _gender, _message;
  bool _busy = false, _loaded = false, _public = false;
  @override
  void dispose() {
    _name.dispose();
    _birth.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final error = validateBirthDate(_birth.text);
    if (_name.text.trim().isEmpty || error != null) {
      setState(() => _message = error ?? 'Isi nama anggota.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(directoryRepositoryProvider).updateDependent(widget.id, {
        'name': _name.text.trim(),
        'birth_date': _birth.text.isEmpty ? null : _birth.text,
        'gender': _gender,
        'is_public': _public
      });
      ref.invalidate(dependentDetailProvider(widget.id));
      if (mounted) setState(() => _message = 'Data anggota disimpan.');
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _card(String memberId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final card =
          await ref.read(directoryRepositoryProvider).card(widget.id, memberId);
      if (card['validity'] is Map) {
        final v = card['validity'] as Map;
        card['status'] = v['status'];
        card['valid_until'] = v['valid_until'];
      }
      if (mounted) {
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text('Kartu Anggota'),
                    content: SingleChildScrollView(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          for (final key in [
                            'name',
                            'community_name',
                            'member_number',
                            'status',
                            'valid_until'
                          ])
                            if (card[key] != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                      '${_cardLabel(key)}: ${key == 'status' ? membershipStatusLabel(card[key]) : card[key]}'))
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'))
                    ]));
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _cardLabel(String key) => switch (key) {
        'name' => 'Nama',
        'community_name' => 'Komunitas',
        'member_number' => 'Nomor anggota',
        'status' => 'Status',
        'valid_until' => 'Berlaku sampai',
        _ => key
      };
  Future<void> _revoke(String grant) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Lepaskan hubungan wali?'),
                content: const Text(
                    'Akses Anda ke data anggota ini akan dicabut. Histori keanggotaan tetap tersimpan.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Lepaskan'))
                ]));
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(directoryRepositoryProvider).revoke(grant);
      ref.invalidate(guardianDependentsProvider);
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/guardians');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = dependentDetailProvider(widget.id);
    return Scaffold(
        appBar: AppBar(title: const Text('Anggota dalam Perwalian')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: ref.watch(provider).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => DirectoryError(
                            message: e.toString(),
                            retry: () => ref.invalidate(provider)),
                        data: (data) {
                          if (!_loaded) {
                            _loaded = true;
                            _name.text = data['name']?.toString() ?? '';
                            _birth.text = data['birth_date']?.toString() ?? '';
                            _gender = data['gender'] as String?;
                            _public = data['is_public'] == true;
                          }
                          return ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                const Text(
                                    'Wali hanya mengelola data dependent. PIN dan akun login tetap milik masing-masing.'),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: _name,
                                    decoration: const InputDecoration(
                                        labelText: 'Nama anggota')),
                                const SizedBox(height: 16),
                                TextField(
                                    controller: _birth,
                                    decoration: const InputDecoration(
                                        labelText: 'Tanggal lahir (opsional)',
                                        hintText: 'YYYY-MM-DD')),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                    initialValue: _gender ?? '',
                                    decoration: const InputDecoration(
                                        labelText: 'Gender'),
                                    items: const [
                                      DropdownMenuItem(
                                          value: '',
                                          child: Text('Belum diketahui')),
                                      DropdownMenuItem(
                                          value: 'male',
                                          child: Text('Laki-laki')),
                                      DropdownMenuItem(
                                          value: 'female',
                                          child: Text('Perempuan'))
                                    ],
                                    onChanged: _busy
                                        ? null
                                        : (v) => setState(() =>
                                            _gender = v == '' ? null : v)),
                                const SizedBox(height: 16),
                                if (_message != null) Text(_message!),
                                SwitchListTile(
                                    title: const Text(
                                        'Tampilkan di direktori publik'),
                                    subtitle: const Text(
                                        'Nama, peran, foto dan asal komunitas saja. Data pribadi tetap dibatasi.'),
                                    value: _public,
                                    onChanged: _busy
                                        ? null
                                        : (v) => setState(() => _public = v)),
                                FilledButton(
                                    onPressed: _busy ? null : _save,
                                    child: const Text('Simpan Data')),
                                const Divider(height: 32),
                                for (final item
                                    in data['memberships'] as List? ?? [])
                                  ListTile(
                                      title: Text(
                                          item['community_name']?.toString() ??
                                              'Komunitas'),
                                      subtitle: Text(
                                          'Status: ${membershipStatusLabel(item['status'])} · ${item['member_number'] ?? ''}'),
                                      trailing: TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () =>
                                                  _card(item['id'].toString()),
                                          child: const Text('Kartu'))),
                                if (data['grant_id'] != null)
                                  OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _revoke(
                                              data['grant_id'].toString()),
                                      child:
                                          const Text('Lepaskan Hubungan Wali'))
                              ]);
                        })))));
  }
}

String membershipStatusLabel(Object? status) => switch (status) {
      'active' => 'Aktif',
      'pending' => 'Menunggu persetujuan',
      'archived' => 'Diarsipkan',
      'valid' => 'Berlaku',
      'expired' => 'Kedaluwarsa',
      'not_configured' => 'Belum diatur',
      'inactive' => 'Tidak aktif',
      'no_dues' => 'Iuran belum diatur',
      _ => status?.toString() ?? 'Belum diketahui'
    };
