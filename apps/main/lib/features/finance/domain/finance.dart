/// Integer rupiah throughout; points are intentionally not represented here.
class WalletSummary {
  const WalletSummary(
      {this.available = 0,
      this.packageReserve = 0,
      this.payoutHold = 0,
      this.identityId = ''});
  final int available, packageReserve, payoutHold;
  final String identityId;
  int get total => available + packageReserve + payoutHold;
}

class FinancePage<T> {
  const FinancePage(this.items, {this.page = 1, this.lastPage = 1});
  final List<T> items;
  final int page, lastPage;
  bool get hasMore => page < lastPage;
}

class WalletTransaction {
  const WalletTransaction(
      {required this.id,
      required this.kind,
      required this.amount,
      required this.createdAt,
      this.communityName = '',
      this.reference = '',
      this.actor = '',
      this.postings = const []});
  final String id, kind, createdAt, communityName, reference, actor;
  final int amount;
  final List<LedgerPosting> postings;
}

class LedgerPosting {
  const LedgerPosting(this.account, this.amount);
  final String account;
  final int amount;
}

class PaymentReceipt {
  const PaymentReceipt(
      {required this.id,
      required this.status,
      required this.claimedAmount,
      this.verifiedAmount,
      this.communityId = '',
      this.communityName = '',
      this.beneficiaryName = '',
      this.purpose = 'topup',
      this.reference = '',
      this.proofUrl,
      this.note = '',
      this.reviewNote = '',
      this.createdAt = '',
      this.reviewedAt = '',
      this.reviewedBy = '',
      this.canReview = false,
      this.collector = const BillingSettings(),
      this.verifiedReference = '',
      this.invoiceIds = const []});
  final String id,
      status,
      communityId,
      communityName,
      beneficiaryName,
      purpose,
      reference,
      note,
      reviewNote,
      createdAt,
      reviewedAt,
      reviewedBy;
  final String? proofUrl;
  final int claimedAmount;
  final int? verifiedAmount;
  final bool canReview;
  final BillingSettings collector;
  final String verifiedReference;
  final List<String> invoiceIds;
}

class BillingEntitlement {
  const BillingEntitlement(
      {required this.state,
      required this.active,
      this.trialStart,
      this.trialEnd,
      this.validUntil,
      this.inactiveAt,
      this.arrearsAmount = 0,
      this.billingScheme = ''});
  final String state, billingScheme;
  final bool active;
  final String? trialStart, trialEnd, validUntil, inactiveAt;
  final int arrearsAmount;
  String get label => switch (state) {
        'trial' => 'Masa gratis',
        'active' => 'Aktif',
        'exempt' => 'Bebas iuran',
        'archived' => 'Diarsipkan',
        _ => 'Tidak aktif',
      };
}

class BillingInvoice {
  const BillingInvoice(
      {required this.id,
      required this.kind,
      required this.periodStart,
      required this.periodEnd,
      required this.amount,
      required this.paidAmount,
      required this.outstanding,
      required this.status,
      this.legacyNominalUnrecorded = false,
      this.prorated = false,
      this.coveredDays,
      this.nominalDays,
      this.nominalAmount});
  final bool legacyNominalUnrecorded;
  final bool prorated;
  final int? coveredDays, nominalDays, nominalAmount;
  final String id, kind, periodStart, periodEnd, status;
  final int amount, paidAmount, outstanding;
  bool get hasProrationDetails =>
      prorated &&
      (coveredDays ?? 0) > 0 &&
      (nominalDays ?? 0) > 0 &&
      coveredDays! <= nominalDays! &&
      (nominalAmount ?? 0) > 0;
  String get label => switch (kind) {
        'entry' => 'Uang pendaftaran',
        'platform' => 'Langganan komunitas',
        _ => 'Iuran anggota',
      };
}

class BillingSettings {
  const BillingSettings(
      {this.memberAmount = 0,
      this.entryFee = 0,
      this.periodMonths = 1,
      this.platformMonthlyAmount = 100000,
      this.bankName = '',
      this.accountNumber = '',
      this.accountName = ''});
  final int memberAmount, entryFee, periodMonths, platformMonthlyAmount;
  final String bankName, accountNumber, accountName;
}

class BillingNotice {
  const BillingNotice(this.id, this.type, this.message, this.createdAt,
      {this.readAt,
      this.communityId = '',
      this.subjectKind = 'member',
      this.memberId});
  final String id, type, message, createdAt, communityId, subjectKind;
  final String? readAt, memberId;
}

class BillingOverview {
  const BillingOverview(
      {required this.scope,
      required this.entitlement,
      this.invoices = const [],
      this.settings = const BillingSettings(),
      this.canManage = false,
      this.canConfigure = false,
      this.platformActive = true,
      this.notices = const []});
  final String scope;
  final BillingEntitlement entitlement;
  final List<BillingInvoice> invoices;
  final BillingSettings settings;
  final bool canManage, canConfigure, platformActive;
  final List<BillingNotice> notices;
  int get outstanding => invoices.fold(0, (sum, i) => sum + i.outstanding);
}

class InactiveSubject {
  const InactiveSubject(
      {required this.id,
      required this.name,
      required this.entitlement,
      this.role = '',
      this.reviewDue = false,
      this.platform = false});
  final String id, name, role;
  final BillingEntitlement entitlement;
  final bool reviewDue, platform;
}

class BillingNoticeFeed {
  const BillingNoticeFeed(this.items, this.unreadCount);
  final List<BillingNotice> items;
  final int unreadCount;
}

class FinanceConflictException implements Exception {
  const FinanceConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FinanceDataException implements Exception {
  const FinanceDataException();
  @override
  String toString() =>
      'Data nominal dari server tidak valid. Muat ulang sebelum melanjutkan pembayaran.';
}

class FinanceAuthenticationException implements Exception {
  const FinanceAuthenticationException();
  @override
  String toString() => 'Sesi berakhir. Silakan masuk kembali.';
}
