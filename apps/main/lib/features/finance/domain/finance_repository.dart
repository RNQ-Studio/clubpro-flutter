import 'finance.dart';

abstract interface class FinanceRepository {
  Future<BillingNoticeFeed> notices();
  Future<void> readNotice(String id);
  Future<WalletSummary> wallet(
      {String scope = 'identity', String? communityId});
  Future<FinancePage<WalletTransaction>> transactions(
      {String scope = 'identity',
      String direction = '',
      String kind = '',
      String? communityId,
      int page = 1});
  Future<WalletTransaction> transaction(String id,
      {String scope = 'identity', String? communityId});
  Future<FinancePage<PaymentReceipt>> receipts(
      {String? communityId,
      String status = '',
      int page = 1,
      bool manage = false});
  Future<PaymentReceipt> submitReceipt(Map<String, Object?> fields);
  Future<PaymentReceipt> verifyReceipt(String id, Map<String, Object?> fields);
  Future<PaymentReceipt> rejectReceipt(
      String communityId, String id, String reason, String key);
  Future<BillingOverview> billing(String communityId,
      {String scope = 'member', String? targetMemberId});
  Future<void> pay(String communityId, String scope, String key,
      {String? targetMemberId,
      required List<String> invoiceIds,
      required int expectedAmount});
  Future<void> renew(String communityId, String scope,
      {String? targetMemberId});
  Future<void> saveSettings(String communityId, Map<String, Object?> fields);
  Future<List<InactiveSubject>> inactive(String communityId);
  Future<void> decide(String communityId, InactiveSubject subject,
      String action, String reason);
}
