import '../../domain/entities/dues.dart';
import '../../domain/repositories/dues_repository.dart';
import '../datasources/dues_remote_data_source.dart';

class DuesRepositoryImpl implements DuesRepository {
  const DuesRepositoryImpl(this._remote);

  final DuesRemoteDataSource _remote;

  @override
  Future<DuesOverview> getOverview(String communityId, {int? year}) =>
      _remote.fetchOverview(communityId, year: year);

  @override
  Future<DuesSettings> saveSettings(
    String communityId,
    DuesSettingsInput input,
  ) =>
      _remote.saveSettings(communityId, input);

  @override
  Future<DuesPayment> pay(
    String communityId, {
    required int monthsCount,
    required String proofAssetId,
    String? note,
  }) =>
      _remote.pay(
        communityId,
        monthsCount: monthsCount,
        proofAssetId: proofAssetId,
        note: note,
      );

  @override
  Future<Paged<DuesPayment>> getPayments(
    String communityId, {
    required int page,
    DuesPaymentStatus? status,
  }) =>
      _remote.fetchPayments(communityId, page: page, status: status);

  @override
  Future<DuesPayment> approve(String communityId, String paymentId) =>
      _remote.approve(communityId, paymentId);

  @override
  Future<DuesPayment> reject(
    String communityId,
    String paymentId,
    String note,
  ) =>
      _remote.reject(communityId, paymentId, note);

  @override
  Future<Paged<MemberDues>> getMembers(
    String communityId, {
    required int year,
    required int page,
    String search = '',
  }) =>
      _remote.fetchMembers(
        communityId,
        year: year,
        page: page,
        search: search,
      );

  @override
  Future<MemberDuesDetail> getMember(
    String communityId,
    String userId, {
    required int year,
  }) =>
      _remote.fetchMember(communityId, userId, year: year);

  @override
  Future<void> setMonth(
    String communityId,
    String userId,
    DateTime month, {
    required bool paid,
  }) =>
      _remote.setMonth(communityId, userId, month, paid: paid);

  @override
  Future<void> setEntryFee(
    String communityId,
    String userId, {
    required bool paid,
  }) =>
      _remote.setEntryFee(communityId, userId, paid: paid);
}
