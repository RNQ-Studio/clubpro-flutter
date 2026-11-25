import '../../finance/data/finance_models.dart';
import '../../finance/domain/finance.dart';
import '../domain/training.dart';

int _nonnegative(Object? value) {
  final result = requiredMoney(value);
  if (result < 0) throw const FinanceDataException();
  return result;
}

TrainingPackage trainingPackageFromJson(Map<String, dynamic> j) {
  final sessions = _nonnegative(j['sessions']),
      price = _nonnegative(j['price']);
  final floor = _nonnegative(j['session_floor']),
      last = _nonnegative(j['session_last']);
  if (![7, 14, 21].contains(sessions) ||
      price < sessions ||
      floor != price ~/ sessions ||
      last != price - floor * (sessions - 1)) {
    throw const FinanceDataException();
  }
  return TrainingPackage(
      sessions: sessions, price: price, sessionFloor: floor, sessionLast: last);
}

TrainingCatalog trainingCatalogFromJson(Map<String, dynamic> j) =>
    TrainingCatalog(
        version: money(j['version']),
        enabled: j['enabled'] == true,
        packages: [
          for (final p in financeList(j['packages'])) trainingPackageFromJson(p)
        ]);
TrainingLocation trainingLocationFromJson(Map<String, dynamic> j) =>
    TrainingLocation(
        id: textOf(j['id']),
        name: textOf(j['name']),
        address: textOf(j['address']),
        active: j['active'] == true,
        version: money(j['version']),
        canConfirm: j['can_confirm'] == true,
        managerIds: [
          for (final id in j['manager_member_ids'] as List? ?? []) '$id'
        ],
        splits: [
          for (final s in financeList(j['splits']))
            TrainingSplit(textOf(s['member_id']), textOf(s['name']),
                _nonnegative(s['amount']))
        ]);
TrainingSession trainingSessionFromJson(Map<String, dynamic> j) =>
    TrainingSession(
        id: textOf(j['id']),
        title: textOf(j['title']),
        locationId: textOf(j['location_id']),
        locationName: textOf(j['location_name']),
        startsAt: textOf(j['starts_at']),
        endsAt: textOf(j['ends_at']),
        canConfirm: j['can_confirm'] == true);
TrainingPurchase trainingPurchaseFromJson(Map<String, dynamic> j) {
  final sessions = _nonnegative(j['sessions']),
      remaining = _nonnegative(j['remaining_sessions']);
  final price = _nonnegative(j['price']),
      amount = _nonnegative(j['remaining_amount']),
      floor = _nonnegative(j['session_floor']);
  if (![7, 14, 21].contains(sessions) ||
      price < sessions ||
      remaining > sessions ||
      floor != price ~/ sessions ||
      amount > price ||
      (remaining == 0
          ? amount != 0
          : amount != price - floor * (sessions - remaining))) {
    throw const FinanceDataException();
  }
  return TrainingPurchase(
      id: textOf(j['id']),
      sessions: sessions,
      remainingSessions: remaining,
      price: price,
      remainingAmount: amount,
      sessionFloor: floor,
      createdAt: textOf(j['created_at']),
      reservationId: textOf(j['reservation_id']),
      journalId: textOf(j['journal_id']));
}

TrainingAttendance trainingAttendanceFromJson(Map<String, dynamic> j) =>
    TrainingAttendance(
        id: textOf(j['id']),
        sessionId: textOf(j['session_id']),
        sessionTitle: textOf(j['session_title']),
        locationId: textOf(j['location_id']),
        locationName: textOf(j['location_name']),
        memberId: textOf(j['member_id']),
        memberName: textOf(j['member_name']),
        status: textOf(j['status']),
        purchaseId: textOf(j['purchase_id']),
        allocation: _nonnegative(j['allocation']),
        createdAt: textOf(j['created_at']),
        confirmedAt: textOf(j['confirmed_at']),
        confirmedBy: textOf(j['confirmed_by']),
        journalId: textOf(j['journal_id']),
        eventId: textOf(j['event_id']),
        correctionReason: textOf(j['correction_reason']),
        correctedAt: textOf(j['corrected_at']),
        correctedBy: textOf(j['corrected_by_name'] ?? j['corrected_by']),
        correctionJournalId: textOf(j['correction_journal_id']),
        snapshot: financeMap(j['snapshot']));
TrainingOverview trainingOverviewFromJson(Map<String, dynamic> j) =>
    TrainingOverview(
        communityName: textOf(j['community_name']),
        selfMemberId: textOf(j['self_member_id']),
        active: j['active'] == true,
        canConfigure: j['can_configure'] == true,
        canConfirm: j['can_confirm'] == true,
        canReport: j['can_report'] == true,
        catalog: trainingCatalogFromJson(financeMap(j['catalog'])),
        locations: [
          for (final l in financeList(j['locations']))
            trainingLocationFromJson(l)
        ],
        members: [
          for (final m in financeList(j['members']))
            TrainingMember(
                textOf(m['id']), textOf(m['name']), textOf(m['role']))
        ],
        sessions: [
          for (final s in financeList(j['sessions'])) trainingSessionFromJson(s)
        ],
        purchases: [
          for (final p in financeList(j['purchases']))
            trainingPurchaseFromJson(p)
        ],
        attendances: [
          for (final a in financeList(j['attendances']))
            trainingAttendanceFromJson(a)
        ]);
TrainingReport trainingReportFromJson(Map<String, dynamic> j) {
  final t = financeMap(j['totals']);
  int? optional(String k) => t[k] == null ? null : _nonnegative(t[k]);
  return TrainingReport(
      scope: textOf(j['scope']),
      purchasedAmount: optional('purchased_amount'),
      reservedAmount: optional('reserved_amount'),
      allocatedAmount: _nonnegative(t['allocated_amount']),
      filteredAllocatedAmount: _nonnegative(t['filtered_allocated_amount']),
      filteredAttendanceCount: _nonnegative(t['filtered_attendance_count']),
      purchasedSessions: optional('purchased_sessions'),
      usedSessions: optional('used_sessions'),
      remainingSessions: optional('remaining_sessions'),
      balanced: t['balanced'] as bool?,
      locations: [
        for (final l in financeList(j['locations']))
          TrainingLocationRevenue(
              textOf(l['location_id']),
              textOf(l['location_name']),
              _nonnegative(l['allocated_amount']),
              _nonnegative(l['attendance_count']))
      ],
      recipients: [
        for (final r in financeList(j['recipients']))
          TrainingRecipientRevenue(r['member_id']?.toString(),
              textOf(r['name']), _nonnegative(r['amount']))
      ],
      purchases: [
        for (final p in financeList(j['purchases'])) trainingPurchaseFromJson(p)
      ],
      attendances: [
        for (final a in financeList(j['attendances']))
          trainingAttendanceFromJson(a)
      ]);
}
