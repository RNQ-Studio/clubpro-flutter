import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:app_main/features/training/presentation/training_screen.dart';
import 'package:app_main/features/training/presentation/training_settings_screen.dart';
import 'package:app_main/features/training/presentation/training_session_screen.dart';
import 'package:app_main/features/training/presentation/training_report_screen.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/training/training_screens_test.dart' show trainingApp;
import '../test/features/training/fake_training_repository.dart';
import 'render_s03_test.dart' show fonts;

void main() {
  setUpAll(fonts);
  for (final width in [500.0, 1280.0]) {
    for (final name in [
      'packages',
      'owned-packages',
      'sessions',
      'history',
      'locations',
      'catalog',
      'catalog-locations',
      'location-managers',
      'location-recipients',
      'session-form',
      'report-summary',
      'report-details',
      'recipient-report',
      'empty',
      'inactive',
      'pending',
      'error',
      'loading',
      'attendance-detail-large',
      'catalog-large',
      'location-recipients-large',
      'session-form-large',
      'report-summary-large'
    ]) {
      testWidgets('$name at $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repo = FakeTraining();
        Widget screen = const TrainingScreen(communityId: '1');
        if (name.startsWith('catalog')) {
          screen = const TrainingSettingsScreen(communityId: '1');
        }
        if (name.startsWith('location-')) {
          screen =
              const TrainingLocationScreen(communityId: '1', locationId: '1');
        }
        if (name.startsWith('session-form')) {
          screen = const TrainingSessionScreen(communityId: '1');
        }
        if (name.startsWith('report-') || name == 'recipient-report') {
          screen = const TrainingReportScreen(communityId: '1');
        }
        if (name == 'recipient-report') {
          repo.reportValue = reportFixture(recipient: true);
        }
        if (name == 'empty') {
          repo.value = trainingFixture(empty: true, founder: false);
        }
        if (name == 'inactive') repo.value = trainingFixture(active: false);
        if (name == 'pending') repo.value = trainingFixture(ownPending: true);
        if (name == 'error') {
          repo.loadError = const NetworkException(
              'Koneksi terputus. Periksa koneksi lalu coba lagi.');
        }
        if (name == 'loading') repo.loadGate = Completer<void>();
        final boundaryKey = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: boundaryKey,
            child: trainingApp(screen, repo,
                scale: name.contains('large') ? 1.5 : 1)));
        if (name == 'loading') {
          await t.pump(const Duration(milliseconds: 500));
        } else {
          await t.pumpAndSettle();
        }
        Future<void> tab(String text) async {
          await t.tap(find.text(text).first);
          await t.pumpAndSettle();
        }

        if (name == 'sessions' || name == 'pending') await tab('Latihan');
        if (name == 'history' || name == 'attendance-detail-large') {
          await tab('Riwayat');
        }
        if (name == 'locations') await tab('Lokasi');
        if ([
              'owned-packages',
              'catalog-locations',
              'location-recipients',
              'report-details'
            ].contains(name) ||
            name == 'location-recipients-large') {
          await t.drag(find.byType(ListView), const Offset(0, -1200));
          await t.pumpAndSettle();
        }
        if (name == 'attendance-detail-large') {
          await t
              .ensureVisible(find.byKey(const Key('attendance-attendance-1')));
          await t.tap(find.byKey(const Key('attendance-attendance-1')));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s04-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        if (name == 'loading') {
          repo.loadGate!.complete();
          await t.pumpAndSettle();
        }
      });
    }
  }
}
