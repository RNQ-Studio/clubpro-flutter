import '../entities/community.dart';
import '../entities/community_draft.dart';

abstract interface class CommunityRepository {
  Future<CommunitiesPage> getCommunities({
    required int page,
    String search = '',
    String? type,
  });

  Future<List<Community>> getMine();

  Future<CommunityDetail> getCommunity(String id);

  Future<List<CommunityTypeOption>> getTypes();

  Future<List<RegionProvince>> getRegions();

  /// Unggah satu foto, mengembalikan id asetnya.
  Future<String> uploadImage(CommunityImage image, {required String category});

  Future<CommunityDetail> submit(CommunityDraft draft);

  /// Komunitas yang diikuti pengguna yang login.
  Future<List<Community>> getJoined();

  Future<void> join(String communityId);

  /// Keluar, atau membatalkan permintaan bergabung.
  Future<void> leave(String communityId);

  Future<CommunityMembersPage> getMembers(
    String communityId, {
    required int page,
    bool pending = false,
  });

  Future<void> approveMember(String communityId, String memberId);

  Future<void> setMemberRole(
    String communityId,
    String memberId,
    CommunityRole role,
  );

  /// Mengeluarkan anggota atau menolak permintaan bergabung.
  Future<void> removeMember(String communityId, String memberId);

  Future<CommunityActivities> getActivities(String communityId);

  Future<void> createActivity(String communityId, CommunityActivityInput input);

  Future<void> updateActivity(
    String communityId,
    String activityId,
    CommunityActivityInput input,
  );

  Future<void> deleteActivity(String communityId, String activityId);

  Future<void> addPhoto(String communityId, String assetId);

  Future<void> removePhoto(String communityId, String assetId);

  Future<CommunityMemberProfile> getMemberProfile(String userId);
}
