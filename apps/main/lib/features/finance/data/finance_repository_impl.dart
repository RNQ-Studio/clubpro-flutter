import '../domain/finance.dart';
import '../domain/finance_repository.dart';
import 'finance_models.dart';
import 'finance_remote_data_source.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  const FinanceRepositoryImpl(this.remote);
  final FinanceRemoteDataSource remote;
  String _base(String id) => 'communities/$id';
  FinancePage<T> _page<T>(
          Map<String, dynamic> j, T Function(Map<String, dynamic>) parse) =>
      FinancePage([for (final raw in financeList(j['items'])) parse(raw)],
          page: money(j['current_page']) == 0 ? 1 : money(j['current_page']),
          lastPage: money(j['last_page']) == 0 ? 1 : money(j['last_page']));
  @override
  Future<BillingNoticeFeed> notices() async {
    final j = await remote.get('billing-notices');
    return BillingNoticeFeed([
      for (final n in financeList(j['items']))
        BillingNotice(textOf(n['id']), textOf(n['type']), textOf(n['message']),
            textOf(n['created_at']),
            readAt: n['read_at'] as String?,
            communityId: textOf(n['community_id']),
            subjectKind: textOf(n['subject_kind']),
            memberId: n['member_id']?.toString())
    ], money(j['unread_count']));
  }

  @override
  Future<void> readNotice(String id) async {
    await remote.post('billing-notices/$id/read', {});
  }

  @override
  Future<WalletSummary> wallet(
          {String scope = 'identity', String? communityId}) async =>
      walletFromJson(await remote.get('wallet', {
        'scope': scope,
        if (communityId != null) 'community_id': communityId
      }));
  @override
  Future<FinancePage<WalletTransaction>> transactions(
          {String scope = 'identity',
          String direction = '',
          String kind = '',
          String? communityId,
          int page = 1}) async =>
      _page(
          await remote.get('wallet/transactions', {
            'page': page,
            'scope': scope,
            if (direction.isNotEmpty) 'direction': direction,
            if (kind.isNotEmpty) 'type': kind,
            if (communityId != null) 'community_id': communityId
          }),
          transactionFromJson);
  @override
  Future<WalletTransaction> transaction(String id,
          {String scope = 'identity', String? communityId}) async =>
      transactionFromJson(await remote.get('wallet/transactions/$id', {
        'scope': scope,
        if (communityId != null) 'community_id': communityId
      }));
  @override
  Future<FinancePage<PaymentReceipt>> receipts(
      {String? communityId,
      String status = '',
      int page = 1,
      bool manage = false}) async {
    final j = await remote.get(
        communityId == null
            ? 'wallet/receipts'
            : '${_base(communityId)}/receipts',
        {'page': page, if (status.isNotEmpty) 'status': status});
    return _page(j, receiptFromJson);
  }

  @override
  Future<PaymentReceipt> submitReceipt(Map<String, Object?> fields) async {
    final community = fields['community_id'].toString();
    final scope = fields['scope']?.toString();
    final path = scope == null
        ? '${_base(community)}/topups'
        : '${_base(community)}/receipts';
    return receiptFromJson(await remote.post(
        path,
        {...fields, if (scope != null) 'purpose': scope}
          ..remove('community_id')
          ..remove('scope')));
  }

  @override
  Future<PaymentReceipt> verifyReceipt(
          String id, Map<String, Object?> fields) async =>
      receiptFromJson(await remote.post(
          '${_base(fields['community_id'].toString())}/receipts/$id/verify',
          {...fields}..remove('community_id')));
  @override
  Future<PaymentReceipt> rejectReceipt(
          String communityId, String id, String reason, String key) async =>
      receiptFromJson(await remote.post(
          '${_base(communityId)}/receipts/$id/reject',
          {'note': reason, 'idempotency_key': key}));
  @override
  Future<BillingOverview> billing(String communityId,
          {String scope = 'member', String? targetMemberId}) async =>
      billingFromJson(await remote.get('${_base(communityId)}/billing', {
        'scope': scope,
        if (targetMemberId != null) 'target_member_id': targetMemberId
      }));
  @override
  Future<void> pay(String communityId, String scope, String key,
      {String? targetMemberId,
      required List<String> invoiceIds,
      required int expectedAmount}) async {
    await remote.post('${_base(communityId)}/billing/pay', {
      'scope': scope,
      'idempotency_key': key,
      'invoice_ids': invoiceIds,
      'expected_amount': expectedAmount,
      if (targetMemberId != null) 'target_member_id': int.parse(targetMemberId)
    });
  }

  @override
  Future<void> renew(String communityId, String scope,
      {String? targetMemberId}) async {
    await remote.post('${_base(communityId)}/billing/renew', {
      'scope': scope,
      if (targetMemberId != null) 'target_member_id': int.parse(targetMemberId)
    });
  }

  @override
  Future<void> saveSettings(
      String communityId, Map<String, Object?> fields) async {
    await remote.patch('${_base(communityId)}/billing/settings', fields);
  }

  @override
  Future<List<InactiveSubject>> inactive(String communityId) async =>
      inactiveFromJson(
          await remote.get('${_base(communityId)}/billing/inactive'));
  @override
  Future<void> decide(String communityId, InactiveSubject subject,
      String action, String reason) async {
    await remote.post('${_base(communityId)}/billing/lifecycle', {
      'subject': subject.platform ? 'platform' : 'member',
      if (!subject.platform) 'member_id': int.parse(subject.id),
      'action': action,
      'reason': reason,
    });
  }
}
