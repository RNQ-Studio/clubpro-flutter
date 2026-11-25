// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trainingRepository)
final trainingRepositoryProvider = TrainingRepositoryProvider._();

final class TrainingRepositoryProvider extends $FunctionalProvider<
    TrainingRepository,
    TrainingRepository,
    TrainingRepository> with $Provider<TrainingRepository> {
  TrainingRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'trainingRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trainingRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrainingRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrainingRepository create(Ref ref) {
    return trainingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrainingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrainingRepository>(value),
    );
  }
}

String _$trainingRepositoryHash() =>
    r'5fde22eeef29b29fe5b7c536e4feaaab5954e4e4';

@ProviderFor(trainingOverview)
final trainingOverviewProvider = TrainingOverviewFamily._();

final class TrainingOverviewProvider extends $FunctionalProvider<
        AsyncValue<TrainingOverview>,
        TrainingOverview,
        FutureOr<TrainingOverview>>
    with $FutureModifier<TrainingOverview>, $FutureProvider<TrainingOverview> {
  TrainingOverviewProvider._(
      {required TrainingOverviewFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'trainingOverviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trainingOverviewHash();

  @override
  String toString() {
    return r'trainingOverviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrainingOverview> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TrainingOverview> create(Ref ref) {
    final argument = this.argument as String;
    return trainingOverview(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrainingOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trainingOverviewHash() => r'ffb2777ab74c449de80f44ba33b0fa2b12ee328d';

final class TrainingOverviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrainingOverview>, String> {
  TrainingOverviewFamily._()
      : super(
          retry: _noRetry,
          name: r'trainingOverviewProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  TrainingOverviewProvider call(
    String communityId,
  ) =>
      TrainingOverviewProvider._(argument: communityId, from: this);

  @override
  String toString() => r'trainingOverviewProvider';
}

@ProviderFor(trainingReport)
final trainingReportProvider = TrainingReportFamily._();

final class TrainingReportProvider extends $FunctionalProvider<
        AsyncValue<TrainingReport>, TrainingReport, FutureOr<TrainingReport>>
    with $FutureModifier<TrainingReport>, $FutureProvider<TrainingReport> {
  TrainingReportProvider._(
      {required TrainingReportFamily super.from,
      required (
        String, {
        String? locationId,
        String? recipientMemberId,
        String? from,
        String? to,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'trainingReportProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$trainingReportHash();

  @override
  String toString() {
    return r'trainingReportProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TrainingReport> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TrainingReport> create(Ref ref) {
    final argument = this.argument as (
      String, {
      String? locationId,
      String? recipientMemberId,
      String? from,
      String? to,
    });
    return trainingReport(
      ref,
      argument.$1,
      locationId: argument.locationId,
      recipientMemberId: argument.recipientMemberId,
      from: argument.from,
      to: argument.to,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrainingReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trainingReportHash() => r'41690ee7bf2fa74704fe7b45c6d4383748f33335';

final class TrainingReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<TrainingReport>,
            (
              String, {
              String? locationId,
              String? recipientMemberId,
              String? from,
              String? to,
            })> {
  TrainingReportFamily._()
      : super(
          retry: _noRetry,
          name: r'trainingReportProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  TrainingReportProvider call(
    String communityId, {
    String? locationId,
    String? recipientMemberId,
    String? from,
    String? to,
  }) =>
      TrainingReportProvider._(argument: (
        communityId,
        locationId: locationId,
        recipientMemberId: recipientMemberId,
        from: from,
        to: to,
      ), from: this);

  @override
  String toString() => r'trainingReportProvider';
}
