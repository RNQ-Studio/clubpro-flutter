/// Memuat ulang app dengan file terbaru dari server.
abstract interface class AppRefresher {
  /// Melempar bila file terbaru tidak bisa diunduh; app tetap berjalan.
  Future<void> refresh();
}
