import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:app_main/app.dart';
import 'package:app_main/config/main_config.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/finance/presentation/wallet_screen.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
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
import 'finance_screens_test.dart' show FakeFinance;

class _Database extends Mock implements AppDatabase {}

class _Storage implements StorageService {
  final values = <String, String>{};
  Completer<void>? reads, deletes;
  @override
  Future<void> init() async {}
  @override
  Future<String?> read(String key) async {
    if (key == 'auth_user') await reads?.future;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    await deletes?.future;
    values.remove(key);
  }

  @override
  Future<void> clear() async {
    values.clear();
  }
}

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.status = 200});
  final int status;
  int requests = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    requests++;
    return ResponseBody.fromString(
        jsonEncode(status == 200
            ? {'success': true, 'data': _cached.toJson()}
            : {'success': false, 'message': 'Sesi fixture ditolak.'}),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType]
        });
  }

  @override
  void close({bool force = false}) {}
}

const _cached = UserModel(
    id: '1',
    name: 'Akun Fixture',
    email: 'fixture@anaklangit.manahpro.web.id',
    token: 'fixture-token',
    serverCompletion: ProfileCompletion(completed: 12, total: 12, missing: []));
AuthRepository _repository(_Storage storage, _AuthAdapter adapter) =>
    AuthRepositoryImpl(
        local: AuthLocalDataSource(storage),
        remote: AuthRemoteDataSource(
            Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
              ..httpClientAdapter = adapter));
Widget _application(_Storage storage, _AuthAdapter adapter, FakeFinance finance,
        {bool bootstrap = true}) =>
    ProviderScope(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_repository(storage, adapter)),
          financeRepositoryProvider.overrideWithValue(finance),
          settingsRepositoryProvider
              .overrideWith((ref) async => SettingsRepositoryImpl(storage)),
          communityRepositoryProvider.overrideWithValue(FakeCommunityRepository(
              detail: testDetail(myRole: CommunityRole.member),
              joined: [testCommunity('1', myRole: CommunityRole.member)])),
          homePromotionsProvider
              .overrideWith((ref) async => const HomePromotions(banners: [])),
        ],
        child: bootstrap
            ? App(storage: storage, database: _Database())
            : MaterialApp.router(
                theme: AppTheme.light, routerConfig: appRouter));
Future<void> _ticks(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 10));
  }
}

ProviderContainer _container(WidgetTester t) =>
    ProviderScope.containerOf(t.element(find.byType(MaterialApp)));
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
  final privateRoutes = [
    '/wallet',
    '/wallet/topup?community=1',
    '/wallet/receipts?community=1&manage=1',
    '/wallet/transactions/journal-1?scope=community&community=1',
    '/billing-notices',
    '/notifications',
    '/communities/1/billing?scope=member&member=42',
    '/communities/1/billing/settings',
    '/communities/1/billing/inactive',
    '/communities/1/dues',
    '/communities/1/dues/pay',
    '/communities/1/card',
  ];
  for (final route in privateRoutes) {
    testWidgets(
        'real App delays private builder until storage resolves: $route',
        (t) async {
      final storage = _Storage()..reads = Completer<void>();
      final adapter = _AuthAdapter();
      final finance = FakeFinance();
      appRouter.go(route);
      await t.pumpWidget(_application(storage, adapter, finance));
      await _ticks(t);
      expect(_container(t).read(authProvider), isA<AuthLoading>());
      expect(appRouter.routeInformationProvider.value.uri.path,
          AppRoutes.authCheck);
      expect(
          appRouter.routeInformationProvider.value.uri.queryParameters['from'],
          route);
      expect(finance.walletCalls, 0);
      expect(finance.calls, isEmpty);
      expect(adapter.requests, 0);
      expect(find.byType(WalletScreen), findsNothing);
      storage.reads!.complete();
      await t.pumpAndSettle();
      final uri = appRouter.routeInformationProvider.value.uri;
      expect(uri.path, '/login');
      expect(uri.queryParameters['from'], route);
      expect(finance.walletCalls, 0);
      expect(finance.calls, isEmpty);
    });
  }
  for (final status in [401, 403]) {
    testWidgets(
        'real cached profile rejected HTTP$status is cleared without private reads',
        (t) async {
      final storage = _Storage()..reads = Completer<void>();
      storage.values.addAll({
        'auth_user': jsonEncode(_cached.toJson()),
        AppConstants.keyAuthToken: 'fixture-rejected'
      });
      final adapter = _AuthAdapter(status: status), finance = FakeFinance();
      const route = '/communities/1/billing?scope=member&member=42';
      appRouter.go(route);
      await t.pumpWidget(_application(storage, adapter, finance));
      await _ticks(t);
      expect(finance.calls, isEmpty);
      storage.reads!.complete();
      await t.pumpAndSettle();
      expect(adapter.requests, 1);
      expect(storage.values.containsKey('auth_user'), false);
      expect(storage.values.containsKey(AppConstants.keyAuthToken), false);
      expect(_container(t).read(authProvider), isA<AuthUnauthenticated>());
      expect(appRouter.routeInformationProvider.value.uri.path, '/login');
      expect(
          appRouter.routeInformationProvider.value.uri.queryParameters['from'],
          route);
      expect(finance.walletCalls, 0);
      expect(finance.calls, isEmpty);
    });
  }
  testWidgets(
      'valid delayed session opens requested wallet after check exactly once',
      (t) async {
    final storage = _Storage()..reads = Completer<void>();
    storage.values['auth_user'] = jsonEncode(_cached.toJson());
    final adapter = _AuthAdapter(), finance = FakeFinance();
    appRouter.go('/wallet?scope=identity');
    await t.pumpWidget(_application(storage, adapter, finance));
    await _ticks(t);
    expect(finance.walletCalls, 0);
    storage.reads!.complete();
    await t.pumpAndSettle();
    expect(adapter.requests, 1);
    expect(find.byType(WalletScreen), findsOneWidget);
    expect(appRouter.routeInformationProvider.value.uri.toString(),
        '/wallet?scope=identity');
    expect(finance.walletCalls, 1);
  });
  testWidgets(
      'session expiry redirects immediately while storage cleanup waits',
      (t) async {
    final storage = _Storage();
    storage.values['auth_user'] = jsonEncode(_cached.toJson());
    final adapter = _AuthAdapter(), finance = FakeFinance();
    const route = '/wallet?scope=community&community=1';
    appRouter.go(route);
    await t.pumpWidget(_application(storage, adapter, finance));
    await t.pumpAndSettle();
    final readsBefore = finance.walletCalls,
        historyBefore = finance.calls.length;
    storage.deletes = Completer<void>();
    final expired = _container(t).read(authProvider.notifier).sessionExpired();
    await _ticks(t);
    expect(appRouter.routeInformationProvider.value.uri.path, '/login');
    expect(finance.walletCalls, readsBefore);
    expect(finance.calls.length, historyBefore);
    expect(finance.submitted, isEmpty);
    expect(finance.payKeys, isEmpty);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, '/login');
    await t.pumpAndSettle();
    expect(find.byType(WalletScreen), findsNothing);
    expect(appRouter.routeInformationProvider.value.uri.queryParameters['from'],
        route);
    storage.deletes!.complete();
    await expired;
    await t.pumpAndSettle();
    expect(_container(t).read(authProvider), isA<AuthUnauthenticated>());
  });
  testWidgets(
      'logout removes private view and preserves return even during logout loading',
      (t) async {
    final storage = _Storage();
    storage.values['auth_user'] = jsonEncode(_cached.toJson());
    final adapter = _AuthAdapter(), finance = FakeFinance();
    appRouter.go('/wallet');
    await t.pumpWidget(_application(storage, adapter, finance));
    await t.pumpAndSettle();
    final readsBefore = finance.walletCalls,
        historyBefore = finance.calls.length;
    storage.deletes = Completer<void>();
    final logout = _container(t).read(authProvider.notifier).logout();
    await _ticks(t);
    expect(
        appRouter.routeInformationProvider.value.uri.path, AppRoutes.authCheck);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path,
        AppRoutes.authCheck);
    expect(finance.walletCalls, readsBefore);
    expect(finance.calls.length, historyBefore);
    expect(finance.submitted, isEmpty);
    expect(finance.payKeys, isEmpty);
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(WalletScreen), findsNothing);
    storage.deletes!.complete();
    await logout;
    await t.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/login');
    expect(appRouter.routeInformationProvider.value.uri.queryParameters['from'],
        '/wallet');
  });
  testWidgets(
      'auth error while restoring session reaches login with full return target',
      (t) async {
    final storage = _Storage()..reads = Completer<void>();
    final adapter = _AuthAdapter(), finance = FakeFinance();
    const route = '/wallet/receipts?community=7&manage=1';
    appRouter.go(route);
    await t.pumpWidget(_application(storage, adapter, finance));
    await _ticks(t);
    storage.reads!
        .completeError(const ServerException('Sesi tidak dapat dimuat.'));
    await t.pumpAndSettle();
    expect(_container(t).read(authProvider), isA<AuthError>());
    expect(appRouter.routeInformationProvider.value.uri.path, '/login');
    expect(appRouter.routeInformationProvider.value.uri.queryParameters['from'],
        route);
    expect(finance.calls, isEmpty);
  });
  testWidgets(
      'successful login returns to original managed billing URI after bootstrap',
      (t) async {
    final storage = _Storage()..reads = Completer<void>();
    final adapter = _AuthAdapter(), finance = FakeFinance();
    const route = '/communities/1/billing?scope=member&member=42';
    appRouter.go(route);
    await t.pumpWidget(_application(storage, adapter, finance));
    await _ticks(t);
    storage.reads!.complete();
    await t.pumpAndSettle();
    _container(t).read(authProvider.notifier).acceptAuthenticatedUser(_cached);
    await t.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.toString(), route);
    expect(finance.calls, contains('billing:1:member:42'));
  });
  testWidgets(
      'financial401 offers explicit login preserving URI without App refresh listener',
      (t) async {
    final storage = _Storage();
    storage.values['auth_user'] = jsonEncode(_cached.toJson());
    final adapter = _AuthAdapter(),
        finance = FakeFinance()
          ..loadError = const FinanceAuthenticationException();
    const route = '/wallet?scope=community&community=1';
    appRouter.go(route);
    await t
        .pumpWidget(_application(storage, adapter, finance, bootstrap: false));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('finance-login')), findsWidgets);
    await t.tap(find.byKey(const Key('finance-login')).first);
    await t.pumpAndSettle();
    expect(appRouter.routeInformationProvider.value.uri.path, '/login');
    expect(appRouter.routeInformationProvider.value.uri.queryParameters['from'],
        route);
  });
}
