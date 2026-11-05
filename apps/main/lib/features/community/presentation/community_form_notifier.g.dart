// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Isian, langkah, dan pengiriman form pengajuan komunitas.

@ProviderFor(CommunityFormNotifier)
final communityFormProvider = CommunityFormNotifierProvider._();

/// Isian, langkah, dan pengiriman form pengajuan komunitas.
final class CommunityFormNotifierProvider
    extends $NotifierProvider<CommunityFormNotifier, CommunityFormState> {
  /// Isian, langkah, dan pengiriman form pengajuan komunitas.
  CommunityFormNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'communityFormProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityFormNotifierHash();

  @$internal
  @override
  CommunityFormNotifier create() => CommunityFormNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CommunityFormState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CommunityFormState>(value),
    );
  }
}

String _$communityFormNotifierHash() =>
    r'751413d418a3e1216237342bc1b51a10e65a898f';

/// Isian, langkah, dan pengiriman form pengajuan komunitas.

abstract class _$CommunityFormNotifier extends $Notifier<CommunityFormState> {
  CommunityFormState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CommunityFormState, CommunityFormState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CommunityFormState, CommunityFormState>,
        CommunityFormState,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
