import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/auth_repository_provider.dart';
import '../data/region_repository_impl.dart';
import '../domain/entities/region.dart';
import '../domain/repositories/region_repository.dart';

part 'region_providers.g.dart';

@Riverpod(keepAlive: true)
RegionRepository regionRepository(Ref ref) =>
    RegionRepositoryImpl(ref.watch(apiClientProvider).dio);

/// Provinsi beserta kabupaten/kotanya; jarang berubah, jadi dimuat sekali per
/// sesi (dipakai form komunitas dan data diri).
@Riverpod(keepAlive: true)
Future<List<RegionProvince>> indonesiaRegions(Ref ref) =>
    ref.watch(regionRepositoryProvider).getIndonesia();
