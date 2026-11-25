import '../domain/training.dart';
import '../domain/training_repository.dart';
import 'training_models.dart';
import 'training_remote_data_source.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  const TrainingRepositoryImpl(this.remote);
  final TrainingRemoteDataSource remote;
  String _base(String id) => 'communities/$id/training';
  @override
  Future<TrainingOverview> overview(String communityId) async =>
      trainingOverviewFromJson(await remote.request('GET', _base(communityId)));
  @override
  Future<void> saveCatalog(
      String communityId, Map<String, Object?> fields) async {
    await remote.request('PUT', '${_base(communityId)}/catalog',
        fields: fields);
  }

  @override
  Future<void> saveLocation(String communityId, String? locationId,
      Map<String, Object?> fields) async {
    await remote.request(locationId == null ? 'POST' : 'PUT',
        '${_base(communityId)}/locations${locationId == null ? '' : '/$locationId'}',
        fields: fields);
  }

  @override
  Future<void> createSession(
      String communityId, Map<String, Object?> fields) async {
    await remote.request('POST', '${_base(communityId)}/sessions',
        fields: fields);
  }

  @override
  Future<void> purchase(String communityId, TrainingPackage package,
      int version, String key) async {
    await remote.request('POST', '${_base(communityId)}/purchases', fields: {
      'sessions': package.sessions,
      'expected_price': package.price,
      'catalog_version': version,
      'idempotency_key': key
    });
  }

  @override
  Future<void> checkIn(String communityId, String sessionId, String key) async {
    await remote.request(
        'POST', '${_base(communityId)}/sessions/$sessionId/check-in',
        fields: {'idempotency_key': key});
  }

  @override
  Future<void> confirm(
      String communityId, String sessionId, String memberId, String key) async {
    await remote.request(
        'POST', '${_base(communityId)}/sessions/$sessionId/confirm',
        fields: {'member_id': int.parse(memberId), 'idempotency_key': key});
  }

  @override
  Future<void> correct(String communityId, String attendanceId, String reason,
      String key) async {
    await remote.request(
        'POST', '${_base(communityId)}/attendances/$attendanceId/correct',
        fields: {'reason': reason, 'idempotency_key': key});
  }

  @override
  Future<TrainingReport> report(String communityId,
          {String? locationId,
          String? recipientMemberId,
          String? from,
          String? to}) async =>
      trainingReportFromJson(
          await remote.request('GET', '${_base(communityId)}/report', query: {
        if (locationId != null) 'location_id': locationId,
        if (recipientMemberId != null) 'recipient_member_id': recipientMemberId,
        if (from != null) 'from': from,
        if (to != null) 'to': to
      }));
}
