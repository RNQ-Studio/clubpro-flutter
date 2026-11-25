import 'training.dart';

abstract interface class TrainingRepository {
  Future<TrainingOverview> overview(String communityId);
  Future<void> saveCatalog(String communityId, Map<String, Object?> fields);
  Future<void> saveLocation(
      String communityId, String? locationId, Map<String, Object?> fields);
  Future<void> createSession(String communityId, Map<String, Object?> fields);
  Future<void> purchase(
      String communityId, TrainingPackage package, int version, String key);
  Future<void> checkIn(String communityId, String sessionId, String key);
  Future<void> confirm(
      String communityId, String sessionId, String memberId, String key);
  Future<void> correct(
      String communityId, String attendanceId, String reason, String key);
  Future<TrainingReport> report(String communityId,
      {String? locationId,
      String? recipientMemberId,
      String? from,
      String? to});
}
