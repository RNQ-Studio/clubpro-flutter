/// Kapan popup Paid Promotion terakhir tampil, per akun, di perangkat ini.
abstract interface class PromotionPopupStore {
  Future<DateTime?> lastShown(String userId);

  Future<void> markShown(String userId, DateTime at);
}
