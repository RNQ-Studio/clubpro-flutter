import '../../domain/entities/community.dart';
import '../../domain/entities/community_draft.dart';
import '../../domain/repositories/community_repository.dart';
import '../datasources/community_remote_data_source.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl(this._remote);

  final CommunityRemoteDataSource _remote;

  @override
  Future<CommunitiesPage> getCommunities({
    required int page,
    String search = '',
    String? type,
  }) =>
      _remote.fetchCommunities(page: page, search: search, type: type);

  @override
  Future<List<Community>> getMine() => _remote.fetchMine();

  @override
  Future<CommunityDetail> getCommunity(String id) => _remote.fetchCommunity(id);

  @override
  Future<List<CommunityTypeOption>> getTypes() => _remote.fetchTypes();

  @override
  Future<List<RegionProvince>> getRegions() => _remote.fetchRegions();

  @override
  Future<String> uploadImage(
    CommunityImage image, {
    required String category,
  }) =>
      _remote.uploadImage(image, category: category);

  @override
  Future<CommunityDetail> submit(CommunityDraft draft) =>
      _remote.submit(draft.toPayload());

  @override
  Future<List<Community>> getJoined() => _remote.fetchJoined();

  @override
  Future<void> join(String communityId) => _remote.join(communityId);

  @override
  Future<void> leave(String communityId) => _remote.leave(communityId);

  @override
  Future<CommunityMembersPage> getMembers(
    String communityId, {
    required int page,
    bool pending = false,
  }) =>
      _remote.fetchMembers(communityId, page: page, pending: pending);

  @override
  Future<void> approveMember(String communityId, String memberId) =>
      _remote.approveMember(communityId, memberId);

  @override
  Future<void> setMemberRole(
    String communityId,
    String memberId,
    CommunityRole role,
  ) =>
      _remote.setMemberRole(communityId, memberId, role);

  @override
  Future<void> removeMember(String communityId, String memberId) =>
      _remote.removeMember(communityId, memberId);

  @override
  Future<CommunityActivities> getActivities(String communityId) =>
      _remote.fetchActivities(communityId);

  @override
  Future<void> createActivity(
    String communityId,
    CommunityActivityInput input,
  ) =>
      _remote.createActivity(communityId, input.toPayload());

  @override
  Future<void> updateActivity(
    String communityId,
    String activityId,
    CommunityActivityInput input,
  ) =>
      _remote.updateActivity(communityId, activityId, input.toPayload());

  @override
  Future<void> deleteActivity(String communityId, String activityId) =>
      _remote.deleteActivity(communityId, activityId);

  @override
  Future<void> addPhoto(String communityId, String assetId) =>
      _remote.addPhoto(communityId, assetId);

  @override
  Future<void> removePhoto(String communityId, String assetId) =>
      _remote.removePhoto(communityId, assetId);

  @override
  Future<CommunityMemberProfile> getMemberProfile(String userId) =>
      _remote.fetchMemberProfile(userId);
}
