/// Komunitas yang terakhir dipilih untuk Beranda, per akun, di perangkat ini.
abstract interface class ActiveCommunityStore {
  Future<String?> read(String userId);

  Future<void> write(String userId, String communityId);
}
