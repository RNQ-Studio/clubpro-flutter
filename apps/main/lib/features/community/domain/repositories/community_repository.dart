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
}
