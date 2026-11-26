import '../../marketplace/presentation/marketplace_widgets.dart';
import '../../home/presentation/widgets/lobby_links.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../community/domain/entities/community.dart';
import 'directory_providers.dart';

/// Lobi publik; seluruh konten dapat digulir bersama saat keyboard terbuka.
class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen(
      {super.key, this.communityId, this.initialMembers = false});
  final String? communityId;
  final bool initialMembers;
  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  bool _members = false;
  String _search = '';
  String? _role;
  int _page = 1;
  @override
  void initState() {
    super.initState();
    _members = widget.communityId != null || widget.initialMembers;
  }

  @override
  void didUpdateWidget(covariant DirectoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.communityId != oldWidget.communityId ||
        widget.initialMembers != oldWidget.initialMembers) {
      _members = widget.communityId != null || widget.initialMembers;
      _search = '';
      _role = null;
      _page = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = directoryResultsProvider(
        members: _members,
        search: _search,
        communityId: widget.communityId,
        role: _role,
        page: _page);
    final auth = ref.watch(authProvider);
    final result = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: const Text('Jelajahi Komunitas'), actions: [
        TextButton(
            onPressed: () => context
                .push(auth is AuthAuthenticated ? '/guardians' : '/login'),
            child: Text(
                auth is AuthAuthenticated ? 'Akun & wali' : 'Masuk / Daftar'))
      ]),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(provider);
            await ref.read(provider.future);
          },
          child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (widget.communityId == null) ...[
                  Text('Temukan komunitas Anda',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                        key: const Key('lobby-create-community'),
                        onPressed: () {
                          final target = AppRoutes.createCommunity;
                          context.push(auth is AuthAuthenticated
                              ? target
                              : '/login?from=${encodeLoginReturn(target)}');
                        },
                        icon: const Icon(Icons.add_business_outlined),
                        label: const Text('Daftarkan komunitas')),
                    OutlinedButton.icon(
                        key: const Key('lobby-community-rankings'),
                        onPressed: () => context.push(AppRoutes.rankings),
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('Ranking komunitas')),
                    OutlinedButton.icon(
                        key: const Key('lobby-public-ads'),
                        onPressed: () => context.push(AppRoutes.memberAds),
                        icon: const Icon(Icons.campaign_outlined),
                        label: const Text('Iklan anggota')),
                  ]),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                            value: false,
                            label: Text('Komunitas'),
                            icon: MediaQuery.sizeOf(context).width < 380
                                ? null
                                : const Icon(Icons.groups_outlined)),
                        ButtonSegment(
                            value: true,
                            label: Text('Anggota'),
                            icon: MediaQuery.sizeOf(context).width < 380
                                ? null
                                : const Icon(Icons.person_search_outlined))
                      ],
                      selected: {
                        _members
                      },
                      onSelectionChanged: (v) => setState(() {
                            _members = v.first;
                            _role = null;
                            _page = 1;
                          })),
                ],
                MarketplaceEntry(communityId: widget.communityId),
                const SizedBox(height: 16),
                TextField(
                    key: ValueKey(
                        'directory-search-${widget.communityId}-${widget.initialMembers}'),
                    decoration: InputDecoration(
                        labelText: _members
                            ? 'Cari nama anggota'
                            : 'Cari nama komunitas',
                        prefixIcon: const Icon(Icons.search)),
                    onChanged: (v) => setState(() {
                          _search = v;
                          _page = 1;
                        })),
                if (_members)
                  Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _role,
                          decoration: const InputDecoration(labelText: 'Peran'),
                          items: [
                            const DropdownMenuItem(
                                value: '', child: Text('Semua peran')),
                            for (final role in CommunityRole.values)
                              DropdownMenuItem(
                                  value: role.apiValue, child: Text(role.label))
                          ],
                          onChanged: (v) => setState(() {
                                _role = v == '' ? null : v;
                                _page = 1;
                              }))),
                const SizedBox(height: 16),
                ...result.when(
                    loading: () => const <Widget>[
                          Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()))
                        ],
                    error: (e, _) => <Widget>[
                          DirectoryError(
                              message: e.toString(),
                              retry: () => ref.invalidate(provider))
                        ],
                    data: (page) => <Widget>[
                          if (page.items.isEmpty)
                            const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Belum ada hasil. Coba pencarian lain.')),
                          for (final item in page.items)
                            ListTile(
                                leading: Icon(_members
                                    ? Icons.person_outline
                                    : Icons.groups_outlined),
                                title: Text(item.name),
                                subtitle: Text(item.subtitle),
                                trailing: _members
                                    ? IconButton(
                                        tooltip: 'Profil & lapak anggota',
                                        onPressed: () => context.push(
                                            AppRoutes.marketSeller(item.id)),
                                        icon: const Icon(
                                            Icons.storefront_outlined))
                                    : const Icon(Icons.chevron_right),
                                onTap: () => context.push(
                                    '/explore/communities/${item.communityId ?? item.id}')),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                    onPressed: _page > 1
                                        ? () => setState(() => _page--)
                                        : null,
                                    icon: const Icon(Icons.chevron_left)),
                                Text('$_page / ${page.lastPage}'),
                                IconButton(
                                    onPressed: _page < page.lastPage
                                        ? () => setState(() => _page++)
                                        : null,
                                    icon: const Icon(Icons.chevron_right))
                              ])
                        ]),
              ]),
        ),
      ))),
    );
  }
}

class DirectoryError extends StatelessWidget {
  const DirectoryError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: retry, child: const Text('Coba Lagi'))
          ])));
}

class PublicCommunityScreen extends ConsumerWidget {
  const PublicCommunityScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = publicCommunityProvider(id);
    return Scaffold(
        appBar: AppBar(title: const Text('Komunitas')),
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: ref.watch(provider).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => DirectoryError(
                            message: e.toString(),
                            retry: () => ref.invalidate(provider)),
                        data: (c) => ListView(
                                padding: const EdgeInsets.all(24),
                                children: [
                                  Text(c.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                  const SizedBox(height: 8),
                                  Text(c.subtitle),
                                  const SizedBox(height: 24),
                                  Text(c.description),
                                  CommunityLobbyLinks(communityId: id),
                                  MarketplaceEntry(communityId: id),
                                  const SizedBox(height: 24),
                                  OutlinedButton.icon(
                                      onPressed: () => context.push(
                                          '/explore/communities/$id/members'),
                                      icon: const Icon(Icons.person_search),
                                      label:
                                          const Text('Cari anggota dan peran')),
                                  FilledButton(
                                      onPressed: () {
                                        final auth = ref.read(authProvider);
                                        final target = '/communities/$id';
                                        context.push(auth is AuthAuthenticated
                                            ? target
                                            : '/login?from=${encodeLoginReturn(target)}');
                                      },
                                      child: Text(ref.watch(authProvider)
                                              is AuthAuthenticated
                                          ? 'Buka komunitas / bergabung'
                                          : 'Masuk untuk bergabung')),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Informasi pribadi anggota tidak ditampilkan di direktori publik.')
                                ]))))));
  }
}
