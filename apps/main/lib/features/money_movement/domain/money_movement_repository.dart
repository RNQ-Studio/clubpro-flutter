import 'money_movement.dart';

abstract interface class MoneyMovementRepository {
  Future<PrimaryBankAccount?> primaryAccount();
  Future<PrimaryBankAccount> savePrimaryAccount(Map<String, Object?> fields);
  Future<MovementPage<TransferRecipient>> recipients(
      String query, String communityId,
      {int page = 1});
  Future<MemberTransfer> transfer(Map<String, Object?> fields);
  Future<MovementPage<MemberTransfer>> transfers({int page = 1});
  Future<MovementPage<Payout>> payouts(
      {String? communityId,
      bool manage = false,
      String status = '',
      String query = '',
      int page = 1});
  Future<Payout> payout(String id);
  Future<Payout> requestPayout(Map<String, Object?> fields);
  Future<Payout> partAction(
      String partId, String action, Map<String, Object?> fields,
      {String? fragmentId});
  Future<Payout> editPendingFragment(
      String partId, String fragmentId, Map<String, Object?> fields);
  Future<PayoutReconciliation> reconciliation(String communityId);
  Future<ProofFile> proof(String url);
}
