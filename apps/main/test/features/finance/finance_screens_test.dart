import 'package:app_main/features/finance/data/finance_models.dart'
    show inactiveFromJson;
import 'package:app_main/features/member_card/domain/entities/member_card.dart';
import 'package:app_main/features/member_card/presentation/member_card_providers.dart';
import 'package:app_main/features/member_card/presentation/screens/member_card_screen.dart';
import 'package:app_main/router/app_router.dart' show appRouter;
import 'dart:async';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/domain/finance_repository.dart';
import 'package:app_main/features/finance/presentation/billing_management_screen.dart';
import 'package:app_main/features/finance/presentation/billing_screen.dart';
import 'package:app_main/features/finance/presentation/billing_notices_screen.dart';
import 'package:app_main/features/finance/presentation/finance_providers.dart';
import 'package:app_main/features/finance/presentation/receipt_screen.dart';
import 'package:app_main/features/finance/presentation/topup_screen.dart';
import 'package:app_main/features/finance/presentation/wallet_screen.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../community/fake_community_repository.dart';

BillingOverview billingFixture(
        {String state = 'expired',
        bool active = false,
        int amount = 150000,
        bool canManage = false,
        bool canConfigure = false,
        bool platformActive = true,
        String scope = 'member'}) =>
    BillingOverview(
        scope: scope,
        entitlement: BillingEntitlement(
            state: state,
            active: active,
            arrearsAmount: amount,
            trialStart: '2026-11-19',
            trialEnd: '2026-11-26',
            validUntil: '2026-12-26',
            inactiveAt: '2026-08-26'),
        invoices: amount == 0
            ? []
            : [
                BillingInvoice(
                    id: 'invoice-1',
                    kind: scope,
                    periodStart: '2026-11-26',
                    periodEnd: '2026-12-26',
                    amount: amount + 25000,
                    paidAmount: 25000,
                    outstanding: amount,
                    status: 'partially_paid')
              ],
        settings: const BillingSettings(
            memberAmount: 100000,
            entryFee: 50000,
            periodMonths: 1,
            bankName: 'Bank Fixture',
            accountNumber: '00001111',
            accountName: 'Komunitas Uji'),
        canManage: canManage,
        canConfigure: canConfigure,
        platformActive: platformActive,
        notices: const [
          BillingNotice('n1', 'expiry',
              'Lunasi seluruh kewajiban untuk kembali aktif.', '2026-11-25')
        ]);
PaymentReceipt receiptFixture(
        {bool canReview = false,
        String purpose = 'topup',
        String status = 'pending'}) =>
    PaymentReceipt(
        id: 'receipt-1',
        status: status,
        claimedAmount: 150000,
        communityId: '1',
        beneficiaryName: 'Akun Uji',
        purpose: purpose,
        reference: 'referensi-bank-fixture',
        createdAt: '2026-11-25T23:15:00Z',
        canReview: canReview);
const transactionFixture = WalletTransaction(
    id: 'journal-1',
    kind: 'incoming_receipt',
    amount: 200000,
    createdAt: '2026-11-25T23:15:00Z',
    reference: 'bukti-fixture',
    actor: 'Admin Fixture',
    postings: [LedgerPosting('available', 200000)]);

class FakeFinance implements FinanceRepository {
  BillingNoticeFeed noticeValue = const BillingNoticeFeed([
    BillingNotice(
        'notice-1',
        'inactive_review',
        'Anggota tiga bulan tidak aktif. Pilih pertahankan atau arsipkan.',
        '2026-11-25T23:15:00Z',
        communityId: '1',
        memberId: '42')
  ], 1);
  @override
  Future<BillingNoticeFeed> notices() async {
    await _load();
    return noticeValue;
  }

  @override
  Future<void> readNotice(String id) async {
    calls.add('read:$id');
    await _action();
    noticeValue = const BillingNoticeFeed([], 0);
  }

  WalletSummary walletValue = const WalletSummary(
      available: 200000, packageReserve: 50000, payoutHold: 25000);
  BillingOverview billingValue = billingFixture();
  List<WalletTransaction> history = [transactionFixture];
  List<PaymentReceipt> receiptValues = [receiptFixture()];
  List<InactiveSubject> inactiveValues = [
    const InactiveSubject(
        id: '42',
        name: 'Anggota tidak aktif',
        role: 'member',
        reviewDue: true,
        entitlement: BillingEntitlement(
            state: 'expired',
            active: false,
            arrearsAmount: 150000,
            inactiveAt: '2026-08-26'))
  ];
  Exception? loadError, actionError;
  Completer<void>? actionGate, loadGate;
  int walletCalls = 0;
  final calls = <String>[],
      submitted = <Map<String, Object?>>[],
      verified = <Map<String, Object?>>[];
  final payKeys = <String>[];
  String? paidTarget;
  List<String>? paidInvoiceIds;
  int? paidExpectedAmount;
  Future<void> _load() async {
    await loadGate?.future;
    if (loadError != null) throw loadError!;
  }

  Future<void> _action() async {
    await actionGate?.future;
    if (actionError != null) throw actionError!;
  }

  @override
  Future<WalletSummary> wallet(
      {String scope = 'identity', String? communityId}) async {
    walletCalls++;
    await _load();
    calls.add('wallet:$scope:$communityId');
    return walletValue;
  }

  @override
  Future<FinancePage<WalletTransaction>> transactions(
      {String scope = 'identity',
      String direction = '',
      String kind = '',
      String? communityId,
      int page = 1}) async {
    await _load();
    calls.add('history:$scope:$direction:$page');
    return FinancePage(history, page: page, lastPage: 2);
  }

  @override
  Future<WalletTransaction> transaction(String id,
      {String scope = 'identity', String? communityId}) async {
    await _load();
    calls.add('detail:$scope:$communityId');
    return transactionFixture;
  }

  @override
  Future<FinancePage<PaymentReceipt>> receipts(
      {String? communityId,
      String status = '',
      int page = 1,
      bool manage = false}) async {
    await _load();
    calls.add('receipts:$communityId:$status');
    return FinancePage(receiptValues);
  }

  @override
  Future<PaymentReceipt> submitReceipt(Map<String, Object?> fields) async {
    submitted.add(fields);
    await _action();
    return receiptFixture();
  }

  @override
  Future<PaymentReceipt> verifyReceipt(
      String id, Map<String, Object?> fields) async {
    verified.add(fields);
    await _action();
    return receiptFixture(status: 'verified');
  }

  @override
  Future<PaymentReceipt> rejectReceipt(
      String communityId, String id, String reason, String key) async {
    calls.add('reject:$communityId:$reason');
    await _action();
    return receiptFixture(status: 'rejected');
  }

  @override
  Future<BillingOverview> billing(String communityId,
      {String scope = 'member', String? targetMemberId}) async {
    await _load();
    calls.add('billing:$communityId:$scope:$targetMemberId');
    return billingValue;
  }

  @override
  Future<void> pay(String communityId, String scope, String key,
      {String? targetMemberId,
      required List<String> invoiceIds,
      required int expectedAmount}) async {
    payKeys.add(key);
    paidTarget = targetMemberId;
    paidInvoiceIds = invoiceIds;
    paidExpectedAmount = expectedAmount;
    await _action();
    billingValue = billingFixture(state: 'active', active: true, amount: 0);
  }

  @override
  Future<void> renew(String communityId, String scope,
      {String? targetMemberId}) async {
    calls.add('renew:$communityId:$scope');
    await _action();
  }

  @override
  Future<void> saveSettings(
      String communityId, Map<String, Object?> fields) async {
    submitted.add(fields);
    await _action();
  }

  @override
  Future<List<InactiveSubject>> inactive(String communityId) async {
    await _load();
    return inactiveValues;
  }

  @override
  Future<void> decide(String communityId, InactiveSubject subject,
      String action, String reason) async {
    calls.add('$action:${subject.id}:$reason');
    await _action();
  }
}

class FixtureAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthAuthenticated(
      User(id: '1', name: 'Akun Uji', email: 'uji@anaklangit.manahpro.web.id'));
}

Widget financeApp(Widget screen,
        {FakeFinance? repo,
        FakeCommunityRepository? community,
        double scale = 1,
        List<Override> extraOverrides = const []}) =>
    ProviderScope(
        overrides: [
          ...extraOverrides,
          financeRepositoryProvider.overrideWithValue(repo ?? FakeFinance()),
          authProvider.overrideWith(FixtureAuth.new),
          communityRepositoryProvider.overrideWithValue(community ??
              FakeCommunityRepository(
                  detail: testDetail(myRole: CommunityRole.member),
                  joined: [
                    testCommunity('1',
                        myRole: CommunityRole.member,
                        myStatus: CommunityMembershipStatus.active)
                  ])),
          communityImagePickerProvider
              .overrideWithValue(FakeCommunityImagePicker())
        ],
        child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('id'),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            routerConfig: GoRouter(routes: [
              GoRoute(path: '/', builder: (context, state) => screen),
              GoRoute(
                  path: '/wallet',
                  builder: (_, s) => WalletScreen(
                      scope: s.uri.queryParameters['scope'] ?? 'identity',
                      communityId: s.uri.queryParameters['community'])),
              GoRoute(
                  path: '/wallet/topup',
                  builder: (_, s) => TopupScreen(
                      communityId: s.uri.queryParameters['community'],
                      scope: s.uri.queryParameters['scope'],
                      targetMemberId: s.uri.queryParameters['member'])),
              GoRoute(
                  path: '/wallet/receipts',
                  builder: (_, s) => ReceiptScreen(
                      communityId: s.uri.queryParameters['community'])),
              GoRoute(
                  path: '/wallet/transactions/:id',
                  builder: (_, s) =>
                      WalletTransactionScreen(id: s.pathParameters['id']!)),
              GoRoute(
                  path: '/communities/:id/billing',
                  builder: (_, s) => BillingScreen(
                      communityId: s.pathParameters['id']!,
                      scope: s.uri.queryParameters['scope'] ?? 'member',
                      targetMemberId: s.uri.queryParameters['member'])),
              GoRoute(
                  path: '/communities/:id/card',
                  builder: (context, state) =>
                      const Scaffold(body: Text('KTA tetap tersedia'))),
            ])));
void size(WidgetTester t, {double width = 500, double height = 1100}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> visible(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
      'wallet buckets do not offer held funds as available; filter and detail work',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(financeApp(const WalletScreen(), repo: repo));
    await t.pumpAndSettle();
    expect(find.text('Rp200.000'), findsOneWidget);
    expect(find.text('Rp275.000'), findsOneWidget);
    expect(find.text('Cadangan paket'), findsOneWidget);
    expect(find.text('Ditahan pencairan'), findsOneWidget);
    await t.tap(find.text('Semua arus'));
    await t.pumpAndSettle();
    await t.tap(find.text('Keluar').last);
    await t.pumpAndSettle();
    expect(repo.calls, contains('history:identity:out:1'));
    await visible(t, find.text('Penerimaan terverifikasi'));
    await t.tap(find.text('Penerimaan terverifikasi'));
    await t.pumpAndSettle();
    expect(find.text('Pelaku: Admin Fixture'), findsOneWidget);
    expect(find.text('Tanggal: 26/11/2026 06:15 WIB'), findsOneWidget);
  });
  testWidgets('wallet empty failed retry and loading states are honest',
      (t) async {
    size(t);
    final repo = FakeFinance()..loadGate = Completer<void>();
    await t.pumpWidget(financeApp(const WalletScreen(), repo: repo));
    await t.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    repo.loadError = const ServerException('Server uji gagal.');
    repo.loadGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('Server uji gagal.'), findsWidgets);
    repo.loadError = null;
    repo.history = [];
    await t.tap(find.text('Coba Lagi').last);
    await t.pumpAndSettle();
    expect(find.text('Belum ada transaksi pada filter ini.'), findsOneWidget);
  });
  testWidgets('insufficient wallet directs topup and does not submit payment',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..walletValue = const WalletSummary(available: 1000);
    await t.pumpWidget(
        financeApp(const BillingScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('billing-topup')));
    expect(find.byKey(const Key('billing-pay-wallet')), findsNothing);
    await t.tap(find.byKey(const Key('billing-topup')));
    await t.pumpAndSettle();
    expect(find.byType(TopupScreen), findsOneWidget);
    expect(repo.payKeys, isEmpty);
  });
  testWidgets(
      'wallet full payment activates without membership approval and prevents double click',
      (t) async {
    size(t);
    final repo = FakeFinance()..actionGate = Completer<void>();
    await t.pumpWidget(financeApp(
        const BillingScreen(communityId: '1', targetMemberId: '42'),
        repo: repo));
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('billing-pay-wallet')));
    await t.tap(find.byKey(const Key('billing-pay-wallet')));
    await t.pumpAndSettle();
    await t.tap(find.text('Bayar sekarang'));
    await t.pump();
    expect(repo.payKeys, hasLength(1));
    expect(repo.paidTarget, '42');
    expect(repo.paidInvoiceIds, ['invoice-1']);
    expect(repo.paidExpectedAmount, 150000);
    final button =
        t.widget<FilledButton>(find.byKey(const Key('billing-pay-wallet')));
    expect(button.onPressed, isNull);
    repo.actionGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('Aktif'), findsOneWidget);
    expect(repo.payKeys, hasLength(1));
  });
  testWidgets(
      'ambiguous failed payment retries same key without declaring paid',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..actionError = const ServerException('Koneksi terputus.');
    await t.pumpWidget(
        financeApp(const BillingScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await visible(t, find.byKey(const Key('billing-pay-wallet')));
      await t.tap(find.byKey(const Key('billing-pay-wallet')));
      await t.pumpAndSettle();
      await t.tap(find.text('Bayar sekarang'));
      await t.pumpAndSettle();
    }
    expect(repo.payKeys, hasLength(2));
    expect(repo.payKeys[0], repo.payKeys[1]);
    expect(find.text('Tidak aktif'), findsOneWidget);
  });
  testWidgets(
      'direct proof supports partial payment and explicit excess allocation; upload reused on retry',
      (t) async {
    size(t, height: 1700);
    final repo = FakeFinance()
      ..actionError = const ServerException('Coba lagi.');
    final community = FakeCommunityRepository(detail: testDetail());
    await t.pumpWidget(financeApp(
        const TopupScreen(
            communityId: '1', scope: 'member', targetMemberId: '42'),
        repo: repo,
        community: community));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nominal transfer yang diajukan'),
        '50000');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi transfer / berita bank'),
        'partial-ref');
    await visible(t, find.byKey(const Key('receipt-pick-proof')));
    await t.tap(find.byKey(const Key('receipt-pick-proof')));
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('receipt-submit')));
    await t.tap(find.byKey(const Key('receipt-submit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('receipt-submit')));
    await t.pumpAndSettle();
    expect(repo.submitted, hasLength(2));
    expect(repo.submitted[0]['idempotency_key'],
        repo.submitted[1]['idempotency_key']);
    expect(repo.submitted[0]['claimed_amount'], 50000);
    expect(repo.submitted[0]['credit_excess'], false);
    expect(repo.submitted[0]['target_member_id'], 42);
    expect(repo.submitted[0]['invoice_ids'], ['invoice-1']);
    expect(community.uploads, hasLength(1));
  });
  testWidgets('topup validates positive integer and proof before sending',
      (t) async {
    size(t, height: 1400);
    final repo = FakeFinance();
    await t.pumpWidget(
        financeApp(const TopupScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('receipt-submit')));
    await t.pumpAndSettle();
    expect(repo.submitted, isEmpty);
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nominal transfer yang diajukan'),
        '100000');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi transfer / berita bank'),
        'bank-ref');
    await visible(t, find.byKey(const Key('receipt-submit')));
    await t.tap(find.byKey(const Key('receipt-submit')));
    await t.pumpAndSettle();
    expect(find.text('Pilih foto bukti transfer terlebih dahulu.'),
        findsOneWidget);
    expect(repo.submitted, isEmpty);
  });
  testWidgets(
      'expired route A does not use selected community B, payment and KTA remain reachable',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(financeApp(
        const BillingAccessGate(
            communityId: '1',
            child: Scaffold(body: Text('Kegiatan terlindungi'))),
        repo: repo));
    await t.pumpAndSettle();
    expect(repo.calls, contains('billing:1:member:null'));
    expect(find.text('Kegiatan terlindungi'), findsNothing);
    await t.tap(find.text('Lihat status KTA'));
    await t.pumpAndSettle();
    expect(find.text('KTA tetap tersedia'), findsOneWidget);
  });
  testWidgets(
      'active member with expired platform cannot access internal screen',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..billingValue = billingFixture(
          state: 'active', active: true, amount: 0, platformActive: false);
    await t.pumpWidget(financeApp(
        const BillingAccessGate(
            communityId: '1', child: Text('Kegiatan terlindungi')),
        repo: repo));
    await t.pumpAndSettle();
    expect(find.text('Kegiatan terlindungi'), findsNothing);
    expect(find.textContaining('Langganan komunitas tidak aktif.'),
        findsOneWidget);
  });
  testWidgets('valid community B and guest public detail remain usable',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..billingValue = billingFixture(state: 'active', active: true, amount: 0);
    await t.pumpWidget(financeApp(
        const BillingAccessGate(
            communityId: '2', child: Scaffold(body: Text('Komunitas B aktif'))),
        repo: repo));
    await t.pumpAndSettle();
    expect(repo.calls, contains('billing:2:member:null'));
    expect(find.text('Komunitas B aktif'), findsOneWidget);
    await t.pumpWidget(financeApp(
        const BillingAccessGate(
            communityId: '3', child: Scaffold(body: Text('Detail publik'))),
        repo: FakeFinance(),
        community: FakeCommunityRepository(detail: testDetail())));
    await t.pumpAndSettle();
    expect(find.text('Detail publik'), findsOneWidget);
  });
  testWidgets(
      'community admin sees no verification action on own platform receipt',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..receiptValues = [receiptFixture(purpose: 'platform')];
    await t.pumpWidget(financeApp(
        const ReceiptScreen(communityId: '1', manage: true),
        repo: repo));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('receipt-review-receipt-1')), findsNothing);
  });
  testWidgets(
      'authorized review accepts editable received amount and locks sending',
      (t) async {
    size(t, height: 1400);
    final repo = FakeFinance()
      ..actionGate = Completer<void>()
      ..receiptValues = [receiptFixture(canReview: true)];
    await t.pumpWidget(financeApp(
        const ReceiptScreen(communityId: '1', manage: true),
        repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('receipt-review-receipt-1')));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nominal yang benar-benar diterima'),
        '140000');
    await t.tap(find.byKey(const Key('receipt-verify')));
    await t.pumpAndSettle();
    expect(repo.verified, isEmpty);
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('receipt-verify')));
    await t.pump();
    expect(repo.verified.single['verified_amount'], 140000);
    expect(repo.verified.single['bank_reference'], 'referensi-bank-fixture');
    expect(
        t
            .widget<FilledButton>(find.byKey(const Key('receipt-verify')))
            .onPressed,
        isNull);
    repo.actionGate!.complete();
    await t.pumpAndSettle();
  });
  testWidgets('lifecycle retain requires reason and does not waive obligations',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(
        financeApp(const LifecycleScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Pertahankan'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pertahankan').last);
    await t.pumpAndSettle();
    expect(repo.calls.where((s) => s.startsWith('retain:')), isEmpty);
    await t.enterText(find.widgetWithText(TextFormField, 'Alasan keputusan'),
        'Masih menjadi anggota');
    await t.tap(find.text('Pertahankan').last);
    await t.pumpAndSettle();
    expect(repo.calls, contains('retain:42:Masih menjadi anggota'));
    expect(repo.billingValue.entitlement.arrearsAmount, 150000);
  });
  testWidgets(
      'founder settings save integer fee period and bank without rewriting history',
      (t) async {
    size(t, height: 1600);
    final repo = FakeFinance()
      ..billingValue = billingFixture(canConfigure: true);
    await t.pumpWidget(
        financeApp(const BillingSettingsScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Iuran per periode'), '75000');
    await t.tap(find.text('1 bulan'));
    await t.pumpAndSettle();
    await t.tap(find.text('3 bulan').last);
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('billing-settings-save')));
    await t.tap(find.byKey(const Key('billing-settings-save')));
    await t.pumpAndSettle();
    expect(repo.submitted.single['dues_amount'], 75000);
    expect(repo.submitted.single['period_months'], 3);
    expect(repo.billingValue.invoices.single.amount, 175000);
  });
  testWidgets('large text max integer and long references fit narrow viewport',
      (t) async {
    size(t, width: 500, height: 1400);
    final repo = FakeFinance()
      ..walletValue = const WalletSummary(available: 9007199254740991)
      ..history = [
        WalletTransaction(
            id: 'journal-max',
            kind: 'incoming_receipt',
            amount: 9007199254740991,
            createdAt: '2026-11-25T23:15:00Z',
            reference:
                'Referensi pembayaran yang sangat panjang untuk pemeriksaan tampilan',
            actor: 'Admin panjang')
      ];
    await t
        .pumpWidget(financeApp(const WalletScreen(), repo: repo, scale: 1.5));
    await t.pumpAndSettle();
    expect(t.takeException(), null);
  });
  testWidgets(
      'payment reminder feed exposes inactivity action and marks read once',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(financeApp(const BillingNoticesScreen(), repo: repo));
    await t.pumpAndSettle();
    expect(find.text('1 belum dibaca'), findsOneWidget);
    expect(
        find.textContaining('Anggota tiga bulan tidak aktif.'), findsOneWidget);
    await t.tap(find.text('Tandai dibaca'));
    await t.pumpAndSettle();
    expect(repo.calls.where((s) => s == 'read:notice-1'), hasLength(1));
    expect(find.text('0 belum dibaca'), findsOneWidget);
    expect(find.text('Belum ada pengingat pembayaran.'), findsOneWidget);
  });
  testWidgets(
      'rapid payment taps open one confirmation and cancel leaves wallet untouched',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(
        financeApp(const BillingScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    final pay = find.byKey(const Key('billing-pay-wallet'));
    await visible(t, pay);
    await t.tap(pay);
    await t.tap(pay, warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('Bayar dari saldo?'), findsOneWidget);
    await t.tap(find.text('Kembali'));
    await t.pumpAndSettle();
    expect(repo.payKeys, isEmpty);
    expect(t.widget<FilledButton>(pay).onPressed, isNotNull);
  });
  testWidgets('main notifications route opens real billing reminder feed',
      (t) async {
    size(t);
    final repo = FakeFinance();
    appRouter.go(AppRoutes.notifications);
    await t.pumpWidget(ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(FixtureAuth.new)
        ],
        child: MaterialApp.router(
            theme: AppTheme.light, routerConfig: appRouter)));
    await t.pumpAndSettle();
    expect(find.byType(BillingNoticesScreen), findsOneWidget);
    expect(find.textContaining('coming soon'), findsNothing);
  });
  for (final state in ['trial', 'exempt', 'expired']) {
    testWidgets(
        'KTA $state works without legacy paid month and shows platform limit',
        (t) async {
      size(t);
      final card = MemberCard(
          memberNumber: 'KU-000042',
          name: 'Anggota Uji',
          roleLabel: 'Anggota',
          community: testCommunity('1'),
          validity: MemberCardValidity(
              status: state == 'expired'
                  ? MemberCardStatus.expired
                  : MemberCardStatus.active,
              entitlementState: state,
              platformActive: false));
      await t.pumpWidget(ProviderScope(
          overrides: [
            memberCardProvider('1').overrideWith((ref) async => card),
            communityRepositoryProvider.overrideWithValue(
                FakeCommunityRepository(
                    joined: [testCommunity('1', myRole: CommunityRole.member)]))
          ],
          child: MaterialApp(
              theme: AppTheme.light,
              home: const MemberCardScreen(communityId: '1'))));
      await t.pumpAndSettle();
      expect(t.takeException(), null);
      expect(find.textContaining('Langganan komunitas tidak aktif.'),
          findsOneWidget);
    });
  }
  testWidgets(
      'community transaction deep link preserves fund authorization scope',
      (t) async {
    size(t);
    final repo = FakeFinance();
    appRouter.go('/wallet/transactions/journal-1?scope=community&community=7');
    await t.pumpWidget(ProviderScope(
        overrides: [
          financeRepositoryProvider.overrideWithValue(repo),
          authProvider.overrideWith(FixtureAuth.new)
        ],
        child: MaterialApp.router(
            theme: AppTheme.light, routerConfig: appRouter)));
    await t.pumpAndSettle();
    expect(repo.calls, contains('detail:community:7'));
  });
  for (final state in ['trial', 'exempt']) {
    testWidgets(
        'active $state has no expired debt notice and exempt has no renewal',
        (t) async {
      size(t);
      final repo = FakeFinance()
        ..billingValue = billingFixture(state: state, active: true, amount: 0);
      await t.pumpWidget(
          financeApp(const BillingScreen(communityId: '1'), repo: repo));
      await t.pumpAndSettle();
      expect(find.text('Lunasi seluruh kewajiban untuk kembali aktif.'),
          findsNothing);
      if (state == 'exempt') {
        expect(find.byKey(const Key('billing-renew')), findsNothing);
        expect(find.textContaining('Peran Anda bebas iuran komunitas.'),
            findsOneWidget);
      }
    });
  }
  testWidgets(
      'confirmation binds invoices and amount across a new period and conflict asks reconfirmation',
      (t) async {
    size(t);
    final repo = FakeFinance();
    await t.pumpWidget(
        financeApp(const BillingScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('billing-pay-wallet')));
    await t.tap(find.byKey(const Key('billing-pay-wallet')));
    await t.pumpAndSettle();
    repo.billingValue = billingFixture(amount: 175000);
    repo.actionError = const FinanceConflictException(
        'Nominal berubah. Periksa ulang tagihan sebelum membayar.');
    await t.tap(find.text('Bayar sekarang'));
    await t.pumpAndSettle();
    expect(repo.paidInvoiceIds, ['invoice-1']);
    expect(repo.paidExpectedAmount, 150000);
    expect(repo.payKeys, hasLength(1));
    expect(
        find.text('Nominal berubah. Periksa ulang tagihan sebelum membayar.'),
        findsOneWidget);
  });
  testWidgets(
      'historical approved receipt is labeled history and never has approval action',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..receiptValues = [
        receiptFixture(
            status: 'legacy_verified', purpose: 'legacy_dues', canReview: true)
      ];
    await t.pumpWidget(financeApp(
        const ReceiptScreen(communityId: '1', manage: true),
        repo: repo));
    await t.pumpAndSettle();
    expect(find.textContaining('Histori terverifikasi'), findsOneWidget);
    expect(find.byKey(const Key('receipt-review-receipt-1')), findsNothing);
  });
  testWidgets(
      'managed member transfer return retains child billing and own receipt history',
      (t) async {
    size(t, height: 1700);
    final repo = FakeFinance();
    await t.pumpWidget(financeApp(
        const TopupScreen(
            communityId: '1', scope: 'member', targetMemberId: '42'),
        repo: repo));
    await t.pumpAndSettle();
    await t.enterText(
        find.widgetWithText(TextFormField, 'Nominal transfer yang diajukan'),
        '50000');
    await t.enterText(
        find.widgetWithText(TextFormField, 'Referensi transfer / berita bank'),
        'child-ref');
    await visible(t, find.byKey(const Key('receipt-pick-proof')));
    await t.tap(find.byKey(const Key('receipt-pick-proof')));
    await t.pumpAndSettle();
    await visible(t, find.byKey(const Key('receipt-submit')));
    await t.tap(find.byKey(const Key('receipt-submit')));
    await t.pumpAndSettle();
    await t.tap(find.text('Kembali ke ringkasan'));
    await t.pumpAndSettle();
    expect(repo.calls, contains('billing:1:member:42'));
  });
  testWidgets(
      'platform lifecycle wrapper exposes archive community action with reason',
      (t) async {
    size(t);
    final repo = FakeFinance()
      ..inactiveValues = inactiveFromJson({
        'members': [],
        'community': {
          'id': 1,
          'name': 'Komunitas Uji',
          'review_due': true,
          'entitlement': {
            'state': 'expired',
            'active': false,
            'arrears_amount': 300000,
            'inactive_at': '2026-08-26'
          }
        }
      });
    await t.pumpWidget(
        financeApp(const LifecycleScreen(communityId: '1'), repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.text('Arsipkan / hapus komunitas'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextFormField, 'Alasan keputusan'),
        'Tidak digunakan lagi');
    await t.tap(find.text('Arsipkan'));
    await t.pumpAndSettle();
    expect(repo.calls, contains('archive:1:Tidak digunakan lagi'));
    expect(find.text('Data diarsipkan; histori transaksi dipertahankan.'),
        findsOneWidget);
  });
}
