import '../../finance/data/finance_models.dart';
import '../../finance/domain/finance.dart';
import '../domain/money_movement.dart';

PrimaryBankAccount bankAccountFromJson(Map<String, dynamic> j) =>
    PrimaryBankAccount(
        bankCode: textOf(j['bank_code']),
        bankName: textOf(j['bank_name']),
        accountNumber: textOf(j['account_number']),
        accountName: textOf(j['account_name']),
        maskedNumber: textOf(j['masked_number']),
        version: money(j['version']));
TransferRecipient recipientFromJson(Map<String, dynamic> j) =>
    TransferRecipient(
        identityId: textOf(j['identity_id']),
        name: textOf(j['name']),
        communityId: textOf(j['community_id']),
        communityName: textOf(j['community_name']));
MemberTransfer memberTransferFromJson(Map<String, dynamic> j) {
  final amount = requiredMoney(j['amount']);
  if (amount <= 0 || textOf(j['status']) != 'succeeded') {
    throw const FinanceDataException();
  }
  return MemberTransfer(
      id: textOf(j['id']),
      reference: textOf(j['reference']),
      amount: amount,
      status: textOf(j['status']),
      sender: textOf(financeMap(j['sender'])['name']),
      recipient: textOf(financeMap(j['recipient'])['name']),
      createdAt: textOf(j['created_at']),
      direction: textOf(j['direction']));
}

Payout payoutFromJson(Map<String, dynamic> j) {
  final amount = requiredMoney(j['amount']),
      verified = requiredMoney(j['verified_amount']),
      remaining = requiredMoney(j['remaining_amount']),
      released = requiredMoney(j['released_amount']);
  if (amount <= 0 ||
      verified < 0 ||
      remaining < 0 ||
      released < 0 ||
      verified + remaining + released != amount ||
      (j['status'] == 'succeeded' && verified != amount)) {
    throw const FinanceDataException();
  }
  return Payout(
      id: textOf(j['id']),
      reference: textOf(j['reference']),
      communityId: textOf(j['community_id']),
      memberName: textOf(financeMap(j['member'])['name']),
      amount: amount,
      verified: verified,
      remaining: remaining,
      released: released,
      status: textOf(j['status']),
      version: money(j['version']),
      destination: bankAccountFromJson(financeMap(j['destination'])),
      createdAt: textOf(j['created_at']),
      canCancel: j['can_cancel'] == true,
      memberPhone: financeMap(j['member_contact'])['available'] == true
          ? financeMap(j['member_contact'])['phone'] as String?
          : null,
      parts: [for (final p in financeList(j['parts'])) payoutPartFromJson(p)]);
}

PayoutPart payoutPartFromJson(Map<String, dynamic> j) {
  final amount = requiredMoney(j['amount']),
      verified = requiredMoney(j['verified_amount']),
      remaining = requiredMoney(j['remaining_amount']),
      released = j['released_amount'] == null
          ? (['failed', 'cancelled'].contains(j['status'])
              ? amount - verified
              : 0)
          : requiredMoney(j['released_amount']);
  if (amount <= 0 ||
      verified < 0 ||
      remaining < 0 ||
      released < 0 ||
      verified + remaining + released != amount ||
      (j['status'] == 'succeeded' && verified != amount)) {
    throw const FinanceDataException();
  }
  final contact = financeMap(j['founder_contact']);
  return PayoutPart(
      id: textOf(j['id']),
      communityId: textOf(j['community_id']),
      communityName: textOf(j['community_name']),
      amount: amount,
      verified: verified,
      remaining: remaining,
      released: released,
      status: textOf(j['status']),
      version: money(j['version']),
      canManage: j['can_manage'] == true,
      sourceAccount: j['source_account'] is Map
          ? bankAccountFromJson(financeMap(j['source_account']))
          : null,
      founderPhone:
          contact['available'] == true ? contact['phone'] as String? : null,
      fragments: [
        for (final f in financeList(j['fragments']))
          PayoutFragment(
              id: textOf(f['id']),
              amount: requiredMoney(f['amount']),
              reference: textOf(f['bank_reference']),
              note: textOf(f['note']),
              status: textOf(f['status']),
              proofUrl: f['proof_url'] as String?,
              createdAt: textOf(f['created_at']),
              verifiedAt: f['verified_at'] as String?,
              verifiedBy: textOf(f['verified_by']))
      ],
      events: [
        for (final e in financeList(j['events']))
          PayoutEvent(textOf(e['status']), textOf(e['actor_name']),
              textOf(e['at']), textOf(e['note']))
      ]);
}
