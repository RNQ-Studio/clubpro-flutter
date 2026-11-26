import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_main/features/achievements/domain/achievements.dart';
import 'package:app_main/features/directory/presentation/directory_screen.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/home/presentation/widgets/lobby_links.dart';
import 'package:app_main/features/home/presentation/widgets/member_lobby_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/home/s07_lobbies_test.dart' show lobbyApp;
import '../test/features/community/fake_community_repository.dart'
    show testCommunity;
import 'render_s03_test.dart' show fonts;

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final name in [
      'main-lobby',
      'member-search',
      'community-lobby',
      'community-management',
      'member-lobby',
      'member-lobby-large',
      'member-loading',
      'member-error'
    ]) {
      testWidgets('$name $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final wallet = name == 'member-loading' || name == 'member-error'
            ? Completer<WalletSummary>()
            : null;
        final points = name == 'member-loading' || name == 'member-error'
            ? Completer<AchievementPage>()
            : null;
        final Widget screen = switch (name) {
          'main-lobby' => const DirectoryScreen(),
          'member-search' => const DirectoryScreen(initialMembers: true),
          'community-lobby' => const PublicCommunityScreen(id: '2'),
          'community-management' =>
            const CommunityLobbyLinks(communityId: '2', canRecord: true),
          _ => MemberLobbyCard(community: testCommunity('2')),
        };
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: key,
            child: lobbyApp(screen,
                guest: name == 'main-lobby' ||
                    name == 'member-search' ||
                    name == 'community-lobby',
                wallet: wallet,
                points: points,
                scale: name.contains('large') ? 1.5 : 1)));
        await t.pump();
        if (name == 'member-error') {
          wallet!.completeError(Exception('offline'));
          points!.completeError(Exception('offline'));
        }
        if (name == 'member-loading') {
          await t.pump(const Duration(milliseconds: 250));
        } else {
          await t.pumpAndSettle();
        }
        expect(t.takeException(), isNull);
        await t.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await boundary.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s07-lobbies';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        if (name == 'member-loading') {
          wallet!.complete(const WalletSummary());
          points!.complete(const AchievementPage([]));
          await t.pumpAndSettle();
        }
      });
    }
  }
}
