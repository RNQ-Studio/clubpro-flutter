class DirectoryItem {
  const DirectoryItem(this.id, this.name, this.subtitle,
      {this.communityId,
      this.description = '',
      this.role = '',
      this.membershipId});
  final String id, name, subtitle, description, role;
  final String? communityId, membershipId;
}

class DirectoryPage {
  const DirectoryPage(this.items, this.page, this.lastPage);
  final List<DirectoryItem> items;
  final int page, lastPage;
}

abstract interface class DirectoryRepository {
  Future<DirectoryPage> search(
      {required bool members,
      String search = '',
      String? communityId,
      String? role,
      int page = 1});
  Future<DirectoryItem> community(String id);
  Future<List<Map<String, dynamic>>> internalMembers(String communityId,
      {String search = '',
      String? role,
      String status = 'active',
      int page = 1});
  Future<Map<String, dynamic>> createMember(
      String communityId, Map<String, Object?> fields);
  Future<Map<String, dynamic>> memberDetail(
      String communityId, String memberId);
  Future<void> editMember(
      String communityId, String memberId, Map<String, Object?> fields);
  Future<void> invite(String communityId, String memberId, String email,
      {required bool account});
  Future<List<Map<String, dynamic>>> invitations();
  Future<void> sendEmailVerification();
  Future<void> claim(String id, String token, {bool accept = false});
  Future<List<Map<String, dynamic>>> dependents();
  Future<Map<String, dynamic>> dependent(String id);
  Future<void> updateDependent(String id, Map<String, Object?> fields);
  Future<void> revoke(String grantId);
  Future<Map<String, dynamic>> card(String identityId, String memberId);
  Future<void> updateCommunity(String id, Map<String, Object?> fields);
}
