import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/money_movement_remote_data_source.dart';
import '../data/money_movement_repository_impl.dart';
import '../domain/money_movement.dart';
import '../domain/money_movement_repository.dart';
part 'money_movement_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;
@Riverpod(keepAlive: true)
MoneyMovementRepository moneyMovementRepository(Ref ref) =>
    MoneyMovementRepositoryImpl(
        MoneyMovementRemoteDataSource(ref.watch(apiClientProvider).dio));
@Riverpod(retry: _noRetry)
Future<PrimaryBankAccount?> primaryBankAccount(Ref ref) =>
    ref.watch(moneyMovementRepositoryProvider).primaryAccount();
@Riverpod(retry: _noRetry)
Future<MovementPage<TransferRecipient>> transferRecipients(
        Ref ref, String query, String communityId, {int page = 1}) =>
    ref
        .watch(moneyMovementRepositoryProvider)
        .recipients(query, communityId, page: page);
@Riverpod(retry: _noRetry)
Future<MovementPage<MemberTransfer>> memberTransfers(Ref ref, {int page = 1}) =>
    ref.watch(moneyMovementRepositoryProvider).transfers(page: page);
@Riverpod(retry: _noRetry)
Future<MovementPage<Payout>> payouts(Ref ref,
        {String? communityId,
        bool manage = false,
        String status = '',
        String query = '',
        int page = 1}) =>
    ref.watch(moneyMovementRepositoryProvider).payouts(
        communityId: communityId,
        manage: manage,
        status: status,
        query: query,
        page: page);
@Riverpod(retry: _noRetry)
Future<Payout> payoutDetail(Ref ref, String id) =>
    ref.watch(moneyMovementRepositoryProvider).payout(id);
@Riverpod(retry: _noRetry)
Future<PayoutReconciliation> payoutReconciliation(
        Ref ref, String communityId) =>
    ref.watch(moneyMovementRepositoryProvider).reconciliation(communityId);
void invalidateMovements(void Function(ProviderOrFamily) invalidate) {
  invalidate(primaryBankAccountProvider);
  invalidate(memberTransfersProvider);
  invalidate(payoutsProvider);
  invalidate(payoutDetailProvider);
  invalidate(payoutReconciliationProvider);
}
