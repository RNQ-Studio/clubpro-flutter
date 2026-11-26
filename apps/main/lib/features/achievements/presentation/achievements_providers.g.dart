// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(achievementsRepository)
final achievementsRepositoryProvider = AchievementsRepositoryProvider._();

final class AchievementsRepositoryProvider extends $FunctionalProvider<
    AchievementsRepository,
    AchievementsRepository,
    AchievementsRepository> with $Provider<AchievementsRepository> {
  AchievementsRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'achievementsRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$achievementsRepositoryHash();

  @$internal
  @override
  $ProviderElement<AchievementsRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AchievementsRepository create(Ref ref) {
    return achievementsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AchievementsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AchievementsRepository>(value),
    );
  }
}

String _$achievementsRepositoryHash() =>
    r'475b0753b3b354214905880b6f93714f638d15f3';

@ProviderFor(achievementRules)
final achievementRulesProvider = AchievementRulesFamily._();

final class AchievementRulesProvider extends $FunctionalProvider<
        AsyncValue<AchievementRules>,
        AchievementRules,
        FutureOr<AchievementRules>>
    with $FutureModifier<AchievementRules>, $FutureProvider<AchievementRules> {
  AchievementRulesProvider._(
      {required AchievementRulesFamily super.from,
      required bool super.argument})
      : super(
          retry: _noRetry,
          name: r'achievementRulesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$achievementRulesHash();

  @override
  String toString() {
    return r'achievementRulesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AchievementRules> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AchievementRules> create(Ref ref) {
    final argument = this.argument as bool;
    return achievementRules(
      ref,
      admin: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementRulesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$achievementRulesHash() => r'a7b841a28674cb559e52b671fa65281c6e9d2590';

final class AchievementRulesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AchievementRules>, bool> {
  AchievementRulesFamily._()
      : super(
          retry: _noRetry,
          name: r'achievementRulesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  AchievementRulesProvider call({
    bool admin = false,
  }) =>
      AchievementRulesProvider._(argument: admin, from: this);

  @override
  String toString() => r'achievementRulesProvider';
}

@ProviderFor(rankings)
final rankingsProvider = RankingsFamily._();

final class RankingsProvider extends $FunctionalProvider<
        AsyncValue<AchievementPage>, AchievementPage, FutureOr<AchievementPage>>
    with $FutureModifier<AchievementPage>, $FutureProvider<AchievementPage> {
  RankingsProvider._(
      {required RankingsFamily super.from,
      required ({
        String scope,
        String? communityId,
        String period,
        String? month,
        String? asOf,
        String? gender,
        String? ageGroup,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'rankingsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rankingsHash();

  @override
  String toString() {
    return r'rankingsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<AchievementPage> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AchievementPage> create(Ref ref) {
    final argument = this.argument as ({
      String scope,
      String? communityId,
      String period,
      String? month,
      String? asOf,
      String? gender,
      String? ageGroup,
      int page,
    });
    return rankings(
      ref,
      scope: argument.scope,
      communityId: argument.communityId,
      period: argument.period,
      month: argument.month,
      asOf: argument.asOf,
      gender: argument.gender,
      ageGroup: argument.ageGroup,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is RankingsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rankingsHash() => r'2a001501611a292cccd6729c7984135b8a94b4f2';

final class RankingsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<AchievementPage>,
            ({
              String scope,
              String? communityId,
              String period,
              String? month,
              String? asOf,
              String? gender,
              String? ageGroup,
              int page,
            })> {
  RankingsFamily._()
      : super(
          retry: _noRetry,
          name: r'rankingsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  RankingsProvider call({
    String scope = 'communities',
    String? communityId,
    String period = 'month',
    String? month,
    String? asOf,
    String? gender,
    String? ageGroup,
    int page = 1,
  }) =>
      RankingsProvider._(argument: (
        scope: scope,
        communityId: communityId,
        period: period,
        month: month,
        asOf: asOf,
        gender: gender,
        ageGroup: ageGroup,
        page: page,
      ), from: this);

  @override
  String toString() => r'rankingsProvider';
}

@ProviderFor(myAchievements)
final myAchievementsProvider = MyAchievementsFamily._();

final class MyAchievementsProvider extends $FunctionalProvider<
        AsyncValue<AchievementPage>, AchievementPage, FutureOr<AchievementPage>>
    with $FutureModifier<AchievementPage>, $FutureProvider<AchievementPage> {
  MyAchievementsProvider._(
      {required MyAchievementsFamily super.from, required int super.argument})
      : super(
          retry: _noRetry,
          name: r'myAchievementsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$myAchievementsHash();

  @override
  String toString() {
    return r'myAchievementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AchievementPage> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AchievementPage> create(Ref ref) {
    final argument = this.argument as int;
    return myAchievements(
      ref,
      page: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MyAchievementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myAchievementsHash() => r'85aac38a78588ff371153969152e8b8f8b82fcb5';

final class MyAchievementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AchievementPage>, int> {
  MyAchievementsFamily._()
      : super(
          retry: _noRetry,
          name: r'myAchievementsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MyAchievementsProvider call({
    int page = 1,
  }) =>
      MyAchievementsProvider._(argument: page, from: this);

  @override
  String toString() => r'myAchievementsProvider';
}

@ProviderFor(communityAchievements)
final communityAchievementsProvider = CommunityAchievementsFamily._();

final class CommunityAchievementsProvider extends $FunctionalProvider<
        AsyncValue<AchievementPage>, AchievementPage, FutureOr<AchievementPage>>
    with $FutureModifier<AchievementPage>, $FutureProvider<AchievementPage> {
  CommunityAchievementsProvider._(
      {required CommunityAchievementsFamily super.from,
      required (
        String, {
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'communityAchievementsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$communityAchievementsHash();

  @override
  String toString() {
    return r'communityAchievementsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<AchievementPage> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AchievementPage> create(Ref ref) {
    final argument = this.argument as (
      String, {
      int page,
    });
    return communityAchievements(
      ref,
      argument.$1,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityAchievementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityAchievementsHash() =>
    r'e3fb3bc1c1dbe68f4be79c7dfa78877342c34ce0';

final class CommunityAchievementsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<AchievementPage>,
            (
              String, {
              int page,
            })> {
  CommunityAchievementsFamily._()
      : super(
          retry: _noRetry,
          name: r'communityAchievementsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  CommunityAchievementsProvider call(
    String id, {
    int page = 1,
  }) =>
      CommunityAchievementsProvider._(argument: (
        id,
        page: page,
      ), from: this);

  @override
  String toString() => r'communityAchievementsProvider';
}

@ProviderFor(memberAds)
final memberAdsProvider = MemberAdsFamily._();

final class MemberAdsProvider extends $FunctionalProvider<
        AsyncValue<MemberAdPage>, MemberAdPage, FutureOr<MemberAdPage>>
    with $FutureModifier<MemberAdPage>, $FutureProvider<MemberAdPage> {
  MemberAdsProvider._(
      {required MemberAdsFamily super.from,
      required ({
        bool mine,
        String? communityId,
        String? sellerId,
        String search,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'memberAdsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memberAdsHash();

  @override
  String toString() {
    return r'memberAdsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MemberAdPage> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MemberAdPage> create(Ref ref) {
    final argument = this.argument as ({
      bool mine,
      String? communityId,
      String? sellerId,
      String search,
      int page,
    });
    return memberAds(
      ref,
      mine: argument.mine,
      communityId: argument.communityId,
      sellerId: argument.sellerId,
      search: argument.search,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberAdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberAdsHash() => r'c75165707a23f13f53cd50bf44c657f1c3997924';

final class MemberAdsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MemberAdPage>,
            ({
              bool mine,
              String? communityId,
              String? sellerId,
              String search,
              int page,
            })> {
  MemberAdsFamily._()
      : super(
          retry: _noRetry,
          name: r'memberAdsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MemberAdsProvider call({
    bool mine = false,
    String? communityId,
    String? sellerId,
    String search = '',
    int page = 1,
  }) =>
      MemberAdsProvider._(argument: (
        mine: mine,
        communityId: communityId,
        sellerId: sellerId,
        search: search,
        page: page,
      ), from: this);

  @override
  String toString() => r'memberAdsProvider';
}

@ProviderFor(achievementMembers)
final achievementMembersProvider = AchievementMembersFamily._();

final class AchievementMembersProvider extends $FunctionalProvider<
        AsyncValue<List<Map<String, dynamic>>>,
        List<Map<String, dynamic>>,
        FutureOr<List<Map<String, dynamic>>>>
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  AchievementMembersProvider._(
      {required AchievementMembersFamily super.from,
      required (
        String, {
        String search,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'achievementMembersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$achievementMembersHash();

  @override
  String toString() {
    return r'achievementMembersProvider'
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
      int page,
    });
    return achievementMembers(
      ref,
      argument.$1,
      search: argument.search,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AchievementMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$achievementMembersHash() =>
    r'26648f292814b476e6672a156da985807db69d19';

final class AchievementMembersFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<List<Map<String, dynamic>>>,
            (
              String, {
              String search,
              int page,
            })> {
  AchievementMembersFamily._()
      : super(
          retry: _noRetry,
          name: r'achievementMembersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  AchievementMembersProvider call(
    String communityId, {
    String search = '',
    int page = 1,
  }) =>
      AchievementMembersProvider._(argument: (
        communityId,
        search: search,
        page: page,
      ), from: this);

  @override
  String toString() => r'achievementMembersProvider';
}
