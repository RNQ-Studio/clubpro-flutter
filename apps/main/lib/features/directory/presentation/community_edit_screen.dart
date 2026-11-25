import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/domain/entities/community.dart';
import '../../community/presentation/community_providers.dart';
import 'directory_providers.dart';

class CommunityEditScreen extends ConsumerStatefulWidget {
  const CommunityEditScreen({super.key, required this.community});
  final CommunityDetail community;
  @override
  ConsumerState<CommunityEditScreen> createState() =>
      _CommunityEditScreenState();
}

class _CommunityEditScreenState extends ConsumerState<CommunityEditScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  bool _busy = false;
  String? _message;
  static const _labels = {
    'name': 'Nama komunitas',
    'short_name': 'Nama singkat',
    'description': 'Deskripsi',
    'address': 'Alamat komunitas',
    'contact_name': 'Nama kontak organisasi',
    'contact_phone': 'Telepon kontak organisasi',
    'contact_email': 'Email kontak organisasi'
  };
  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _fields = {
      for (final item in {
        'name': c.name,
        'short_name': c.shortName,
        'description': c.description,
        'address': c.address,
        'contact_name': c.contactName,
        'contact_phone': c.contactPhone,
        'contact_email': c.contactEmail ?? ''
      }.entries)
        item.key: TextEditingController(text: item.value)
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(directoryRepositoryProvider)
          .updateCommunity(widget.community.id, {
        for (final e in _fields.entries)
          e.key: e.value.text.trim().isEmpty ? null : e.value.text.trim()
      });
      ref.invalidate(communityDetailProvider(widget.community.id));
      if (mounted) setState(() => _message = 'Profil komunitas disimpan.');
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Kelola Komunitas')),
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    Form(
                        key: _form,
                        child: Column(children: [
                          for (final e in _fields.entries)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: TextFormField(
                                    controller: e.value,
                                    decoration: InputDecoration(
                                        labelText: _labels[e.key]),
                                    maxLines: e.key == 'description' ? 4 : 1,
                                    validator: (v) => (e.key == 'name' ||
                                                e.key == 'short_name') &&
                                            (v?.trim().isEmpty ?? true)
                                        ? 'Isian wajib diisi.'
                                        : null))
                        ])),
                    if (_message != null) Text(_message!),
                    FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? 'Menyimpan…' : 'Simpan Komunitas'))
                  ])))));
}
