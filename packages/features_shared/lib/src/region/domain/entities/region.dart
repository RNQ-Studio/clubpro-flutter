/// Kabupaten/kota Indonesia (kode Kemendagri, mis. `32.73` Kota Bandung).
class RegionCity {
  const RegionCity({required this.code, required this.name});

  final String code;
  final String name;

  @override
  bool operator ==(Object other) => other is RegionCity && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Provinsi beserta kabupaten/kotanya (kode Kemendagri, mis. `32` Jawa Barat).
class RegionProvince {
  const RegionProvince({
    required this.code,
    required this.name,
    required this.cities,
  });

  final String code;
  final String name;
  final List<RegionCity> cities;

  RegionCity? city(String? code) =>
      cities.where((c) => c.code == code).firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is RegionProvince && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

extension RegionProvinceList on List<RegionProvince> {
  RegionProvince? byCode(String? code) =>
      where((p) => p.code == code).firstOrNull;
}
