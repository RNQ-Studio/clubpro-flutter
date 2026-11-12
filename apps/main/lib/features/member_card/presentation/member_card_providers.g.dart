// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_card_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memberCardRepository)
final memberCardRepositoryProvider = MemberCardRepositoryProvider._();

final class MemberCardRepositoryProvider extends $FunctionalProvider<
    MemberCardRepository,
    MemberCardRepository,
    MemberCardRepository> with $Provider<MemberCardRepository> {
  MemberCardRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'memberCardRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memberCardRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemberCardRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemberCardRepository create(Ref ref) {
    return memberCardRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemberCardRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemberCardRepository>(value),
    );
  }
}

String _$memberCardRepositoryHash() =>
    r'dc5dfa2c913efdf0fa78be327c3654fdec1898c6';

/// Kartu anggota saya di komunitas [communityId].

@ProviderFor(memberCard)
final memberCardProvider = MemberCardFamily._();

/// Kartu anggota saya di komunitas [communityId].

final class MemberCardProvider extends $FunctionalProvider<
        AsyncValue<MemberCard>, MemberCard, FutureOr<MemberCard>>
    with $FutureModifier<MemberCard>, $FutureProvider<MemberCard> {
  /// Kartu anggota saya di komunitas [communityId].
  MemberCardProvider._(
      {required MemberCardFamily super.from, required String super.argument})
      : super(
          retry: noRetry,
          name: r'memberCardProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memberCardHash();

  @override
  String toString() {
    return r'memberCardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MemberCard> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MemberCard> create(Ref ref) {
    final argument = this.argument as String;
    return memberCard(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberCardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberCardHash() => r'ba26e9ecce29b96bfe7e4143632316b5c320163c';

/// Kartu anggota saya di komunitas [communityId].

final class MemberCardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MemberCard>, String> {
  MemberCardFamily._()
      : super(
          retry: noRetry,
          name: r'memberCardProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Kartu anggota saya di komunitas [communityId].

  MemberCardProvider call(
    String communityId,
  ) =>
      MemberCardProvider._(argument: communityId, from: this);

  @override
  String toString() => r'memberCardProvider';
}
