// Merender screenshot layar utama app (ukuran ponsel 360×780 dp) dengan font
// Roboto & Material Icons asli dari SDK Flutter — untuk review visual tanpa
// perangkat. Tidak ikut `melos run test` (berada di tool/).
//
//   RENDER_DIR=/tmp/shots flutter test tool/render_screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/branding/club_brand.dart';
import 'package:app_main/branding/club_logo.dart';
import 'package:app_main/features/admin/presentation/admin_providers.dart';
import 'package:app_main/features/admin/presentation/screens/admin_communities_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_community_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_panel_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_user_detail_screen.dart';
import 'package:app_main/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/community/presentation/screens/communities_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_detail_screen.dart';
import 'package:app_main/features/community/presentation/screens/community_form_screen.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/shell/main_shell.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_main/features/admin/domain/entities/admin_community.dart';

import '../test/features/admin/fake_admin_repository.dart';
import '../test/features/community/fake_community_repository.dart';

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
  final outDir = Platform.environment['RENDER_DIR'] ?? 'build/screens';
  final boundaryKey = GlobalKey();

  setUpAll(_loadFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget app, {
    Future<void> Function()? before,
    Size size = const Size(360, 780),
  }) async {
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
        if (image is! NetworkImage) await precacheImage(image, element);
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
  }) {
    final community = communities ?? FakeCommunityRepository();
    final router = GoRouter(
      initialLocation: location,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.communities,
                  builder: (_, __) => const CommunitiesScreen()),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: AppRoutes.profile,
                  builder: (_, __) => const ProfileScreen()),
            ]),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider
            .overrideWith(() => _FixedAuthNotifier(AuthAuthenticated(user))),
        homeBannersProvider.overrideWith((ref) async => defaultHomeBanners),
        communityRepositoryProvider.overrideWithValue(community),
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

  Widget admin(String location, {AdminCommunityDetail? review}) {
    final now = DateTime.now();
    final repository = FakeAdminRepository(
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
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
            () => _FixedAuthNotifier(const AuthAuthenticated(_superAdmin))),
        adminRepositoryProvider.overrideWithValue(repository),
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
      ],
    );
    return ProviderScope(
      overrides: [
        communityRepositoryProvider.overrideWithValue(repository),
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

  testWidgets('01-onboarding', (tester) async {
    await shoot(
      tester,
      '01-onboarding',
      material(const OnboardingScreen(pages: ClubBrand.onboardingPages),
          const AuthUnauthenticated()),
    );
  });

  testWidgets('02-onboarding-iuran', (tester) async {
    await shoot(
      tester,
      '02-onboarding-iuran',
      material(const OnboardingScreen(pages: ClubBrand.onboardingPages),
          const AuthUnauthenticated()),
      before: () async {
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text('Selanjutnya'));
          await tester.pumpAndSettle();
        }
      },
    );
  });

  testWidgets('03-login', (tester) async {
    await shoot(
      tester,
      '03-login',
      material(
        const GoogleLoginScreen(
          title: ClubBrand.name,
          subtitle: ClubBrand.loginSubtitle,
          logo: ClubLogo(size: 112),
        ),
        const AuthUnauthenticated(),
      ),
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
    await shoot(tester, '05-beranda', shell(_partial));
  });

  testWidgets('06-segera-hadir', (tester) async {
    await shoot(tester, '06-segera-hadir', shell(_partial), before: () async {
      await tester.tap(find.byKey(const Key('home-menu-member-card')));
      await tester.pumpAndSettle();
    });
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
}
