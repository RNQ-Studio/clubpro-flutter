import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/banner_remote_data_source.dart';
import '../domain/entities/home_banner.dart';

part 'home_providers.g.dart';

/// Banner bawaan bila admin belum memasang banner atau server tak terjangkau.
const defaultHomeBanners = [
  HomeBanner(
    id: 'default-welcome',
    title: 'Selamat datang di Anak Langit Archery',
    subtitle: 'Aplikasi resmi anggota club panahan Anak Langit.',
  ),
  HomeBanner(
    id: 'default-profile',
    title: 'Lengkapi data diri Anda',
    subtitle: 'Bantu pengurus club mendata anggota lewat halaman Profil.',
    linkUrl: AppRoutes.profile,
  ),
  HomeBanner(
    id: 'default-schedule',
    title: 'Jadwal latihan & absensi',
    subtitle: 'Segera hadir: pantau jadwal dan catat kehadiran dari aplikasi.',
  ),
];

@riverpod
BannerRemoteDataSource bannerRemoteDataSource(Ref ref) =>
    BannerRemoteDataSource(ref.watch(apiClientProvider).dio);

@riverpod
Future<List<HomeBanner>> homeBanners(Ref ref) async {
  try {
    final banners =
        await ref.watch(bannerRemoteDataSourceProvider).fetchBanners();
    return banners.isEmpty ? defaultHomeBanners : banners;
  } catch (_) {
    // Offline / server lama: Beranda tetap punya slider.
    return defaultHomeBanners;
  }
}
