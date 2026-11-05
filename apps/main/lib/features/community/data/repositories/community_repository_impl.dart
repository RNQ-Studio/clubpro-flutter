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
}
