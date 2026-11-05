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
  CommunityRole? myRole,
  String shortName = 'PN',
}) =>
    Community(
      id: id,
      name: name,
      shortName: shortName,
      myRole: myRole,
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
  CommunityRole? myRole,
  bool isJoinPending = false,
  int membersCount = 3,
  int pendingMembersCount = 0,
  int upcomingActivitiesCount = 0,
  List<CommunityPhoto> photos = const [],
  bool? canManage,
}) =>
    CommunityDetail(
      id: id,
      myRole: myRole,
      isMember: myRole != null,
      isJoinPending: isJoinPending,
      canManage: canManage ?? (myRole?.canManage ?? false),
      membersCount: membersCount,
      pendingMembersCount: pendingMembersCount,
      upcomingActivitiesCount: upcomingActivitiesCount,
      photos: photos,
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

CommunityMember testMember(
  String id, {
  String? name,
  CommunityRole role = CommunityRole.member,
  String? userId,
}) =>
    CommunityMember(
      id: id,
      userId: userId ?? 'u$id',
      name: name ?? 'Anggota $id',
      role: role,
      joinedAt: DateTime.utc(2026, 11, 5, 6),
    );

CommunityMember testRequest(String id, {String? name}) => CommunityMember(
      id: id,
      userId: 'u$id',
      name: name ?? 'Calon $id',
      role: CommunityRole.member,
      requestedAt: DateTime.utc(2026, 11, 5, 6),
    );

CommunityActivity testActivity(
  String id, {
  String title = 'Latihan Bersama',
  required DateTime startsAt,
  String? location,
  String? description,
}) =>
    CommunityActivity(
      id: id,
      title: title,
      startsAt: startsAt,
      location: location,
      description: description,
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
    this.joined = const [],
    List<CommunityMember> members = const [],
    List<CommunityMember> requests = const [],
    this.activities = const CommunityActivities(),
    this.profile,
    this.membersPerPage = 50,
  })  : members = [...members],
        requests = [...requests];

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

  /// Melempar pada `getJoined`, bila diisi.
  Exception? joinedError;
  List<Community> joined;
  int joinedCalls = 0;

  List<CommunityMember> members;
  List<CommunityMember> requests;
  int membersPerPage;
  CommunityActivities activities;
  CommunityMemberProfile? profile;

  /// Melempar pada tindakan berikutnya, satu kali.
  Exception? actionError;

  final listCalls = <({int page, String search, String? type})>[];
  final uploads = <String>[];
  final submitted = <CommunityDraft>[];
  final memberCalls = <({int page, bool pending})>[];

  /// Tindakan yang sampai ke server, mis. `role:5:admin`.
  final actions = <String>[];
  final activityInputs = <CommunityActivityInput>[];

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

  void _record(String action) {
    final failure = actionError;
    if (failure != null) {
      actionError = null;
      throw failure;
    }
    actions.add(action);
  }

  @override
  Future<List<Community>> getJoined() async {
    joinedCalls++;
    final failure = joinedError;
    if (failure != null) throw failure;
    return joined;
  }

  @override
  Future<void> join(String communityId) async => _record('join');

  @override
  Future<void> leave(String communityId) async => _record('leave');

  @override
  Future<CommunityMembersPage> getMembers(
    String communityId, {
    required int page,
    bool pending = false,
  }) async {
    memberCalls.add((page: page, pending: pending));
    final source = pending ? requests : members;
    final start = (page - 1) * membersPerPage;
    return CommunityMembersPage(
      members: source.skip(start).take(membersPerPage).toList(),
      currentPage: page,
      lastPage: (source.length / membersPerPage).ceil().clamp(1, 1000),
    );
  }

  @override
  Future<void> approveMember(String communityId, String memberId) async {
    _record('approve:$memberId');
    final request = requests.firstWhere((m) => m.id == memberId);
    requests.remove(request);
    members.add(
      testMember(memberId, name: request.name, userId: request.userId),
    );
  }

  @override
  Future<void> setMemberRole(
    String communityId,
    String memberId,
    CommunityRole role,
  ) async {
    _record('role:$memberId:${role.apiValue}');
    final index = members.indexWhere((m) => m.id == memberId);
    final member = members[index];
    members[index] = testMember(
      memberId,
      name: member.name,
      userId: member.userId,
      role: role,
    );
  }

  @override
  Future<void> removeMember(String communityId, String memberId) async {
    _record('remove:$memberId');
    members.removeWhere((m) => m.id == memberId);
    requests.removeWhere((m) => m.id == memberId);
  }

  @override
  Future<CommunityActivities> getActivities(String communityId) async =>
      activities;

  @override
  Future<void> createActivity(
    String communityId,
    CommunityActivityInput input,
  ) async {
    _record('activity:create');
    activityInputs.add(input);
    activities = CommunityActivities(
      upcoming: [
        ...activities.upcoming,
        testActivity(
          'baru',
          title: input.title,
          startsAt: input.startsAt,
        ),
      ],
      past: activities.past,
    );
  }

  @override
  Future<void> updateActivity(
    String communityId,
    String activityId,
    CommunityActivityInput input,
  ) async {
    _record('activity:update:$activityId');
    activityInputs.add(input);
  }

  @override
  Future<void> deleteActivity(String communityId, String activityId) async {
    _record('activity:delete:$activityId');
    activities = CommunityActivities(
      upcoming: activities.upcoming.where((a) => a.id != activityId).toList(),
      past: activities.past.where((a) => a.id != activityId).toList(),
    );
  }

  @override
  Future<void> addPhoto(String communityId, String assetId) async =>
      _record('photo:add:$assetId');

  @override
  Future<void> removePhoto(String communityId, String assetId) async =>
      _record('photo:remove:$assetId');

  @override
  Future<CommunityMemberProfile> getMemberProfile(String userId) async {
    final failure = error;
    if (failure != null) throw failure;
    return profile!;
  }
}

class FakeCommunityImagePicker extends CommunityImagePicker {
  FakeCommunityImagePicker({this.error, this.cancels = false});

  Exception? error;

  /// Pengguna menutup pemilih tanpa memilih.
  bool cancels;
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
    if (cancels) return const [];
    return [
      for (var i = 0; i < limit && i < 2; i++)
        testImage('foto-${limits.length}-$i.png'),
    ];
  }
}
