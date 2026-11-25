import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/domain/entities/community.dart';
import '../../community/data/models/community_model.dart';
import '../../community/presentation/community_providers.dart';
import 'directory_providers.dart';
import 'directory_screen.dart';
import 'member_identity_screen.dart';

class InternalMembersScreen extends ConsumerStatefulWidget {
  const InternalMembersScreen({super.key, required this.community});
  final CommunityDetail community;
  @override
  ConsumerState<InternalMembersScreen> createState() =>
      _InternalMembersScreenState();
}

class _InternalMembersScreenState extends ConsumerState<InternalMembersScreen> {
  String _search = '';
  String? _role;
  bool _archived = false, _busy = false;
  String? _message;
  int _page = 1;
  Future<void> _restore(String memberId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .approveMember(widget.community.id, memberId);
      ref.invalidate(internalMemberResultsProvider);
      ref.invalidate(communityMembersProvider(widget.community.id));
      if (mounted) {
        setState(() => _message =
            'Anggota diaktifkan kembali. Nomor dan riwayat tetap sama.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = internalMemberResultsProvider(widget.community.id,
        search: _search,
        role: _role,
        status: _archived ? 'archived' : 'active',
        page: _page);
    return Scaffold(
        appBar: AppBar(title: const Text('Cari Anggota Komunitas')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            if (widget.community.myRole?.canManageMembers ??
                                false)
                              SwitchListTile(
                                  title: const Text(
                                      'Tampilkan anggota diarsipkan'),
                                  value: _archived,
                                  onChanged: _busy
                                      ? null
                                      : (v) => setState(() {
                                            _archived = v;
                                            _page = 1;
                                          })),
                            if (_message != null) Text(_message!),
                            TextField(
                                decoration: const InputDecoration(
                                    labelText: 'Cari nama anggota',
                                    prefixIcon: Icon(Icons.search)),
                                onChanged: (v) => setState(() {
                                      _search = v;
                                      _page = 1;
                                    })),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                                initialValue: _role ?? '',
                                decoration:
                                    const InputDecoration(labelText: 'Peran'),
                                items: [
                                  const DropdownMenuItem(
                                      value: '', child: Text('Semua peran')),
                                  for (final role in CommunityRole.values)
                                    DropdownMenuItem(
                                        value: role.apiValue,
                                        child: Text(role.label))
                                ],
                                onChanged: (v) => setState(() {
                                      _role = v == '' ? null : v;
                                      _page = 1;
                                    }))
                          ])),
                      Expanded(
                          child: ref.watch(provider).when(
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (e, _) => DirectoryError(
                                  message: e.toString(),
                                  retry: () => ref.invalidate(provider)),
                              data: (members) => ListView(children: [
                                    if (members.isEmpty)
                                      const ListTile(
                                          title: Text(
                                              'Tidak ada anggota pada halaman ini.')),
                                    for (final data in members)
                                      ListTile(
                                          title: Text(data['name'].toString()),
                                          subtitle: Text(
                                              CommunityRole.fromApi(data['role'])?.label ??
                                                  'Anggota'),
                                          trailing: data['merged_into_member_id'] !=
                                                  null
                                              ? Text(
                                                  'Digabung #${data['merged_into_member_id']}')
                                              : _archived &&
                                                      (widget.community.myRole == CommunityRole.creator ||
                                                          data['role'] != 'creator' &&
                                                              data['role'] !=
                                                                  'admin')
                                                  ? TextButton(
                                                      onPressed: _busy
                                                          ? null
                                                          : () => _restore(
                                                              data['id']
                                                                  .toString()),
                                                      child: const Text(
                                                          'Aktifkan'))
                                                  : null,
                                          onTap: (widget.community.myRole?.canRecordMembers ?? false)
                                              ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MemberIdentityScreen(communityId: widget.community.id, member: communityMemberFromJson(data))))
                                              : null),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: _page > 1
                                                  ? () =>
                                                      setState(() => _page--)
                                                  : null,
                                              icon: const Icon(
                                                  Icons.chevron_left)),
                                          Text('Halaman $_page'),
                                          IconButton(
                                              onPressed: members.isNotEmpty
                                                  ? () =>
                                                      setState(() => _page++)
                                                  : null,
                                              icon: const Icon(
                                                  Icons.chevron_right))
                                        ])
                                  ])))
                    ])))));
  }
}
