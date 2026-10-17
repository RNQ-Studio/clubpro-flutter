import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth/domain/entities/user.dart';
import '../domain/entities/member_profile.dart';
import 'widgets/profile_avatar_picker.dart';

/// Form data diri anggota. Semua isian boleh kosong (kecuali nama); hanya
/// isian yang berubah yang dikirim lewat [MemberProfileFormState.changes].
class MemberProfileForm extends StatefulWidget {
  const MemberProfileForm({super.key, required this.user});

  final User user;

  @override
  State<MemberProfileForm> createState() => MemberProfileFormState();
}

class MemberProfileFormState extends State<MemberProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _birthPlace = TextEditingController(text: widget.user.birthPlace);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _address = TextEditingController(text: widget.user.address);
  late final _emergencyName =
      TextEditingController(text: widget.user.emergencyContactName);
  late final _emergencyPhone =
      TextEditingController(text: widget.user.emergencyContactPhone);

  late MemberGender? _gender = widget.user.gender;
  late DateTime? _birthDate = widget.user.birthDate;
  late DateTime? _archeryStartedAt = widget.user.archeryStartedAt;
  late BowType? _bowType = widget.user.bowType;
  late BloodType? _bloodType = widget.user.bloodType;
  String? _archeryError;

  @override
  void dispose() {
    for (final c in [
      _name,
      _birthPlace,
      _phone,
      _address,
      _emergencyName,
      _emergencyPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool validate() {
    // Aturan sama dengan backend: tanggal mulai >= tanggal lahir.
    final archeryError = _archeryStartedAt != null &&
            _birthDate != null &&
            _archeryStartedAt!.isBefore(_birthDate!)
        ? 'Tidak boleh sebelum tanggal lahir'
        : null;
    setState(() => _archeryError = archeryError);
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    return fieldsValid && archeryError == null;
  }

  /// Kunci API → nilai baru; `null` = isian dikosongkan.
  Map<String, Object?> changes() {
    final user = widget.user;
    final changes = <String, Object?>{};

    void text(String key, TextEditingController c, String? original,
        {String Function(String)? normalize}) {
      var value = c.text.trim();
      if (normalize != null) value = normalize(value);
      final before = (original ?? '').trim();
      if (value != before) changes[key] = value.isEmpty ? null : value;
    }

    void pick(String key, Object? value, Object? original) {
      if (value != original) changes[key] = value;
    }

    text('name', _name, user.name);
    text('birth_place', _birthPlace, user.birthPlace);
    text('phone', _phone, user.phone, normalize: _digitsOnly);
    text('address', _address, user.address);
    text('emergency_contact_name', _emergencyName, user.emergencyContactName);
    text('emergency_contact_phone', _emergencyPhone, user.emergencyContactPhone,
        normalize: _digitsOnly);
    pick('gender', _gender?.apiValue, user.gender?.apiValue);
    pick('birth_date', _iso(_birthDate), _iso(user.birthDate));
    pick('archery_started_at', _iso(_archeryStartedAt),
        _iso(user.archeryStartedAt));
    pick('bow_type', _bowType?.apiValue, user.bowType?.apiValue);
    pick('blood_type', _bloodType?.apiValue, user.bloodType?.apiValue);

    return changes;
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[\s\-.()]'), '');

  static String? _iso(DateTime? date) =>
      date == null ? null : AppDateUtils.isoDate(date);

  static String? _phoneValidator(String? value) {
    final digits = _digitsOnly(value ?? '');
    if (digits.isEmpty) return null;
    return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(digits)
        ? null
        : 'Nomor tidak valid (8–15 angka)';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 17),
      firstDate: DateTime(1930),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Tanggal lahir',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickArcheryStart() async {
    final now = DateTime.now();
    final first = _birthDate ?? DateTime(1950);
    final picked = await showDatePicker(
      context: context,
      initialDate: _archeryStartedAt ?? now,
      firstDate: first,
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Pertama kali mencoba panahan',
    );
    if (picked != null) {
      setState(() {
        // Yang dicatat bulan & tahunnya saja.
        _archeryStartedAt = DateTime(picked.year, picked.month);
        _archeryError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: ProfileAvatarPicker()),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Foto profil',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const _SectionTitle('Data Pribadi', Icons.badge_outlined),
          TextFormField(
            key: const Key('field-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nama lengkap'),
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
            controller: _birthPlace,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Tempat lahir'),
          ),
          const SizedBox(height: 16),
          _DateField(
            key: const Key('field-birth-date'),
            label: 'Tanggal lahir',
            value: _birthDate == null
                ? null
                : AppDateUtils.longDateId(_birthDate!),
            icon: Icons.cake_outlined,
            onTap: _pickBirthDate,
            onClear: () => setState(() => _birthDate = null),
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
              labelText: 'Nomor HP / WhatsApp',
              hintText: '08xxxxxxxxxx',
            ),
            validator: _phoneValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              alignLabelWithHint: true,
            ),
          ),
          const _SectionTitle('Panahan', Icons.sports_score_outlined),
          _DateField(
            key: const Key('field-archery-start'),
            label: 'Kapan pertama kali mencoba panahan?',
            value: _archeryStartedAt == null
                ? null
                : AppDateUtils.monthYearId(_archeryStartedAt!),
            icon: Icons.event_outlined,
            errorText: _archeryError,
            onTap: _pickArcheryStart,
            onClear: () => setState(() => _archeryStartedAt = null),
          ),
          const SizedBox(height: 16),
          const _FieldLabel('Jenis busur'),
          _Choices<BowType>(
            values: BowType.values,
            selected: _bowType,
            label: (b) => b.label,
            onChanged: (v) => setState(() => _bowType = v),
          ),
          const _SectionTitle(
              'Kesehatan & Kontak Darurat', Icons.health_and_safety_outlined),
          const _FieldLabel('Golongan darah'),
          _Choices<BloodType>(
            values: BloodType.values,
            selected: _bloodType,
            label: (b) => b.label,
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama kontak darurat',
              hintText: 'Mis. orang tua / pasangan',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emergencyPhone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
            ],
            decoration:
                const InputDecoration(labelText: 'Nomor kontak darurat'),
            validator: _phoneValidator,
          ),
        ],
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

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.onClear,
    this.errorText,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          prefixIcon: Icon(icon),
          suffixIcon: value == null
              ? const Icon(Icons.arrow_drop_down_rounded)
              : IconButton(
                  tooltip: 'Kosongkan',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
        ),
        child: value == null ? null : Text(value!),
      ),
    );
  }
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(label(value)),
            selected: value == selected,
            // Ketuk lagi pilihan yang aktif untuk mengosongkan.
            onSelected: (on) => onChanged(on ? value : null),
          ),
      ],
    );
  }
}
