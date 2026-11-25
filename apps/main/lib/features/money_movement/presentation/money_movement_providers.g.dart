// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money_movement_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(moneyMovementRepository)
final moneyMovementRepositoryProvider = MoneyMovementRepositoryProvider._();

final class MoneyMovementRepositoryProvider extends $FunctionalProvider<
    MoneyMovementRepository,
    MoneyMovementRepository,
    MoneyMovementRepository> with $Provider<MoneyMovementRepository> {
  MoneyMovementRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'moneyMovementRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$moneyMovementRepositoryHash();

  @$internal
  @override
  $ProviderElement<MoneyMovementRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MoneyMovementRepository create(Ref ref) {
    return moneyMovementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MoneyMovementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MoneyMovementRepository>(value),
    );
  }
}

String _$moneyMovementRepositoryHash() =>
    r'aa0ba98bd71eeedbfed26b10c7678b4ee7bee8dd';

@ProviderFor(primaryBankAccount)
final primaryBankAccountProvider = PrimaryBankAccountProvider._();

final class PrimaryBankAccountProvider extends $FunctionalProvider<
        AsyncValue<PrimaryBankAccount?>,
        PrimaryBankAccount?,
        FutureOr<PrimaryBankAccount?>>
    with
        $FutureModifier<PrimaryBankAccount?>,
        $FutureProvider<PrimaryBankAccount?> {
  PrimaryBankAccountProvider._()
      : super(
          from: null,
          argument: null,
          retry: _noRetry,
          name: r'primaryBankAccountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$primaryBankAccountHash();

  @$internal
  @override
  $FutureProviderElement<PrimaryBankAccount?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PrimaryBankAccount?> create(Ref ref) {
    return primaryBankAccount(ref);
  }
}

String _$primaryBankAccountHash() =>
    r'09109dc69d2e6a0829072f5d7bb2f587555540e0';

@ProviderFor(transferRecipients)
final transferRecipientsProvider = TransferRecipientsFamily._();

final class TransferRecipientsProvider extends $FunctionalProvider<
        AsyncValue<MovementPage<TransferRecipient>>,
        MovementPage<TransferRecipient>,
        FutureOr<MovementPage<TransferRecipient>>>
    with
        $FutureModifier<MovementPage<TransferRecipient>>,
        $FutureProvider<MovementPage<TransferRecipient>> {
  TransferRecipientsProvider._(
      {required TransferRecipientsFamily super.from,
      required (
        String,
        String, {
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'transferRecipientsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$transferRecipientsHash();

  @override
  String toString() {
    return r'transferRecipientsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MovementPage<TransferRecipient>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MovementPage<TransferRecipient>> create(Ref ref) {
    final argument = this.argument as (
      String,
      String, {
      int page,
    });
    return transferRecipients(
      ref,
      argument.$1,
      argument.$2,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TransferRecipientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$transferRecipientsHash() =>
    r'ee9169468d4416728826075d52dec339b49eecd5';

final class TransferRecipientsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MovementPage<TransferRecipient>>,
            (
              String,
              String, {
              int page,
            })> {
  TransferRecipientsFamily._()
      : super(
          retry: _noRetry,
          name: r'transferRecipientsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  TransferRecipientsProvider call(
    String query,
    String communityId, {
    int page = 1,
  }) =>
      TransferRecipientsProvider._(argument: (
        query,
        communityId,
        page: page,
      ), from: this);

  @override
  String toString() => r'transferRecipientsProvider';
}

@ProviderFor(memberTransfers)
final memberTransfersProvider = MemberTransfersFamily._();

final class MemberTransfersProvider extends $FunctionalProvider<
        AsyncValue<MovementPage<MemberTransfer>>,
        MovementPage<MemberTransfer>,
        FutureOr<MovementPage<MemberTransfer>>>
    with
        $FutureModifier<MovementPage<MemberTransfer>>,
        $FutureProvider<MovementPage<MemberTransfer>> {
  MemberTransfersProvider._(
      {required MemberTransfersFamily super.from, required int super.argument})
      : super(
          retry: _noRetry,
          name: r'memberTransfersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$memberTransfersHash();

  @override
  String toString() {
    return r'memberTransfersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MovementPage<MemberTransfer>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MovementPage<MemberTransfer>> create(Ref ref) {
    final argument = this.argument as int;
    return memberTransfers(
      ref,
      page: argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MemberTransfersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$memberTransfersHash() => r'74f888a8a96b209d6bd8d61aca782e7531683d35';

final class MemberTransfersFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<MovementPage<MemberTransfer>>, int> {
  MemberTransfersFamily._()
      : super(
          retry: _noRetry,
          name: r'memberTransfersProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  MemberTransfersProvider call({
    int page = 1,
  }) =>
      MemberTransfersProvider._(argument: page, from: this);

  @override
  String toString() => r'memberTransfersProvider';
}

@ProviderFor(payouts)
final payoutsProvider = PayoutsFamily._();

final class PayoutsProvider extends $FunctionalProvider<
        AsyncValue<MovementPage<Payout>>,
        MovementPage<Payout>,
        FutureOr<MovementPage<Payout>>>
    with
        $FutureModifier<MovementPage<Payout>>,
        $FutureProvider<MovementPage<Payout>> {
  PayoutsProvider._(
      {required PayoutsFamily super.from,
      required ({
        String? communityId,
        bool manage,
        String status,
        String query,
        int page,
      })
          super.argument})
      : super(
          retry: _noRetry,
          name: r'payoutsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$payoutsHash();

  @override
  String toString() {
    return r'payoutsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<MovementPage<Payout>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MovementPage<Payout>> create(Ref ref) {
    final argument = this.argument as ({
      String? communityId,
      bool manage,
      String status,
      String query,
      int page,
    });
    return payouts(
      ref,
      communityId: argument.communityId,
      manage: argument.manage,
      status: argument.status,
      query: argument.query,
      page: argument.page,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payoutsHash() => r'b594f47a3f774faa9a75d5afa1c788883e204eeb';

final class PayoutsFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<MovementPage<Payout>>,
            ({
              String? communityId,
              bool manage,
              String status,
              String query,
              int page,
            })> {
  PayoutsFamily._()
      : super(
          retry: _noRetry,
          name: r'payoutsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PayoutsProvider call({
    String? communityId,
    bool manage = false,
    String status = '',
    String query = '',
    int page = 1,
  }) =>
      PayoutsProvider._(argument: (
        communityId: communityId,
        manage: manage,
        status: status,
        query: query,
        page: page,
      ), from: this);

  @override
  String toString() => r'payoutsProvider';
}

@ProviderFor(payoutDetail)
final payoutDetailProvider = PayoutDetailFamily._();

final class PayoutDetailProvider
    extends $FunctionalProvider<AsyncValue<Payout>, Payout, FutureOr<Payout>>
    with $FutureModifier<Payout>, $FutureProvider<Payout> {
  PayoutDetailProvider._(
      {required PayoutDetailFamily super.from, required String super.argument})
      : super(
          retry: _noRetry,
          name: r'payoutDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$payoutDetailHash();

  @override
  String toString() {
    return r'payoutDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Payout> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Payout> create(Ref ref) {
    final argument = this.argument as String;
    return payoutDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payoutDetailHash() => r'88ba2937bbab46eae77b98c2554370aa963a238f';

final class PayoutDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Payout>, String> {
  PayoutDetailFamily._()
      : super(
          retry: _noRetry,
          name: r'payoutDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PayoutDetailProvider call(
    String id,
  ) =>
      PayoutDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'payoutDetailProvider';
}

@ProviderFor(payoutReconciliation)
final payoutReconciliationProvider = PayoutReconciliationFamily._();

final class PayoutReconciliationProvider extends $FunctionalProvider<
        AsyncValue<PayoutReconciliation>,
        PayoutReconciliation,
        FutureOr<PayoutReconciliation>>
    with
        $FutureModifier<PayoutReconciliation>,
        $FutureProvider<PayoutReconciliation> {
  PayoutReconciliationProvider._(
      {required PayoutReconciliationFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'payoutReconciliationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$payoutReconciliationHash();

  @override
  String toString() {
    return r'payoutReconciliationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PayoutReconciliation> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PayoutReconciliation> create(Ref ref) {
    final argument = this.argument as String;
    return payoutReconciliation(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PayoutReconciliationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$payoutReconciliationHash() =>
    r'44c724412cc95923144c2bb4e5a78ab81d3ad62f';

final class PayoutReconciliationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PayoutReconciliation>, String> {
  PayoutReconciliationFamily._()
      : super(
          retry: _noRetry,
          name: r'payoutReconciliationProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  PayoutReconciliationProvider call(
    String communityId,
  ) =>
      PayoutReconciliationProvider._(argument: communityId, from: this);

  @override
  String toString() => r'payoutReconciliationProvider';
}
