import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_main/features/directory/presentation/directory_screen.dart';
import 'package:app_main/features/directory/presentation/guardian_screen.dart';
import 'package:app_main/features/directory/presentation/member_identity_screen.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/directory/s02_screens_test.dart' as fixture;

Future<void> fonts() async {
  final sdk =
      File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
  Future<ByteData> data(String name) async => ByteData.sublistView(
      await File('$sdk/artifacts/material_fonts/$name').readAsBytes());
  await Future.wait([
    (FontLoader('Roboto')
          ..addFont(data('Roboto-Regular.ttf'))
          ..addFont(data('Roboto-Medium.ttf'))
          ..addFont(data('Roboto-Bold.ttf')))
        .load(),
    (FontLoader('MaterialIcons')..addFont(data('MaterialIcons-Regular.otf')))
        .load()
  ]);
}

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final entry in <String, Widget>{
      'directory': const DirectoryScreen(),
      'community': const PublicCommunityScreen(id: '1'),
      'manual': const MemberIdentityScreen(communityId: '1'),
      'guardian': const GuardianScreen(),
      'guardian-in-app': const GuardianScreen(),
      'guardian-consent': const GuardianScreen(),
      'dependent': const DependentScreen(id: '4'),
      'pin-login': const PinScreen(),
      'pin-change': const PinScreen(mode: PinMode.manage),
      'pin-google': const PinScreen(mode: PinMode.manage),
      'pin-password': const PinScreen(mode: PinMode.manage),
      'pin-recovery-account': const PinScreen(mode: PinMode.recovery),
      'pin-recovery': const PinScreen(mode: PinMode.recovery)
    }.entries) {
      testWidgets('${entry.key} at $width', (t) async {
        t.view.physicalSize = Size(width, 950);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final key = GlobalKey();
        final repo = fixture.FakeDirectory()
          ..inApp = entry.key.startsWith('guardian-in-app') ||
              entry.key == 'guardian-consent'
          ..mixedInvites = entry.key == 'guardian-in-app'
          ..accountInvite = entry.key == 'guardian-consent';
        final pin = fixture.FakePin()
          ..emailAvailable = entry.key != 'pin-recovery-account';
        final user = User(
            id: '1',
            name: 'Akun Uji',
            email: 'uji@anaklangit.manahpro.web.id',
            pinEnabled: entry.key != 'pin-password',
            pinGoogleReauthenticated: entry.key == 'pin-google');
        await t.pumpWidget(RepaintBoundary(
            key: key,
            child: fixture.app(entry.value,
                auth: AuthAuthenticated(user), repo: repo, pin: pin)));
        await t.pumpAndSettle();
        if (entry.key == 'guardian-consent') {
          await t.tap(find.text('Setujui'));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s02-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/${entry.key}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
