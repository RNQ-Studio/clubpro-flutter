import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community.dart';
import '../../../community/presentation/widgets/community_photo_viewer.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/admin_community.dart';
import '../admin_community_providers.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Data lengkap satu komunitas dan keputusan verifikasinya.
class AdminCommunityDetailScreen extends StatelessWidget {
  const AdminCommunityDetailScreen({super.key, required this.communityId});

  final String communityId;

  @override
  Widget build(BuildContext context) =>
      AdminGate(child: _DetailView(communityId: communityId));
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.communityId});

  final String communityId;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  bool _busy = false;

  AdminCommunityDetailNotifierProvider get _provider =>
      adminCommunityDetailProvider(widget.communityId);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _review(
    CommunityStatus status,
    String success, {
    String? note,
  }) async {
    setState(() => _busy = true);
    try {
      await ref.read(_provider.notifier).review(status: status, note: note);
      _showMessage(success);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(AdminCommunityDetail community) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setujui komunitas ini?'),
        content: Text(
          '${community.name} akan tampil di daftar Komunitas dan terlihat '
          'oleh semua anggota.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('admin-approve-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _review(CommunityStatus.approved, 'Komunitas disetujui');
  }

  Future<void> _reject(AdminCommunityDetail community) async {
    final revoking = community.status == CommunityStatus.approved;
    final note = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(
        title: revoking ? 'Cabut verifikasi?' : 'Tolak komunitas ini?',
        action: revoking ? 'Cabut Verifikasi' : 'Tolak',
        message: revoking
            ? '${community.name} akan hilang dari daftar Komunitas.'
            : '${community.name} tidak akan tampil di daftar Komunitas.',
      ),
    );
    if (note == null) return;
    await _review(
      CommunityStatus.rejected,
      revoking ? 'Verifikasi dicabut' : 'Komunitas ditolak',
      note: note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(_provider);
    final community = detail.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Komunitas')),
      bottomNavigationBar: community == null
          ? null
          : _ReviewBar(
              status: community.status,
              busy: _busy,
              onApprove: () => _approve(community),
              onReject: () => _reject(community),
            ),
      body: detail.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AdminErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(_provider),
        ),
        data: (community) => RefreshIndicator(
          onRefresh: () => ref.refresh(_provider.future),
          child: _DetailBody(community: community),
        ),
      ),
    );
  }
}

/// Tindakan sesuai status: keputusan bisa diubah agar kesalahan bisa diperbaiki.
class _ReviewBar extends StatelessWidget {
  const _ReviewBar({
    required this.status,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final CommunityStatus status;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    final reject = OutlinedButton.icon(
      key: const Key('admin-reject'),
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: BorderSide(color: error),
      ),
      onPressed: busy ? null : onReject,
      icon: const Icon(Icons.close_rounded, size: 18),
      label: Text(
        status == CommunityStatus.approved ? 'Cabut Verifikasi' : 'Tolak',
      ),
    );
    final approve = FilledButton.icon(
      key: const Key('admin-approve'),
      onPressed: busy ? null : onApprove,
      icon: const Icon(Icons.verified_rounded, size: 18),
      label: const Text('Setujui'),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: adminHairline(context))),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (status != CommunityStatus.rejected)
                        Expanded(child: reject),
                      if (status == CommunityStatus.pending)
                        const SizedBox(width: 10),
                      if (status != CommunityStatus.approved)
                        Expanded(child: approve),
                    ],
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

/// Meminta alasan: pengaju perlu tahu yang harus diperbaiki.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog({
    required this.title,
    required this.action,
    required this.message,
  });

  final String title;
  final String action;
  final String message;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  static const _minLength = 5;
  static const _maxLength = 500;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().length >= _minLength;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 14),
            TextField(
              key: const Key('admin-reject-note'),
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Alasan',
                hintText: 'Mis. Foto kegiatan belum jelas',
                helperText: 'Alasan ini terlihat oleh pengaju',
                helperMaxLines: 2,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('admin-reject-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: _valid
              ? () => Navigator.pop(context, _controller.text.trim())
              : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.community});

  /// Lebar minimum untuk dua kolom.
  static const _twoColumnWidth = 820.0;

  final AdminCommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final photos = AdminSection(
      title: 'Foto Lampiran (${community.photoUrls.length})',
      icon: Icons.photo_library_outlined,
      children: [
        if (community.photoUrls.isEmpty)
          const AdminInfoRow('Foto', null)
        else
          CommunityPhotoGrid(urls: community.photoUrls),
      ],
    );
    final about = AdminSection(
      title: 'Tentang Komunitas',
      icon: Icons.info_outline_rounded,
      children: [
        SelectableText(
          community.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
    final location = AdminSection(
      title: 'Lokasi',
      icon: Icons.place_outlined,
      children: [
        AdminInfoRow('Provinsi', community.provinceName),
        AdminInfoRow('Kota/Kabupaten', community.cityName),
        AdminInfoRow('Alamat', community.address),
      ],
    );
    final contact = AdminSection(
      title: 'Kontak Person',
      icon: Icons.support_agent_rounded,
      children: [
        AdminInfoRow('Nama', community.contactName),
        AdminInfoRow('Nomor', community.contactPhone),
        AdminInfoRow('Email', community.contactEmail),
      ],
    );
    final submitter = _SubmitterSection(community: community);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= _twoColumnWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(community: community),
                    const SizedBox(height: 16),
                    if (community.reviewedAt != null)
                      _ReviewResult(community: community),
                    if (twoColumns)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: [photos, about])),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [location, contact, submitter],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      photos,
                      about,
                      location,
                      contact,
                      submitter,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.community});

  final AdminCommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = community.logoUrl;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: CommunityColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('admin-community-logo'),
            customBorder: const CircleBorder(),
            onTap: logo == null
                ? null
                : () => showCommunityPhotoViewer(context, [logo], 0),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CommunityLogo(
                name: community.name,
                url: logo,
                size: 76,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  community.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${community.shortName} · ${community.typeLabel}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CommunityStatusBadge(status: community.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewResult extends StatelessWidget {
  const _ReviewResult({required this.community});

  final AdminCommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final approved = community.status == CommunityStatus.approved;
    return AdminSection(
      title: approved ? 'Disetujui' : 'Hasil Verifikasi',
      icon: approved ? Icons.verified_rounded : Icons.fact_check_outlined,
      children: [
        AdminInfoRow('Oleh', community.reviewer?.name),
        AdminInfoRow('Waktu', AdminTime.full(community.reviewedAt)),
        if (community.reviewNote != null)
          AdminInfoRow('Alasan', community.reviewNote),
      ],
    );
  }
}

class _SubmitterSection extends StatelessWidget {
  const _SubmitterSection({required this.community});

  final AdminCommunityDetail community;

  @override
  Widget build(BuildContext context) {
    final submitter = community.submitter;
    return AdminSection(
      title: 'Pengaju',
      icon: Icons.person_outline_rounded,
      children: [
        AdminInfoRow('Nama', submitter?.name ?? 'Akun terhapus'),
        AdminInfoRow('Email', submitter?.email),
        AdminInfoRow('Diajukan', AdminTime.full(community.createdAt)),
        if (submitter != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('admin-open-submitter'),
              onPressed: () => context.push(AppRoutes.adminUser(submitter.id)),
              child: const Text('Lihat Data Pengguna'),
            ),
          ),
      ],
    );
  }
}
