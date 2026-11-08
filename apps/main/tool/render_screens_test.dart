// Merender screenshot layar utama app (ukuran ponsel 360×780 dp) dengan font
// Roboto & Material Icons asli dari SDK Flutter — untuk review visual tanpa
// perangkat. Tidak ikut `melos run test` (berada di tool/).
//
//   RENDER_DIR=/tmp/shots flutter test tool/render_screens_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/branding/club_login.dart';
import 'package:app_main/features/admin/domain/entities/admin_banner.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:app_main/features/admin/presentation/screens/admin_banner_form_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_banners_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_communities_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_community_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/communities_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_detail_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_form_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_start_screen.dart';
import 'package:app_main/features/community/presentation/screens/member_profile_screen.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import 'package:app_main/features/dues/presentation/screens/dues_members_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_pay_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_payments_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_settings_screen.dart';
import 'package:app_main/features/home/domain/app_refresher.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:app_main/features/admin/domain/entities/admin_community.dart';

import '../test/features/admin/fake_admin_repository.dart';
import '../test/features/community/fake_community_repository.dart';
import '../test/features/dues/fake_dues_repository.dart';
import '../test/features/home/fake_promotion_popup_store.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> checkCurrentUser() async {}
}

const _partial = User(
  id: '1',
  name: 'Rina Ayu Lestari',
  email: 'rina.ayu@gmail.com',
  gender: MemberGender.female,
  bloodType: BloodType.o,
  phone: '081234567890',
);

final _complete = User(
  id: '1',
  name: 'Rina Ayu Lestari',
  email: 'rina.ayu@gmail.com',
  gender: MemberGender.female,
  birthPlace: 'Bandung',
  birthDate: DateTime(2001, 4, 12),
  phone: '081234567890',
  address: 'Jl. Merdeka No. 10, Bandung',
  bloodType: BloodType.o,
  emergencyContactName: 'Ibu Sari',
  emergencyContactPhone: '081298765432',
  completion: const ProfileCompletion(completed: 10, total: 10, missing: []),
);

class _ShownRefresher implements AppRefresher {
  @override
  Future<void> refresh() async {}
}

const _superAdmin = User(
  id: '1',
  name: 'Rina Ayu Lestari',
  email: 'rina.ayu@gmail.com',
  roles: [User.superAdminRole],
);

Future<void> _loadFonts() async {
  final sdk =
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final dir = '$sdk/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('MaterialIcons-Regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

void main() {
  // ignore: invalid_use_of_visible_for_testing_member
  PackageInfo.setMockInitialValues(
    appName: 'app_main',
    packageName: 'app_main',
    version: '1.0.0',
    buildNumber: '78',
    buildSignature: '',
  );
  final outDir = Platform.environment['RENDER_DIR'] ?? 'build/screens';
  final boundaryKey = GlobalKey();

  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget app, {
    Future<void> Function()? before,
    Size size = const Size(360, 780),
    bool photos = false,
  }) async {
    if (photos) debugNetworkImageHttpClientProvider = _PhotoClient.new;
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Bawaan test menggambar bayangan sebagai blok hitam.
    debugDisableShadows = false;

    await tester.pumpWidget(RepaintBoundary(key: boundaryKey, child: app));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    if (before != null) await before();
    // Gambar aset (logo) di-decode di luar fake async; tunggu, lalu gambar ulang.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = (element.widget as Image).image;
        // URL contoh tidak bisa diunduh di sini.
        if (photos || image is! NetworkImage) {
          await precacheImage(image, element);
        }
      }
    });
    await tester.pump();

    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(outDir).createSync(recursive: true);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
    debugDisableShadows = true;
    debugNetworkImageHttpClientProvider = null;
  }

  Widget material(Widget home, AuthState auth) => ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: home,
        ),
      );

  Widget shell(
    User user, {
    String location = '/',
    FakeCommunityRepository? communities,
    List<HomeBanner> banners = _homeBanners,
    bool popup = false,
    Map<String, String>? saved,
    FakeDuesRepository? dues,
  }) {
    final community = communities ?? FakeCommunityRepository();
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'communities',
              builder: (_, __) => const CommunitiesScreen(),
            ),
            GoRoute(
              path: 'profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider
            .overrideWith(() => _FixedAuthNotifier(AuthAuthenticated(user))),
        homePromotionsProvider.overrideWith(
          (ref) async => HomePromotions(banners: banners),
        ),
        // Selain shot popup: popup baru saja tampil, Beranda tidak tertutup.
        promotionPopupStoreProvider.overrideWithValue(
          FakePromotionPopupStore(popup ? null : {'1': DateTime.now()}),
        ),
        communityRepositoryProvider.overrideWithValue(community),
        regionRepositoryProvider.overrideWithValue(community),
        activeCommunityStoreProvider
            .overrideWithValue(FakeActiveCommunityStore(saved)),
        duesRepositoryProvider.overrideWithValue(
          dues ?? FakeDuesRepository(overview: notConfigured),
        ),
        appRefresherProvider.overrideWithValue(_ShownRefresher()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }

  Widget admin(
    String location, {
    AdminCommunityDetail? review,
    List<AdminBanner>? banners,
  }) {
    final now = DateTime.now();
    final repository = FakeAdminRepository(
      banners: banners ??
          [
            adminBanner(
              '1',
              title: 'Latihan Bersama Akhir Pekan',
              subtitle: 'Terbuka untuk semua anggota',
              linkUrl: '/communities/5',
              linkCommunity: const AdminBannerCommunity(
                  id: '5', name: 'Pemanah Nusantara'),
            ),
            adminBanner('2', title: '', linkUrl: AppRoutes.createCommunity),
            adminBanner(
              '3',
              title: 'Kejuaraan Panahan Tradisional Tingkat Provinsi 2026',
              imageUrl: null,
              linkUrl: 'https://anaklangit.manahpro.web.id/kejuaraan-2026',
              status: AdminBannerStatus.scheduled,
              startsAt: DateTime(2026, 12, 1, 8),
            ),
            adminBanner(
              '4',
              title: 'Promo Iuran Tahunan',
              status: AdminBannerStatus.inactive,
              linkUrl: AppRoutes.profile,
            ),
          ],
      pages: [
        [
          adminUser(
            '1',
            email: 'rina.ayu@gmail.com',
            isSuperAdmin: true,
            lastSeenAt: now.subtract(const Duration(minutes: 3)),
            device: adminDevices.first,
          ),
          adminUser(
            '2',
            name: 'Budi Santoso',
            email: 'budi.santoso@gmail.com',
            lastSeenAt: now.subtract(const Duration(hours: 5)),
            device: adminDevices.last,
          ),
          adminUser(
            '3',
            name: 'Citra Dewi Maharani Putri Kusumawardhani',
            email: 'citra.dewi.maharani.kusumawardhani@gmail.com',
            isActive: false,
            lastSeenAt: now.subtract(const Duration(days: 30)),
            device: adminDevices.first,
          ),
          adminUser('4', name: 'Dimas', email: 'dimas@gmail.com'),
        ],
      ],
      detail: adminDetail(id: '2', name: 'Budi Santoso'),
      communityPages: [
        [
          adminCommunity(
            '5',
            name: 'Fotografer Priangan',
            createdAt: now.subtract(const Duration(minutes: 12)),
          ),
          adminCommunity(
            '4',
            name: 'Sepak Bola Solo',
            submitter: 'Budi Santoso',
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
          adminCommunity(
            '3',
            status: CommunityStatus.approved,
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          adminCommunity(
            '2',
            name: 'Komunitas Nama Sangat Panjang Sekali Sampai Terpotong',
            status: CommunityStatus.rejected,
            createdAt: now.subtract(const Duration(days: 30)),
          ),
        ],
      ],
      community: review ?? adminCommunityDetail(),
    );
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
        GoRoute(
          path: AppRoutes.adminPanel,
          builder: (_, __) => const AdminPanelScreen(),
          routes: [
            GoRoute(
              path: 'users',
              builder: (_, __) => const AdminUsersScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminUserDetailScreen(
                    userId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'communities',
              builder: (_, __) => const AdminCommunitiesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminCommunityDetailScreen(
                    communityId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'banners',
              builder: (_, __) => const AdminBannersScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, __) => const AdminBannerFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => AdminBannerFormScreen(
                    bannerId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
            () => _FixedAuthNotifier(const AuthAuthenticated(_superAdmin))),
        adminRepositoryProvider.overrideWithValue(repository),
        communityImagePickerProvider
            .overrideWithValue(FakeCommunityImagePicker()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }

  Widget duesApp(FakeDuesRepository dues, String location) {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/communities/:id/dues',
          builder: (_, state) =>
              DuesScreen(communityId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'pay',
              builder: (_, state) =>
                  DuesPayScreen(communityId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'settings',
              builder: (_, state) =>
                  DuesSettingsScreen(communityId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'payments',
              builder: (_, state) =>
                  DuesPaymentsScreen(communityId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'members',
              builder: (_, state) =>
                  DuesMembersScreen(communityId: state.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: ':userId',
                  builder: (_, state) => DuesMemberScreen(
                    communityId: state.pathParameters['id']!,
                    userId: state.pathParameters['userId']!,
                    initialYear: 2026,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          () => _FixedAuthNotifier(AuthAuthenticated(_complete)),
        ),
        duesRepositoryProvider.overrideWithValue(dues),
        communityRepositoryProvider.overrideWithValue(
          FakeCommunityRepository(
            detail: testDetail(myRole: CommunityRole.creator),
          ),
        ),
        communityImagePickerProvider
            .overrideWithValue(FakeCommunityImagePicker()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }

  Widget communityApp(FakeCommunityRepository repository, String location) {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: AppRoutes.communities,
          builder: (_, __) => const CommunitiesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, __) => const CommunityFormScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) => CommunityDetailScreen(
                communityId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/members/:id',
          builder: (_, state) =>
              MemberProfileScreen(userId: state.pathParameters['id']!),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          () => _FixedAuthNotifier(AuthAuthenticated(_complete)),
        ),
        communityRepositoryProvider.overrideWithValue(repository),
        regionRepositoryProvider.overrideWithValue(repository),
        communityImagePickerProvider
            .overrideWithValue(FakeCommunityImagePicker()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
      ),
    );
  }

  /// Klub ramai dilihat creator-nya.
  FakeCommunityRepository club({
    CommunityRole? role = CommunityRole.creator,
    bool isJoinPending = false,
  }) {
    const url = 'https://anaklangit.manahpro.web.id/api/v1/assets';
    final today = DateTime.now();
    return FakeCommunityRepository(
      detail: testDetail(
        myRole: role,
        isJoinPending: isJoinPending,
        membersCount: 128,
        pendingMembersCount: role?.canManage ?? false ? 2 : 0,
        upcomingActivitiesCount: 3,
        photos: [
          for (var i = 1; i <= 7; i++)
            CommunityPhoto(id: 'p$i', url: '$url/$i/file'),
        ],
      ),
      members: [
        testMember('1',
            name: _complete.name,
            userId: _complete.id,
            role: CommunityRole.creator),
        testMember('2', name: 'Rina Ayu', role: CommunityRole.admin),
        testMember('3', name: 'Budi Santoso'),
        testMember('4', name: 'Sari Wulandari'),
        testMember('5', name: 'Dimas Pratama'),
        testMember('6', name: 'Ayu Lestari'),
      ],
      requests: role?.canManage ?? false
          ? [
              testRequest('8', name: 'Fajar Nugroho'),
              testRequest('9', name: 'Maya Kartika'),
            ]
          : const [],
      activities: CommunityActivities(
        upcoming: [
          testActivity(
            '1',
            title: 'Latihan Bersama Akhir Pekan',
            startsAt: today.add(const Duration(days: 3)),
            location: 'Lapangan Gasibu, Bandung',
            description: 'Bawa perlengkapan sendiri. Pemula sangat disambut!',
          ),
          testActivity(
            '2',
            title: 'Turnamen Persahabatan',
            startsAt: today.add(const Duration(days: 17)),
            location: 'GOR Pajajaran',
          ),
          testActivity(
            '3',
            title: 'Kopdar Akhir Tahun',
            startsAt: today.add(const Duration(days: 45)),
          ),
        ],
        past: [
          testActivity(
            '4',
            title: 'Kopdar Perdana',
            startsAt: today.subtract(const Duration(days: 12)),
            location: 'Taman Lansia',
          ),
        ],
      ),
      profile: CommunityMemberProfile(
        id: 'u2',
        name: 'Rina Ayu',
        registeredAt: DateTime.utc(2026, 3, 14),
        communities: [
          SharedCommunity(
            id: '1',
            name: 'Pemanah Nusantara',
            role: CommunityRole.admin,
            joinedAt: DateTime.utc(2026, 3, 20),
          ),
          SharedCommunity(
            id: '2',
            name: 'Fotografer Priangan',
            role: CommunityRole.member,
            joinedAt: DateTime.utc(2026, 7, 2),
          ),
        ],
      ),
    );
  }

  Future<void> openClubTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(
      of: find.byType(TabBar),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  FakeCommunityRepository filledCommunities() => FakeCommunityRepository(
        pages: [
          [
            testCommunity('1'),
            testCommunity('2', name: 'Sepak Bola Priangan'),
            testCommunity('3', name: 'Fashion Nusantara Bandung'),
          ],
        ],
        mine: [
          testCommunity('9',
              name: 'Fotografer Priangan', status: CommunityStatus.pending),
        ],
        detail: testDetail(status: CommunityStatus.pending),
      );

  /// Mengisi form sampai [steps] langkah lewat, seperti pengguna.
  Future<void> fillForm(WidgetTester tester, int steps) async {
    Finder field(String name) => find.byKey(Key('community-field-$name'));
    Future<void> next() async {
      await tester.tap(find.byKey(const Key('community-next')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('community-logo')));
    await tester.pumpAndSettle();
    await tester.enterText(field('name'), 'Persatuan Pemanah Nusantara');
    await tester.enterText(field('short_name'), 'PPN');
    await tester.tap(find.byKey(const Key('community-type-panahan')));
    await tester.pumpAndSettle();
    if (steps < 1) return;
    await next();

    await tester.tap(find.byKey(const Key('community-province')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jawa Barat').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('community-city-32')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kota Bandung').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        field('address'), 'Jl. Merdeka No. 10, Sumur Bandung');
    if (steps < 2) return;
    await next();

    await tester.enterText(field('contact_name'), 'Rina Ayu Lestari');
    await tester.enterText(field('contact_phone'), '0812 3456 7890');
    if (steps < 3) return;
    await next();

    await tester.enterText(
      field('description'),
      'Komunitas pecinta panahan tradisional yang rutin berlatih setiap akhir '
      'pekan di Bandung dan terbuka untuk pemula.',
    );
    await tester.tap(find.byKey(const Key('community-add-photo')));
    await tester.pumpAndSettle();
    if (steps < 4) return;
    await next();
  }

  /// Komunitas terverifikasi terpopuler untuk rekomendasi.
  List<Community> popularCommunities() => [
        testCommunity('11', name: 'Gowes Bandung Raya', membersCount: 412),
        testCommunity('12', name: 'Futsal Pasundan', membersCount: 287),
        testCommunity('13', name: 'Pemanah Nusantara', membersCount: 128),
        testCommunity('14', name: 'Fotografi Jalanan', membersCount: 96),
        testCommunity('15', name: 'Kuliner Nusantara', membersCount: 64),
      ];

  /// Belum tergabung; [requests] = permintaan bergabung yang menunggu.
  FakeCommunityRepository newcomer({List<Community> requests = const []}) =>
      FakeCommunityRepository(
        joined: requests,
        pages: [popularCommunities()],
      );

  /// Anggota aktif komunitas [club] dengan peran [role].
  FakeCommunityRepository memberOf({
    CommunityRole role = CommunityRole.member,
    CommunityStatus status = CommunityStatus.approved,
    List<Community> others = const [],
  }) {
    final repository = club(role: role);
    final detail = repository.detail!;
    repository.joined = [
      testCommunity(
        '1',
        myRole: role,
        status: status,
        membersCount: detail.membersCount,
      ),
      ...others,
    ];
    if (status != CommunityStatus.approved) {
      repository.detail = testDetail(
        myRole: role,
        status: status,
        membersCount: 1,
        upcomingActivitiesCount: detail.upcomingActivitiesCount,
        photos: detail.photos,
      );
    }
    return repository;
  }

  final otherClubs = [
    testCommunity(
      '2',
      name: 'Futsal Pasundan',
      myRole: CommunityRole.admin,
      membersCount: 287,
    ),
    testCommunity(
      '3',
      name: 'Gowes Bandung Raya',
      myRole: CommunityRole.member,
      membersCount: 412,
    ),
  ];

  Widget login({AuthState auth = const AuthUnauthenticated()}) => ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FixedAuthNotifier(auth)),
          appRefresherProvider.overrideWithValue(_ShownRefresher()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const ClubLoginPage(),
        ),
      );

  for (final (name, size) in [
    ('03-login', const Size(360, 780)),
    ('03b-login-desktop', const Size(1280, 800)),
    ('03c-login-500', const Size(500, 900)),
    ('03d-login-pendek', const Size(360, 600)),
  ]) {
    testWidgets(name, (tester) async {
      await shoot(tester, name, login(),
          size: size, before: () => tester.pumpAndSettle());
    });
  }

  testWidgets('03e-login-galat', (tester) async {
    await shoot(
      tester,
      '03e-login-galat',
      login(
        auth: const AuthError(
          'Login Google dibatalkan atau gagal. Silakan coba lagi.',
        ),
      ),
      before: () => tester.pumpAndSettle(),
    );
  });

  testWidgets('04-setup', (tester) async {
    await shoot(
        tester,
        '04-setup',
        material(
            const ProfileSetupScreen(), const AuthAuthenticated(_partial)));
  });

  testWidgets('05-beranda', (tester) async {
    await shoot(tester, '05-beranda', shell(_partial, communities: newcomer()));
  });

  testWidgets('06-beranda-pilih-komunitas', (tester) async {
    await shoot(
      tester,
      '06-beranda-pilih-komunitas',
      shell(_complete, communities: memberOf(others: otherClubs)),
    );
  });

  testWidgets('07-profil-belum-lengkap', (tester) async {
    await shoot(tester, '07-profil-belum-lengkap',
        shell(_partial, location: AppRoutes.profile));
  });

  testWidgets('08-profil-lengkap', (tester) async {
    await shoot(tester, '08-profil-lengkap',
        shell(_complete, location: AppRoutes.profile));
  });

  testWidgets('09-beranda-super-admin', (tester) async {
    await shoot(tester, '09-beranda-super-admin', shell(_superAdmin));
  });

  testWidgets('10-admin-panel', (tester) async {
    await shoot(tester, '10-admin-panel', admin(AppRoutes.adminPanel));
  });

  testWidgets('11-admin-panel-desktop', (tester) async {
    await shoot(tester, '11-admin-panel-desktop', admin(AppRoutes.adminPanel),
        size: const Size(1280, 800));
  });

  testWidgets('12-admin-detail', (tester) async {
    await shoot(tester, '12-admin-detail', admin(AppRoutes.adminUser('2')),
        size: const Size(360, 1500));
  });

  testWidgets('13-admin-detail-desktop', (tester) async {
    await shoot(
        tester, '13-admin-detail-desktop', admin(AppRoutes.adminUser('2')),
        size: const Size(1280, 900));
  });

  const tall = Size(360, 1000);
  const desktop = Size(1280, 800);

  testWidgets('14-komunitas-kosong', (tester) async {
    await shoot(tester, '14-komunitas-kosong',
        shell(_complete, location: AppRoutes.communities));
  });

  testWidgets('15-komunitas-daftar', (tester) async {
    await shoot(
      tester,
      '15-komunitas-daftar',
      shell(
        _complete,
        location: AppRoutes.communities,
        communities: filledCommunities(),
      ),
    );
  });

  testWidgets('16-komunitas-daftar-desktop', (tester) async {
    await shoot(
      tester,
      '16-komunitas-daftar-desktop',
      communityApp(filledCommunities(), AppRoutes.communities),
      size: desktop,
    );
  });

  testWidgets('17-komunitas-detail', (tester) async {
    await shoot(tester, '17-komunitas-detail',
        communityApp(filledCommunities(), AppRoutes.community('9')),
        size: tall);
  });

  testWidgets('18-form-identitas', (tester) async {
    await shoot(
      tester,
      '18-form-identitas',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: tall,
    );
  });

  testWidgets('19-form-galat', (tester) async {
    await shoot(
      tester,
      '19-form-galat',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: tall,
      before: () async {
        await tester.tap(find.byKey(const Key('community-next')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('20-form-lokasi', (tester) async {
    await shoot(
      tester,
      '20-form-lokasi',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: tall,
      before: () async {
        await fillForm(tester, 1);
        await tester.tap(find.byKey(const Key('community-province')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('21-form-cerita', (tester) async {
    await shoot(
      tester,
      '21-form-cerita',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: tall,
      before: () => fillForm(tester, 3),
    );
  });

  testWidgets('22-form-tinjau', (tester) async {
    await shoot(
      tester,
      '22-form-tinjau',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: const Size(360, 1320),
      before: () => fillForm(tester, 4),
    );
  });

  testWidgets('23-form-desktop', (tester) async {
    await shoot(
      tester,
      '23-form-desktop',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      size: desktop,
      before: () => fillForm(tester, 0),
    );
  });

  testWidgets('24-form-terkirim', (tester) async {
    await shoot(
      tester,
      '24-form-terkirim',
      communityApp(FakeCommunityRepository(), AppRoutes.createCommunity),
      before: () async {
        await fillForm(tester, 4);
        await tester.tap(find.byKey(const Key('community-next')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('25-kelola-user', (tester) async {
    await shoot(tester, '25-kelola-user', admin(AppRoutes.adminUsers));
  });

  testWidgets('26-kelola-komunitas', (tester) async {
    await shoot(
        tester, '26-kelola-komunitas', admin(AppRoutes.adminCommunities));
  });

  testWidgets('27-kelola-komunitas-desktop', (tester) async {
    await shoot(tester, '27-kelola-komunitas-desktop',
        admin(AppRoutes.adminCommunities),
        size: desktop);
  });

  testWidgets('28-verifikasi', (tester) async {
    await shoot(tester, '28-verifikasi', admin(AppRoutes.adminCommunity('5')),
        size: const Size(360, 1240));
  });

  testWidgets('29-verifikasi-desktop', (tester) async {
    await shoot(
        tester, '29-verifikasi-desktop', admin(AppRoutes.adminCommunity('5')),
        size: const Size(1280, 860));
  });

  testWidgets('30-tolak', (tester) async {
    await shoot(tester, '30-tolak', admin(AppRoutes.adminCommunity('5')),
        before: () async {
      await tester.tap(find.byKey(const Key('admin-reject')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin-reject-note')),
        'Foto kegiatan belum jelas.',
      );
      await tester.pumpAndSettle();
    });
  });

  testWidgets('31-sudah-ditolak', (tester) async {
    await shoot(
      tester,
      '31-sudah-ditolak',
      admin(
        AppRoutes.adminCommunity('5'),
        review: adminCommunityDetail(
          status: CommunityStatus.rejected,
          reviewNote: 'Foto kegiatan belum jelas.',
          reviewedAt: DateTime(2026, 11, 5, 14, 30),
          reviewer: const AdminCommunityPerson(id: '1', name: 'Pemilik'),
        ),
      ),
      size: const Size(360, 1000),
    );
  });

  testWidgets('33-beranda-komunitas-saya', (tester) async {
    await shoot(
      tester,
      '33-beranda-komunitas-saya',
      shell(
        _complete,
        communities: FakeCommunityRepository(
          joined: [
            testCommunity('1',
                shortName: 'Pemanah', myRole: CommunityRole.creator),
            testCommunity('2',
                shortName: 'Priangan FC', myRole: CommunityRole.admin),
            testCommunity('3',
                shortName: 'Fotografer', myRole: CommunityRole.member),
            testCommunity('4',
                shortName: 'Fashion',
                myRole: CommunityRole.creator,
                status: CommunityStatus.pending),
          ],
        ),
      ),
    );
  });

  testWidgets('34-beranda-belum-ada-komunitas', (tester) async {
    await shoot(tester, '34-beranda-belum-ada-komunitas', shell(_complete));
  });

  testWidgets('35-klub-info', (tester) async {
    await shoot(
      tester,
      '35-klub-info',
      communityApp(club(), AppRoutes.community('1')),
      size: tall,
      photos: true,
    );
  });

  testWidgets('36-klub-anggota', (tester) async {
    await shoot(
      tester,
      '36-klub-anggota',
      communityApp(club(), AppRoutes.community('1')),
      size: tall,
      before: () => openClubTab(tester, 'Anggota'),
    );
  });

  testWidgets('37-klub-galeri', (tester) async {
    await shoot(
      tester,
      '37-klub-galeri',
      communityApp(club(), AppRoutes.community('1')),
      size: tall,
      photos: true,
      before: () => openClubTab(tester, 'Galeri'),
    );
  });

  testWidgets('38-klub-kegiatan', (tester) async {
    await shoot(
      tester,
      '38-klub-kegiatan',
      communityApp(club(), AppRoutes.community('1')),
      size: tall,
      before: () => openClubTab(tester, 'Kegiatan'),
    );
  });

  testWidgets('39-klub-desktop', (tester) async {
    await shoot(
      tester,
      '39-klub-desktop',
      communityApp(club(), AppRoutes.community('1')),
      size: desktop,
      before: () => openClubTab(tester, 'Anggota'),
    );
  });

  testWidgets('40-klub-belum-gabung', (tester) async {
    await shoot(
      tester,
      '40-klub-belum-gabung',
      communityApp(club(role: null), AppRoutes.community('1')),
      before: () => openClubTab(tester, 'Anggota'),
    );
  });

  testWidgets('41-klub-menunggu', (tester) async {
    await shoot(
      tester,
      '41-klub-menunggu',
      communityApp(
        club(role: null, isJoinPending: true),
        AppRoutes.community('1'),
      ),
    );
  });

  testWidgets('42-klub-tergulung', (tester) async {
    await shoot(
      tester,
      '42-klub-tergulung',
      communityApp(club(), AppRoutes.community('1')),
      before: () async {
        await openClubTab(tester, 'Kegiatan');
        await tester.drag(find.byType(TabBarView), const Offset(0, -500));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('43-kegiatan-baru', (tester) async {
    await shoot(
      tester,
      '43-kegiatan-baru',
      communityApp(club(), AppRoutes.community('1')),
      before: () async {
        await openClubTab(tester, 'Kegiatan');
        await tester.tap(find.byKey(const Key('club-add-activity')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('44-profil-anggota', (tester) async {
    await shoot(
      tester,
      '44-profil-anggota',
      communityApp(club(), AppRoutes.member('u2')),
    );
  });

  testWidgets('45-kelola-banner', (tester) async {
    await shoot(tester, '45-kelola-banner', admin(AppRoutes.adminBanners),
        photos: true);
  });

  testWidgets('46-kelola-banner-desktop', (tester) async {
    await shoot(
        tester, '46-kelola-banner-desktop', admin(AppRoutes.adminBanners),
        size: desktop, photos: true);
  });

  testWidgets('47-banner-baru', (tester) async {
    await shoot(tester, '47-banner-baru', admin(AppRoutes.adminBannerNew),
        size: const Size(360, 1000), before: () async {
      await tester.tap(find.byKey(const Key('admin-banner-save')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('48-banner-pratinjau', (tester) async {
    await shoot(tester, '48-banner-pratinjau', admin(AppRoutes.adminBannerNew),
        size: const Size(360, 1100), before: () async {
      await tester.tap(find.byKey(const Key('admin-banner-photo')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('admin-banner-title')),
          'Latihan Bersama Akhir Pekan');
      await tester.enterText(find.byKey(const Key('admin-banner-subtitle')),
          'Terbuka untuk semua anggota');
      await tester.tap(find.byKey(const Key('admin-banner-link-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buka tautan di browser').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('admin-banner-url')), 'anaklangit.manahpro');
      await tester.tap(find.byKey(const Key('admin-banner-save')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('49-banner-ubah-desktop', (tester) async {
    await shoot(
        tester, '49-banner-ubah-desktop', admin(AppRoutes.adminBanner('1')),
        size: const Size(1280, 1100), photos: true);
  });

  testWidgets('50-banner-pilih-komunitas', (tester) async {
    await shoot(
        tester, '50-banner-pilih-komunitas', admin(AppRoutes.adminBanner('1')),
        before: () async {
      await tester.scrollUntilVisible(
        find.byKey(const Key('admin-banner-community')),
        200,
        scrollable: find
            .descendant(
                of: find.byType(Form), matching: find.byType(Scrollable))
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-banner-community')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('51-admin-panel-tiga-menu', (tester) async {
    await shoot(tester, '51-admin-panel-tiga-menu', admin(AppRoutes.adminPanel),
        size: desktop);
  });

  testWidgets('52-beranda-tanpa-banner', (tester) async {
    await shoot(
      tester,
      '52-beranda-tanpa-banner',
      shell(_complete, banners: const [], communities: memberOf()),
    );
  });

  testWidgets('53-beranda-anggota', (tester) async {
    await shoot(
        tester, '53-beranda-anggota', shell(_complete, communities: memberOf()),
        size: const Size(360, 1180));
  });

  testWidgets('54-beranda-pengelola', (tester) async {
    await shoot(
      tester,
      '54-beranda-pengelola',
      shell(
        _complete,
        banners: const [],
        communities: memberOf(role: CommunityRole.creator, others: otherClubs),
        saved: {'1': '1'},
      ),
      size: const Size(360, 1400),
    );
  });

  testWidgets('55-ganti-komunitas', (tester) async {
    await shoot(
      tester,
      '55-ganti-komunitas',
      shell(
        _complete,
        communities: memberOf(role: CommunityRole.creator, others: otherClubs),
        saved: {'1': '1'},
      ),
      before: () async {
        await tester.tap(find.byKey(const Key('home-club-switch')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('56-gabung-komunitas', (tester) async {
    await shoot(
      tester,
      '56-gabung-komunitas',
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              () => _FixedAuthNotifier(const AuthAuthenticated(_partial))),
          communityRepositoryProvider.overrideWithValue(newcomer()),
          activeCommunityStoreProvider
              .overrideWithValue(FakeActiveCommunityStore()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('id'),
          home: const CommunityStartScreen(),
        ),
      ),
      size: const Size(360, 900),
    );
  });

  testWidgets('57-beranda-desktop', (tester) async {
    await shoot(
      tester,
      '57-beranda-desktop',
      shell(
        _superAdmin,
        communities: memberOf(role: CommunityRole.creator, others: otherClubs),
        saved: {'1': '1'},
      ),
      size: const Size(1280, 1300),
    );
  });

  testWidgets('58-beranda-menunggu-persetujuan', (tester) async {
    await shoot(
      tester,
      '58-beranda-menunggu-persetujuan',
      shell(
        _complete,
        banners: const [],
        communities: newcomer(requests: [
          testCommunity(
            '12',
            name: 'Futsal Pasundan',
            myRole: CommunityRole.member,
            myStatus: CommunityMembershipStatus.pending,
          ),
        ]),
      ),
      size: const Size(360, 1000),
    );
  });

  testWidgets('59-beranda-menunggu-verifikasi', (tester) async {
    await shoot(
      tester,
      '59-beranda-menunggu-verifikasi',
      shell(
        _complete,
        banners: const [],
        communities: memberOf(
          role: CommunityRole.creator,
          status: CommunityStatus.pending,
        ),
      ),
      size: const Size(360, 1100),
    );
  });

  testWidgets('60-beranda-desktop-mulai', (tester) async {
    await shoot(
      tester,
      '60-beranda-desktop-mulai',
      shell(_complete, communities: newcomer()),
      size: const Size(1280, 1000),
    );
  });

  testWidgets('61-iuran-saya', (tester) async {
    await shoot(tester, '61-iuran-saya',
        duesApp(FakeDuesRepository(), AppRoutes.communityDues('1')),
        size: const Size(360, 1500));
  });

  testWidgets('62-bayar-iuran', (tester) async {
    await shoot(
      tester,
      '62-bayar-iuran',
      duesApp(FakeDuesRepository(), AppRoutes.communityDuesPay('1')),
      size: const Size(360, 1150),
      before: () async {
        await tester.ensureVisible(find.byKey(const Key('dues-proof-pick')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('dues-proof-pick')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('63-pengaturan-iuran', (tester) async {
    await shoot(
      tester,
      '63-pengaturan-iuran',
      duesApp(FakeDuesRepository(overview: managerOverview()),
          AppRoutes.communityDuesSettings('1')),
      size: const Size(360, 1100),
    );
  });

  testWidgets('64-verifikasi-iuran', (tester) async {
    await shoot(
      tester,
      '64-verifikasi-iuran',
      duesApp(FakeDuesRepository(payments: pendingPayments()),
          AppRoutes.communityDuesPayments('1')),
    );
  });

  testWidgets('65-kalender-anggota', (tester) async {
    await shoot(
      tester,
      '65-kalender-anggota',
      duesApp(FakeDuesRepository(members: membersPage()),
          AppRoutes.communityDuesMembers('1')),
    );
  });

  testWidgets('66-iuran-anggota', (tester) async {
    await shoot(
      tester,
      '66-iuran-anggota',
      duesApp(FakeDuesRepository(member: memberDetail()),
          AppRoutes.communityDuesMember('1', '2')),
      size: const Size(360, 1150),
    );
  });

  testWidgets('67-ubah-status-bulan', (tester) async {
    await shoot(
      tester,
      '67-ubah-status-bulan',
      duesApp(FakeDuesRepository(member: memberDetail()),
          AppRoutes.communityDuesMember('1', '2')),
      before: () async {
        await tester.tap(find.byKey(const Key('dues-month-2026-8')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('68-beranda-iuran', (tester) async {
    final repository = memberOf(role: CommunityRole.creator);
    repository.detail = testDetail(
      myRole: CommunityRole.creator,
      membersCount: 128,
      pendingMembersCount: 2,
      upcomingActivitiesCount: 3,
      duesConfigured: true,
      pendingDuesPaymentsCount: 1,
    );
    await shoot(
      tester,
      '68-beranda-iuran',
      shell(
        _complete,
        banners: const [],
        communities: repository,
        dues: FakeDuesRepository(),
      ),
      size: const Size(360, 1500),
    );
  });

  testWidgets('69-iuran-desktop', (tester) async {
    await shoot(
      tester,
      '69-iuran-desktop',
      duesApp(FakeDuesRepository(overview: managerOverview()),
          AppRoutes.communityDues('1')),
      size: const Size(1280, 1000),
    );
  });

  testWidgets('70-verifikasi-desktop', (tester) async {
    await shoot(
      tester,
      '70-verifikasi-desktop',
      duesApp(FakeDuesRepository(payments: memberOverview().payments),
          AppRoutes.communityDuesPayments('1')),
      size: const Size(1280, 900),
      before: () async {
        await tester.tap(find.text('Riwayat'));
        await tester.pumpAndSettle();
      },
    );
  });

  Future<void> promoPhotos(WidgetTester tester, {bool landscape = false}) =>
      tester.runAsync(() async {
        _photoBytes = await _promoImage(
          landscape ? const Size(960, 480) : const Size(540, 810),
          landscape ? 'Diskon Busur 30%' : 'Diskon Busur\nRecurve 30%',
          'Khusus anggota komunitas · s.d. 30 Nov',
        );
      });

  const promotions = [
    HomeBanner(
      id: '1',
      title: '',
      imageUrl: 'https://anaklangit.manahpro.web.id/promo-busur.png',
      linkUrl: 'https://wa.me/6281234567890?text=Halo',
      buttonLabel: 'Chat Penjual via WhatsApp',
    ),
    HomeBanner(
      id: '2',
      title: 'Kejuaraan Panahan Tradisional 2026',
      subtitle: 'Daftar sebelum 1 Desember',
      linkUrl: 'https://anaklangit.manahpro.web.id/kejuaraan',
    ),
    HomeBanner(id: '3', title: 'Latihan Bersama Akhir Pekan'),
  ];

  for (final (name, size) in [
    ('71-popup-promosi', const Size(360, 780)),
    ('72-popup-promosi-desktop', desktop),
    ('73-popup-promosi-500', const Size(500, 900)),
    ('74-popup-promosi-pendek', const Size(390, 640)),
  ]) {
    testWidgets(name, (tester) async {
      await promoPhotos(tester);
      addTearDown(() => _photoBytes = null);
      await shoot(
        tester,
        name,
        shell(_complete,
            banners: promotions, popup: true, communities: memberOf()),
        size: size,
        photos: true,
        before: () => tester.pumpAndSettle(),
      );
    });
  }

  testWidgets('75-popup-gambar-landscape', (tester) async {
    await promoPhotos(tester, landscape: true);
    addTearDown(() => _photoBytes = null);
    await shoot(
      tester,
      '75-popup-gambar-landscape',
      shell(
        _complete,
        // URL lain: gambar portrait shot sebelumnya masih di cache.
        banners: const [
          HomeBanner(
            id: '1',
            title: '',
            imageUrl: 'https://anaklangit.manahpro.web.id/promo-landscape.png',
            linkUrl: 'https://wa.me/6281234567890',
            buttonLabel: 'Chat Penjual via WhatsApp',
          ),
        ],
        popup: true,
        communities: memberOf(),
      ),
      photos: true,
      before: () => tester.pumpAndSettle(),
    );
  });

  testWidgets('76-jeda-popup', (tester) async {
    await shoot(tester, '76-jeda-popup', admin(AppRoutes.adminBanners),
        before: () async {
      await tester.tap(find.byKey(const Key('admin-promotion-interval-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-promotion-interval-72')));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('77-promosi-whatsapp', (tester) async {
    await promoPhotos(tester);
    addTearDown(() => _photoBytes = null);
    await shoot(
        tester,
        '77-promosi-whatsapp',
        admin(AppRoutes.adminBanner('5'), banners: [
          adminBanner(
            '5',
            title: '',
            imageUrl: 'https://anaklangit.manahpro.web.id/promo-busur.png',
            linkUrl: 'https://wa.me/6281234567890?text=Halo%2C%20saya%20'
                'tertarik%20promo%20busur',
            buttonLabel: 'Chat Penjual via WhatsApp',
          ),
        ]),
        size: const Size(360, 1500),
        photos: true);
  });

  testWidgets('32-beranda-bawah', (tester) async {
    await shoot(
      tester,
      '32-beranda-bawah',
      shell(_superAdmin),
      size: const Size(360, 1060),
      before: () async {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
      },
    );
  });
}

/// Banner contoh seperti yang dibuat di Kelola Banner.
const _homeBanners = [
  HomeBanner(
    id: '1',
    title: 'Latihan Bersama Akhir Pekan',
    subtitle: 'Terbuka untuk semua anggota komunitas.',
  ),
  HomeBanner(id: '2', title: 'Pendaftaran Kejuaraan Dibuka'),
];

/// Gambar pengganti untuk shot tertentu; null = PNG contoh.
List<int>? _photoBytes;

/// Gambar promosi contoh dengan teks, agar rasio dan potongan terlihat.
Future<List<int>> _promoImage(Size size, String headline, String detail) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [
        Color(0xFF0E3B2E),
        Color(0xFF1F7A53),
        Color(0xFFE0B341),
      ], const [
        0,
        0.55,
        1,
      ]),
  );
  canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.26),
      size.shortestSide * 0.32, Paint()..color = const Color(0x22FFFFFF));
  void text(String value, double top, double fontSize, FontWeight weight) {
    (TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: fontSize,
          fontWeight: weight,
          color: Colors.white,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.84))
        .paint(canvas, Offset(size.width * 0.08, top));
  }

  text('PAID PROMOTION', size.height * 0.08, size.shortestSide * 0.05,
      FontWeight.w500);
  text(headline, size.height * 0.5, size.shortestSide * 0.12, FontWeight.bold);
  text(detail, size.height * 0.86, size.shortestSide * 0.045, FontWeight.w500);
  final image = await recorder
      .endRecording()
      .toImage(size.width.round(), size.height.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Semua unduhan gambar dijawab dengan PNG contoh.
class _PhotoClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _PhotoRequest();
}

class _PhotoRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _PhotoResponse();
}

class _PhotoResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => (_photoBytes ?? testImageBytes).length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream.value(_photoBytes ?? testImageBytes as List<int>).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}
