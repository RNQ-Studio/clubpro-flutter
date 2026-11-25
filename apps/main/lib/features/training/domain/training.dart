/// Training funds are integer rupiah; packages never expire by default.
class TrainingPackage {
  const TrainingPackage(
      {required this.sessions,
      required this.price,
      required this.sessionFloor,
      required this.sessionLast});
  final int sessions, price, sessionFloor, sessionLast;
}

class TrainingCatalog {
  const TrainingCatalog(
      {this.version = 0, this.enabled = false, this.packages = const []});
  final int version;
  final bool enabled;
  final List<TrainingPackage> packages;
}

class TrainingMember {
  const TrainingMember(this.id, this.name, this.role);
  final String id, name, role;
  bool get canManage => ['creator', 'admin', 'officer', 'coach'].contains(role);
}

class TrainingSplit {
  const TrainingSplit(this.memberId, this.name, this.amount);
  final String memberId, name;
  final int amount;
}

class TrainingLocation {
  const TrainingLocation(
      {required this.id,
      required this.name,
      this.address = '',
      this.active = true,
      this.version = 0,
      this.managerIds = const [],
      this.splits = const [],
      this.canConfirm = false});
  final String id, name, address;
  final bool active, canConfirm;
  final int version;
  final List<String> managerIds;
  final List<TrainingSplit> splits;
  int get splitTotal => splits.fold(0, (sum, s) => sum + s.amount);
}

class TrainingSession {
  const TrainingSession(
      {required this.id,
      required this.title,
      required this.locationId,
      required this.locationName,
      required this.startsAt,
      required this.endsAt,
      this.canConfirm = false});
  final String id, title, locationId, locationName, startsAt, endsAt;
  final bool canConfirm;
  bool get isOpen {
    final start = DateTime.tryParse(startsAt), end = DateTime.tryParse(endsAt);
    final now = DateTime.now().toUtc();
    return start != null &&
        end != null &&
        !now.isBefore(start) &&
        now.isBefore(end);
  }
}

class TrainingPurchase {
  const TrainingPurchase(
      {required this.id,
      required this.sessions,
      required this.remainingSessions,
      required this.price,
      required this.remainingAmount,
      required this.sessionFloor,
      this.createdAt = '',
      this.reservationId = '',
      this.journalId = ''});
  final String id, createdAt, reservationId, journalId;
  final int sessions, remainingSessions, price, remainingAmount, sessionFloor;
  int get usedSessions => sessions - remainingSessions;
}

class TrainingAttendance {
  const TrainingAttendance(
      {required this.id,
      required this.sessionId,
      required this.sessionTitle,
      required this.locationId,
      required this.locationName,
      required this.memberId,
      required this.memberName,
      required this.status,
      this.purchaseId = '',
      this.allocation = 0,
      this.createdAt = '',
      this.confirmedAt = '',
      this.confirmedBy = '',
      this.journalId = '',
      this.eventId = '',
      this.correctionReason = '',
      this.correctedAt = '',
      this.correctedBy = '',
      this.correctionJournalId = '',
      this.snapshot = const {}});
  final String id,
      sessionId,
      sessionTitle,
      locationId,
      locationName,
      memberId,
      memberName,
      status,
      purchaseId,
      createdAt,
      confirmedAt,
      confirmedBy,
      journalId,
      eventId,
      correctionReason,
      correctedAt,
      correctedBy,
      correctionJournalId;
  final int allocation;
  final Map<String, Object?> snapshot;
  String get statusLabel => switch (status) {
        'pending' => 'Menunggu konfirmasi',
        'confirmed' => 'Terkonfirmasi',
        'corrected' => 'Dikoreksi teknis',
        _ => 'Status belum dikenali'
      };
}

class TrainingOverview {
  const TrainingOverview(
      {this.communityName = '',
      this.selfMemberId = '',
      this.active = false,
      this.canConfigure = false,
      this.canConfirm = false,
      this.canReport = false,
      this.catalog = const TrainingCatalog(),
      this.locations = const [],
      this.members = const [],
      this.sessions = const [],
      this.purchases = const [],
      this.attendances = const []});
  final String communityName, selfMemberId;
  final bool active, canConfigure, canConfirm, canReport;
  final TrainingCatalog catalog;
  final List<TrainingLocation> locations;
  final List<TrainingMember> members;
  final List<TrainingSession> sessions;
  final List<TrainingPurchase> purchases;
  final List<TrainingAttendance> attendances;
}

class TrainingLocationRevenue {
  const TrainingLocationRevenue(
      this.id, this.name, this.amount, this.attendances);
  final String id, name;
  final int amount, attendances;
}

class TrainingRecipientRevenue {
  const TrainingRecipientRevenue(this.memberId, this.name, this.amount);
  final String? memberId;
  final String name;
  final int amount;
}

class TrainingReport {
  const TrainingReport(
      {this.scope = 'community',
      this.purchasedAmount,
      this.reservedAmount,
      this.allocatedAmount = 0,
      this.filteredAllocatedAmount = 0,
      this.filteredAttendanceCount = 0,
      this.purchasedSessions,
      this.usedSessions,
      this.remainingSessions,
      this.balanced,
      this.locations = const [],
      this.recipients = const [],
      this.purchases = const [],
      this.attendances = const []});
  final String scope;
  final int? purchasedAmount,
      reservedAmount,
      purchasedSessions,
      usedSessions,
      remainingSessions;
  final int allocatedAmount, filteredAllocatedAmount, filteredAttendanceCount;
  final bool? balanced;
  final List<TrainingLocationRevenue> locations;
  final List<TrainingRecipientRevenue> recipients;
  final List<TrainingPurchase> purchases;
  final List<TrainingAttendance> attendances;
}
