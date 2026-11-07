import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../home/presentation/home_providers.dart';
import '../domain/entities/admin_banner.dart';
import '../domain/entities/admin_community.dart';
import 'admin_community_providers.dart';
import 'admin_providers.dart';

part 'admin_banner_providers.g.dart';

class AdminBannersState {
  const AdminBannersState({
    required this.banners,
    required this.summary,
    this.isSavingOrder = false,
  });

  /// Sesuai urutan tampil di Beranda.
  final List<AdminBanner> banners;
  final AdminBannerSummary summary;
  final bool isSavingOrder;

  /// Banner tayang yang tidak muat di slider Beranda.
  Set<String> get overLimitIds {
    var live = 0;
    return {
      for (final banner in banners)
        if (banner.status == AdminBannerStatus.live &&
            ++live > summary.maxVisible)
          banner.id,
    };
  }

  AdminBanner? byId(String id) =>
      banners.where((banner) => banner.id == id).firstOrNull;
}

/// Kelola Banner. Setiap perubahan ikut menyegarkan slider Beranda.
@riverpod
class AdminBannersNotifier extends _$AdminBannersNotifier {
  @override
  Future<AdminBannersState> build() async =>
      _state(await ref.read(adminRepositoryProvider).getBanners());

  static AdminBannersState _state(AdminBanners data) =>
      AdminBannersState(banners: data.banners, summary: data.summary);

  /// Tarik untuk segarkan: daftar lama tetap tampil selama memuat.
  Future<void> refresh() async {
    final result = await AsyncValue.guard(build);
    if (ref.mounted) state = result;
  }

  /// Pindahkan [from] ke posisi [to] (indeks sesudah dipindah) lalu simpan.
  /// Gagal → urutan kembali seperti semula dan galatnya diteruskan.
  Future<void> move(int from, int to) async {
    final current = state.asData?.value;
    if (current == null || current.isSavingOrder || from == to) return;

    final banners = [...current.banners];
    banners.insert(to, banners.removeAt(from));
    state = AsyncData(AdminBannersState(
      banners: banners,
      summary: current.summary,
      isSavingOrder: true,
    ));

    try {
      final saved = await ref
          .read(adminRepositoryProvider)
          .reorderBanners([for (final banner in banners) banner.id]);
      if (!ref.mounted) return;
      state = AsyncData(_state(saved));
      _changed();
    } catch (e) {
      if (!ref.mounted) rethrow;
      state = AsyncData(current);
      // Banner ditambah atau dihapus di tempat lain: tampilkan yang terbaru.
      if (e is AdminConflictException) await refresh();
      rethrow;
    }
  }

  /// Tambah ([id] null) atau ubah banner.
  Future<AdminBanner> save(AdminBannerInput input, {String? id}) async {
    final repository = ref.read(adminRepositoryProvider);
    final banner = id == null
        ? await repository.createBanner(input)
        : await repository.updateBanner(id, input);
    if (ref.mounted) {
      await refresh();
      _changed();
    }
    return banner;
  }

  Future<void> delete(String id) async {
    await ref.read(adminRepositoryProvider).deleteBanner(id);
    if (!ref.mounted) return;
    await refresh();
    _changed();
  }

  void _changed() {
    ref.invalidate(homeBannersProvider);
    ref.invalidate(adminSummaryProvider);
  }
}
