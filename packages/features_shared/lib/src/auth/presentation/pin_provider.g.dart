// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(pinRepository)
final pinRepositoryProvider = PinRepositoryProvider._();

final class PinRepositoryProvider
    extends $FunctionalProvider<PinRepository, PinRepository, PinRepository>
    with $Provider<PinRepository> {
  PinRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pinRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pinRepositoryHash();

  @$internal
  @override
  $ProviderElement<PinRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PinRepository create(Ref ref) {
    return pinRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PinRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PinRepository>(value),
    );
  }
}

String _$pinRepositoryHash() => r'053b64f512b5f67d8313741d02c4c15186b6abb9';

@ProviderFor(pinEmailRecoveryAvailable)
final pinEmailRecoveryAvailableProvider = PinEmailRecoveryAvailableProvider._();

final class PinEmailRecoveryAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  PinEmailRecoveryAvailableProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noPinOptionsRetry,
          name: r'pinEmailRecoveryAvailableProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pinEmailRecoveryAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return pinEmailRecoveryAvailable(ref);
  }
}

String _$pinEmailRecoveryAvailableHash() =>
    r'56c0901d9de8c2e0c0ed417bf66a40a472ea60eb';
