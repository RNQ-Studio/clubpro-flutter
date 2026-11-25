// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movement_sharing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(movementSharing)
final movementSharingProvider = MovementSharingProvider._();

final class MovementSharingProvider extends $FunctionalProvider<MovementSharing,
    MovementSharing, MovementSharing> with $Provider<MovementSharing> {
  MovementSharingProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'movementSharingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$movementSharingHash();

  @$internal
  @override
  $ProviderElement<MovementSharing> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MovementSharing create(Ref ref) {
    return movementSharing(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MovementSharing value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MovementSharing>(value),
    );
  }
}

String _$movementSharingHash() => r'f85a63413f99c70c3272e55356ea94cee544049c';
