import 'dart:async';
import 'package:app_main/features/training/domain/training.dart';
import 'package:app_main/features/training/presentation/training_providers.dart';
import 'package:app_main/features/training/presentation/training_screen.dart';
import 'package:app_main/features/training/presentation/training_settings_screen.dart';
import 'package:app_main/features/training/presentation/training_session_screen.dart';
import 'package:app_main/features/training/presentation/training_report_screen.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../finance/finance_screens_test.dart' show FakeFinance;
import 'fake_training_repository.dart';

Widget trainingApp(Widget screen, FakeTraining repo, {double scale = 1}) =>
    ProviderScope(
        overrides: [
          trainingRepositoryProvider.overrideWithValue(repo),
          financeRepositoryProvider.overrideWithValue(FakeFinance())
        ],
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            routerConfig: GoRouter(initialLocation: '/screen', routes: [
              GoRoute(
                  path: '/',
                  builder: (_, state) =>
                      const Scaffold(body: Text('Kembali ke latihan')),
                  routes: [
                    GoRoute(path: 'screen', builder: (_, state) => screen)
                  ]),
              GoRoute(
                  path: '/communities/:id/training/settings',
                  builder: (_, state) =>
                      const TrainingSettingsScreen(communityId: '1')),
              GoRoute(
                  path: '/communities/:id/training/locations/new',
                  builder: (_, state) =>
                      const TrainingLocationScreen(communityId: '1')),
              GoRoute(
                  path: '/communities/:id/training/locations/:locationId',
                  builder: (_, s) => TrainingLocationScreen(
                      communityId: '1',
                      locationId: s.pathParameters['locationId'])),
              GoRoute(
                  path: '/communities/:id/training/sessions/new',
                  builder: (_, state) =>
                      const TrainingSessionScreen(communityId: '1')),
              GoRoute(
                  path: '/communities/:id/training/report',
                  builder: (_, state) =>
                      const TrainingReportScreen(communityId: '1')),
              GoRoute(
                  path: '/wallet/topup',
                  builder: (_, state) =>
                      const Scaffold(body: Text('Top up saldo tersedia'))),
              GoRoute(
                  path: '/communities/:id/billing',
                  builder: (_, state) =>
                      const Scaffold(body: Text('Pembayaran keanggotaan')))
            ])));
void trainingSize(WidgetTester t, {double width = 500, double height = 1100}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> tapVisible(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
      'purchase uses quote once and retry preserves idempotency after network failure',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining()
      ..actionError = const NetworkException('Koneksi terputus.');
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const Key('training-buy-7')));
    await tapVisible(t, find.byKey(const Key('training-buy-confirm')));
    expect(repo.calls, ['purchase']);
    expect(repo.bodies.single,
        {'sessions': 7, 'expected_price': 100003, 'catalog_version': 2});
    await tapVisible(t, find.byKey(const Key('training-buy-7')));
    await tapVisible(t, find.byKey(const Key('training-buy-confirm')));
    expect(repo.keys[0], repo.keys[1]);
    repo.actionError = null;
    await tapVisible(t, find.byKey(const Key('training-buy-7')));
    await tapVisible(t, find.byKey(const Key('training-buy-confirm')));
    expect(repo.keys.toSet().length, 1);
    await t.drag(find.byType(ListView), const Offset(0, 1000));
    await t.pumpAndSettle();
    expect(find.textContaining('Dana dicadangkan sekali'), findsOneWidget);
  });
  testWidgets('busy purchase blocks duplicate taps', (t) async {
    trainingSize(t);
    final repo = FakeTraining()..actionGate = Completer<void>();
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const Key('training-buy-7')));
    await t.tap(find.byKey(const Key('training-buy-confirm')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(repo.calls, ['purchase']);
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('training-buy-7')))
            .onPressed,
        null);
    repo.actionGate!.complete();
    await t.pumpAndSettle();
  });
  testWidgets(
      'check-in is pending; staff confirmation chooses target and never calls purchase',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining();
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.text('Latihan').first);
    await tapVisible(t, find.byKey(const Key('training-checkin-1')));
    expect(repo.calls, ['checkin']);
    expect(find.textContaining('Jatah dan dana belum berubah'), findsOneWidget);
    await tapVisible(t, find.byKey(const Key('training-confirm-1')));
    await tapVisible(t, find.byKey(const Key('training-confirm-member')));
    await tapVisible(t, find.text('Atlet Fixture').last);
    await tapVisible(t, find.byKey(const Key('training-confirm-submit')));
    expect(repo.calls, ['checkin', 'confirm']);
    expect(repo.bodies.last['member_id'], '3');
  });
  testWidgets('inactive member and location disable attendance and purchase',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining()..value = trainingFixture(active: false);
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('training-buy-7')))
            .onPressed,
        null);
    await tapVisible(t, find.text('Latihan').first);
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const Key('training-checkin-1')))
            .onPressed,
        null);
    repo.value = trainingFixture(locationActive: false);
    ProviderScope.containerOf(t.element(find.byType(TrainingScreen)))
        .invalidate(trainingOverviewProvider('1'));
    await t.pumpAndSettle();
    expect(find.textContaining('Lokasi tidak aktif'), findsOneWidget);
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('training-confirm-1')))
            .onPressed,
        null);
  });
  testWidgets('existing own check-in disables second request', (t) async {
    trainingSize(t);
    final repo = FakeTraining()..value = trainingFixture(ownPending: true);
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.text('Latihan').first);
    expect(
        t
            .widget<OutlinedButton>(find.byKey(const Key('training-checkin-1')))
            .onPressed,
        null);
    expect(repo.calls, isEmpty);
  });
  testWidgets('history shows immutable splits and technical correction reason',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining();
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.text('Riwayat'));
    await tapVisible(t, find.byKey(const Key('attendance-attendance-1')));
    expect(find.text('Pelatih Fixture: Rp8.000'), findsOneWidget);
    expect(find.text('Kas komunitas: Rp2.286'), findsOneWidget);
    await tapVisible(t, find.byKey(const Key('training-correct')));
    await t.enterText(find.byKey(const Key('training-correction-reason')),
        'Koreksi salah konfirmasi fixture');
    await tapVisible(t, find.byKey(const Key('training-correct-submit')));
    expect(repo.calls, ['correct']);
    expect(repo.bodies.single['reason'], 'Koreksi salah konfirmasi fixture');
  });
  testWidgets('catalog validates larger package cheaper and sends version',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining();
    await t.pumpWidget(
        trainingApp(const TrainingSettingsScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.descendant(
            of: find.byKey(const Key('training-price-14')),
            matching: find.byType(TextFormField)),
        '250000');
    await tapVisible(t, find.byKey(const Key('training-save-catalog')));
    expect(repo.calls, isEmpty);
    expect(find.byKey(const Key('finance-error')), findsOneWidget);
    await t.enterText(
        find.descendant(
            of: find.byKey(const Key('training-price-14')),
            matching: find.byType(TextFormField)),
        '180005');
    await tapVisible(t, find.byKey(const Key('training-save-catalog')));
    expect(repo.calls, ['catalog']);
    expect(repo.bodies.single['expected_version'], 2);
  });
  testWidgets(
      'catalog conflict requires explicit reload and non-founder cannot configure',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining()
      ..actionError = const FinanceConflictException('Versi telah berubah.');
    await t.pumpWidget(
        trainingApp(const TrainingSettingsScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const Key('training-save-catalog')));
    expect(
        t
            .widget<FilledButton>(
                find.byKey(const Key('training-save-catalog')))
            .onPressed,
        null);
    expect(find.text('Muat ulang aturan terbaru'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(trainingApp(
        const TrainingSettingsScreen(communityId: '1'),
        FakeTraining()..value = trainingFixture(founder: false)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('training-save-catalog')), findsNothing);
    expect(find.textContaining('Hanya pendiri komunitas'), findsOneWidget);
  });
  testWidgets(
      'location form sends community managers and nominal including zero',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining();
    await t.pumpWidget(trainingApp(
        const TrainingLocationScreen(communityId: '1', locationId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.descendant(
            of: find.byKey(const Key('training-split-2')),
            matching: find.byType(TextFormField)),
        '0');
    await tapVisible(t, find.byKey(const Key('training-save-location')));
    expect(repo.calls, ['location:1']);
    expect(repo.bodies.single['manager_member_ids'], [2]);
    expect(repo.bodies.single['splits'], [
      {'member_id': 2, 'amount': 0},
      {'member_id': 4, 'amount': 4000}
    ]);
    expect(repo.bodies.single['expected_version'], 2);
  });
  testWidgets(
      'session converts WIB independent of local timezone and retry key is stable',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining()
      ..actionError = const NetworkException('Koneksi terputus.');
    await t.pumpWidget(
        trainingApp(const TrainingSessionScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('training-session-title')), 'Latihan fixture');
    await tapVisible(t, find.byKey(const Key('training-session-location')));
    await tapVisible(t, find.text('Lapangan Utama').last);
    await t.enterText(
        find.byKey(const Key('training-session-start')), '2026-11-26 16:00');
    await t.enterText(
        find.byKey(const Key('training-session-end')), '2026-11-26 18:00');
    await tapVisible(t, find.byKey(const Key('training-save-session')));
    await tapVisible(t, find.byKey(const Key('training-save-session')));
    expect(repo.keys[0], repo.keys[1]);
    expect(repo.bodies.first['starts_at'], '2026-11-26T09:00:00.000Z');
  });
  testWidgets(
      'report filters pass WIB dates and displays community reconciliation',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining();
    await t.pumpWidget(
        trainingApp(const TrainingReportScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.byKey(const Key('training-report-from')), '2026-11-01');
    await t.enterText(
        find.byKey(const Key('training-report-to')), '2026-11-26');
    await tapVisible(t, find.byKey(const Key('training-apply-report')));
    expect(repo.filters.last['from'], '2026-11-01');
    expect(repo.filters.last['to'], '2026-11-26');
    await t.ensureVisible(find.byKey(const Key('training-report-balanced')));
    expect(find.textContaining('Seimbang: harga dibayar'), findsOneWidget);
  });
  testWidgets('recipient report never claims global reconciliation', (t) async {
    trainingSize(t);
    final repo = FakeTraining()..reportValue = reportFixture(recipient: true);
    await t.pumpWidget(
        trainingApp(const TrainingReportScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('training-report-balanced')), findsNothing);
    expect(find.text('Hanya pendapatan Anda'), findsOneWidget);
    expect(find.textContaining('Atlet Fixture'), findsNothing);
    expect(find.text('Lapangan Utama'), findsNothing);
    expect(find.text('Per lokasi'), findsNothing);
    expect(find.byKey(const Key('attendance-attendance-1')), findsNothing);
  });
  testWidgets('loading empty and error retry recover', (t) async {
    trainingSize(t);
    final repo = FakeTraining()
      ..loadGate = Completer<void>()
      ..value = trainingFixture(empty: true);
    await t
        .pumpWidget(trainingApp(const TrainingScreen(communityId: '1'), repo));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.loadGate!.complete();
    await t.pumpAndSettle();
    expect(find.textContaining('Belum ada paket dibeli'), findsOneWidget);
    repo.loadError = const NetworkException('Koneksi fixture terputus.');
    ProviderScope.containerOf(t.element(find.byType(TrainingScreen)))
        .invalidate(trainingOverviewProvider('1'));
    await t.pumpAndSettle();
    expect(find.text('Koneksi fixture terputus.'), findsOneWidget);
    repo.loadError = null;
    await tapVisible(t, find.text('Coba Lagi'));
    expect(find.textContaining('Belum ada paket dibeli'), findsOneWidget);
  });
  testWidgets(
      'stale inactive recipients and managers are removed with explanation before save',
      (t) async {
    trainingSize(t);
    final source = trainingFixture();
    final repo = FakeTraining()
      ..value = TrainingOverview(
          canConfigure: true,
          active: true,
          locations: source.locations,
          members: const [TrainingMember('3', 'Atlet Fixture', 'member')]);
    await t.pumpWidget(trainingApp(
        const TrainingLocationScreen(communityId: '1', locationId: '1'), repo));
    await t.pumpAndSettle();
    expect(find.textContaining('akan dihapus saat Anda menyimpan'),
        findsOneWidget);
    await tapVisible(t, find.byKey(const Key('training-save-location')));
    expect(repo.calls, ['location:1']);
    expect(repo.bodies.single['splits'], isEmpty);
    expect(repo.bodies.single['manager_member_ids'], isEmpty);
    expect(t.takeException(), null);
  });
  testWidgets(
      'successful catalogue save reloads next version before another save',
      (t) async {
    trainingSize(t);
    final repo = FakeTraining()..actionGate = Completer<void>();
    await t.pumpWidget(
        trainingApp(const TrainingSettingsScreen(communityId: '1'), repo));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('training-save-catalog')));
    await t.tap(find.byKey(const Key('training-save-catalog')));
    await t.pump();
    repo.value = trainingFixture(catalogVersion: 3);
    repo.actionGate!.complete();
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const Key('training-save-catalog')));
    expect(repo.bodies.first['expected_version'], 2);
    expect(repo.bodies.last['expected_version'], 3);
  });
  for (final correction in [true, false]) {
    testWidgets(
        'staff failure never offers own topup for ${correction ? 'correction' : 'confirmation'}',
        (t) async {
      trainingSize(t);
      final repo = FakeTraining()
        ..actionError = const ServerException(
            'Saldo penerima tidak mencukupi untuk koreksi.');
      await t.pumpWidget(
          trainingApp(const TrainingScreen(communityId: '1'), repo));
      await t.pumpAndSettle();
      if (correction) {
        await tapVisible(t, find.text('Riwayat'));
        await tapVisible(t, find.byKey(const Key('attendance-attendance-1')));
        await tapVisible(t, find.byKey(const Key('training-correct')));
        await t.enterText(find.byKey(const Key('training-correction-reason')),
            'Kesalahan konfirmasi fixture');
        await tapVisible(t, find.byKey(const Key('training-correct-submit')));
      } else {
        await tapVisible(t, find.text('Latihan').first);
        await tapVisible(t, find.byKey(const Key('training-confirm-1')));
        await tapVisible(t, find.byKey(const Key('training-confirm-member')));
        await tapVisible(t, find.text('Atlet Fixture').last);
        await tapVisible(t, find.byKey(const Key('training-confirm-submit')));
      }
      await t.drag(find.byType(ListView), const Offset(0, 1000));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('finance-error')), findsOneWidget);
      expect(find.text('Top up saldo'), findsNothing);
    });
  }
  test('invalid WIB date is rejected', () {
    expect(trainingWibInput('2026-02-30 16:00'), null);
    expect(trainingWibInput('2026-11-26 25:00'), null);
    expect(trainingWibInput('2026-11-26 16:00')!.hour, 9);
  });
}
