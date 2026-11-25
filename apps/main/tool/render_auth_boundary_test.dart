import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/finance_widgets.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'render_s03_test.dart' as fonts;
import '../test/features/finance/finance_screens_test.dart' as fixture;

class _PendingAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthInitial();
  @override
  Future<void> checkCurrentUser() async {}
}

void main() {
  setUpAll(fonts.fonts);
  for (final width in [500.0, 1280.0]) {
    for (final check in [true, false]) {
      testWidgets(
          '${check ? 'session-check' : 'finance-login-required'} at $width',
          (t) async {
        t.view.physicalSize = Size(width, 950);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final key = GlobalKey();
        if (check) {
          appRouter.go('/wallet?scope=community&community=1');
          await t.pumpWidget(RepaintBoundary(
              key: key,
              child: ProviderScope(
                  overrides: [authProvider.overrideWith(_PendingAuth.new)],
                  child: MaterialApp.router(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.light,
                      routerConfig: appRouter))));
          await t.pump(const Duration(milliseconds: 200));
          await t.pump(const Duration(milliseconds: 100));
        } else {
          await t.pumpWidget(RepaintBoundary(
              key: key,
              child: fixture.financeApp(Scaffold(
                  appBar: AppBar(title: const Text('Saldo & riwayat')),
                  body: FinanceError(
                      error: const FinanceAuthenticationException(),
                      retry: () {})))));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1),
              bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir =
              Platform.environment['RENDER_DIR'] ?? 'build/s03-auth-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/${check ? 'session-check' : 'finance-login-required'}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
