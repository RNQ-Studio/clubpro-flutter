import '../domain/finance.dart';

Map<String, dynamic> financeMap(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const {};
List<Map<String, dynamic>> financeList(Object? raw) =>
    raw is List ? raw.map(financeMap).toList() : const [];
const maxSafeRupiah = 9007199254740991;
int money(Object? raw) {
  if (raw == null) return 0;
  final value = raw is int
      ? raw
      : raw is String && RegExp(r'^-?[0-9]+$').hasMatch(raw)
          ? int.tryParse(raw)
          : null;
  if (value == null || value.abs() > maxSafeRupiah) {
    throw const FinanceDataException();
  }
  return value;
}

int requiredMoney(Object? raw) {
  if (raw == null) throw const FinanceDataException();
  return money(raw);
}

String textOf(Object? raw) => raw?.toString() ?? '';

WalletSummary walletFromJson(Map<String, dynamic> j) {
  final available = requiredMoney(j['available']),
      reserved = money(j['reserved']),
      held = money(j['held']);
  final total = available + reserved + held;
  if (available < 0 ||
      reserved < 0 ||
      held < 0 ||
      total > maxSafeRupiah ||
      (j['total'] != null && money(j['total']) != total)) {
    throw const FinanceDataException();
  }
  return WalletSummary(
      available: available,
      packageReserve: reserved,
      payoutHold: held,
      identityId: textOf(j['identity_id']));
}

WalletTransaction transactionFromJson(Map<String, dynamic> j) =>
    WalletTransaction(
        id: textOf(j['id']),
        kind: textOf(j['operation']),
        amount: requiredMoney(j['amount']),
        createdAt: textOf(j['created_at']),
        communityName: textOf(j['community_id']),
        reference: textOf(j['reference']),
        actor: textOf(financeMap(j['actor'])['name']),
        postings: [
          for (final p in financeList(j['postings']))
            LedgerPosting(
                textOf(p['account'] ?? p['account_name'] ?? p['bucket']),
                money(p['amount']))
        ]);
PaymentReceipt receiptFromJson(Map<String, dynamic> j) => PaymentReceipt(
        id: textOf(j['id']),
        status: textOf(j['status']),
        claimedAmount: requiredMoney(j['claimed_amount']),
        verifiedAmount:
            j['verified_amount'] == null ? null : money(j['verified_amount']),
        communityId: textOf(j['community_id']),
        communityName: textOf(j['community_name']),
        beneficiaryName: textOf(financeMap(j['user'])['name']),
        purpose: textOf(j['purpose']),
        reference: textOf(j['bank_reference']),
        proofUrl: j['proof_url'] as String?,
        note: textOf(j['note']),
        reviewNote: textOf(j['review_note']),
        createdAt: textOf(j['created_at']),
        reviewedAt: textOf(j['reviewed_at']),
        reviewedBy: textOf(financeMap(j['reviewer'])['name']),
        canReview: j['can_review'] == true,
        collector: BillingSettings(
            bankName: textOf(financeMap(j['collector_snapshot'])['bank_name']),
            accountNumber:
                textOf(financeMap(j['collector_snapshot'])['account_number']),
            accountName:
                textOf(financeMap(j['collector_snapshot'])['account_name'])),
        verifiedReference: textOf(j['verified_reference']),
        invoiceIds: [
          for (final id in j['invoice_ids'] as List? ?? const []) '$id'
        ]);
BillingEntitlement entitlementFromJson(Map<String, dynamic> j) =>
    BillingEntitlement(
        state: textOf(j['state']),
        active: j['active'] == true,
        trialStart: j['trial_start'] as String?,
        trialEnd: j['trial_end'] as String?,
        validUntil: j['valid_until'] as String?,
        inactiveAt: j['inactive_at'] as String?,
        arrearsAmount: money(j['arrears_amount']),
        billingScheme: textOf(j['billing_scheme']));
BillingOverview billingFromJson(Map<String, dynamic> j) {
  final s = financeMap(j['settings']);
  return BillingOverview(
      scope: textOf(j['scope']),
      entitlement: entitlementFromJson(financeMap(j['entitlement'])),
      invoices: [
        for (final i in financeList(j['invoices']))
          BillingInvoice(
              id: textOf(i['id']),
              kind: textOf(i['kind']),
              periodStart: textOf(i['period_start']),
              periodEnd: textOf(i['period_end']),
              amount: money(i['amount']),
              paidAmount: money(i['paid_amount']),
              outstanding: money(i['outstanding']),
              status: textOf(i['status']),
              legacyNominalUnrecorded:
                  financeMap(i['snapshot'])['legacy_nominal_unrecorded'] ==
                      true,
              prorated: financeMap(i['snapshot'])['prorated'] == true,
              coveredDays: financeMap(i['snapshot'])['covered_days'] == null
                  ? null
                  : money(financeMap(i['snapshot'])['covered_days']),
              nominalDays: financeMap(i['snapshot'])['nominal_days'] == null
                  ? null
                  : money(financeMap(i['snapshot'])['nominal_days']),
              nominalAmount: financeMap(i['snapshot'])['nominal_amount'] == null
                  ? null
                  : money(financeMap(i['snapshot'])['nominal_amount']))
      ],
      settings: BillingSettings(
          memberAmount: money(s['member_amount']),
          entryFee: money(s['entry_fee']),
          periodMonths: money(s['period_months']),
          platformMonthlyAmount: money(s['platform_monthly_amount']),
          bankName: textOf(s['bank_name']),
          accountNumber: textOf(s['account_number']),
          accountName: textOf(s['account_name'])),
      canManage: j['can_manage'] == true,
      canConfigure: j['can_configure'] == true,
      platformActive: j['platform_active'] != false,
      notices: [
        for (final n in financeList(j['notices']))
          BillingNotice(textOf(n['id']), textOf(n['type']),
              textOf(n['message']), textOf(n['created_at']))
      ]);
}

List<InactiveSubject> inactiveFromJson(Map<String, dynamic> j) => [
      for (final m in financeList(j['members']))
        InactiveSubject(
            id: textOf(m['id']),
            name: textOf(m['name']),
            role: textOf(m['role']),
            entitlement: entitlementFromJson(financeMap(m['entitlement'])),
            reviewDue: m['review_due'] == true),
      if (j['community'] is Map)
        InactiveSubject(
            id: textOf(financeMap(j['community'])['id']),
            name: textOf(financeMap(j['community'])['name']),
            platform: true,
            reviewDue: financeMap(j['community'])['review_due'] == true,
            entitlement: entitlementFromJson(
                financeMap(financeMap(j['community'])['entitlement']))),
    ];
