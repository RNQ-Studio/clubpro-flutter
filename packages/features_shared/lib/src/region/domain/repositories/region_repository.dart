import '../entities/region.dart';

abstract interface class RegionRepository {
  /// Seluruh provinsi Indonesia beserta kabupaten/kotanya.
  Future<List<RegionProvince>> getIndonesia();
}
