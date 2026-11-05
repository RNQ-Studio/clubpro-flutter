import 'dart:convert';
import 'dart:typed_data';

import 'package:app_main/features/community/data/community_image_picker.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:app_main/features/community/domain/repositories/community_repository.dart';

/// PNG 16×16 bergradasi emas.
final testImageBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAmklEQVR42mOIsWKKt2FKsm'
  'dOdWTOdGHJcWfN92Qt8mEr82OvDGSvCeGoD+NojuRsi+bqjOPqTeRmIEn1hGQeBpJUT07j'
  'YSBJ9bQMXgaSVM/K5mMgSfXcPD4GklQvKOBnIEn14mJ+BpJULy8VYCBJ9aoKQQaSVK+tFm'
  'QgSfWGWiEGklRvaRBmIEn19iZhBpJU72oVYSBJ9b4OUQCAbPgltql/LAAAAABJRU5ErkJg'
  'gg==',
);

CommunityImage testImage([String name = 'foto.png']) => CommunityImage(
      bytes: Uint8List.fromList(testImageBytes),
      filename: name,
      mimeType: 'image/png',
    );

const testTypes = [
  CommunityTypeOption(value: 'panahan', label: 'Panahan'),
  CommunityTypeOption(value: 'sepak_bola', label: 'Sepak Bola'),
  CommunityTypeOption(value: 'fashion', label: 'Fashion'),
  CommunityTypeOption(value: 'fotografi', label: 'Fotografi'),
  CommunityTypeOption(value: 'kuliner', label: 'Kuliner'),
  CommunityTypeOption(value: 'gaming', label: 'Gaming & E-Sport'),
  CommunityTypeOption(value: CommunityTypeOption.other, label: 'Lainnya'),
];

const testBandung = RegionCity(code: '32.73', name: 'Kota Bandung');
const testBogor = RegionCity(code: '32.71', name: 'Kota Bogor');
const testJabar = RegionProvince(
  code: '32',
  name: 'Jawa Barat',
  cities: [testBandung, testBogor],
);
const testSurabaya = RegionCity(code: '35.78', name: 'Kota Surabaya');
const testJatim = RegionProvince(
  code: '35',
  name: 'Jawa Timur',
  cities: [testSurabaya],
);
const testRegions = [testJabar, testJatim];

Community testCommunity(
  String id, {
  String name = 'Pemanah Nusantara',
  CommunityStatus status = CommunityStatus.approved,
}) =>
    Community(
      id: id,
      name: name,
      shortName: 'PN',
      type: 'panahan',
      typeLabel: 'Panahan',
      status: status,
      cityName: 'Kota Bandung',
      provinceName: 'Jawa Barat',
      description: 'Komunitas pecinta panahan tradisional yang rutin berlatih '
          'setiap akhir pekan di Bandung.',
    );

CommunityDetail testDetail({
  String id = '1',
  CommunityStatus status = CommunityStatus.approved,
  String? email = 'pengurus@gmail.com',
  String? reviewNote,
}) =>
    CommunityDetail(
      id: id,
      name: 'Pemanah Nusantara',
      shortName: 'PN',
      type: 'panahan',
      typeLabel: 'Panahan',
      status: status,
      cityName: 'Kota Bandung',
      provinceName: 'Jawa Barat',
      description: 'Komunitas pecinta panahan tradisional yang rutin berlatih '
          'setiap akhir pekan di Bandung.',
      address: 'Jl. Merdeka No. 10, Sumur Bandung',
      contactName: 'Rina Ayu',
      contactPhone: '081234567890',
      contactEmail: email,
      reviewNote: reviewNote,
    );

/// Draft lengkap yang lolos semua langkah.
CommunityDraft completeDraft() => CommunityDraft(
      logo: testImage('logo.png'),
      name: 'Pemanah Nusantara',
      shortName: 'PN',
      type: testTypes.first,
      province: testJabar,
      city: testBandung,
      address: 'Jl. Merdeka No. 10, Sumur Bandung',
      contactName: 'Rina Ayu',
      contactPhone: '0812 3456-7890',
      description: 'Komunitas pecinta panahan tradisional yang rutin berlatih.',
      photos: [testImage('a.png'), testImage('b.png')],
    );

class FakeCommunityRepository implements CommunityRepository {
  FakeCommunityRepository({
    this.pages = const [],
    this.mine = const [],
    this.detail,
    this.error,
    this.regionsError,
  });

  /// Halaman daftar berurutan; halaman ke-n dipakai untuk `page: n`.
  List<List<Community>> pages;
  List<Community> mine;
  CommunityDetail? detail;

  /// Melempar pada pengambilan daftar & detail, bila diisi.
  Exception? error;
  Exception? regionsError;

  /// Melempar saat mengunggah foto dengan nama ini, satu kali.
  String? failUploadOf;
  Exception uploadError = Exception('Gagal mengunggah');

  /// Melempar saat `submit`, satu kali.
  Exception? submitError;

  final listCalls = <({int page, String search, String? type})>[];
  final uploads = <String>[];
  final submitted = <CommunityDraft>[];

  @override
  Future<CommunitiesPage> getCommunities({
    required int page,
    String search = '',
    String? type,
  }) async {
    listCalls.add((page: page, search: search, type: type));
    final failure = error;
    if (failure != null) throw failure;
    return CommunitiesPage(
      communities: page <= pages.length ? pages[page - 1] : const [],
      currentPage: page,
      lastPage: pages.isEmpty ? 1 : pages.length,
    );
  }

  @override
  Future<List<Community>> getMine() async => mine;

  @override
  Future<CommunityDetail> getCommunity(String id) async {
    final failure = error;
    if (failure != null) throw failure;
    return detail!;
  }

  @override
  Future<List<CommunityTypeOption>> getTypes() async => testTypes;

  @override
  Future<List<RegionProvince>> getRegions() async {
    final failure = regionsError;
    if (failure != null) throw failure;
    return testRegions;
  }

  @override
  Future<String> uploadImage(
    CommunityImage image, {
    required String category,
  }) async {
    if (failUploadOf == image.filename) {
      failUploadOf = null;
      throw uploadError;
    }
    uploads.add('$category:${image.filename}');
    return 'aset-${image.filename}';
  }

  @override
  Future<CommunityDetail> submit(CommunityDraft draft) async {
    final failure = submitError;
    if (failure != null) {
      submitError = null;
      throw failure;
    }
    submitted.add(draft);
    return testDetail(status: CommunityStatus.pending);
  }
}

class FakeCommunityImagePicker extends CommunityImagePicker {
  FakeCommunityImagePicker({this.error});

  Exception? error;
  final limits = <int>[];

  @override
  Future<CommunityImage?> pickLogo() async {
    final failure = error;
    if (failure != null) throw failure;
    return testImage('logo.png');
  }

  @override
  Future<List<CommunityImage>> pickPhotos(int limit) async {
    final failure = error;
    if (failure != null) throw failure;
    limits.add(limit);
    return [
      for (var i = 0; i < limit && i < 2; i++)
        testImage('foto-${limits.length}-$i.png'),
    ];
  }
}
