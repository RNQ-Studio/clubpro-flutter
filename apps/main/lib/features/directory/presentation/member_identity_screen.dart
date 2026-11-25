import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../community/domain/entities/community.dart';
import '../../community/presentation/community_providers.dart';
import 'directory_providers.dart';

/// Identitas stabil, terpisah dari akun login. Undangan tidak memberi akses
/// sebelum pemilik email masuk dan mengklaim tokennya.
class MemberIdentityScreen extends ConsumerStatefulWidget {
  const MemberIdentityScreen(
      {super.key, required this.communityId, this.member});
  final String communityId;
  final CommunityMember? member;
  @override
  ConsumerState<MemberIdentityScreen> createState() =>
      _MemberIdentityScreenState();
}

class _MemberIdentityScreenState extends ConsumerState<MemberIdentityScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _birth = TextEditingController(),
      _reference = TextEditingController(),
      _email = TextEditingController(),
      _accountEmail = TextEditingController();
  late final String _idempotencyKey = _newRequestId();
  String? _gender, _message, _memberId;
  bool _busy = false, _loadSucceeded = true;
  List<dynamic> _grants = [];
  bool get _linked => widget.member?.userId.isNotEmpty ?? false;
  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _name.text = m?.name ?? '';
    _birth.text = m?.birthDate ?? '';
    _gender = m?.gender;
    _reference.text = m?.externalReference ?? '';
    _memberId = m?.id;
    if (m != null) {
      _loadSucceeded = false;
      Future.microtask(_load);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _birth, _reference, _email, _accountEmail]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final data = await ref
          .read(directoryRepositoryProvider)
          .memberDetail(widget.communityId, _memberId!);
      if (!mounted) return;
      setState(() {
        _loadSucceeded = true;
        _name.text = data['name']?.toString() ?? _name.text;
        _birth.text = data['birth_date']?.toString() ?? '';
        _gender = data['gender'] as String?;
        _reference.text = data['external_reference']?.toString() ?? '';
        _grants = data['guardian_grants'] as List? ?? [];
        _accountEmail.text = data['account_email']?.toString() ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke(String id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(directoryRepositoryProvider).revoke(id);
      await _load();
      if (mounted) setState(() => _message = 'Hubungan wali dicabut.');
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy ||
        !_loadSucceeded ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final repo = ref.read(directoryRepositoryProvider);
      final fields = <String, Object?>{
        'name': _name.text.trim(),
        'account_email': _accountEmail.text.trim().isEmpty
            ? null
            : _accountEmail.text.trim(),
        'birth_date': _birth.text.isEmpty ? null : _birth.text,
        'gender': _gender,
        'external_reference':
            _reference.text.isEmpty ? null : _reference.text.trim()
      };
      if (_memberId == null) {
        final result = await repo.createMember(widget.communityId,
            {...fields, 'idempotency_key': _idempotencyKey});
        _memberId = result['id'].toString();
      } else {
        await repo.editMember(widget.communityId, _memberId!, fields);
      }
      ref.invalidate(communityDetailProvider(widget.communityId));
      ref.invalidate(communityMembersProvider(widget.communityId));
      if (mounted) {
        setState(() => _message =
            'Identitas anggota berhasil disimpan. Nomor keanggotaan dan riwayat tetap dipertahankan.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(bool account) async {
    if (_busy || _memberId == null) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _message = 'Isi alamat email yang valid.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(directoryRepositoryProvider).invite(
          widget.communityId, _memberId!, _email.text.trim(),
          account: account);
      if (mounted) {
        setState(() => _message =
            'Undangan dibuat. Penerima dapat membuka Akun dan Hubungan Wali setelah masuk dengan email terverifikasi. Jika menerima kode melalui email, gunakan kode tersebut.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: Text(widget.member == null
              ? 'Catat Anggota Manual'
              : 'Kelola Identitas Anggota')),
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                          key: _form,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                    'Anggota dapat dicatat sebelum mempunyai akun. Nama yang sama tidak otomatis digabung dengan orang lain.'),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _name,
                                    readOnly: _linked,
                                    decoration: const InputDecoration(
                                        labelText: 'Nama anggota'),
                                    validator: (v) =>
                                        (v?.trim().isEmpty ?? true)
                                            ? 'Isi nama anggota.'
                                            : null),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _birth,
                                    readOnly: _linked,
                                    decoration: const InputDecoration(
                                        labelText: 'Tanggal lahir (opsional)',
                                        hintText: 'YYYY-MM-DD'),
                                    validator: validateBirthDate),
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
                                    onChanged: _busy || _linked
                                        ? null
                                        : (v) => setState(() =>
                                            _gender = v == '' ? null : v)),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _reference,
                                    readOnly: _linked,
                                    decoration: const InputDecoration(
                                        labelText: 'Referensi lokal (opsional)',
                                        helperText:
                                            'Nomor rujukan unik di komunitas ini untuk mencegah duplikasi.')),
                                const SizedBox(height: 16),
                                TextFormField(
                                    controller: _accountEmail,
                                    readOnly: _linked,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Email akun anggota (opsional)',
                                        helperText:
                                            'Mencegah duplikasi; penautan perlu verifikasi email.',
                                        helperMaxLines: 3),
                                    validator: (v) => v != null &&
                                            v.isNotEmpty &&
                                            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                .hasMatch(v)
                                        ? 'Email tidak valid.'
                                        : null),
                                const SizedBox(height: 16),
                                if (!_loadSucceeded)
                                  TextButton(
                                      onPressed: _busy ? null : _load,
                                      child: const Text(
                                          'Coba Muat Identitas Lagi')),
                                if (_message != null)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Text(_message!,
                                          key: const Key(
                                              'member-identity-message'))),
                                if (_linked)
                                  const Text(
                                      'Profil akun terhubung diubah oleh pemilik melalui Ubah Data Diri. Hubungan wali dapat dikelola melalui undangan di bawah.'),
                                if (!_linked)
                                  FilledButton(
                                      onPressed: _busy || !_loadSucceeded
                                          ? null
                                          : _save,
                                      child: Text(_busy
                                          ? 'Memproses…'
                                          : 'Simpan Anggota')),
                                if (_memberId != null) ...[
                                  for (final grant in _grants)
                                    ListTile(
                                        title: Text(
                                            grant['email']?.toString() ??
                                                'Wali'),
                                        subtitle: Text(
                                            grant['revoked_at'] == null
                                                ? 'Terverifikasi'
                                                : 'Dicabut'),
                                        trailing: grant['revoked_at'] == null
                                            ? TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () => _revoke(
                                                        grant['id'].toString()),
                                                child: const Text('Cabut'))
                                            : null),
                                  const Divider(height: 40),
                                  const Text('Hubungkan akun atau wali',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Wali memakai akun sendiri. Undangan berlaku 24 jam dan tidak memberikan hak mengubah PIN atau akun anak. Saat anggota mengklaim akun, hubungan wali lama berakhir; pemilik akun dapat mengundang wali kembali.'),
                                  const SizedBox(height: 16),
                                  TextField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Email pemilik akun / wali')),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                      onPressed:
                                          _busy ? null : () => _invite(false),
                                      child: const Text('Undang Wali')),
                                  OutlinedButton(
                                      onPressed:
                                          _busy ? null : () => _invite(true),
                                      child:
                                          const Text('Hubungkan Akun Anggota'))
                                ],
                              ])))))));
}

String? validateBirthDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final date = DateTime.tryParse(value);
  final now = DateTime.now();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      date == null ||
      date.toIso8601String().substring(0, 10) != value ||
      date.isAfter(now) ||
      date.isBefore(DateTime(now.year - 120, now.month, now.day))) {
    return 'Gunakan tanggal YYYY-MM-DD yang valid, maksimal 120 tahun.';
  }
  return null;
}

String _newRequestId() {
  final r = Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
