import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/entities/user.dart';
import '../../region/domain/entities/region.dart';
import '../../region/presentation/region_providers.dart';
import '../domain/entities/member_profile.dart';

/// Form data diri anggota: nama, jenis kelamin, nomor WhatsApp, domisili, dan
/// wilayah sesuai NIK. Semua isian boleh kosong (kecuali nama); hanya isian
/// yang berubah yang dikirim lewat [MemberProfileFormState.changes].
class MemberProfileForm extends ConsumerStatefulWidget {
  const MemberProfileForm({super.key, required this.user});

  final User user;

  @override
  ConsumerState<MemberProfileForm> createState() => MemberProfileFormState();
}

class MemberProfileFormState extends ConsumerState<MemberProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);

  late MemberGender? _gender = widget.user.gender;
  late var _domicile = _RegionChoice.of(widget.user.domicile);
  late var _nik = _RegionChoice.of(widget.user.nikRegion);
  late bool _nikSame = widget.user.nikSameAsDomicile;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool validate() => _formKey.currentState?.validate() ?? false;

  /// Kunci API → nilai baru; `null` = isian dikosongkan. Provinsi & kota
  /// selalu dikirim berpasangan.
  Map<String, Object?> changes() {
    final user = widget.user;
    final changes = <String, Object?>{};

    final name = _name.text.trim();
    if (name != user.name.trim()) changes['name'] = name;

    final phone = _digitsOnly(_phone.text.trim());
    if (phone != (user.phone ?? '').trim()) {
      changes['phone'] = phone.isEmpty ? null : phone;
    }

    if (_gender != user.gender) changes['gender'] = _gender?.apiValue;

    void region(String prefix, _RegionChoice choice, MemberRegion? before) {
      if (choice == _RegionChoice.of(before)) return;
      changes['${prefix}_province_code'] = choice.provinceCode;
      changes['${prefix}_city_code'] = choice.cityCode;
    }

    region('domicile', _domicile, user.domicile);
    if (_nikSame != user.nikSameAsDomicile) {
      changes['nik_same_as_domicile'] = _nikSame;
    }
    // Sama dengan domisili: server menyalin domisili ke wilayah NIK.
    if (!_nikSame) region('nik', _nik, user.nikRegion);

    return changes;
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[\s\-.()]'), '');

  static String? _phoneValidator(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.isEmpty) return null;
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits)
        ? null
        : 'Nomor tidak valid (8–15 angka)';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle('Data Pribadi', Icons.badge_outlined),
          TextFormField(
            key: const Key('field-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Nama tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Jenis kelamin'),
          SegmentedButton<MemberGender>(
            key: const Key('field-gender'),
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              for (final g in MemberGender.values)
                ButtonSegment(value: g, label: Text(g.label)),
            ],
            selected: {if (_gender != null) _gender!},
            onSelectionChanged: (s) =>
                setState(() => _gender = s.isEmpty ? null : s.first),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('field-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Nomor WhatsApp',
              hintText: '08xxxxxxxxxx',
              prefixIcon: Icon(Icons.chat_outlined),
            ),
            validator: _phoneValidator,
          ),
          const _SectionTitle('Domisili', Icons.home_outlined),
          _RegionFields(
            prefix: 'domicile',
            label: 'domisili',
            value: _domicile,
            onChanged: (v) => setState(() => _domicile = v),
          ),
          const _SectionTitle('Sesuai NIK (KTP)', Icons.credit_card_outlined),
          _SameAsDomicile(
            value: _nikSame,
            domicile: _domicile,
            onChanged: (v) => setState(() => _nikSame = v),
          ),
          if (!_nikSame) ...[
            const SizedBox(height: 14),
            _RegionFields(
              prefix: 'nik',
              label: 'sesuai NIK',
              value: _nik,
              onChanged: (v) => setState(() => _nik = v),
            ),
          ],
        ],
      ),
    );
  }
}

/// Pilihan provinsi + kota (kode), boleh kosong.
class _RegionChoice {
  const _RegionChoice(this.provinceCode, this.cityCode);

  factory _RegionChoice.of(MemberRegion? region) =>
      _RegionChoice(region?.provinceCode, region?.cityCode);

  final String? provinceCode;
  final String? cityCode;

  @override
  bool operator ==(Object other) =>
      other is _RegionChoice &&
      other.provinceCode == provinceCode &&
      other.cityCode == cityCode;

  @override
  int get hashCode => Object.hash(provinceCode, cityCode);
}

/// Dropdown Provinsi lalu Kota/Kabupaten (bisa dicari dengan mengetik); kota
/// mengikuti provinsi terpilih.
class _RegionFields extends ConsumerWidget {
  const _RegionFields({
    required this.prefix,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String prefix;
  final String label;
  final _RegionChoice value;
  final ValueChanged<_RegionChoice> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final menuStyle = MenuStyle(
      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.surface),
      elevation: const WidgetStatePropertyAll(6),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return ref.watch(indonesiaRegionsProvider).when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Row(
            key: Key('field-$prefix-error'),
            children: [
              Expanded(
                  child: Text(e.toString(), style: theme.textTheme.bodySmall)),
              TextButton(
                onPressed: () => ref.invalidate(indonesiaRegionsProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
          data: (provinces) {
            final province = provinces.byCode(value.provinceCode);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownMenuFormField<RegionProvince>(
                  key: Key('field-$prefix-province'),
                  expandedInsets: EdgeInsets.zero,
                  menuHeight: 320,
                  menuStyle: menuStyle,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  label: const Text('Provinsi'),
                  hintText: 'Pilih atau ketik provinsi',
                  leadingIcon: const Icon(Icons.map_outlined),
                  initialSelection: province,
                  onSelected: (selected) {
                    if (selected == null || selected == province) return;
                    // Kota lama bukan bagian dari provinsi baru.
                    onChanged(_RegionChoice(selected.code, null));
                  },
                  dropdownMenuEntries: [
                    for (final item in provinces)
                      DropdownMenuEntry(value: item, label: item.name),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownMenuFormField<RegionCity>(
                  // Kunci per provinsi: pilihan & teks kota lama ikut hilang.
                  key: Key('field-$prefix-city-${province?.code ?? 'kosong'}'),
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
                  initialSelection: province?.city(value.cityCode),
                  validator: (_) => province != null && value.cityCode == null
                      ? 'Pilih kota/kabupaten $label'
                      : null,
                  onSelected: (selected) {
                    if (selected == null) return;
                    onChanged(_RegionChoice(value.provinceCode, selected.code));
                  },
                  dropdownMenuEntries: [
                    for (final item in province?.cities ?? const <RegionCity>[])
                      DropdownMenuEntry(value: item, label: item.name),
                  ],
                ),
              ],
            );
          },
        );
  }
}

/// "Sama dengan domisili": wilayah NIK mengikuti domisili.
class _SameAsDomicile extends ConsumerWidget {
  const _SameAsDomicile({
    required this.value,
    required this.domicile,
    required this.onChanged,
  });

  final bool value;
  final _RegionChoice domicile;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final provinces = ref.watch(indonesiaRegionsProvider).asData?.value;
    final province = provinces?.byCode(domicile.provinceCode);
    final city = province?.city(domicile.cityCode);
    final subtitle = !value
        ? 'Pilih bila wilayah di KTP sama dengan domisili'
        : city == null
            ? 'Ikut domisili — pilih domisili di atas'
            : '${city.name}, ${province!.name}';

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        key: const Key('field-nik-same'),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('Sama dengan domisili'),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
