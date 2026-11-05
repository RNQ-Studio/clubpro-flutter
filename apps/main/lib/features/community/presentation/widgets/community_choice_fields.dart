import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community.dart';
import '../community_form_notifier.dart';
import '../community_providers.dart';
import 'community_image_fields.dart';
import 'community_visuals.dart';

/// Pilihan jenis komunitas.
class CommunityTypeField extends ConsumerWidget {
  const CommunityTypeField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.error,
  });

  final CommunityTypeOption? selected;
  final ValueChanged<CommunityTypeOption> onSelected;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis Komunitas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ref.watch(communityTypesProvider).when(
              loading: () => const _LoadingLine(),
              error: (e, _) => _RetryLine(
                message: e.toString(),
                onRetry: () => ref.invalidate(communityTypesProvider),
              ),
              data: (types) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in types)
                    _TypeChip(
                      type: type,
                      selected: type.value == selected?.value,
                      onTap: () => onSelected(type),
                    ),
                ],
              ),
            ),
        if (error != null) ...[
          const SizedBox(height: 6),
          CommunityFieldError(error!),
        ],
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final CommunityTypeOption type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? Colors.white : theme.colorScheme.onSurface;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('community-type-${type.value}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? CommunityColors.brown
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? CommunityColors.brown : communityHairline(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                communityTypeIcon(type.value),
                size: 17,
                color:
                    selected ? CommunityColors.goldLight : CommunityColors.gold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  type.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown Provinsi dan Kota/Kabupaten. Keduanya bisa dicari dengan mengetik;
/// kota mengikuti provinsi terpilih.
class CommunityRegionFields extends ConsumerWidget {
  const CommunityRegionFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(communityFormProvider);
    final notifier = ref.read(communityFormProvider.notifier);
    final province = form.draft.province;
    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surface,
      ),
      elevation: const WidgetStatePropertyAll(6),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: communityHairline(context)),
        ),
      ),
    );

    return ref.watch(indonesiaRegionsProvider).when(
          loading: () => const _LoadingLine(),
          error: (e, _) => _RetryLine(
            message: e.toString(),
            onRetry: () => ref.invalidate(indonesiaRegionsProvider),
          ),
          data: (provinces) => Column(
            children: [
              DropdownMenuFormField<RegionProvince>(
                key: const Key('community-province'),
                expandedInsets: EdgeInsets.zero,
                menuHeight: 320,
                menuStyle: menuStyle,
                enableFilter: true,
                requestFocusOnTap: true,
                label: const Text('Provinsi'),
                hintText: 'Pilih atau ketik provinsi',
                leadingIcon: const Icon(Icons.map_outlined),
                initialSelection: province,
                forceErrorText: form.errorOf('province_code'),
                onSelected: (value) {
                  if (value != null) notifier.setProvince(value);
                },
                dropdownMenuEntries: [
                  for (final item in provinces)
                    DropdownMenuEntry(value: item, label: item.name),
                ],
              ),
              const SizedBox(height: 14),
              DropdownMenuFormField<RegionCity>(
                // Kunci per provinsi: pilihan & teks kota lama ikut hilang.
                key: Key('community-city-${province?.code ?? 'kosong'}'),
                enabled: province != null,
                expandedInsets: EdgeInsets.zero,
                menuHeight: 320,
                menuStyle: menuStyle,
                enableFilter: true,
                requestFocusOnTap: true,
                label: const Text('Kota/Kabupaten'),
                hintText: province == null
                    ? 'Pilih provinsi terlebih dahulu'
                    : 'Pilih atau ketik kota/kabupaten',
                leadingIcon: const Icon(Icons.location_city_rounded),
                initialSelection: form.draft.city,
                forceErrorText: form.errorOf('city_code'),
                onSelected: (value) {
                  if (value == null) return;
                  notifier.edit(
                    (draft) => draft.copyWith(city: value),
                    fields: const ['city_code'],
                  );
                },
                dropdownMenuEntries: [
                  for (final item in province?.cities ?? const <RegionCity>[])
                    DropdownMenuEntry(value: item, label: item.name),
                ],
              ),
            ],
          ),
        );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RetryLine extends StatelessWidget {
  const _RetryLine({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    );
  }
}
