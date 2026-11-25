import 'dart:async';
import 'package:app_main/features/training/domain/training.dart';
import 'package:app_main/features/training/domain/training_repository.dart';

TrainingAttendance attendanceFixture({String status = 'confirmed'}) =>
    TrainingAttendance(
        id: 'attendance-1',
        sessionId: '1',
        sessionTitle: 'Latihan sore',
        locationId: '1',
        locationName: 'Lapangan Utama',
        memberId: '3',
        memberName: 'Atlet Fixture',
        status: status,
        purchaseId: status == 'pending' ? '' : 'purchase-1',
        allocation: status == 'pending' ? 0 : 14286,
        createdAt: '2026-11-25T23:15:00Z',
        confirmedAt: status == 'pending' ? '' : '2026-11-25T23:16:00Z',
        confirmedBy: status == 'pending' ? '' : 'Pelatih Fixture',
        journalId: status == 'pending' ? '' : 'journal-1',
        eventId: 'event-1',
        snapshot: status == 'pending'
            ? {}
            : {
                'location_version': 2,
                'splits': [
                  {'name': 'Pelatih Fixture', 'amount': 8000},
                  {'name': 'Pengelola Fixture', 'amount': 4000}
                ],
                'residual': 2286,
                'platform_amount': 0
              });
TrainingOverview trainingFixture(
        {bool founder = true,
        bool active = true,
        bool empty = false,
        bool locationActive = true,
        bool ownPending = false,
        int catalogVersion = 2}) =>
    TrainingOverview(
        communityName: 'Komunitas Fixture',
        selfMemberId: '1',
        active: active,
        canConfigure: founder,
        canConfirm: founder,
        canReport: founder,
        catalog: TrainingCatalog(
            version: catalogVersion,
            enabled: !empty,
            packages: empty
                ? []
                : const [
                    TrainingPackage(
                        sessions: 7,
                        price: 100003,
                        sessionFloor: 14286,
                        sessionLast: 14287),
                    TrainingPackage(
                        sessions: 14,
                        price: 180005,
                        sessionFloor: 12857,
                        sessionLast: 12864),
                    TrainingPackage(
                        sessions: 21,
                        price: 250007,
                        sessionFloor: 11905,
                        sessionLast: 11907)
                  ]),
        locations: empty
            ? []
            : [
                TrainingLocation(
                    id: '1',
                    name: 'Lapangan Utama',
                    address: 'Alamat fixture komunitas',
                    active: locationActive,
                    version: 2,
                    managerIds: const ['2'],
                    splits: const [
                      TrainingSplit('2', 'Pelatih Fixture', 8000),
                      TrainingSplit('4', 'Pengelola Fixture', 4000)
                    ],
                    canConfirm: founder)
              ],
        members: empty
            ? []
            : const [
                TrainingMember('1', 'Pendiri Fixture', 'creator'),
                TrainingMember('2', 'Pelatih Fixture', 'coach'),
                TrainingMember('3', 'Atlet Fixture', 'member'),
                TrainingMember('4', 'Pengelola Fixture', 'officer')
              ],
        sessions: empty
            ? []
            : [
                TrainingSession(
                    id: '1',
                    title: 'Latihan sore',
                    locationId: '1',
                    locationName: 'Lapangan Utama',
                    startsAt: DateTime.now()
                        .toUtc()
                        .subtract(const Duration(minutes: 10))
                        .toIso8601String(),
                    endsAt: DateTime.now()
                        .toUtc()
                        .add(const Duration(hours: 2))
                        .toIso8601String(),
                    canConfirm: founder)
              ],
        purchases: empty
            ? []
            : const [
                TrainingPurchase(
                    id: 'purchase-1',
                    sessions: 7,
                    remainingSessions: 6,
                    price: 100003,
                    remainingAmount: 85717,
                    sessionFloor: 14286,
                    createdAt: '2026-11-25T23:00:00Z',
                    reservationId: 'reserve-1',
                    journalId: 'purchase-journal-1')
              ],
        attendances: empty
            ? []
            : ownPending
                ? [
                    const TrainingAttendance(
                        id: 'attendance-own',
                        sessionId: '1',
                        sessionTitle: 'Latihan sore',
                        locationId: '1',
                        locationName: 'Lapangan Utama',
                        memberId: '1',
                        memberName: 'Pendiri Fixture',
                        status: 'pending')
                  ]
                : [attendanceFixture()]);
TrainingReport reportFixture({bool recipient = false, bool empty = false}) =>
    TrainingReport(
        scope: recipient ? 'recipient' : 'community',
        purchasedAmount: recipient ? null : 100003,
        reservedAmount: recipient ? null : 85717,
        allocatedAmount: recipient ? 8000 : 14286,
        filteredAllocatedAmount: recipient ? 8000 : 14286,
        filteredAttendanceCount: 1,
        purchasedSessions: recipient ? null : 7,
        usedSessions: recipient ? null : 1,
        remainingSessions: recipient ? null : 6,
        balanced: recipient ? null : true,
        locations: empty || recipient
            ? []
            : [
                TrainingLocationRevenue(
                    '1', 'Lapangan Utama', recipient ? 8000 : 14286, 1)
              ],
        recipients: empty
            ? []
            : recipient
                ? const [TrainingRecipientRevenue('2', 'Pelatih Fixture', 8000)]
                : const [
                    TrainingRecipientRevenue('2', 'Pelatih Fixture', 8000),
                    TrainingRecipientRevenue('4', 'Pengelola Fixture', 4000),
                    TrainingRecipientRevenue(null, 'Kas komunitas', 2286)
                  ],
        purchases: recipient || empty ? [] : trainingFixture().purchases,
        attendances: empty || recipient ? [] : [attendanceFixture()]);

class FakeTraining implements TrainingRepository {
  TrainingOverview value = trainingFixture();
  TrainingReport reportValue = reportFixture();
  Object? loadError, actionError;
  Completer<void>? loadGate, actionGate;
  int loads = 0;
  final calls = <String>[],
      keys = <String>[],
      bodies = <Map<String, Object?>>[],
      filters = <Map<String, Object?>>[];
  Future<void> _load() async {
    loads++;
    await loadGate?.future;
    if (loadError != null) throw loadError!;
  }

  Future<void> _act(
      String action, String? key, Map<String, Object?> body) async {
    calls.add(action);
    if (key != null) keys.add(key);
    bodies.add(body);
    await actionGate?.future;
    if (actionError != null) throw actionError!;
  }

  @override
  Future<TrainingOverview> overview(String communityId) async {
    await _load();
    return value;
  }

  @override
  Future<void> saveCatalog(String communityId, Map<String, Object?> fields) =>
      _act('catalog', null, fields);
  @override
  Future<void> saveLocation(String communityId, String? locationId,
          Map<String, Object?> fields) =>
      _act('location:$locationId', null, fields);
  @override
  Future<void> createSession(String communityId, Map<String, Object?> fields) =>
      _act('session', fields['idempotency_key'] as String?, fields);
  @override
  Future<void> purchase(String communityId, TrainingPackage package,
          int version, String key) =>
      _act('purchase', key, {
        'sessions': package.sessions,
        'expected_price': package.price,
        'catalog_version': version
      });
  @override
  Future<void> checkIn(String communityId, String sessionId, String key) =>
      _act('checkin', key, {'session_id': sessionId});
  @override
  Future<void> confirm(
          String communityId, String sessionId, String memberId, String key) =>
      _act('confirm', key, {'session_id': sessionId, 'member_id': memberId});
  @override
  Future<void> correct(
          String communityId, String attendanceId, String reason, String key) =>
      _act('correct', key, {'attendance_id': attendanceId, 'reason': reason});
  @override
  Future<TrainingReport> report(String communityId,
      {String? locationId,
      String? recipientMemberId,
      String? from,
      String? to}) async {
    filters.add({
      'location_id': locationId,
      'recipient_member_id': recipientMemberId,
      'from': from,
      'to': to
    });
    await _load();
    return reportValue;
  }
}
