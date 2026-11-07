import 'package:core/core.dart';

import '../../../community/domain/entities/community.dart';
import '../../domain/entities/dues.dart';

DateTime? _time(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

/// "2026-03" → 1 Maret 2026.
DateTime? duesMonthFromApi(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-');
  if (parts.length < 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  return year == null || month == null ? null : DateTime(year, month);
}

/// 1 Maret 2026 → "2026-03".
String duesMonthToApi(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';

List<DateTime> _months(Object? value) => [
      for (final item in value as List<dynamic>? ?? const [])
        if (duesMonthFromApi(item) case final month?) month,
    ];

DuesSettings duesSettingsFromJson(Map<String, dynamic> json) => DuesSettings(
      configured: json['configured'] as bool? ?? false,
      monthlyAmount: json['monthly_amount'] as int?,
      entryFee: json['entry_fee'] as int? ?? 0,
      startDate: _time(json['start_date']),
      dueDay: json['due_day'] as int?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      accountName: json['account_name'] as String?,
    );

DuesCalendar duesCalendarFromJson(Map<String, dynamic> json) => DuesCalendar(
      months: [
        for (final item in json['months'] as List<dynamic>? ?? const [])
          if (duesMonthFromApi((item as Map<String, dynamic>)['month'])
              case final month?)
            DuesMonth(
              month: month,
              status: DuesMonthStatus.fromApi(item['status']),
            ),
      ],
      billableFrom: duesMonthFromApi(json['billable_from']),
      arrearsCount: json['arrears_count'] as int? ?? 0,
      paidUntil: duesMonthFromApi(json['paid_until']),
      entryFeePaid: json['entry_fee_paid'] as bool? ?? false,
    );

DuesPayment duesPaymentFromJson(Map<String, dynamic> json) {
  final user = json['user'] as Map<String, dynamic>? ?? const {};
  return DuesPayment(
    id: json['id'].toString(),
    userId: user['id'].toString(),
    userName: user['name'] as String? ?? '',
    userAvatarUrl: user['avatar_url'] as String?,
    months: _months(json['months']),
    monthlyAmount: json['monthly_amount'] as int,
    entryFee: json['entry_fee'] as int? ?? 0,
    totalAmount: json['total_amount'] as int,
    status: DuesPaymentStatus.fromApi(json['status']),
    proofUrl: json['proof_url'] as String?,
    note: json['note'] as String?,
    reviewNote: json['review_note'] as String?,
    reviewedBy: json['reviewed_by'] as String?,
    reviewedAt: _time(json['reviewed_at']),
    createdAt: _time(json['created_at']),
  );
}

DuesOverview duesOverviewFromJson(Map<String, dynamic> json) {
  final me = json['me'] as Map<String, dynamic>?;
  return DuesOverview(
    settings: duesSettingsFromJson(json['settings'] as Map<String, dynamic>),
    year: json['year'] as int,
    canManage: json['can_manage'] as bool? ?? false,
    me: me == null
        ? null
        : MyDues(
            calendar: duesCalendarFromJson(me),
            entryFeeDue: me['entry_fee_due'] as int? ?? 0,
            nextUnpaidMonths: _months(me['next_unpaid_months']),
          ),
    payments: [
      for (final item in json['payments'] as List<dynamic>? ?? const [])
        duesPaymentFromJson(item as Map<String, dynamic>),
    ],
    pendingPaymentsCount: json['pending_payments_count'] as int?,
  );
}

MemberDues memberDuesFromJson(Map<String, dynamic> json) => MemberDues(
      userId: json['user_id'].toString(),
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: CommunityRole.fromApi(json['role']) ?? CommunityRole.member,
      joinedAt: _time(json['joined_at']),
      calendar: duesCalendarFromJson(json),
      entryFeeDue: json['entry_fee_due'] as int?,
    );

MemberDuesDetail memberDuesDetailFromJson(Map<String, dynamic> json) =>
    MemberDuesDetail(
      settings: duesSettingsFromJson(json['settings'] as Map<String, dynamic>),
      year: json['year'] as int,
      member: memberDuesFromJson(json['member'] as Map<String, dynamic>),
      payments: [
        for (final item in json['payments'] as List<dynamic>? ?? const [])
          duesPaymentFromJson(item as Map<String, dynamic>),
      ],
    );

Paged<T> pagedFromJson<T>(
  Map<String, dynamic> body,
  T Function(Map<String, dynamic>) item,
) {
  final pagination = (body['meta'] as Map<String, dynamic>?)?['pagination']
      as Map<String, dynamic>?;
  return Paged(
    items: [
      for (final row in body['data'] as List<dynamic>)
        item(row as Map<String, dynamic>),
    ],
    currentPage: pagination?['current_page'] as int? ?? 1,
    lastPage: pagination?['last_page'] as int? ?? 1,
  );
}

Map<String, Object?> duesSettingsToPayload(DuesSettingsInput input) => {
      'dues_amount': input.monthlyAmount,
      'entry_fee': input.entryFee,
      'dues_start_date': AppDateUtils.isoDate(input.startDate),
      'dues_bank_name': input.bankName.trim(),
      'dues_account_number': input.accountNumber.replaceAll(RegExp(r'\D'), ''),
      'dues_account_name': input.accountName.trim(),
    };
