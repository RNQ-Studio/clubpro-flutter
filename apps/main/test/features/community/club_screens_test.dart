import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/community_detail_screen.dart';
import 'package:app_main/features/community/presentation/screens/member_profile_screen.dart';
import 'package:app_main/features/community/presentation/widgets/club_common.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fake_community_repository.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this.fixed);

  final AuthState fixed;

  @override
  AuthState build() => fixed;
}

const _me = User(id: 'u1', name: 'Saya', email: 'saya@gmail.com');

Widget _app(
  FakeCommunityRepository repository, {
  String? location,
  FakeCommunityImagePicker? picker,
}) {
  final router = GoRouter(
    initialLocation: location ?? AppRoutes.community('1'),
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Text('BERANDA'),
        routes: [
          GoRoute(
            path: 'communities/:id',
            builder: (_, state) => CommunityDetailScreen(
              communityId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'members/:id',
            builder: (_, state) =>
                MemberProfileScreen(userId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        () => _FixedAuthNotifier(const AuthAuthenticated(_me)),
      ),
      communityRepositoryProvider.overrideWithValue(repository),
      communityImagePickerProvider
          .overrideWithValue(picker ?? FakeCommunityImagePicker()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void _size(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _open(WidgetTester tester, String tab) async {
  await tester.tap(find.widgetWithText(Tab, tab).first);
  await tester.pumpAndSettle();
}

/// Tab Anggota memakai Badge, jadi teksnya tidak langsung di `Tab.text`.
Future<void> _openMembers(WidgetTester tester) async {
  await tester.tap(find.descendant(
    of: find.byType(TabBar),
    matching: find.text('Anggota'),
  ));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String memberId, String item) async {
  await tester.tap(find.byKey(Key('club-member-menu-$memberId')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('club-confirm')));
  await tester.pumpAndSettle();
}

/// Isi tab digulir bersama sampul; tinggi layar cukup agar semua baris terbangun.
void _tall(WidgetTester tester) => _size(tester, 500, 1400);

void main() {
  group('sampul', () {
    testWidgets('empat tab tersedia dan Info terbuka lebih dulu',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(detail: testDetail()),
      ));
      await tester.pumpAndSettle();

      final labels = find.descendant(
        of: find.byType(TabBar),
        matching: find.byType(Text),
      );
      expect(
        tester.widgetList<Text>(labels).map((text) => text.data),
        containsAllInOrder(['Info', 'Anggota', 'Galeri', 'Kegiatan']),
      );
      expect(find.text('Tentang Komunitas'), findsOneWidget);
    });

    testWidgets('bukan anggota bisa meminta bergabung', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(detail: testDetail());
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      // Server mengembalikan status baru sesudah permintaan terkirim.
      repository.detail = testDetail(isJoinPending: true);
      await tester.tap(find.byKey(const Key('club-join')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['join']);
      expect(find.text('Menunggu Persetujuan'), findsOneWidget);
      expect(find.byKey(const Key('club-join')), findsNothing);
    });

    testWidgets('gagal bergabung: pesan tampil dan tombol tetap ada',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(detail: testDetail())
        ..actionError = const ServerException('Tidak bisa bergabung.');
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('club-join')));
      await tester.pumpAndSettle();

      expect(find.text('Tidak bisa bergabung.'), findsOneWidget);
      expect(find.byKey(const Key('club-join')), findsOneWidget);
    });

    testWidgets('permintaan bisa dibatalkan sesudah konfirmasi',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(isJoinPending: true),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      repository.detail = testDetail();
      await tester.tap(find.byKey(const Key('club-cancel-join')));
      await tester.pumpAndSettle();
      expect(repository.actions, isEmpty);

      await _confirm(tester);

      expect(repository.actions, ['leave']);
      expect(find.byKey(const Key('club-join')), findsOneWidget);
    });

    testWidgets('anggota melihat perannya, bukan tombol gabung',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.creator),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Anda Creator komunitas ini'), findsOneWidget);
      expect(find.byKey(const Key('club-join')), findsNothing);
    });

    testWidgets('pengajuan belum disetujui tidak bisa digabungi',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(status: CommunityStatus.pending),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('club-join')), findsNothing);
    });

    testWidgets('angka di sampul membuka tabnya', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          activities: CommunityActivities(
            upcoming: [
              testActivity(
                '1',
                title: 'Kopdar Akbar',
                startsAt: DateTime.now().add(const Duration(days: 3)),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('club-stat-activities')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('club-next-activity-card')), findsOneWidget);
    });

    testWidgets('sampul yang tergulung tidak menerima ketukan', (tester) async {
      _size(tester, 500, 420);
      final repository = FakeCommunityRepository(detail: testDetail());
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(TabBarView), const Offset(0, -900));
      await tester.pumpAndSettle();

      // Tombol Gabung tak terlihat lagi, tetapi posisinya di samping judul.
      final join = tester.getCenter(find.byKey(const Key('club-join')));
      await tester.tapAt(Offset(420, join.dy));
      await tester.pumpAndSettle();

      expect(repository.actions, isEmpty);
    });
  });

  group('info', () {
    testWidgets('pengurus mendapat pintasan permintaan bergabung',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(
            myRole: CommunityRole.admin,
            pendingMembersCount: 2,
          ),
          requests: [testRequest('8'), testRequest('9')],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 permintaan bergabung'), findsOneWidget);
      await tester.tap(find.byKey(const Key('club-requests-shortcut')));
      await tester.pumpAndSettle();

      expect(find.text('Calon 8'), findsOneWidget);
    });

    testWidgets('kegiatan terdekat tampil dengan hitung mundur',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(),
          activities: CommunityActivities(
            upcoming: [
              testActivity(
                '1',
                title: 'Kopdar Akbar',
                startsAt: DateTime.now().add(const Duration(days: 1)),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kopdar Akbar'), findsOneWidget);
      expect(find.textContaining('Besok'), findsOneWidget);
    });

    testWidgets('anggota bisa keluar sesudah konfirmasi', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.member),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('club-leave')));
      await tester.pumpAndSettle();
      await _confirm(tester);

      expect(repository.actions, ['leave']);
      expect(find.text('BERANDA'), findsOneWidget);
    });

    testWidgets('creator tidak punya tombol keluar', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.creator),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('club-leave')), findsNothing);
    });
  });

  group('anggota', () {
    final roster = [
      testMember('1', name: 'Saya', role: CommunityRole.creator, userId: 'u1'),
      testMember('2', name: 'Rina Ayu', role: CommunityRole.admin),
      testMember('3', name: 'Budi Santoso'),
    ];

    testWidgets('bukan anggota: daftar terkunci', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(membersCount: 12),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.text('Khusus anggota'), findsOneWidget);
      expect(find.textContaining('12 anggotanya'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsNothing);
      expect(repository.memberCalls, isEmpty);
    });

    testWidgets('pengurus dan anggota dikelompokkan', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          members: roster,
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.text('Pengurus'), findsOneWidget);
      expect(find.byType(ClubRoleBadge), findsNWidgets(2));
      expect(find.text('Saya (Anda)'), findsOneWidget);
    });

    testWidgets('anggota biasa tidak punya menu kelola', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          members: roster,
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
      expect(find.byKey(const Key('club-member-menu-3')), findsNothing);
    });

    testWidgets('creator menjadikan anggota admin sesudah konfirmasi',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '3', 'Jadikan Admin');
      expect(repository.actions, isEmpty);
      await _confirm(tester);

      expect(repository.actions, ['role:3:admin']);
      expect(find.byType(ClubRoleBadge), findsNWidgets(3));
      expect(find.text('Budi Santoso kini admin'), findsOneWidget);
    });

    testWidgets('batal di konfirmasi: tidak ada yang berubah', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '3', 'Jadikan Admin');
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(repository.actions, isEmpty);
      expect(find.byType(ClubRoleBadge), findsNWidgets(2));
    });

    testWidgets('admin juga bisa memberi akses admin', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '3', 'Jadikan Admin');
      await _confirm(tester);

      expect(repository.actions, ['role:3:admin']);
    });

    testWidgets('admin tidak bisa menyentuh admin lain atau creator',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.admin),
          members: [
            ...roster,
            testMember('4', name: 'Admin Lain', role: CommunityRole.admin),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.byKey(const Key('club-member-menu-1')), findsNothing);
      expect(find.byKey(const Key('club-member-menu-2')), findsNothing);
      expect(find.byKey(const Key('club-member-menu-4')), findsNothing);
      expect(find.byKey(const Key('club-member-menu-3')), findsOneWidget);
    });

    testWidgets('creator bisa mencabut admin', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '2', 'Cabut Admin');
      await _confirm(tester);

      expect(repository.actions, ['role:2:member']);
    });

    testWidgets('super admin bukan anggota setara creator', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(canManage: true),
          members: [
            testMember('2', name: 'Rina Ayu', role: CommunityRole.admin),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.byKey(const Key('club-member-menu-2')), findsOneWidget);
    });

    testWidgets('super admin yang kebetulan anggota biasa tetap setara creator',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member, canManage: true),
          members: [
            testMember('2', name: 'Rina Ayu', role: CommunityRole.admin),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      expect(find.byKey(const Key('club-member-menu-2')), findsOneWidget);
    });

    testWidgets('admin bisa mundur dari perannya sendiri', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
        members: [
          testMember('1',
              name: 'Saya', role: CommunityRole.admin, userId: 'u1'),
        ],
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '1', 'Mundur dari Admin');
      await _confirm(tester);

      expect(repository.actions, ['role:1:member']);
    });

    testWidgets('mengeluarkan anggota menghapus barisnya', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        members: roster,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '3', 'Keluarkan');
      await _confirm(tester);

      expect(repository.actions, ['remove:3']);
      expect(find.text('Budi Santoso'), findsNothing);
    });

    testWidgets('ditolak server: pesannya tampil, peran tidak berubah',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
        members: roster,
      )..actionError = const ServerException('Akses Anda sudah dicabut.');
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await _choose(tester, '3', 'Jadikan Admin');
      await _confirm(tester);

      expect(find.text('Akses Anda sudah dicabut.'), findsOneWidget);
      expect(find.byType(ClubRoleBadge), findsNWidgets(2));
    });

    testWidgets('menerima permintaan memindahkannya ke daftar anggota',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(
          myRole: CommunityRole.creator,
          pendingMembersCount: 1,
        ),
        members: roster,
        requests: [testRequest('9', name: 'Calon Baru')],
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);
      expect(find.text('Permintaan Bergabung'), findsOneWidget);

      repository.detail = testDetail(myRole: CommunityRole.creator);
      await tester.tap(find.byKey(const Key('club-approve-9')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['approve:9']);
      expect(find.text('Permintaan Bergabung'), findsNothing);
      expect(find.byKey(const Key('club-member-9')), findsOneWidget);
    });

    testWidgets('menolak permintaan menghapusnya', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
        members: roster,
        requests: [testRequest('9', name: 'Calon Baru')],
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await tester.tap(find.byKey(const Key('club-reject-9')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['remove:9']);
      expect(find.text('Calon Baru'), findsNothing);
    });

    testWidgets('jumlah permintaan tampil di tab Anggota', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(
            myRole: CommunityRole.creator,
            pendingMembersCount: 4,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final badge = tester.widget<Badge>(
        find.byKey(const Key('club-requests-badge')),
      );
      expect(badge.isLabelVisible, isTrue);
      expect((badge.label! as Text).data, '4');
    });

    testWidgets('mengetuk anggota membuka profilnya', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          members: roster,
          profile: const CommunityMemberProfile(id: 'u3', name: 'Budi Santoso'),
        ),
      ));
      await tester.pumpAndSettle();
      await _openMembers(tester);

      await tester.tap(find.byKey(const Key('club-member-3')));
      await tester.pumpAndSettle();

      expect(find.text('Profil Anggota'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    testWidgets('daftar panjang dimuat bertahap', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.member),
        members: [testMember('1'), testMember('2')],
        membersPerPage: 1,
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _openMembers(tester);
      expect(find.text('Anggota 2'), findsNothing);

      await tester.tap(find.byKey(const Key('club-members-more')));
      await tester.pumpAndSettle();

      expect(find.text('Anggota 2'), findsOneWidget);
      expect(find.byKey(const Key('club-members-more')), findsNothing);
    });
  });

  group('galeri', () {
    const photos = [
      CommunityPhoto(id: 'p1', url: 'https://anaklangit.manahpro.web.id/1.jpg'),
      CommunityPhoto(id: 'p2', url: 'https://anaklangit.manahpro.web.id/2.jpg'),
    ];

    testWidgets('kosong: pengurus diajak menambah foto', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.admin),
        ),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      expect(find.text('Belum ada foto'), findsOneWidget);
      expect(find.byKey(const Key('club-add-photo')), findsOneWidget);
    });

    testWidgets('anggota biasa hanya melihat', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member, photos: photos),
        ),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      expect(find.byKey(const Key('club-photo-1')), findsOneWidget);
      expect(find.byKey(const Key('club-add-photo')), findsNothing);
      expect(find.byKey(const Key('club-photo-remove-0')), findsNothing);
    });

    testWidgets('foto yang dipilih diunggah lalu dipasang', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator, photos: photos),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      await tester.tap(find.byKey(const Key('club-add-photo')));
      await tester.pumpAndSettle();

      expect(repository.uploads, hasLength(2));
      expect(repository.uploads.first, startsWith('community-photo:'));
      expect(repository.actions, hasLength(2));
      expect(repository.actions.first, startsWith('photo:add:aset-'));
      expect(find.text('2 foto ditambahkan'), findsOneWidget);
    });

    testWidgets('batal memilih: tidak ada pesan apa pun', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
      );
      await tester.pumpWidget(_app(
        repository,
        picker: FakeCommunityImagePicker(cancels: true),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      await tester.tap(find.byKey(const Key('club-add-photo')));
      await tester.pumpAndSettle();

      expect(repository.actions, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('sisa ruang membatasi jumlah pilihan', (tester) async {
      _tall(tester);
      final picker = FakeCommunityImagePicker();
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(
            myRole: CommunityRole.creator,
            photos: [
              for (var i = 0; i < 58; i++)
                CommunityPhoto(
                    id: 'p$i',
                    url: 'https://anaklangit.manahpro.web.id/$i.jpg'),
            ],
          ),
        ),
        picker: picker,
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      await tester.tap(find.byKey(const Key('club-add-photo')));
      await tester.pumpAndSettle();

      expect(picker.limits, [2]);
    });

    testWidgets('galeri penuh: tombol nonaktif', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(
            myRole: CommunityRole.creator,
            photos: [
              for (var i = 0; i < 60; i++)
                CommunityPhoto(
                    id: 'p$i',
                    url: 'https://anaklangit.manahpro.web.id/$i.jpg'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      expect(find.text('Galeri penuh (60 foto)'), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('club-add-photo')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('foto dihapus sesudah konfirmasi, memakai id aset',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin, photos: photos),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Galeri');

      await tester.tap(find.byKey(const Key('club-photo-remove-1')));
      await tester.pumpAndSettle();
      expect(repository.actions, isEmpty);
      await _confirm(tester);

      expect(repository.actions, ['photo:remove:p2']);
    });
  });

  group('kegiatan', () {
    final soon = DateTime.now().add(const Duration(days: 3));
    final later = DateTime.now().add(const Duration(days: 20));
    final past = DateTime.now().subtract(const Duration(days: 10));

    CommunityActivities schedule() => CommunityActivities(
          upcoming: [
            testActivity('1', title: 'Kopdar Akbar', startsAt: soon),
            testActivity('2', title: 'Turnamen', startsAt: later),
          ],
          past: [testActivity('3', title: 'Latihan Lama', startsAt: past)],
        );

    testWidgets('terdekat disorot, sisanya berurutan', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
          activities: schedule(),
        ),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      expect(
        find.descendant(
          of: find.byKey(const Key('club-next-activity-card')),
          matching: find.text('Kopdar Akbar'),
        ),
        findsOneWidget,
      );
      expect(find.text('3 hari lagi'), findsOneWidget);
      expect(find.text('Berikutnya'), findsOneWidget);
      expect(find.text('Sudah Berlangsung'), findsOneWidget);
      expect(find.byKey(const Key('club-add-activity')), findsNothing);
      expect(find.byKey(const Key('club-activity-menu-1')), findsNothing);
    });

    testWidgets('kosong: anggota tidak diajak membuat', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(myRole: CommunityRole.member),
        ),
      ));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      expect(find.text('Belum ada kegiatan'), findsOneWidget);
      expect(find.byKey(const Key('club-add-activity')), findsNothing);
    });

    testWidgets('nama wajib diisi sebelum tersimpan', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      await tester.tap(find.byKey(const Key('club-add-activity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('club-activity-save')));
      await tester.pumpAndSettle();

      expect(find.text('Nama kegiatan minimal 3 karakter'), findsOneWidget);
      expect(repository.actions, isEmpty);
    });

    testWidgets('kegiatan baru tersimpan dan langsung tampil', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      await tester.tap(find.byKey(const Key('club-add-activity')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('club-activity-title')),
        'Kopdar Perdana',
      );
      await tester.enterText(
        find.byKey(const Key('club-activity-location')),
        'Lapangan Gasibu',
      );
      await tester.tap(find.byKey(const Key('club-activity-save')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['activity:create']);
      final input = repository.activityInputs.single;
      expect(input.location, 'Lapangan Gasibu');
      expect(input.startsAt.isAfter(DateTime.now()), isTrue);
      expect(find.byKey(const Key('club-activity-save')), findsNothing);
      expect(find.text('Kopdar Perdana'), findsOneWidget);
    });

    testWidgets('gagal tersimpan: form tetap terbuka dengan pesannya',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.admin),
      )..actionError = const ServerException('Nama terlalu panjang.');
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      await tester.tap(find.byKey(const Key('club-add-activity')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('club-activity-title')),
        'Kopdar Perdana',
      );
      await tester.tap(find.byKey(const Key('club-activity-save')));
      await tester.pumpAndSettle();

      expect(find.text('Nama terlalu panjang.'), findsOneWidget);
      expect(find.byKey(const Key('club-activity-save')), findsOneWidget);
    });

    testWidgets('mengubah kegiatan mengisi form dengan data lama',
        (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        activities: schedule(),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      await tester.tap(find.byKey(const Key('club-activity-menu-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Kegiatan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('club-activity-save')));
      await tester.pumpAndSettle();

      expect(repository.actions, ['activity:update:2']);
      expect(repository.activityInputs.single.title, 'Turnamen');
      expect(
        repository.activityInputs.single.startsAt.isAtSameMomentAs(later),
        isTrue,
      );
    });

    testWidgets('kegiatan dihapus sesudah konfirmasi', (tester) async {
      _tall(tester);
      final repository = FakeCommunityRepository(
        detail: testDetail(myRole: CommunityRole.creator),
        activities: schedule(),
      );
      await tester.pumpWidget(_app(repository));
      await tester.pumpAndSettle();
      await _open(tester, 'Kegiatan');

      await tester.tap(find.byKey(const Key('club-activity-menu-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(repository.actions, isEmpty);
      await _confirm(tester);

      expect(repository.actions, ['activity:delete:3']);
      expect(find.text('Latihan Lama'), findsNothing);
    });
  });

  group('tanggal', () {
    test('hitung mundur memakai hari kalender, bukan selisih jam', () {
      final now = DateTime(2026, 11, 5, 23);

      expect(ClubDates.countdown(DateTime(2026, 11, 5, 23, 30), now: now),
          'Hari ini');
      expect(ClubDates.countdown(DateTime(2026, 11, 6, 1), now: now), 'Besok');
      expect(ClubDates.countdown(DateTime(2026, 11, 8, 1), now: now),
          '3 hari lagi');
    });

    test('nama hari dan bulan berbahasa Indonesia', () {
      final date = DateTime(2026, 11, 8);

      expect(ClubDates.full(date), startsWith('Minggu, 8 November 2026'));
      expect(ClubDates.month(date), 'NOV');
    });
  });

  group('profil anggota', () {
    testWidgets('data umum dan komunitas yang sama', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          profile: CommunityMemberProfile(
            id: 'u3',
            name: 'Rina Ayu',
            registeredAt: DateTime.utc(2026, 11, 5),
            communities: [
              SharedCommunity(
                id: '7',
                name: 'Pemanah Nusantara',
                role: CommunityRole.admin,
                joinedAt: DateTime.utc(2026, 11, 5, 6),
              ),
            ],
          ),
        ),
        location: AppRoutes.member('u3'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Rina Ayu'), findsOneWidget);
      expect(find.text('Di CEO sejak November 2026'), findsOneWidget);
      expect(find.text('Pemanah Nusantara'), findsOneWidget);
      expect(find.byType(ClubRoleBadge), findsOneWidget);
    });

    testWidgets('komunitas membuka halaman klubnya', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          detail: testDetail(id: '7'),
          profile: const CommunityMemberProfile(
            id: 'u3',
            name: 'Rina Ayu',
            communities: [
              SharedCommunity(
                id: '7',
                name: 'Klub Lain',
                role: CommunityRole.member,
              ),
            ],
          ),
        ),
        location: AppRoutes.member('u3'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('member-community-7')));
      await tester.pumpAndSettle();

      expect(find.text('Tentang Komunitas'), findsOneWidget);
    });

    testWidgets('tidak tersedia: pesan jelas dan bisa dicoba lagi',
        (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(
        FakeCommunityRepository(
          error: const ServerException('Profil anggota ini tidak tersedia.'),
        ),
        location: AppRoutes.member('u9'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Profil anggota ini tidak tersedia.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('tata letak', () {
    FakeCommunityRepository busyClub() => FakeCommunityRepository(
          detail: CommunityDetail(
            id: '1',
            name: 'Persatuan Pemanah Tradisional Nusantara Raya Bandung Utara',
            shortName: 'PPTNRBU',
            type: 'panahan',
            typeLabel: 'Panahan',
            status: CommunityStatus.approved,
            cityName: 'Kabupaten Kepulauan Seribu Administrasi',
            provinceName: 'Daerah Khusus Ibukota Jakarta',
            description: 'Komunitas pecinta panahan tradisional.',
            address: 'Jl. Merdeka No. 10',
            contactName: 'Rina Ayu',
            contactPhone: '081234567890',
            contactEmail: 'pengurus.komunitas.panahan@gmail.com',
            myRole: CommunityRole.creator,
            isMember: true,
            canManage: true,
            membersCount: 1234,
            pendingMembersCount: 12,
            upcomingActivitiesCount: 120,
            photos: const [
              CommunityPhoto(
                id: 'p1',
                url: 'https://anaklangit.manahpro.web.id/1.jpg',
              ),
              CommunityPhoto(
                id: 'p2',
                url: 'https://anaklangit.manahpro.web.id/2.jpg',
              ),
            ],
          ),
          members: [
            testMember(
              '1',
              name: 'Muhammad Abdurrahman Al-Fatih Wicaksono Putra Pratama',
              role: CommunityRole.creator,
            ),
            testMember(
              '2',
              name: 'Raden Ajeng Sri Wulandari Kusumaningrum Hadiningrat',
              role: CommunityRole.admin,
            ),
            testMember('3'),
          ],
          requests: [
            testRequest('9', name: 'Raden Mas Bagus Prasetyo Wicaksono Adi'),
          ],
          activities: CommunityActivities(
            upcoming: [
              testActivity(
                '1',
                title: 'Turnamen Persahabatan Antar Komunitas Se-Jawa Barat',
                startsAt: DateTime.now().add(const Duration(days: 3)),
                location: 'Gelanggang Olahraga Pajajaran, Kota Bandung',
                description: 'Bawa perlengkapan sendiri.',
              ),
              testActivity(
                '2',
                title: 'Kegiatan Lanjutan Yang Namanya Sangat Panjang Sekali',
                startsAt: DateTime.now().add(const Duration(days: 9)),
                location: 'Gelanggang Olahraga Pajajaran, Kota Bandung',
              ),
            ],
          ),
        );

    Future<void> everyTab(WidgetTester tester) async {
      await tester.pumpWidget(_app(busyClub()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await _openMembers(tester);
      expect(tester.takeException(), isNull);
      await _open(tester, 'Galeri');
      expect(tester.takeException(), isNull);
      await _open(tester, 'Kegiatan');
      expect(tester.takeException(), isNull);
    }

    testWidgets('layar sempit tanpa overflow di semua tab', (tester) async {
      _size(tester, 320, 700);
      await everyTab(tester);
    });

    testWidgets('layar sempit + teks besar tanpa overflow', (tester) async {
      _size(tester, 360, 800);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await everyTab(tester);
    });

    testWidgets('layar lebar: isi tab tidak melebar', (tester) async {
      _size(tester, 1280, 800);
      await tester.pumpWidget(_app(busyClub()));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.text('Tentang Komunitas').first).width,
        lessThanOrEqualTo(760),
      );
      expect(
        tester.getSize(find.byType(ClubSection).first).width,
        lessThanOrEqualTo(760),
      );
    });
  });
}
