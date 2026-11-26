import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_main/app.dart';
import 'package:app_main/config/main_config.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/marketplace/presentation/market_checkout_screen.dart';
import 'package:app_main/features/marketplace/presentation/marketplace_providers.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../community/fake_community_repository.dart';
import '../finance/finance_screens_test.dart' show FakeFinance;
import 'fake_marketplace_repository.dart';

class _Database extends Mock implements AppDatabase {}

const _cached = UserModel(
    id: '1',
    name: 'Akun Fixture',
    email: 'fixture@anaklangit.manahpro.web.id',
    token: 'fixture-token',
    serverCompletion: ProfileCompletion(completed: 12, total: 12, missing: []));

/// Real AuthRepositoryImpl + AuthNotifier are used, including AuthLoading.
/// Only HTTP transport is synthetic; a gate keeps the refresh pending long
/// enough for the actual App's global router listener to redirect and rebuild.
class _AuthAdapter implements HttpClientAdapter {
  int requests = 0;
  final refresh = Completer<void>();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests++;
    if (requests > 1) await refresh.future;
    return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {..._cached.toJson(), 'pin_enabled': requests > 1}
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

class _PinRepository implements PinRepository {
  int saves = 0;

  @override
  Future<bool> emailRecoveryAvailable() async => false;
  @override
  Future<User> login(String identifier, String pin) async => _cached;
  @override
  Future<void> save(String pin,
      {String? currentPin,
      String? currentPassword,
      String? verificationMethod,
      bool useRecentGoogleAuth = false}) async {
    saves++;
  }

  @override
  Future<void> recover(String identifier) async {}
  @override
  Future<void> reset(String identifier, String code, String pin) async {}
}

Widget _application(MarketStorage storage, _AuthAdapter adapter,
        _PinRepository pin, FakeMarketplace market) =>
    ProviderScope(overrides: [
      authRepositoryProvider.overrideWithValue(AuthRepositoryImpl(
          local: AuthLocalDataSource(storage),
          remote: AuthRemoteDataSource(Dio(
              BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
            ..httpClientAdapter = adapter))),
      pinRepositoryProvider.overrideWithValue(pin),
      marketplaceRepositoryProvider.overrideWithValue(market),
      financeRepositoryProvider.overrideWithValue(FakeFinance()),
      settingsRepositoryProvider
          .overrideWith((ref) async => SettingsRepositoryImpl(storage)),
      communityRepositoryProvider.overrideWithValue(FakeCommunityRepository()),
      homePromotionsProvider
          .overrideWith((ref) async => const HomePromotions(banners: [])),
    ], child: App(storage: storage, database: _Database()));

Future<void> _ticks(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _savePin(WidgetTester tester) async {
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Password akun saat ini'),
      'fixture-password');
  await tester.enterText(
      find.widgetWithText(TextFormField, 'PIN baru'), '000000');
  await tester.enterText(
      find.widgetWithText(TextFormField, 'Ulangi PIN baru'), '000000');
  final save = find.text('Simpan PIN');
  await tester.ensureVisible(save);
  await tester.tap(save);
  await _ticks(tester);
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

void main() {
  setUp(() {
    AppConfig.instance = MainConfig();
    PackageInfo.setMockInitialValues(
        appName: 'CEO',
        packageName: 'fixture',
        version: '1',
        buildNumber: '1',
        buildSignature: '');
  });

  for (final target in [
    '/marketplace/checkout/product-1',
    '/marketplace/checkout/product-1?source=community&community=2'
  ]) {
    testWidgets('real App preserves checkout through PIN AuthLoading: $target',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final storage = MarketStorage()
        ..values['auth_user'] = jsonEncode(_cached.toJson());
      final adapter = _AuthAdapter();
      final pin = _PinRepository();
      final market = FakeMarketplace();
      appRouter.go('/account/pin?from=${encodeLoginReturn(target)}');
      await tester.pumpWidget(_application(storage, adapter, pin, market));
      await tester.pumpAndSettle();
      expect(_container(tester).read(authProvider), isA<AuthAuthenticated>());
      expect(adapter.requests, 1);
      await _savePin(tester);
      expect(pin.saves, 1);
      expect(adapter.requests, 2);
      expect(_container(tester).read(authProvider), isA<AuthLoading>());
      expect(appRouter.routeInformationProvider.value.uri.path,
          AppRoutes.authCheck);
      expect(
          decodeLoginReturn(appRouter
              .routeInformationProvider.value.uri.queryParameters['from']),
          target);
      adapter.refresh.complete();
      await tester.pumpAndSettle();
      expect(appRouter.routeInformationProvider.value.uri.toString(), target);
      expect(find.byType(MarketCheckoutScreen), findsOneWidget);
      expect(
          _container(tester).read(authProvider),
          isA<AuthAuthenticated>()
              .having((a) => a.user.pinEnabled, 'PIN', true));
      expect(market.buyCalls, 0);
      expect(tester.takeException(), null);
    });
  }

  testWidgets('PIN return rejects absolute URL instead of leaving the app',
      (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final storage = MarketStorage()
      ..values['auth_user'] = jsonEncode(_cached.toJson());
    final adapter = _AuthAdapter();
    final pin = _PinRepository();
    appRouter.go(Uri(path: '/account/pin', queryParameters: {
      'from': 'https://anaklangit.manahpro.web.id/api/'
    }).toString());
    await tester
        .pumpWidget(_application(storage, adapter, pin, FakeMarketplace()));
    await tester.pumpAndSettle();
    await _savePin(tester);
    adapter.refresh.complete();
    await tester.pumpAndSettle();
    expect(pin.saves, 1);
    expect(appRouter.routeInformationProvider.value.uri.path, '/account/pin');
    expect(appRouter.routeInformationProvider.value.uri.hasAuthority, false);
    expect(tester.takeException(), null);
  });
}
