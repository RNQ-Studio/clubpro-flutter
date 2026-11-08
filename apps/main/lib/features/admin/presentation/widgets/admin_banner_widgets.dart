import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../branding/club_logo.dart';
import '../../../community/presentation/widgets/community_visuals.dart';
import '../../domain/entities/admin_banner.dart';
import '../../domain/entities/admin_community.dart';
import '../admin_providers.dart';
import 'admin_widgets.dart';

extension AdminBannerStatusColor on AdminBannerStatus {
  Color color(BuildContext context) => switch (this) {
        AdminBannerStatus.live => const Color(0xFF178A5B),
        AdminBannerStatus.scheduled => const Color(0xFF1E6FD9),
        AdminBannerStatus.ended => Theme.of(context).colorScheme.error,
        AdminBannerStatus.inactive =>
          Theme.of(context).colorScheme.onSurfaceVariant,
      };
}

/// Gambar kecil promosi (portrait 2:3) di daftar.
class AdminBannerThumb extends StatelessWidget {
  const AdminBannerThumb({super.key, required this.url, this.width = 64});

  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) {
    const placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C3A02), Color(0xFFBE8815)],
        ),
      ),
      child: Center(child: ClubLogo(size: 30)),
    );
    final image = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: width * 1.5,
        child: image == null || image.isEmpty
            ? placeholder
            : CommunityNetworkImage(url: image, fallback: placeholder),
      ),
    );
  }
}

/// Pilih komunitas terverifikasi sebagai tujuan tombol promosi.
Future<AdminBannerCommunity?> showBannerCommunityPicker(BuildContext context) =>
    showModalBottomSheet<AdminBannerCommunity>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _CommunityPicker(),
    );

class _CommunityPicker extends ConsumerStatefulWidget {
  const _CommunityPicker();

  @override
  ConsumerState<_CommunityPicker> createState() => _CommunityPickerState();
}

class _CommunityPickerState extends ConsumerState<_CommunityPicker> {
  Timer? _debounce;

  /// Hanya respons pencarian terakhir yang dipakai.
  int _generation = 0;
  AsyncValue<List<AdminCommunity>> _results = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    setState(() => _results = const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final page = await ref.read(adminRepositoryProvider).getCommunities(
            page: 1,
            search: query.trim(),
            filter: AdminCommunityFilter.approved,
          );
      return page.communities;
    });
    if (mounted && generation == _generation) {
      setState(() => _results = result);
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Pilih komunitas tujuan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Hanya komunitas terverifikasi yang bisa dibuka anggota.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('admin-banner-community-search'),
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau kota',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AdminErrorView(
                message: error.toString(),
                onRetry: () => _search(''),
              ),
              data: (communities) => communities.isEmpty
                  ? Center(
                      child: Text(
                        'Komunitas tidak ditemukan',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: communities.length,
                      itemBuilder: (context, i) {
                        final community = communities[i];
                        return ListTile(
                          key: Key('admin-banner-community-${community.id}'),
                          leading: CommunityLogo(
                            name: community.name,
                            url: community.logoUrl,
                            size: 40,
                          ),
                          title: Text(
                            community.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            community.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            AdminBannerCommunity(
                              id: community.id,
                              name: community.name,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "24 jam", "72 jam (3 hari)".
String promotionIntervalLabel(int hours) => hours >= 48 && hours % 24 == 0
    ? '$hours jam (${hours ~/ 24} hari)'
    : '$hours jam';

/// Ubah jeda tampil popup. Selesai dengan jam baru, atau null bila batal.
Future<int?> showPromotionIntervalDialog(BuildContext context, int current) =>
    showDialog<int>(
      context: context,
      builder: (_) => _IntervalDialog(current: current),
    );

class _IntervalDialog extends StatefulWidget {
  const _IntervalDialog({required this.current});

  final int current;

  @override
  State<_IntervalDialog> createState() => _IntervalDialogState();
}

class _IntervalDialogState extends State<_IntervalDialog> {
  static const _presets = [6, 12, 24, 72, 168];

  late final _hours = TextEditingController(text: '${widget.current}');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  static String? _validate(String? value) {
    final hours = int.tryParse(value?.trim() ?? '');
    if (hours == null) return 'Isi jumlah jam, mis. 24.';
    if (hours < 1 || hours > AdminBannerSummary.maxIntervalHours) {
      return 'Antara 1 dan ${AdminBannerSummary.maxIntervalHours} jam '
          '(30 hari).';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, int.parse(_hours.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Jeda tampil popup'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popup promosi muncul saat anggota membuka Beranda, lalu muncul '
              'lagi di perangkat yang sama sesudah jeda ini lewat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('admin-promotion-interval-field'),
              controller: _hours,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validate,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Tampil setiap',
                suffixText: 'jam',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hours in _presets)
                  ActionChip(
                    key: Key('admin-promotion-interval-$hours'),
                    label: Text(hours % 24 == 0 && hours >= 48
                        ? '${hours ~/ 24} hari'
                        : '$hours jam'),
                    onPressed: () => setState(() {
                      _hours.text = '$hours';
                      _formKey.currentState?.validate();
                    }),
                  ),
              ],
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
          key: const Key('admin-promotion-interval-save'),
          style: FilledButton.styleFrom(minimumSize: const Size(64, 40)),
          onPressed: _submit,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
