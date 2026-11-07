import 'dart:convert';
import 'dart:io';

import 'package:app_main/features/dues/data/models/dues_models.dart';
import 'package:app_main/features/dues/domain/entities/dues.dart';
import 'package:app_main/features/dues/domain/repositories/dues_repository.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
Map<String, dynamic> duesFixture(String name) => jsonDecode(
      File('test/features/dues/fixtures/$name.json').readAsStringSync(),
    ) as Map<String, dynamic>;

/// Anggota menunggak 3 bulan (Agu–Okt 2026), Mar–Mei lunas, Jun–Jul menunggu.
DuesOverview memberOverview() => duesOverviewFromJson(
    duesFixture('dues_me')['data'] as Map<String, dynamic>);

/// Creator komunitas yang sama: belum pernah membayar, ada 1 pembayaran menunggu.
DuesOverview managerOverview() => duesOverviewFromJson(
      duesFixture('dues_me_manager')['data'] as Map<String, dynamic>,
    );

const notConfigured = DuesOverview(
  settings: DuesSettings(configured: false),
  year: 2026,
);

DuesOverview overviewWith({
  bool canManage = false,
  bool configured = true,
  MyDues? me,
  int? pendingPaymentsCount,
  List<DuesPayment> payments = const [],
}) {
  final base = memberOverview();
  return DuesOverview(
    settings:
        configured ? base.settings : const DuesSettings(configured: false),
    year: base.year,
    canManage: canManage,
    me: me ?? base.me,
    payments: payments,
    pendingPaymentsCount: pendingPaymentsCount,
  );
}

List<DuesPayment> pendingPayments() => pagedFromJson(
      duesFixture('dues_payments_pending'),
      duesPaymentFromJson,
    ).items;

MemberDuesDetail memberDetail() => memberDuesDetailFromJson(
      duesFixture('dues_member')['data'] as Map<String, dynamic>,
    );

List<MemberDues> membersPage() =>
    pagedFromJson(duesFixture('dues_members'), memberDuesFromJson).items;

class FakeDuesRepository implements DuesRepository {
  FakeDuesRepository({
    DuesOverview? overview,
    this.payments = const [],
    this.members = const [],
    this.member,
  }) : overview = overview ?? memberOverview();

  DuesOverview overview;
  List<DuesPayment> payments;
  List<MemberDues> members;
  MemberDuesDetail? member;

  /// Melempar pada tindakan berikutnya, satu kali.
  Exception? actionError;

  /// Melempar pada pengambilan ringkasan, bila diisi.
  Exception? overviewError;

  /// Tindakan yang sampai ke server, mis. `month:2:2026-08:paid`.
  final actions = <String>[];
  final overviewYears = <int?>[];
  final memberSearches = <String>[];
  DuesSettingsInput? savedSettings;
  ({int monthsCount, String proofAssetId, String? note})? paid;

  void _record(String action) {
    final failure = actionError;
    if (failure != null) {
      actionError = null;
      throw failure;
    }
    actions.add(action);
  }

  @override
  Future<DuesOverview> getOverview(String communityId, {int? year}) async {
    overviewYears.add(year);
    final failure = overviewError;
    if (failure != null) throw failure;
    return overview;
  }

  @override
  Future<DuesSettings> saveSettings(
    String communityId,
    DuesSettingsInput input,
  ) async {
    _record('settings');
    savedSettings = input;
    return overview.settings;
  }

  @override
  Future<DuesPayment> pay(
    String communityId, {
    required int monthsCount,
    required String proofAssetId,
    String? note,
  }) async {
    _record('pay');
    paid = (monthsCount: monthsCount, proofAssetId: proofAssetId, note: note);
    final months = overview.me!.nextUnpaidMonths.take(monthsCount).toList();
    final monthly = overview.settings.monthlyAmount!;
    return DuesPayment(
      id: '99',
      userId: '2',
      userName: 'Budi Santoso',
      months: months,
      monthlyAmount: monthly,
      entryFee: overview.me!.entryFeeDue,
      totalAmount: monthly * monthsCount + overview.me!.entryFeeDue,
      status: DuesPaymentStatus.pending,
    );
  }

  @override
  Future<Paged<DuesPayment>> getPayments(
    String communityId, {
    required int page,
    DuesPaymentStatus? status,
  }) async =>
      Paged(
        items: [
          for (final p in payments)
            if (status == null || p.status == status) p,
        ],
        currentPage: 1,
        lastPage: 1,
      );

  @override
  Future<DuesPayment> approve(String communityId, String paymentId) async {
    _record('approve:$paymentId');
    payments = [
      for (final p in payments)
        if (p.id != paymentId) p,
    ];
    return pendingPayments().first;
  }

  @override
  Future<DuesPayment> reject(
    String communityId,
    String paymentId,
    String note,
  ) async {
    _record('reject:$paymentId:$note');
    payments = [
      for (final p in payments)
        if (p.id != paymentId) p,
    ];
    return pendingPayments().first;
  }

  @override
  Future<Paged<MemberDues>> getMembers(
    String communityId, {
    required int year,
    required int page,
    String search = '',
  }) async {
    memberSearches.add(search);
    return Paged(
      items: [
        for (final m in members)
          if (m.name.toLowerCase().contains(search.toLowerCase())) m,
      ],
      currentPage: 1,
      lastPage: 1,
    );
  }

  @override
  Future<MemberDuesDetail> getMember(
    String communityId,
    String userId, {
    required int year,
  }) async =>
      member!;

  @override
  Future<void> setMonth(
    String communityId,
    String userId,
    DateTime month, {
    required bool paid,
  }) async =>
      _record('month:$userId:${duesMonthToApi(month)}:'
          '${paid ? 'paid' : 'unpaid'}');

  @override
  Future<void> setEntryFee(
    String communityId,
    String userId, {
    required bool paid,
  }) async =>
      _record('entry-fee:$userId:${paid ? 'paid' : 'unpaid'}');
}
