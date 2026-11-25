// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'directory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(directoryRepository)
final directoryRepositoryProvider = DirectoryRepositoryProvider._();

final class DirectoryRepositoryProvider extends $FunctionalProvider<
    DirectoryRepository,
    DirectoryRepository,
    DirectoryRepository> with $Provider<DirectoryRepository> {
  DirectoryRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'directoryRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$directoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<DirectoryRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DirectoryRepository create(Ref ref) {
    return directoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DirectoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DirectoryRepository>(value),
    );
  }
}

String _$directoryRepositoryHash() =>
    r'592b0af934fae1039e002c274b93b42657600c0b';

@ProviderFor(directoryResults)
final directoryResultsProvider = DirectoryResultsFamily._();

final class DirectoryResultsProvider extends $FunctionalProvider<
        AsyncValue<DirectoryPage>, DirectoryPage, FutureOr<DirectoryPage>>
    with $FutureModifier<DirectoryPage>, $FutureProvider<DirectoryPage> {
  DirectoryResultsProvider._(
      {required DirectoryResultsFamily super.from,
      required ({
        bool members,
        String search,
        String? communityId,
        String? role,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'directoryResultsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$directoryResultsHash();

  @override
  String toString() {
    return r'directoryResultsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DirectoryPage> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DirectoryPage> create(Ref ref) {
    final argument = this.argument as ({
      bool members,
      String search,
      String? communityId,
      String? role,
      int page,
    });
    return directoryResults(
      ref,
      members: argument.members,
      search: argument.search,
      communityId: argument.communityId,
      role: argument.role,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DirectoryResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$directoryResultsHash() => r'ac61b8e2bc779028ffbf251a34ad04bb32092fdd';

final class DirectoryResultsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<DirectoryPage>,
            ({
              bool members,
              String search,
              String? communityId,
              String? role,
              int page,
            })> {
  DirectoryResultsFamily._()
      : super(
          retry: _noRetry,
          name: r'directoryResultsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  DirectoryResultsProvider call({
    bool members = false,
    String search = '',
    String? communityId,
    String? role,
    int page = 1,
  }) =>
      DirectoryResultsProvider._(argument: (
        members: members,
        search: search,
        communityId: communityId,
        role: role,
        page: page,
      ), from: this);

  @override
  String toString() => r'directoryResultsProvider';
}

@ProviderFor(publicCommunity)
final publicCommunityProvider = PublicCommunityFamily._();

final class PublicCommunityProvider extends $FunctionalProvider<
        AsyncValue<DirectoryItem>, DirectoryItem, FutureOr<DirectoryItem>>
    with $FutureModifier<DirectoryItem>, $FutureProvider<DirectoryItem> {
  PublicCommunityProvider._(
      {required PublicCommunityFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'publicCommunityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$publicCommunityHash();

  @override
  String toString() {
    return r'publicCommunityProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DirectoryItem> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DirectoryItem> create(Ref ref) {
    final argument = this.argument as String;
    return publicCommunity(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PublicCommunityProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$publicCommunityHash() => r'8d72f475a9c9c56e7a82d62f14890f8f6ab690a3';

final class PublicCommunityFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DirectoryItem>, String> {
  PublicCommunityFamily._()
      : super(
          retry: _noRetry,
          name: r'publicCommunityProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PublicCommunityProvider call(
    String id,
  ) =>
      PublicCommunityProvider._(argument: id, from: this);

  @override
  String toString() => r'publicCommunityProvider';
}

@ProviderFor(guardianInvitations)
final guardianInvitationsProvider = GuardianInvitationsProvider._();

final class GuardianInvitationsProvider extends $FunctionalProvider<
        AsyncValue<List<Map<String, dynamic>>>,
        List<Map<String, dynamic>>,
        FutureOr<List<Map<String, dynamic>>>>
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  GuardianInvitationsProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noRetry,
          name: r'guardianInvitationsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$guardianInvitationsHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return guardianInvitations(ref);
  }
}

String _$guardianInvitationsHash() =>
    r'4fbb8fa2dd1c35b28702f88362d99963d94196cd';

@ProviderFor(guardianDependents)
final guardianDependentsProvider = GuardianDependentsProvider._();

final class GuardianDependentsProvider extends $FunctionalProvider<
        AsyncValue<List<Map<String, dynamic>>>,
        List<Map<String, dynamic>>,
        FutureOr<List<Map<String, dynamic>>>>
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  GuardianDependentsProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noRetry,
          name: r'guardianDependentsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$guardianDependentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return guardianDependents(ref);
  }
}

String _$guardianDependentsHash() =>
    r'7540701a29e376d20229484b0c641d2c1343d24a';

@ProviderFor(dependentDetail)
final dependentDetailProvider = DependentDetailFamily._();

final class DependentDetailProvider extends $FunctionalProvider<
        AsyncValue<Map<String, dynamic>>,
        Map<String, dynamic>,
        FutureOr<Map<String, dynamic>>>
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  DependentDetailProvider._(
      {required DependentDetailFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'dependentDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$dependentDetailHash();

  @override
  String toString() {
    return r'dependentDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as String;
    return dependentDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DependentDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dependentDetailHash() => r'db964e97e852cdad19c1e98aeb782db645700285';

final class DependentDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, dynamic>>, String> {
  DependentDetailFamily._()
      : super(
          retry: _noRetry,
          name: r'dependentDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  DependentDetailProvider call(
    String id,
  ) =>
      DependentDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'dependentDetailProvider';
}

@ProviderFor(internalMemberResults)
final internalMemberResultsProvider = InternalMemberResultsFamily._();

final class InternalMemberResultsProvider extends $FunctionalProvider<
        AsyncValue<List<Map<String, dynamic>>>,
        List<Map<String, dynamic>>,
        FutureOr<List<Map<String, dynamic>>>>
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  InternalMemberResultsProvider._(
      {required InternalMemberResultsFamily super.from,
      required (
        String, {
        String search,
        String? role,
        String status,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'internalMemberResultsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$internalMemberResultsHash();

  @override
  String toString() {
    return r'internalMemberResultsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as (
      String, {
      String search,
      String? role,
      String status,
      int page,
    });
    return internalMemberResults(
      ref,
      argument.$1,
      search: argument.search,
      role: argument.role,
      status: argument.status,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InternalMemberResultsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$internalMemberResultsHash() =>
    r'e9fe9bab232faccd09d25fa2d6a90696a0470672';

final class InternalMemberResultsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<Map<String, dynamic>>>,
            (
              String, {
              String search,
              String? role,
              String status,
              int page,
            })> {
  InternalMemberResultsFamily._()
      : super(
          retry: _noRetry,
          name: r'internalMemberResultsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  InternalMemberResultsProvider call(
    String communityId, {
    String search = '',
    String? role,
    String status = 'active',
    int page = 1,
  }) =>
      InternalMemberResultsProvider._(argument: (
        communityId,
        search: search,
        role: role,
        status: status,
        page: page,
      ), from: this);

  @override
  String toString() => r'internalMemberResultsProvider';
}
