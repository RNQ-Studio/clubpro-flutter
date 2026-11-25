import 'package:app_main/features/home/presentation/home_screen.dart';
import 'package:app_main/features/home/presentation/home_providers.dart';
import 'package:app_main/features/home/domain/entities/home_banner.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/presentation/active_community_notifier.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import '../test/features/home/fake_promotion_popup_store.dart';
import '../test/features/dues/fake_dues_repository.dart';
import 'package:app_main/features/member_card/domain/entities/member_card.dart';
import 'package:app_main/features/member_card/presentation/member_card_providers.dart';
import 'package:app_main/features/member_card/presentation/screens/member_card_screen.dart';
import '../test/features/community/fake_community_repository.dart'
    show
        testCommunity,
        testDetail,
        FakeCommunityRepository,
        FakeActiveCommunityStore;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/finance/presentation/billing_management_screen.dart';
import 'package:app_main/features/finance/presentation/billing_notices_screen.dart';
import 'package:app_main/features/finance/presentation/billing_screen.dart';
import 'package:app_main/features/finance/presentation/receipt_screen.dart';
import 'package:app_main/features/finance/presentation/topup_screen.dart';
import 'package:app_main/features/finance/presentation/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/features/finance/finance_screens_test.dart' as fixture;

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
    for (final (name, screen) in <(String, Widget)>[
      ('home-member', const HomeScreen()),
      ('home-manager', const HomeScreen()),
      ('wallet', const WalletScreen()),
      ('wallet-large', const WalletScreen()),
      (
        'community-funds',
        const WalletScreen(scope: 'community', communityId: '1')
      ),
      ('platform-income', const WalletScreen(scope: 'platform')),
      ('transaction', const WalletTransactionScreen(id: 'journal-1')),
      ('topup', const TopupScreen(communityId: '1')),
      ('direct-payment', const TopupScreen(communityId: '1', scope: 'member')),
      ('billing-expired', const BillingScreen(communityId: '1')),
      ('billing-trial', const BillingScreen(communityId: '1')),
      ('billing-exempt', const BillingScreen(communityId: '1')),
      (
        'billing-platform',
        const BillingScreen(communityId: '1', scope: 'platform')
      ),
      ('billing-settings', const BillingSettingsScreen(communityId: '1')),
      ('lifecycle', const LifecycleScreen(communityId: '1')),
      ('receipts', const ReceiptScreen(communityId: '1')),
      ('receipt-review', const ReceiptScreen(communityId: '1', manage: true)),
      ('reminders', const BillingNoticesScreen()),
      ('kta-trial', const MemberCardScreen(communityId: '1')),
      ('kta-exempt', const MemberCardScreen(communityId: '1')),
      ('kta-expired', const MemberCardScreen(communityId: '1')),
      ('lifecycle-platform', const LifecycleScreen(communityId: '1')),
      ('billing-legacy', const BillingScreen(communityId: '1')),
      ('billing-archived', const BillingScreen(communityId: '1')),
      (
        'expired-gate',
        const BillingAccessGate(
            communityId: '1', child: Text('Kegiatan terlindungi'))
      ),
    ]) {
      testWidgets('$name at $width', (t) async {
        t.view.physicalSize = Size(width, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final repo = fixture.FakeFinance();
        if (name == 'wallet-large') {
          repo.walletValue = const WalletSummary(
              available: 9005964684850868,
              packageReserve: 1234567890123,
              payoutHold: 2000000);
          repo.history = [
            const WalletTransaction(
                id: 'journal-long',
                kind: 'incoming_receipt',
                amount: 9007199254740991,
                createdAt: '2026-11-25T23:15:00Z',
                reference:
                    'Referensi pembayaran yang sangat panjang untuk pemeriksaan layar')
          ];
        }
        if (name == 'billing-settings')
          repo.billingValue =
              fixture.billingFixture(canConfigure: true, canManage: true);
        if (name == 'billing-trial')
          repo.billingValue =
              fixture.billingFixture(state: 'trial', active: true, amount: 0);
        if (name == 'billing-exempt')
          repo.billingValue =
              fixture.billingFixture(state: 'exempt', active: true, amount: 0);
        if (name == 'billing-platform')
          repo.billingValue = fixture.billingFixture(
              scope: 'platform', canConfigure: true, canManage: true);
        if (name == 'receipt-review')
          repo.receiptValues = [fixture.receiptFixture(canReview: true)];
        if (name == 'lifecycle-platform')
          repo.inactiveValues = [
            const InactiveSubject(
                id: '1',
                name: 'Komunitas Uji',
                platform: true,
                reviewDue: true,
                entitlement: BillingEntitlement(
                    state: 'expired',
                    active: false,
                    arrearsAmount: 300000,
                    inactiveAt: '2026-08-26'))
          ];
        if (name == 'billing-legacy')
          repo.billingValue = const BillingOverview(
              scope: 'member',
              entitlement: BillingEntitlement(
                  state: 'active',
                  active: true,
                  billingScheme: 'legacy_calendar'),
              invoices: [
                BillingInvoice(
                    id: 'legacy-month-1',
                    kind: 'member',
                    periodStart: '2026-11-01',
                    periodEnd: '2026-12-01',
                    amount: 0,
                    paidAmount: 0,
                    outstanding: 0,
                    status: 'paid',
                    legacyNominalUnrecorded: true)
              ]);
        if (name == 'billing-archived')
          repo.billingValue = fixture.billingFixture(state: 'archived');
        final key = GlobalKey();
        await t.pumpWidget(RepaintBoundary(
            key: key,
            child: fixture.financeApp(screen,
                repo: repo,
                community: name.startsWith('home-')
                    ? FakeCommunityRepository(
                        detail: testDetail(
                            myRole: name == 'home-manager'
                                ? CommunityRole.creator
                                : CommunityRole.member),
                        joined: [
                            testCommunity('1',
                                myRole: name == 'home-manager'
                                    ? CommunityRole.creator
                                    : CommunityRole.member)
                          ])
                    : null,
                scale: name == 'wallet-large' ? 1.5 : 1,
                extraOverrides: [
                  if (name.startsWith('home-')) ...[
                    homePromotionsProvider.overrideWith(
                        (ref) async => const HomePromotions(banners: [])),
                    promotionPopupStoreProvider.overrideWithValue(
                        FakePromotionPopupStore({'1': DateTime.now()})),
                    activeCommunityStoreProvider.overrideWithValue(
                        FakeActiveCommunityStore({'1': '1'})),
                    duesRepositoryProvider.overrideWithValue(
                        FakeDuesRepository(overview: notConfigured)),
                  ],
                  if (name.startsWith('kta-'))
                    memberCardProvider('1').overrideWith((ref) async =>
                        MemberCard(
                            memberNumber: 'KU-000042',
                            name: 'Anggota Uji',
                            roleLabel: 'Anggota',
                            community: testCommunity('1'),
                            validity: MemberCardValidity(
                                status: name == 'kta-expired'
                                    ? MemberCardStatus.expired
                                    : MemberCardStatus.active,
                                entitlementState: name.substring(4),
                                platformActive: name != 'kta-expired'))),
                ])));
        await t.pumpAndSettle();
        if (name == 'receipt-review') {
          await t.tap(find.byKey(const Key('receipt-review-receipt-1')));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), null);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await t.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Platform.environment['RENDER_DIR'] ?? 'build/s03-screens';
          Directory(dir).createSync(recursive: true);
          File('$dir/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
