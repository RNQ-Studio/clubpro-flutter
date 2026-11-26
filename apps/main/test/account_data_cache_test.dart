import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_main/app.dart';
import 'package:app_main/config/main_config.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/dues/presentation/widgets/dues_visuals.dart';
import 'package:app_main/router/app_router.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'features/community/fake_community_repository.dart';
import 'features/marketplace/fake_marketplace_repository.dart'
    show MarketStorage;

class _Database extends Mock implements AppDatabase {}

const _accountA = UserModel(
    id: 'account-a',
    name: 'Akun A Fixture',
    email: 'a@anaklangit.manahpro.web.id',
    token: 'fixture-a',
    serverCompletion: ProfileCompletion(completed: 12, total: 12, missing: []));
const _accountB = UserModel(
    id: 'account-b',
    name: 'Akun B Fixture',
    email: 'b@anaklangit.manahpro.web.id',
    token: 'fixture-b',
    serverCompletion: ProfileCompletion(completed: 12, total: 12, missing: []));

class _ProfileAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancel) async =>
      _json({'success': true, 'data': _accountA.toJson()});
  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, Object?> value) =>
    ResponseBody.fromString(jsonEncode(value), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType]
    });

/// Only transport is synthetic; the wallet provider, repository and JSON parser
/// are the production implementations. Each response captures its request owner.
class _WalletAdapter implements HttpClientAdapter {
  String owner = 'a';
  final gates = <String, Completer<void>>{};
  final requests = <String>[];
  final adGates = <String, Completer<void>>{};
  final adRequests = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    if (options.path.contains('/advertisements/')) {
      final requestedOwner = owner;
      adRequests.add(requestedOwner);
      await adGates[requestedOwner]?.future;
      if (requestedOwner == 'b') {
        return ResponseBody.fromString(
            jsonEncode({'success': false, 'message': 'Forbidden.'}), 403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            });
      }
      return _json({
        'success': true,
        'data': {
          'id': 'private-ad',
          'title': 'PRIVATE_A_TITLE_FIXTURE',
          'body': 'PRIVATE_A_BODY_FIXTURE',
          'community': {'id': 1, 'name': 'Komunitas A'},
          'seller': {'identity_id': 1, 'name': 'Akun A'},
          'version': 1,
          'is_active': false,
        }
      });
    }
    if (options.path.endsWith('/transactions')) {
      return _json({
        'success': true,
        'data': {'items': [], 'current_page': 1, 'last_page': 1}
      });
    }
    final requestedOwner = owner;
    requests.add(requestedOwner);
    await gates[requestedOwner]?.future;
    return _json({
      'success': true,
      'data': {
        'identity_id': requestedOwner,
        'available': requestedOwner == 'a' ? 111111 : 222222,
        'reserved': 0,
        'held': 0,
      }
    });
  }

  @override
  void close({bool force = false}) {}
}

class _Communities extends FakeCommunityRepository {
  String owner = 'a';
  final gates = <String, Completer<void>>{};
  final requestedAccounts = <String>[];

  @override
  Future<List<Community>> getJoined({bool includePending = false}) async {
    final requestedOwner = owner;
    requestedAccounts.add(requestedOwner);
    await gates[requestedOwner]?.future;
    return [testCommunity(requestedOwner, name: 'Komunitas $requestedOwner')];
  }
}

Widget _application(
    MarketStorage storage, _WalletAdapter wallet, _Communities communities) {
  final api = DioClient(storage)..dio.httpClientAdapter = wallet;
  final authDio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = _ProfileAdapter();
  return ProviderScope(overrides: [
    authRepositoryProvider.overrideWithValue(AuthRepositoryImpl(
        local: AuthLocalDataSource(storage),
        remote: AuthRemoteDataSource(authDio))),
    apiClientProvider.overrideWithValue(api),
    communityRepositoryProvider.overrideWithValue(communities),
    settingsRepositoryProvider
        .overrideWith((ref) async => SettingsRepositoryImpl(storage)),
  ], child: App(storage: storage, database: _Database()));
}

Future<void> _ticks(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

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

  for (final lateFirstResponse in [false, true]) {
    testWidgets(
        'actual App clears account caches; late A response=$lateFirstResponse',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final storage = MarketStorage()
        ..values['auth_user'] = jsonEncode(_accountA.toJson());
      final wallet = _WalletAdapter();
      final communities = _Communities();
      if (lateFirstResponse) {
        wallet.gates['a'] = Completer<void>();
        communities.gates['a'] = Completer<void>();
      }
      appRouter.go('/wallet');
      await tester.pumpWidget(_application(storage, wallet, communities));
      await _ticks(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      final joined = container.listen(joinedCommunitiesProvider, (_, __) {});
      addTearDown(joined.close);
      await _ticks(tester);
      expect(container.read(authProvider), isA<AuthAuthenticated>());
      expect(wallet.requests, contains('a'));
      expect(communities.requestedAccounts, contains('a'));
      if (!lateFirstResponse) {
        expect(container.read(walletSummaryProvider).requireValue.available,
            111111);
        expect(joined.read().requireValue.single.id, 'a');
        expect(find.text(formatRupiah(111111)), findsWidgets);
      }

      wallet.gates['b'] = Completer<void>();
      communities.gates['b'] = Completer<void>();
      wallet.owner = 'b';
      communities.owner = 'b';
      // Production auth method and actual App/router listener, with no provider
      // overrides for wallet/joined data and no manual invalidation in the test.
      container.read(authProvider.notifier).acceptAuthenticatedUser(_accountB);
      await _ticks(tester);
      expect(container.read(walletSummaryProvider).isLoading, true);
      expect(container.read(walletSummaryProvider).asData, null);
      expect(joined.read().isLoading, true);
      expect(joined.read().asData, null);
      expect(find.text(formatRupiah(111111)), findsNothing);
      expect(wallet.requests.last, 'b');
      expect(communities.requestedAccounts.last, 'b');

      if (lateFirstResponse) {
        wallet.gates['a']!.complete();
        communities.gates['a']!.complete();
        await _ticks(tester);
        expect(container.read(walletSummaryProvider).asData, null);
        expect(joined.read().asData, null);
        expect(find.text(formatRupiah(111111)), findsNothing);
      }
      wallet.gates['b']!.complete();
      communities.gates['b']!.complete();
      await tester.pumpAndSettle();
      expect(
          container.read(walletSummaryProvider).requireValue.available, 222222);
      expect(joined.read().requireValue.single.id, 'b');
      expect(find.text(formatRupiah(222222)), findsWidgets);
      expect(find.text(formatRupiah(111111)), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
        'actual App disposes private editor; late A load=$lateFirstResponse',
        (tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final storage = MarketStorage()
        ..values['auth_user'] = jsonEncode(_accountA.toJson());
      final api = _WalletAdapter();
      if (lateFirstResponse) api.adGates['a'] = Completer<void>();
      appRouter.go('/advertisements/private-ad/edit');
      await tester.pumpWidget(_application(storage, api, _Communities()));
      await _ticks(tester);
      expect(api.adRequests, contains('a'));
      if (!lateFirstResponse) {
        expect(find.text('PRIVATE_A_TITLE_FIXTURE'), findsOneWidget);
        expect(find.text('PRIVATE_A_BODY_FIXTURE'), findsOneWidget);
      }
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      api.adGates['b'] = Completer<void>();
      api.owner = 'b';
      container.read(authProvider.notifier).acceptAuthenticatedUser(_accountB);
      await _ticks(tester);
      expect(find.text('PRIVATE_A_TITLE_FIXTURE'), findsNothing);
      expect(find.text('PRIVATE_A_BODY_FIXTURE'), findsNothing);
      expect(api.adRequests.last, 'b');
      if (lateFirstResponse) {
        api.adGates['a']!.complete();
        await _ticks(tester);
        expect(find.text('PRIVATE_A_TITLE_FIXTURE'), findsNothing);
        expect(find.text('PRIVATE_A_BODY_FIXTURE'), findsNothing);
      }
      api.adGates['b']!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Anda tidak berhak melakukan tindakan ini.'),
          findsOneWidget);
      expect(find.text('PRIVATE_A_TITLE_FIXTURE'), findsNothing);
      expect(find.byKey(const Key('ad-save')), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
