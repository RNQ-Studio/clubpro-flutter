import 'dart:io';
import 'package:app_main/features/achievements/domain/achievements.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:app_main/features/achievements/presentation/achievement_screens.dart';
import 'package:app_main/features/achievements/presentation/member_ads_screens.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/achievements/achievements_screens_test.dart'
    show achievementsApp;
import '../test/features/achievements/fake_achievements_repository.dart';
import 'render_s03_test.dart' show fonts;

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final name in [
      'ranking-communities',
      'ranking-members',
      'ranking-filtered',
      'own-points',
      'central-rules',
      'central-rules-bottom',
      'community-events',
      'community-events-bottom',
      'community-corrected',
      'ad-public',
      'ad-community',
      'ad-own',
      'ad-new',
      'ad-edit',
      'ad-edit-bottom-large',
      'ad-keyboard',
      'empty',
      'error',
      'loading'
    ]) {
      testWidgets('$name at $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repo = FakeAchievements();
        Widget screen = const RankingScreen();
        switch (name) {
          case 'ranking-members':
            screen = const RankingScreen(communityId: '2');
          case 'ranking-filtered':
            screen = const RankingScreen(
                communityId: '2',
                initialGender: 'female',
                initialAgeGroup: '19_35',
                initialMonth: '2026-11');
          case 'own-points':
            screen = const MyAchievementsScreen();
          case 'central-rules' || 'central-rules-bottom':
            screen = const AchievementRulesScreen();
          case 'community-events' || 'community-events-bottom':
            screen = const CommunityAchievementsScreen(communityId: '2');
          case 'community-corrected':
            screen = const CommunityAchievementsScreen(communityId: '2');
            repo.canManage = false;
            repo.row = const AchievementRow(
                id: 'event-1',
                name: 'Atlet · Lomba fixture',
                points: 0,
                type: 'champion',
                status: 'corrected',
                actor: 'Pelatih Fixture',
                createdAt: '2026-11-26T01:00:00Z',
                occurredAt: '2026-11-25T00:00:00Z',
                correctedBy: 'Pendiri Fixture',
                correctedAt: '2026-11-26T02:00:00Z',
                correctionReason:
                    'Hasil kegiatan dibatalkan setelah pemeriksaan referensi.');
          case 'ad-public':
            screen = const MemberAdsScreen();
          case 'ad-community':
            screen = const MemberAdsScreen(communityId: '2');
          case 'ad-own':
            screen = const MemberAdsScreen(mine: true);
          case 'ad-new':
            screen = const MemberAdFormScreen();
          case 'ad-edit' || 'ad-edit-bottom-large' || 'ad-keyboard':
            screen = const MemberAdFormScreen(id: 'ad-1');
          case 'empty':
            repo.empty = true;
          case 'error':
            repo.error = const NetworkException('Koneksi terputus. Coba lagi.');
          case 'loading':
            repo.gate = Completer<void>();
        }
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: key,
            child: achievementsApp(screen, repo,
                scale: name.contains('large') ? 1.5 : 1)));
        if (name == 'loading') {
          await t.pump(const Duration(milliseconds: 250));
        } else {
          await t.pumpAndSettle();
        }
        if (name.contains('bottom')) {
          await t.drag(find.byType(ListView).first, const Offset(0, -1800));
          await t.pumpAndSettle();
        }
        if (name == 'ad-keyboard') {
          t.view.viewInsets = const FakeViewPadding(bottom: 340);
          await t.ensureVisible(find.byKey(const Key('ad-body')));
          await t.tap(find.byKey(const Key('ad-body')));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s07-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        if (repo.gate != null) {
          repo.gate!.complete();
          await t.pumpAndSettle();
        }
      });
    }
  }
}
