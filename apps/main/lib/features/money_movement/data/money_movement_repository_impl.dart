import '../../finance/data/finance_models.dart';
import '../domain/money_movement.dart';
import '../domain/money_movement_repository.dart';
import 'money_movement_models.dart';
import 'money_movement_remote_data_source.dart';

class MoneyMovementRepositoryImpl implements MoneyMovementRepository {
  const MoneyMovementRepositoryImpl(this.remote);
  final MoneyMovementRemoteDataSource remote;
  MovementPage<T> _page<T>(
          Map<String, dynamic> j, T Function(Map<String, dynamic>) parse) =>
      MovementPage([for (final x in financeList(j['items'])) parse(x)],
          page: money(j['current_page']) < 1 ? 1 : money(j['current_page']),
          lastPage: money(j['last_page']) < 1 ? 1 : money(j['last_page']),
          canManage: j['can_manage'] == true);
  @override
  Future<PrimaryBankAccount?> primaryAccount() async {
    final j = await remote.get('bank-accounts/primary');
    return j['account'] == null
        ? null
        : bankAccountFromJson(financeMap(j['account']));
  }

  @override
  Future<PrimaryBankAccount> savePrimaryAccount(
          Map<String, Object?> fields) async =>
      bankAccountFromJson(financeMap(
          (await remote.put('bank-accounts/primary', fields))['account']));
  @override
  Future<MovementPage<TransferRecipient>> recipients(
          String query, String communityId, {int page = 1}) async =>
      _page(
          await remote.get('transfers/recipients',
              {'q': query, 'community_id': communityId, 'page': page}),
          recipientFromJson);
  @override
  Future<MemberTransfer> transfer(Map<String, Object?> fields) async =>
      memberTransferFromJson(await remote.post('transfers', fields));
  @override
  Future<MovementPage<MemberTransfer>> transfers({int page = 1}) async => _page(
      await remote.get('transfers', {'page': page}), memberTransferFromJson);
  @override
  Future<MovementPage<Payout>> payouts(
          {String? communityId,
          bool manage = false,
          String status = '',
          String query = '',
          int page = 1}) async =>
      _page(
          await remote.get('payouts', {
            'scope': manage ? 'manage' : 'mine',
            if (manage && communityId == null) 'handler': 'platform',
            if (communityId != null) 'community_id': communityId,
            'status': status,
            'q': query,
            'page': page
          }),
          payoutFromJson);
  @override
  Future<Payout> payout(String id) async =>
      payoutFromJson(await remote.get('payouts/$id'));
  @override
  Future<Payout> requestPayout(Map<String, Object?> fields) async =>
      payoutFromJson(await remote.post('payouts', fields));
  @override
  Future<Payout> partAction(
          String partId, String action, Map<String, Object?> fields,
          {String? fragmentId}) async =>
      payoutFromJson(await remote.post(
          'payout-parts/$partId/${fragmentId == null ? action : 'fragments/$fragmentId/verify'}',
          fields));
  @override
  Future<Payout> editPendingFragment(String partId, String fragmentId,
          Map<String, Object?> fields) async =>
      payoutFromJson(await remote.put(
          'payout-parts/$partId/fragments/$fragmentId', fields));
  @override
  Future<PayoutReconciliation> reconciliation(String communityId) async {
    final j = await remote.get(communityId == 'platform'
        ? 'payout-reconciliation'
        : 'communities/$communityId/payout-reconciliation');
    return PayoutReconciliation(
        requested: requiredMoney(j['parts_amount']),
        verified: requiredMoney(j['verified_amount']),
        held: requiredMoney(j['held_amount']),
        released: requiredMoney(j['released_amount']),
        balanced: j['balanced'] == true);
  }

  @override
  Future<ProofFile> proof(String url) => remote.proof(url);
}
