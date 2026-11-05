import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/community.dart';
import '../domain/entities/community_draft.dart';
import 'community_providers.dart';

part 'community_form_notifier.g.dart';

enum CommunitySubmitPhase { idle, uploading, saving, done }

class CommunityFormState {
  const CommunityFormState({
    this.draft = const CommunityDraft(),
    this.step = CommunityFormStep.identity,
    this.attempted = const {},
    this.phase = CommunitySubmitPhase.idle,
    this.uploadDone = 0,
    this.uploadTotal = 0,
    this.error,
    this.serverErrors = const {},
    this.result,
  });

  final CommunityDraft draft;
  final CommunityFormStep step;

  /// Langkah yang sudah dicoba dilewati; galatnya baru tampil sesudah itu.
  final Set<CommunityFormStep> attempted;
  final CommunitySubmitPhase phase;
  final int uploadDone;
  final int uploadTotal;

  /// Pesan untuk ditampilkan di atas form.
  final String? error;

  /// Galat isian dari server; hilang begitu isiannya diubah.
  final Map<String, String> serverErrors;
  final CommunityDetail? result;

  bool get isSubmitting =>
      phase == CommunitySubmitPhase.uploading ||
      phase == CommunitySubmitPhase.saving;

  /// Galat yang tampil di bawah isian [field] pada langkah aktif.
  String? errorOf(String field) =>
      serverErrors[field] ??
      (attempted.contains(step) ? draft.errorsFor(step)[field] : null);

  CommunityFormState copyWith({
    CommunityDraft? draft,
    CommunityFormStep? step,
    Set<CommunityFormStep>? attempted,
    CommunitySubmitPhase? phase,
    int? uploadDone,
    int? uploadTotal,
    String? error,
    bool clearError = false,
    Map<String, String>? serverErrors,
    CommunityDetail? result,
  }) =>
      CommunityFormState(
        draft: draft ?? this.draft,
        step: step ?? this.step,
        attempted: attempted ?? this.attempted,
        phase: phase ?? this.phase,
        uploadDone: uploadDone ?? this.uploadDone,
        uploadTotal: uploadTotal ?? this.uploadTotal,
        error: clearError ? null : error ?? this.error,
        serverErrors: serverErrors ?? this.serverErrors,
        result: result ?? this.result,
      );
}

/// Isian, langkah, dan pengiriman form pengajuan komunitas.
@riverpod
class CommunityFormNotifier extends _$CommunityFormNotifier {
  @override
  CommunityFormState build() => const CommunityFormState();

  /// Ubah isian; [fields] adalah nama isian server yang galatnya perlu hilang.
  void edit(
    CommunityDraft Function(CommunityDraft draft) change, {
    List<String> fields = const [],
  }) {
    state = state.copyWith(
      draft: change(state.draft),
      serverErrors: {...state.serverErrors}
        ..removeWhere((field, _) => fields.contains(field)),
    );
  }

  /// `RegionProvince` baru mengosongkan kota: kota lama bukan bagian darinya.
  void setProvince(RegionProvince province) {
    if (province.code == state.draft.province?.code) return;
    edit(
      (draft) => draft.copyWith(province: province, clearCity: true),
      fields: const ['province_code', 'city_code'],
    );
  }

  Future<void> pickLogo() async {
    try {
      final logo = await ref.read(communityImagePickerProvider).pickLogo();
      if (logo == null || !ref.mounted) return;
      edit(
        (draft) => draft.copyWith(logo: logo),
        fields: const ['logo_asset_id'],
      );
      state = state.copyWith(clearError: true);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addPhotos() async {
    final room = CommunityDraft.maxPhotos - state.draft.photos.length;
    if (room <= 0) return;
    try {
      final photos =
          await ref.read(communityImagePickerProvider).pickPhotos(room);
      if (photos.isEmpty || !ref.mounted) return;
      edit(
        (draft) => draft.copyWith(photos: [...draft.photos, ...photos]),
        fields: const ['photo_asset_ids'],
      );
      state = state.copyWith(clearError: true);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: e.toString());
    }
  }

  void removePhoto(int index) {
    edit((draft) => draft.copyWith(
          photos: [...draft.photos]..removeAt(index),
        ));
  }

  /// Lanjut bila isian langkah aktif benar; selain itu galatnya ditampilkan.
  bool next() {
    final step = state.step;
    if (state.draft.errorsFor(step).isNotEmpty) {
      state = state.copyWith(attempted: {...state.attempted, step});
      return false;
    }
    goTo(CommunityFormStep.values[step.index + 1]);
    return true;
  }

  void back() {
    if (state.step.index > 0) {
      goTo(CommunityFormStep.values[state.step.index - 1]);
    }
  }

  void goTo(CommunityFormStep step) {
    state = state.copyWith(step: step, clearError: true);
  }

  Future<void> submit() async {
    if (state.isSubmitting || state.phase == CommunitySubmitPhase.done) return;

    final invalid = state.draft.firstInvalidStep;
    if (invalid != null) {
      state = state.copyWith(
        step: invalid,
        attempted: {...state.attempted, invalid},
      );
      return;
    }

    final repository = ref.read(communityRepositoryProvider);
    final draft = state.draft;
    final waiting = [
      if (draft.logo?.assetId == null) draft.logo,
      ...draft.photos.where((photo) => photo.assetId == null),
    ].length;

    state = state.copyWith(
      phase: CommunitySubmitPhase.uploading,
      uploadDone: 0,
      uploadTotal: waiting,
      clearError: true,
      serverErrors: const {},
    );

    try {
      final logo = state.draft.logo!;
      if (logo.assetId == null) {
        final id =
            await repository.uploadImage(logo, category: 'community-logo');
        if (!ref.mounted) return;
        _markUploaded(
          state.draft.copyWith(logo: logo.withAssetId(id)),
        );
      }

      for (var i = 0; i < state.draft.photos.length; i++) {
        final photo = state.draft.photos[i];
        if (photo.assetId != null) continue;
        final id =
            await repository.uploadImage(photo, category: 'community-photo');
        if (!ref.mounted) return;
        _markUploaded(state.draft.copyWith(
          photos: [...state.draft.photos]..[i] = photo.withAssetId(id),
        ));
      }

      state = state.copyWith(phase: CommunitySubmitPhase.saving);
      final community = await repository.submit(state.draft);
      if (!ref.mounted) return;

      ref.invalidate(myCommunitiesProvider);
      state = state.copyWith(
        phase: CommunitySubmitPhase.done,
        result: community,
      );
    } on CommunityFieldException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        draft: _forgetRejectedImages(e.field),
        phase: CommunitySubmitPhase.idle,
        step: CommunityDraft.stepOf(e.field),
        serverErrors: {e.field: e.message},
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: CommunitySubmitPhase.idle,
        error: e.toString(),
      );
    }
  }

  void _markUploaded(CommunityDraft draft) {
    state = state.copyWith(draft: draft, uploadDone: state.uploadDone + 1);
  }

  /// Foto yang ditolak server harus diunggah ulang pada kiriman berikutnya.
  CommunityDraft _forgetRejectedImages(String field) {
    final draft = state.draft;
    return switch (field) {
      'logo_asset_id' => draft.copyWith(logo: draft.logo?.withAssetId(null)),
      'photo_asset_ids' => draft.copyWith(
          photos: [for (final photo in draft.photos) photo.withAssetId(null)],
        ),
      _ => draft,
    };
  }
}
