// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(financeRepository)
final financeRepositoryProvider = FinanceRepositoryProvider._();

final class FinanceRepositoryProvider extends $FunctionalProvider<
    FinanceRepository,
    FinanceRepository,
    FinanceRepository> with $Provider<FinanceRepository> {
  FinanceRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'financeRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$financeRepositoryHash();

  @$internal
  @override
  $ProviderElement<FinanceRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FinanceRepository create(Ref ref) {
    return financeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FinanceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FinanceRepository>(value),
    );
  }
}

String _$financeRepositoryHash() => r'eeccdceab69d5239085ff27a4d0973d18ddafc5e';

@ProviderFor(billingNoticeFeed)
final billingNoticeFeedProvider = BillingNoticeFeedProvider._();

final class BillingNoticeFeedProvider extends $FunctionalProvider<
        AsyncValue<BillingNoticeFeed>,
        BillingNoticeFeed,
        FutureOr<BillingNoticeFeed>>
    with
        $FutureModifier<BillingNoticeFeed>,
        $FutureProvider<BillingNoticeFeed> {
  BillingNoticeFeedProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noRetry,
          name: r'billingNoticeFeedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$billingNoticeFeedHash();

  @$internal
  @override
  $FutureProviderElement<BillingNoticeFeed> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<BillingNoticeFeed> create(Ref ref) {
    return billingNoticeFeed(ref);
  }
}

String _$billingNoticeFeedHash() => r'f7a782a60260c046f1c166daacafea5b39182b68';

@ProviderFor(walletSummary)
final walletSummaryProvider = WalletSummaryProvider._();

final class WalletSummaryProvider extends $FunctionalProvider<
        AsyncValue<WalletSummary>, WalletSummary, FutureOr<WalletSummary>>
    with $FutureModifier<WalletSummary>, $FutureProvider<WalletSummary> {
  WalletSummaryProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noRetry,
          name: r'walletSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$walletSummaryHash();

  @$internal
  @override
  $FutureProviderElement<WalletSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WalletSummary> create(Ref ref) {
    return walletSummary(ref);
  }
}

String _$walletSummaryHash() => r'c0c6306322b0bd2bbe02f7aca2be411f5823d9b7';

@ProviderFor(fundSummary)
final fundSummaryProvider = FundSummaryFamily._();

final class FundSummaryProvider extends $FunctionalProvider<
        AsyncValue<WalletSummary>, WalletSummary, FutureOr<WalletSummary>>
    with $FutureModifier<WalletSummary>, $FutureProvider<WalletSummary> {
  FundSummaryProvider._(
      {required FundSummaryFamily super.from,
      required (
        String,
        String?,
      )
          super.argument})
      : super(
          retry: _noRetry,
          name: r'fundSummaryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$fundSummaryHash();

  @override
  String toString() {
    return r'fundSummaryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WalletSummary> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WalletSummary> create(Ref ref) {
    final argument = this.argument as (
      String,
      String?,
    );
    return fundSummary(
      ref,
      argument.$1,
      argument.$2,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FundSummaryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fundSummaryHash() => r'8e56f1fca323cb31328725316efc5cfa03c313a5';

final class FundSummaryFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<WalletSummary>,
            (
              String,
              String?,
            )> {
  FundSummaryFamily._()
      : super(
          retry: _noRetry,
          name: r'fundSummaryProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  FundSummaryProvider call(
    String scope,
    String? communityId,
  ) =>
      FundSummaryProvider._(argument: (
        scope,
        communityId,
      ), from: this);

  @override
  String toString() => r'fundSummaryProvider';
}

@ProviderFor(walletTransactions)
final walletTransactionsProvider = WalletTransactionsFamily._();

final class WalletTransactionsProvider extends $FunctionalProvider<
        AsyncValue<FinancePage<WalletTransaction>>,
        FinancePage<WalletTransaction>,
        FutureOr<FinancePage<WalletTransaction>>>
    with
        $FutureModifier<FinancePage<WalletTransaction>>,
        $FutureProvider<FinancePage<WalletTransaction>> {
  WalletTransactionsProvider._(
      {required WalletTransactionsFamily super.from,
      required ({
        String scope,
        String direction,
        String kind,
        String? communityId,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'walletTransactionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$walletTransactionsHash();

  @override
  String toString() {
    return r'walletTransactionsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FinancePage<WalletTransaction>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FinancePage<WalletTransaction>> create(Ref ref) {
    final argument = this.argument as ({
      String scope,
      String direction,
      String kind,
      String? communityId,
      int page,
    });
    return walletTransactions(
      ref,
      scope: argument.scope,
      direction: argument.direction,
      kind: argument.kind,
      communityId: argument.communityId,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WalletTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletTransactionsHash() =>
    r'4ca59516c3f579757138314b8472189bfb4f1cb8';

final class WalletTransactionsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<FinancePage<WalletTransaction>>,
            ({
              String scope,
              String direction,
              String kind,
              String? communityId,
              int page,
            })> {
  WalletTransactionsFamily._()
      : super(
          retry: _noRetry,
          name: r'walletTransactionsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WalletTransactionsProvider call({
    String scope = 'identity',
    String direction = '',
    String kind = '',
    String? communityId,
    int page = 1,
  }) =>
      WalletTransactionsProvider._(argument: (
        scope: scope,
        direction: direction,
        kind: kind,
        communityId: communityId,
        page: page,
      ), from: this);

  @override
  String toString() => r'walletTransactionsProvider';
}

@ProviderFor(walletTransaction)
final walletTransactionProvider = WalletTransactionFamily._();

final class WalletTransactionProvider extends $FunctionalProvider<
        AsyncValue<WalletTransaction>,
        WalletTransaction,
        FutureOr<WalletTransaction>>
    with
        $FutureModifier<WalletTransaction>,
        $FutureProvider<WalletTransaction> {
  WalletTransactionProvider._(
      {required WalletTransactionFamily super.from,
      required (
        String, {
        String scope,
        String? communityId,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'walletTransactionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$walletTransactionHash();

  @override
  String toString() {
    return r'walletTransactionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<WalletTransaction> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WalletTransaction> create(Ref ref) {
    final argument = this.argument as (
      String, {
      String scope,
      String? communityId,
    });
    return walletTransaction(
      ref,
      argument.$1,
      scope: argument.scope,
      communityId: argument.communityId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WalletTransactionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletTransactionHash() => r'68ae27f47758371ba3c84ac2c997409c02b56a0c';

final class WalletTransactionFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<WalletTransaction>,
            (
              String, {
              String scope,
              String? communityId,
            })> {
  WalletTransactionFamily._()
      : super(
          retry: _noRetry,
          name: r'walletTransactionProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  WalletTransactionProvider call(
    String id, {
    String scope = 'identity',
    String? communityId,
  }) =>
      WalletTransactionProvider._(argument: (
        id,
        scope: scope,
        communityId: communityId,
      ), from: this);

  @override
  String toString() => r'walletTransactionProvider';
}

@ProviderFor(paymentReceipts)
final paymentReceiptsProvider = PaymentReceiptsFamily._();

final class PaymentReceiptsProvider extends $FunctionalProvider<
        AsyncValue<FinancePage<PaymentReceipt>>,
        FinancePage<PaymentReceipt>,
        FutureOr<FinancePage<PaymentReceipt>>>
    with
        $FutureModifier<FinancePage<PaymentReceipt>>,
        $FutureProvider<FinancePage<PaymentReceipt>> {
  PaymentReceiptsProvider._(
      {required PaymentReceiptsFamily super.from,
      required ({
        String? communityId,
        String status,
        int page,
        bool manage,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'paymentReceiptsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$paymentReceiptsHash();

  @override
  String toString() {
    return r'paymentReceiptsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<FinancePage<PaymentReceipt>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FinancePage<PaymentReceipt>> create(Ref ref) {
    final argument = this.argument as ({
      String? communityId,
      String status,
      int page,
      bool manage,
    });
    return paymentReceipts(
      ref,
      communityId: argument.communityId,
      status: argument.status,
      page: argument.page,
      manage: argument.manage,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentReceiptsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$paymentReceiptsHash() => r'94c575b09828606a02401043b99b20a2c7dee83a';

final class PaymentReceiptsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<FinancePage<PaymentReceipt>>,
            ({
              String? communityId,
              String status,
              int page,
              bool manage,
            })> {
  PaymentReceiptsFamily._()
      : super(
          retry: _noRetry,
          name: r'paymentReceiptsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PaymentReceiptsProvider call({
    String? communityId,
    String status = '',
    int page = 1,
    bool manage = false,
  }) =>
      PaymentReceiptsProvider._(argument: (
        communityId: communityId,
        status: status,
        page: page,
        manage: manage,
      ), from: this);

  @override
  String toString() => r'paymentReceiptsProvider';
}

@ProviderFor(billingOverview)
final billingOverviewProvider = BillingOverviewFamily._();

final class BillingOverviewProvider extends $FunctionalProvider<
        AsyncValue<BillingOverview>, BillingOverview, FutureOr<BillingOverview>>
    with $FutureModifier<BillingOverview>, $FutureProvider<BillingOverview> {
  BillingOverviewProvider._(
      {required BillingOverviewFamily super.from,
      required (
        String, {
        String scope,
        String? targetMemberId,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'billingOverviewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$billingOverviewHash();

  @override
  String toString() {
    return r'billingOverviewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<BillingOverview> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<BillingOverview> create(Ref ref) {
    final argument = this.argument as (
      String, {
      String scope,
      String? targetMemberId,
    });
    return billingOverview(
      ref,
      argument.$1,
      scope: argument.scope,
      targetMemberId: argument.targetMemberId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BillingOverviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingOverviewHash() => r'c61416ea77e2843931df3f7e7402de211778283f';

final class BillingOverviewFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<BillingOverview>,
            (
              String, {
              String scope,
              String? targetMemberId,
            })> {
  BillingOverviewFamily._()
      : super(
          retry: _noRetry,
          name: r'billingOverviewProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  BillingOverviewProvider call(
    String communityId, {
    String scope = 'member',
    String? targetMemberId,
  }) =>
      BillingOverviewProvider._(argument: (
        communityId,
        scope: scope,
        targetMemberId: targetMemberId,
      ), from: this);

  @override
  String toString() => r'billingOverviewProvider';
}

@ProviderFor(inactiveSubjects)
final inactiveSubjectsProvider = InactiveSubjectsFamily._();

final class InactiveSubjectsProvider extends $FunctionalProvider<
        AsyncValue<List<InactiveSubject>>,
        List<InactiveSubject>,
        FutureOr<List<InactiveSubject>>>
    with
        $FutureModifier<List<InactiveSubject>>,
        $FutureProvider<List<InactiveSubject>> {
  InactiveSubjectsProvider._(
      {required InactiveSubjectsFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'inactiveSubjectsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$inactiveSubjectsHash();

  @override
  String toString() {
    return r'inactiveSubjectsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InactiveSubject>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<InactiveSubject>> create(Ref ref) {
    final argument = this.argument as String;
    return inactiveSubjects(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InactiveSubjectsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inactiveSubjectsHash() => r'ac78feac4c463025cd0d34ed46439b2006861afe';

final class InactiveSubjectsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InactiveSubject>>, String> {
  InactiveSubjectsFamily._()
      : super(
          retry: _noRetry,
          name: r'inactiveSubjectsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  InactiveSubjectsProvider call(
    String communityId,
  ) =>
      InactiveSubjectsProvider._(argument: communityId, from: this);

  @override
  String toString() => r'inactiveSubjectsProvider';
}
