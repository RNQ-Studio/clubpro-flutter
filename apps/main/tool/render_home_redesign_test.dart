// RENDER_DIR=/tmp/clubpro-home flutter test tool/render_home_redesign_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:app_main/features/community/domain/entities/community.dart';
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

void main() {
  final directory = Platform.environment['RENDER_DIR'] ?? 'build/home-redesign';
  setUpAll(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    PackageInfo.setMockInitialValues(
      appName: 'CEO',
      packageName: 'clubpro.main',
      version: '1.0.0',
      buildNumber: '135',
      buildSignature: '',
    );
    await _loadFonts();
  });

  for (final (name, size, group, role, restricted, dark) in [
    (
      'phone-overview',
      const Size(390, 844),
      '',
      CommunityRole.member,
      false,
      false
    ),
    (
      'phone-community',
      const Size(390, 844),
      'home-menu-community',
      CommunityRole.member,
      false,
      false
    ),
    (
      'phone-finance',
      const Size(390, 844),
      'home-menu-finance',
      CommunityRole.member,
      false,
      false
    ),
    (
      'phone-market',
      const Size(390, 844),
      'home-menu-market',
      CommunityRole.member,
      false,
      false
    ),
    (
      'phone-explore',
      const Size(390, 844),
      'home-menu-explore',
      CommunityRole.member,
      false,
      false
    ),
    (
      'phone-manager',
      const Size(390, 844),
      'home-manage-expand',
      CommunityRole.creator,
      false,
      false
    ),
    (
      'phone-restricted',
      const Size(390, 844),
      '',
      CommunityRole.member,
      true,
      false
    ),
    ('phone-dark', const Size(390, 844), '', CommunityRole.member, false, true),
    (
      'phone-small-large-text',
      const Size(320, 700),
      'home-menu-community',
      CommunityRole.creator,
      false,
      false
    ),
    (
      'phone-small-overview-large-text',
      const Size(320, 700),
      '',
      CommunityRole.creator,
      false,
      false
    ),
    (
      'desktop-overview',
      const Size(1280, 960),
      '',
      CommunityRole.member,
      false,
      false
    ),
    (
      'desktop-community',
      const Size(1280, 960),
      'home-menu-community',
      CommunityRole.creator,
      false,
      false
    ),
    (
      'desktop-manager',
      const Size(1280, 960),
      'home-manage-expand',
      CommunityRole.creator,
      false,
      false
    ),
  ]) {
    testWidgets('render $name', (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      debugDisableShadows = false;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: boundaryKey,
        child: homeRedesignApp(
          dark: dark,
          textScale: name.contains('large-text') ? 1.5 : 1,
          dues: true,
          communities:
              homeRedesignRepository(role: role, restricted: restricted),
        ),
      ));
      await tester.pumpAndSettle();
      if (group.isNotEmpty) {
        await homeRedesignExpand(tester, group);
        await tester.ensureVisible(find.byKey(Key(group)));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final screenshot = await boundary.toImage(pixelRatio: 1.5);
        final bytes =
            await screenshot.toByteData(format: ui.ImageByteFormat.png);
        Directory(directory).createSync(recursive: true);
        File('$directory/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        screenshot.dispose();
      });
      debugDisableShadows = true;
    });
  }

  testWidgets('render phone-super-admin', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: boundaryKey,
      child: homeRedesignApp(
          user: const User(
              id: 'central',
              name: 'Admin Pusat',
              email: 'admin@anaklangit.manahpro.web.id',
              roles: [User.superAdminRole]),
          communities: homeRedesignRepository(role: CommunityRole.creator)),
    ));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
            of: find.byType(ListView).first, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(
        find.byKey(const Key('home-admin-panel')), 300,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final screenshot = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      Directory(directory).createSync(recursive: true);
      File('$directory/phone-super-admin.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      screenshot.dispose();
    });
  });
}
