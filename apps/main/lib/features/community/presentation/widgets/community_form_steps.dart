import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/community_draft.dart';
import '../community_form_notifier.dart';
import 'community_choice_fields.dart';
import 'community_image_fields.dart';
import 'community_preview_card.dart';
import 'community_visuals.dart';

/// Isi satu langkah form.
class CommunityFormStepView extends ConsumerWidget {
  const CommunityFormStepView({super.key, required this.showPreview});

  /// Layar sempit tidak punya panel pratinjau: tampilkan di langkah Tinjau.
  final bool showPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(communityFormProvider.select((s) => s.step));
    return switch (step) {
      CommunityFormStep.identity => const _IdentityStep(),
      CommunityFormStep.location => const _LocationStep(),
      CommunityFormStep.contact => const _ContactStep(),
      CommunityFormStep.story => const _StoryStep(),
      CommunityFormStep.review => _ReviewStep(showPreview: showPreview),
    };
  }
}

class _Input extends ConsumerWidget {
  const _Input({
    required this.field,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.hint,
    this.helper,
    this.maxLength,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines,
    this.maxLines = 1,
    this.showCounter = false,
  });

  /// Nama isian server; sekaligus penanda di test.
  final String field;
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String? hint;
  final String? helper;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? minLines;
  final int? maxLines;
  final bool showCounter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      communityFormProvider.select((state) => state.errorOf(field)),
    );
    final multiline = maxLines != 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: Key('community-field-$field'),
        initialValue: value,
        onChanged: onChanged,
        forceErrorText: error,
        keyboardType:
            keyboardType ?? (multiline ? TextInputType.multiline : null),
        textInputAction: multiline ? null : TextInputAction.next,
        textCapitalization: textCapitalization,
        minLines: minLines,
        maxLines: maxLines,
        maxLength: showCounter ? maxLength : null,
        inputFormatters: [
          if (!showCounter && maxLength != null)
            LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          alignLabelWithHint: multiline,
          prefixIcon: multiline
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 72),
                  child: Icon(icon),
                )
              : Icon(icon),
        ),
      ),
    );
  }
}

class _IdentityStep extends ConsumerWidget {
  const _IdentityStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(communityFormProvider);
    final notifier = ref.read(communityFormProvider.notifier);
    final draft = form.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CommunityLogoField(
            logo: draft.logo,
            name: draft.name,
            onPick: notifier.pickLogo,
            error: form.errorOf('logo_asset_id'),
          ),
        ),
        const SizedBox(height: 18),
        _Input(
          field: 'name',
          label: 'Nama Komunitas',
          hint: 'Mis. Persatuan Pemanah Nusantara',
          icon: Icons.groups_rounded,
          value: draft.name,
          maxLength: CommunityDraft.maxNameLength,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(name: value),
            fields: const ['name'],
          ),
        ),
        _Input(
          field: 'short_name',
          label: 'Nama Pendek',
          hint: 'Mis. PPN',
          helper: 'Singkatan atau nama panggilan komunitas',
          icon: Icons.short_text_rounded,
          value: draft.shortName,
          maxLength: CommunityDraft.maxShortNameLength,
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(shortName: value),
            fields: const ['short_name'],
          ),
        ),
        const SizedBox(height: 4),
        CommunityTypeField(
          selected: draft.type,
          error: form.errorOf('type'),
          onSelected: (type) => notifier.edit(
            (d) => d.copyWith(type: type),
            fields: const ['type', 'type_other'],
          ),
        ),
        if (draft.isOtherType) ...[
          const SizedBox(height: 14),
          _Input(
            field: 'type_other',
            label: 'Sebutkan Jenisnya',
            hint: 'Mis. Burung Kicau',
            icon: Icons.edit_note_rounded,
            value: draft.typeOther,
            maxLength: CommunityDraft.maxTypeOtherLength,
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => notifier.edit(
              (d) => d.copyWith(typeOther: value),
              fields: const ['type_other'],
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationStep extends ConsumerWidget {
  const _LocationStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(communityFormProvider.select((s) => s.draft));
    final notifier = ref.read(communityFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CommunityRegionFields(),
        const SizedBox(height: 14),
        _Input(
          field: 'address',
          label: 'Alamat Lengkap',
          hint: 'Nama jalan, nomor, RT/RW, kelurahan, kecamatan',
          icon: Icons.home_work_outlined,
          value: draft.address,
          maxLength: CommunityDraft.maxAddressLength,
          minLines: 3,
          maxLines: 5,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(address: value),
            fields: const ['address'],
          ),
        ),
      ],
    );
  }
}

class _ContactStep extends ConsumerWidget {
  const _ContactStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(communityFormProvider.select((s) => s.draft));
    final notifier = ref.read(communityFormProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Input(
          field: 'contact_name',
          label: 'Nama Kontak Person',
          hint: 'Nama pengurus yang bisa dihubungi',
          icon: Icons.person_outline_rounded,
          value: draft.contactName,
          maxLength: CommunityDraft.maxContactNameLength,
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(contactName: value),
            fields: const ['contact_name'],
          ),
        ),
        _Input(
          field: 'contact_phone',
          label: 'Nomor WhatsApp',
          hint: 'Mis. 0812 3456 7890',
          helper: 'Tampil di halaman komunitas sesudah terverifikasi',
          icon: Icons.phone_iphone_rounded,
          value: draft.contactPhone,
          maxLength: 20,
          keyboardType: TextInputType.phone,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(contactPhone: value),
            fields: const ['contact_phone'],
          ),
        ),
        _Input(
          field: 'contact_email',
          label: 'Email (opsional)',
          hint: 'Mis. pengurus@gmail.com',
          icon: Icons.mail_outline_rounded,
          value: draft.contactEmail,
          maxLength: CommunityDraft.maxContactEmailLength,
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(contactEmail: value),
            fields: const ['contact_email'],
          ),
        ),
      ],
    );
  }
}

class _StoryStep extends ConsumerWidget {
  const _StoryStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(communityFormProvider);
    final notifier = ref.read(communityFormProvider.notifier);
    final draft = form.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Input(
          field: 'description',
          label: 'Deskripsi Komunitas',
          hint:
              'Ceritakan kegiatan, tujuan, dan siapa saja yang bisa bergabung',
          icon: Icons.notes_rounded,
          value: draft.description,
          maxLength: CommunityDraft.maxDescriptionLength,
          showCounter: true,
          minLines: 5,
          maxLines: 9,
          onChanged: (value) => notifier.edit(
            (d) => d.copyWith(description: value),
            fields: const ['description'],
          ),
        ),
        CommunityPhotosField(
          photos: draft.photos,
          onAdd: notifier.addPhotos,
          onRemove: notifier.removePhoto,
          error: form.errorOf('photo_asset_ids'),
        ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({required this.showPreview});

  final bool showPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(communityFormProvider.select((s) => s.draft));
    final email = draft.contactEmail.trim();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPreview) ...[
          CommunityPreviewCard(draft: draft),
          const SizedBox(height: 14),
        ],
        _ReviewSection(
          step: CommunityFormStep.identity,
          rows: [
            ('Nama', draft.name.trim()),
            ('Nama pendek', draft.shortName.trim()),
            ('Jenis', draft.typeLabel ?? '-'),
          ],
        ),
        _ReviewSection(
          step: CommunityFormStep.location,
          rows: [
            ('Provinsi', draft.province?.name ?? '-'),
            ('Kota/Kabupaten', draft.city?.name ?? '-'),
            ('Alamat', draft.address.trim()),
          ],
        ),
        _ReviewSection(
          step: CommunityFormStep.contact,
          rows: [
            ('Nama', draft.contactName.trim()),
            ('WhatsApp', draft.contactPhone.trim()),
            if (email.isNotEmpty) ('Email', email),
          ],
        ),
        _ReviewSection(
          step: CommunityFormStep.story,
          rows: [
            ('Deskripsi', draft.description.trim()),
            ('Lampiran', '${draft.photos.length} foto'),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CommunityColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: CommunityColors.brown, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Komunitas akan diperiksa super admin dan baru tampil di '
                  'publik sesudah disetujui.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CommunityColors.brown,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewSection extends ConsumerWidget {
  const _ReviewSection({required this.step, required this.rows});

  final CommunityFormStep step;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: communityHairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  step.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                key: Key('community-review-edit-${step.name}'),
                onPressed: () =>
                    ref.read(communityFormProvider.notifier).goTo(step),
                child: const Text('Ubah'),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
