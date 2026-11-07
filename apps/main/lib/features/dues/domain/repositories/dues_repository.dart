import '../entities/dues.dart';

abstract interface class DuesRepository {
  Future<DuesOverview> getOverview(String communityId, {int? year});

  Future<DuesSettings> saveSettings(
      String communityId, DuesSettingsInput input);

  Future<DuesPayment> pay(
    String communityId, {
    required int monthsCount,
    required String proofAssetId,
    String? note,
  });

  Future<Paged<DuesPayment>> getPayments(
    String communityId, {
    required int page,
    DuesPaymentStatus? status,
  });

  Future<DuesPayment> approve(String communityId, String paymentId);

  Future<DuesPayment> reject(String communityId, String paymentId, String note);

  Future<Paged<MemberDues>> getMembers(
    String communityId, {
    required int year,
    required int page,
    String search = '',
  });

  Future<MemberDuesDetail> getMember(
    String communityId,
    String userId, {
    required int year,
  });

  Future<void> setMonth(
    String communityId,
    String userId,
    DateTime month, {
    required bool paid,
  });

  Future<void> setEntryFee(
    String communityId,
    String userId, {
    required bool paid,
  });
}
