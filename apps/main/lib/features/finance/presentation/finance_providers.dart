import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/finance.dart';
import '../domain/finance_repository.dart';
import '../data/finance_remote_data_source.dart';
import '../data/finance_repository_impl.dart';
part 'finance_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;
@Riverpod(keepAlive: true)
FinanceRepository financeRepository(Ref ref) => FinanceRepositoryImpl(
    FinanceRemoteDataSource(ref.watch(apiClientProvider).dio));
@Riverpod(retry: _noRetry)
Future<BillingNoticeFeed> billingNoticeFeed(Ref ref) =>
    ref.watch(financeRepositoryProvider).notices();
@Riverpod(retry: _noRetry)
Future<WalletSummary> walletSummary(Ref ref) =>
    ref.watch(financeRepositoryProvider).wallet();
@Riverpod(retry: _noRetry)
Future<WalletSummary> fundSummary(Ref ref, String scope, String? communityId) =>
    ref
        .watch(financeRepositoryProvider)
        .wallet(scope: scope, communityId: communityId);
@Riverpod(retry: _noRetry)
Future<FinancePage<WalletTransaction>> walletTransactions(Ref ref,
        {String scope = 'identity',
        String direction = '',
        String kind = '',
        String? communityId,
        int page = 1}) =>
    ref.watch(financeRepositoryProvider).transactions(
        scope: scope,
        direction: direction,
        kind: kind,
        communityId: communityId,
        page: page);
@Riverpod(retry: _noRetry)
Future<WalletTransaction> walletTransaction(Ref ref, String id,
        {String scope = 'identity', String? communityId}) =>
    ref
        .watch(financeRepositoryProvider)
        .transaction(id, scope: scope, communityId: communityId);
@Riverpod(retry: _noRetry)
Future<FinancePage<PaymentReceipt>> paymentReceipts(Ref ref,
        {String? communityId,
        String status = '',
        int page = 1,
        bool manage = false}) =>
    ref.watch(financeRepositoryProvider).receipts(
        communityId: communityId, status: status, page: page, manage: manage);
@Riverpod(retry: _noRetry)
Future<BillingOverview> billingOverview(Ref ref, String communityId,
        {String scope = 'member', String? targetMemberId}) =>
    ref
        .watch(financeRepositoryProvider)
        .billing(communityId, scope: scope, targetMemberId: targetMemberId);
@Riverpod(retry: _noRetry)
Future<List<InactiveSubject>> inactiveSubjects(Ref ref, String communityId) =>
    ref.watch(financeRepositoryProvider).inactive(communityId);

void invalidateFinance(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(walletSummaryProvider);
  invalidate(billingNoticeFeedProvider);
  invalidate(fundSummaryProvider);
  invalidate(walletTransactionsProvider);
  invalidate(walletTransactionProvider);
  invalidate(paymentReceiptsProvider);
  invalidate(billingOverviewProvider);
  invalidate(inactiveSubjectsProvider);
}
