import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../community/domain/entities/community_draft.dart';
import '../../../community/presentation/community_providers.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../../home/domain/entities/home_banner.dart';
import '../../../home/presentation/widgets/home_banner_slider.dart';
import '../../domain/entities/admin_banner.dart';
import '../admin_banner_providers.dart';
import '../widgets/admin_banner_widgets.dart';
import '../widgets/admin_gate.dart';
import '../widgets/admin_widgets.dart';

/// Tambah banner ([bannerId] null) atau ubah banner yang ada.
class AdminBannerFormScreen extends StatelessWidget {
  const AdminBannerFormScreen({super.key, this.bannerId});

  final String? bannerId;

  @override
  Widget build(BuildContext context) =>
      AdminGate(child: _FormLoader(bannerId: bannerId));
}

class _FormLoader extends ConsumerStatefulWidget {
  const _FormLoader({required this.bannerId});

  final String? bannerId;

  @override
  ConsumerState<_FormLoader> createState() => _FormLoaderState();
}

class _FormLoaderState extends ConsumerState<_FormLoader> {
  /// Tetap dipakai walau banner hilang dari daftar (mis. baru dihapus di sini).
  AdminBanner? _banner;

  @override
  Widget build(BuildContext context) {
    // Daftar tetap hidup selama form terbuka: menyimpan menyegarkannya.
    final banners = ref.watch(adminBannersProvider);
    final id = widget.bannerId;
    if (id == null) return const _BannerForm(banner: null);

    final found = _banner ??= banners.asData?.value.byId(id);
    if (found != null) return _BannerForm(banner: found);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Banner')),
      body: banners.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AdminErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminBannersProvider),
        ),
        data: (_) => AdminErrorView(
          message: 'Banner tidak ditemukan. Mungkin sudah dihapus.',
          onRetry: () => ref.read(adminBannersProvider.notifier).refresh(),
        ),
      ),
    );
  }
}

class _BannerForm extends ConsumerStatefulWidget {
  const _BannerForm({required this.banner});

  final AdminBanner? banner;

  @override
  ConsumerState<_BannerForm> createState() => _BannerFormState();
}

class _BannerFormState extends ConsumerState<_BannerForm> {
  static const _maxWidth = 640.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _url;
  late AdminBannerLinkType _linkType;
  AdminBannerCommunity? _community;
  late bool _active;

  /// Foto baru; `assetId` terisi sesudah terunggah agar tidak diunggah ulang.
  CommunityImage? _image;
  String? _photoError;
  String? _communityError;
  bool _busy = false;

  AdminBanner? get _banner => widget.banner;
  bool get _isNew => _banner == null;
  bool get _hasPhoto =>
      _image != null || (_banner?.imageUrl?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    final banner = _banner;
    _title = TextEditingController(text: banner?.title ?? '')
      ..addListener(_refreshPreview);
    _subtitle = TextEditingController(text: banner?.subtitle ?? '')
      ..addListener(_refreshPreview);
    _linkType = banner?.linkType ?? AdminBannerLinkType.none;
    _url = TextEditingController(
      text: _linkType == AdminBannerLinkType.external ? banner?.linkUrl : '',
    );
    // Komunitas yang sudah terhapus harus dipilih ulang.
    _community = banner?.linkCommunity;
    _active = banner?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _url.dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  String? get _link => switch (_linkType) {
        AdminBannerLinkType.community =>
          _community == null ? null : AppRoutes.community(_community!.id),
        AdminBannerLinkType.external => _url.text.trim(),
        final type => type.fixedLink,
      };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _close() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.adminBanners);

  Future<void> _pickPhoto() async {
    final List<CommunityImage> images;
    try {
      images = await ref.read(communityImagePickerProvider).pickPhotos(1);
    } catch (e) {
      if (mounted) _showMessage(e.toString());
      return;
    }
    if (images.isEmpty || !mounted) return;
    setState(() {
      _image = images.first;
      _photoError = null;
    });
  }

  Future<void> _pickCommunity() async {
    final community = await showBannerCommunityPicker(context);
    if (community == null || !mounted) return;
    setState(() {
      _community = community;
      _communityError = null;
    });
  }

  static String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    final web = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return web ? null : 'Masukkan tautan lengkap, diawali https://';
  }

  Future<void> _save() async {
    if (_busy) return;
    final valid = _formKey.currentState!.validate();
    final noCommunity =
        _linkType == AdminBannerLinkType.community && _community == null;
    setState(() {
      _photoError = _hasPhoto ? null : 'Lampirkan foto banner.';
      _communityError = noCommunity ? 'Pilih komunitas tujuan.' : null;
    });
    if (!valid || !_hasPhoto || noCommunity) return;

    setState(() => _busy = true);
    try {
      var image = _image;
      if (image != null && image.assetId == null) {
        final assetId = await ref
            .read(communityRepositoryProvider)
            .uploadImage(image, category: 'banner');
        image = image.withAssetId(assetId);
        if (mounted) _image = image;
      }
      await ref.read(adminBannersProvider.notifier).save(
            AdminBannerInput(
              title: _title.text,
              subtitle: _subtitle.text,
              linkUrl: _link,
              isActive: _active,
              imageAssetId: image?.assetId,
            ),
            id: _banner?.id,
          );
      if (!mounted) return;
      _showMessage(_isNew ? 'Banner ditambahkan' : 'Banner tersimpan');
      _close();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(AdminBanner banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus banner ini?'),
        content: const Text(
          'Banner dan fotonya dihapus permanen dan hilang dari Beranda. '
          'Untuk menyembunyikan sementara, matikan "Tampilkan di Beranda".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('admin-banner-delete-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(adminBannersProvider.notifier).delete(banner.id);
      if (!mounted) return;
      _showMessage('Banner dihapus');
      _close();
    } catch (e) {
      if (mounted) _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Tambah Banner' : 'Ubah Banner'),
        actions: [
          if (banner != null)
            IconButton(
              key: const Key('admin-banner-delete'),
              tooltip: 'Hapus banner',
              onPressed: _busy ? null : () => _delete(banner),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('admin-banner-save'),
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(switch ((_busy, _isNew)) {
                    (true, _) => 'Menyimpan...',
                    (_, true) => 'Tambah Banner',
                    _ => 'Simpan Perubahan',
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(16.0, (constraints.maxWidth - _maxWidth) / 2);
            return ListView(
              padding: EdgeInsets.fromLTRB(side, 12, side, 24),
              children: [
                _photoSection(context),
                _textSection(),
                _linkSection(context),
                _visibilitySection(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _photoSection(BuildContext context) {
    final theme = Theme.of(context);
    final error = _photoError;
    return AdminSection(
      title: 'Foto & pratinjau',
      icon: Icons.image_rounded,
      children: [
        if (_hasPhoto)
          AspectRatio(
            aspectRatio: HomeBannerCard.aspectRatio,
            child: HomeBannerCard(
              key: const Key('admin-banner-preview'),
              banner: HomeBanner(
                id: 'pratinjau',
                title: _title.text.trim(),
                subtitle: _subtitle.text.trim(),
                imageUrl: _image == null ? _banner?.imageUrl : null,
              ),
              imageBytes: _image?.bytes,
            ),
          )
        else
          _PhotoPlaceholder(
            hasError: error != null,
            onTap: _busy ? null : _pickPhoto,
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('admin-banner-photo'),
              onPressed: _busy ? null : _pickPhoto,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
              label: Text(_hasPhoto ? 'Ganti Foto' : 'Pilih Foto'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'JPG, PNG, atau WebP. Rasio 2:1, mis. 1600×800.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _textSection() {
    return AdminSection(
      title: 'Teks di atas foto (opsional)',
      icon: Icons.short_text_rounded,
      children: [
        TextFormField(
          key: const Key('admin-banner-title'),
          controller: _title,
          maxLength: 120,
          enabled: !_busy,
          decoration: const InputDecoration(
            labelText: 'Judul',
            helperText: 'Kosongkan bila fotonya sudah bertulisan.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const Key('admin-banner-subtitle'),
          controller: _subtitle,
          maxLength: 255,
          maxLines: 2,
          minLines: 1,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Keterangan'),
        ),
      ],
    );
  }

  Widget _linkSection(BuildContext context) {
    final theme = Theme.of(context);
    final community = _community;
    final communityError = _communityError;
    return AdminSection(
      title: 'Saat banner diketuk',
      icon: Icons.touch_app_rounded,
      children: [
        DropdownButtonFormField<AdminBannerLinkType>(
          key: const Key('admin-banner-link-type'),
          initialValue: _linkType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Buka halaman'),
          items: [
            for (final type in AdminBannerLinkType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
          onChanged: _busy
              ? null
              : (type) => setState(() {
                    _linkType = type ?? AdminBannerLinkType.none;
                    _communityError = null;
                  }),
        ),
        if (_linkType == AdminBannerLinkType.community) ...[
          const SizedBox(height: 12),
          InkWell(
            key: const Key('admin-banner-community'),
            onTap: _busy ? null : _pickCommunity,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Komunitas tujuan',
                errorText: communityError,
                suffixIcon: const Icon(Icons.chevron_right_rounded),
              ),
              child: Row(
                children: [
                  if (community != null) ...[
                    CommunityLogo(name: community.name, size: 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      community?.name ?? 'Pilih komunitas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: community == null
                          ? theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_linkType == AdminBannerLinkType.external) ...[
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('admin-banner-url'),
            controller: _url,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            autocorrect: false,
            validator: _validateUrl,
            decoration: const InputDecoration(
              labelText: 'Alamat tautan',
              hintText: 'https://',
              helperText: 'Dibuka di browser, di luar aplikasi.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _visibilitySection(BuildContext context) {
    final theme = Theme.of(context);
    final banner = _banner;
    final start = banner?.startsAt;
    final end = banner?.endsAt;
    return AdminSection(
      title: 'Penayangan',
      icon: Icons.visibility_rounded,
      children: [
        SwitchListTile(
          key: const Key('admin-banner-active'),
          contentPadding: EdgeInsets.zero,
          value: _active,
          onChanged: _busy ? null : (value) => setState(() => _active = value),
          title: const Text('Tampilkan di Beranda'),
          subtitle: const Text(
            'Matikan untuk menyembunyikan tanpa menghapus.',
          ),
        ),
        if (start != null || end != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Jadwal tayang dari back-office: '
              '${start == null ? 'sejak dibuat' : AdminTime.full(start)} '
              'sampai ${end == null ? 'tanpa batas' : AdminTime.full(end)}.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.hasError, required this.onTap});

  final bool hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasError ? theme.colorScheme.error : adminGold;
    return AspectRatio(
      aspectRatio: HomeBannerCard.aspectRatio,
      child: InkWell(
        key: const Key('admin-banner-photo-placeholder'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: color.withValues(alpha: 0.7),
            radius: 18,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_photo_alternate_rounded, size: 36, color: color),
                const SizedBox(height: 8),
                Text(
                  'Pilih foto banner',
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
