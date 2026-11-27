// RENDER_DIR=/tmp/clubpro-home flutter test tool/render_home_redesign_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../test/features/home/home_redesign_test.dart'
    show homeRedesignApp, homeRedesignExpand, homeRedesignRepository;

Future<void> _loadFonts() async {
  final sdk =
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  final directory = '$sdk/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async =>
      ByteData.sublistView(await File('$directory/$name').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(bytes('Roboto-Regular.ttf'))
    ..addFont(bytes('Roboto-Medium.ttf'))
    ..addFont(bytes('Roboto-Bold.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('MaterialIcons-Regular.otf'));
  await Future.wait([roboto.load(), icons.load()]);
}

enum _State {
  data,
  empty,
  communityLoading,
  communityError,
  summaryLoading,
  summaryError,
}

class _RenderCase {
  const _RenderCase(
    this.name, {
    this.size = const Size(360, 800),
    this.group,
    this.role = CommunityRole.member,
    this.restricted = false,
    this.dark = false,
    this.scale = 1,
    this.superAdmin = false,
    this.state = _State.data,
  });

  final String name;
  final Size size;
  final String? group;
  final CommunityRole role;
  final bool restricted, dark, superAdmin;
  final double scale;
  final _State state;
}

const _cases = [
  _RenderCase('phone-overview'),
  _RenderCase('phone-500-overview', size: Size(500, 900)),
  _RenderCase('desktop-overview', size: Size(1280, 900)),
  _RenderCase('phone-community', group: 'community'),
  _RenderCase('phone-activity', group: 'activity'),
  _RenderCase('phone-finance', group: 'finance'),
  _RenderCase('phone-market', group: 'market'),
  _RenderCase('phone-explore', group: 'explore'),
  _RenderCase('phone-manager-overview', role: CommunityRole.creator),
  _RenderCase('phone-manager', role: CommunityRole.creator, group: 'manage'),
  _RenderCase('desktop-manager',
      size: Size(1280, 900), role: CommunityRole.creator, group: 'manage'),
  _RenderCase('phone-super-admin-overview', superAdmin: true),
  _RenderCase('phone-super-admin', superAdmin: true, group: 'admin'),
  _RenderCase('desktop-super-admin',
      size: Size(1280, 900),
      role: CommunityRole.creator,
      superAdmin: true,
      group: 'admin'),
  _RenderCase('phone-dark', dark: true),
  _RenderCase('phone-dark-finance', dark: true, group: 'finance'),
  _RenderCase('desktop-dark-manager',
      size: Size(1280, 900),
      dark: true,
      role: CommunityRole.creator,
      group: 'manage'),
  _RenderCase('phone-small-overview-large-text',
      size: Size(320, 700), role: CommunityRole.creator, scale: 1.5),
  _RenderCase('phone-small-community-large-text',
      size: Size(320, 700),
      role: CommunityRole.creator,
      scale: 1.5,
      group: 'community'),
  _RenderCase('phone-small-finance-large-text',
      size: Size(320, 700), scale: 1.5, group: 'finance'),
  _RenderCase('phone-restricted', restricted: true),
  _RenderCase('phone-without-community', state: _State.empty),
  _RenderCase('phone-community-loading', state: _State.communityLoading),
  _RenderCase('phone-community-error', state: _State.communityError),
  _RenderCase('phone-summary-loading', state: _State.summaryLoading),
  _RenderCase('phone-summary-error', state: _State.summaryError),
];

void main() {
  final directory = Platform.environment['RENDER_DIR'] ?? 'build/home-redesign';
  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'CEO',
      packageName: 'clubpro.main',
      version: '1.0.0',
      buildNumber: '140',
      buildSignature: '',
    );
    await _loadFonts();
  });

  for (final render in _cases) {
    testWidgets('render ${render.name}', (tester) async {
      tester.view.physicalSize = render.size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      debugDisableShadows = false;
      addTearDown(() => debugDisableShadows = true);
      final communities = homeRedesignRepository(
        role: render.role,
        restricted: render.restricted,
        joined: render.state != _State.empty,
      );
      if (render.state == _State.communityLoading) {
        communities.joinedGate = Completer<void>();
      } else if (render.state == _State.communityError) {
        communities.joinedError = Exception('Koneksi terputus');
      }
      final wallet = Completer<WalletSummary>();
      final points = Completer<AchievementPage>();
      final summaryLoading = render.state == _State.summaryLoading;
      final summaryError = render.state == _State.summaryError;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: homeRedesignApp(
          dark: render.dark,
          textScale: render.scale,
          dues: true,
          communities: communities,
          user: render.superAdmin
              ? const User(
                  id: 'central',
                  name: 'Admin Pusat',
                  email: 'admin@anaklangit.manahpro.web.id',
                  roles: [User.superAdminRole],
                  completion:
                      ProfileCompletion(completed: 12, total: 12, missing: []),
                )
              : const User(
                  id: 'home-redesign',
                  name: 'Rina Ayu Lestari',
                  email: 'rina@anaklangit.manahpro.web.id',
                  completion:
                      ProfileCompletion(completed: 12, total: 12, missing: []),
                ),
          wallet: summaryLoading
              ? () => wallet.future
              : summaryError
                  ? () => Future.error(Exception('Koneksi terputus'))
                  : null,
          points: summaryLoading
              ? () => points.future
              : summaryError
                  ? () => Future.error(Exception('Koneksi terputus'))
                  : null,
        ),
      ));
      if (summaryLoading || render.state == _State.communityLoading) {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      } else {
        await tester.pumpAndSettle();
      }
      if (render.group case final group?) {
        await homeRedesignExpand(
          tester,
          group == 'manage' ? 'home-manage-expand' : 'home-menu-$group',
        );
        final panel = find.byKey(Key('home-submenu-$group'));
        if (panel.evaluate().isNotEmpty) {
          await tester.ensureVisible(panel);
        }
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: render.name);
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final screenshot = await boundary.toImage(pixelRatio: 1.5);
        final bytes =
            await screenshot.toByteData(format: ui.ImageByteFormat.png);
        Directory(directory).createSync(recursive: true);
        File('$directory/${render.name}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        screenshot.dispose();
      });
      debugDisableShadows = true;
    });
  }
}
