import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/community/domain/entities/community_draft.dart';
import 'package:app_main/features/community/presentation/community_providers.dart';
import 'package:app_main/features/dues/domain/entities/dues.dart';
import 'package:app_main/features/dues/presentation/dues_providers.dart';
import 'package:app_main/features/dues/presentation/screens/dues_members_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_pay_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_payments_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_screen.dart';
import 'package:app_main/features/dues/presentation/screens/dues_settings_screen.dart';
import 'package:app_main/features/dues/presentation/widgets/dues_visuals.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../community/fake_community_repository.dart';
import 'fake_dues_repository.dart';

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthAuthenticated(
        User(id: '2', name: 'Budi Santoso', email: 'budi@gmail.com'),
      );
}

const _id = '1';

Widget _app(
  FakeDuesRepository dues, {
  required String location,
  FakeCommunityRepository? communities,
  FakeCommunityImagePicker? picker,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/communities/:id/dues',
        builder: (_, state) =>
            DuesScreen(communityId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (_, state) =>
                DuesPayScreen(communityId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, state) =>
                DuesSettingsScreen(communityId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'payments',
            builder: (_, state) =>
                DuesPaymentsScreen(communityId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'members',
            builder: (_, state) =>
                DuesMembersScreen(communityId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: ':userId',
                builder: (_, state) => DuesMemberScreen(
                  communityId: state.pathParameters['id']!,
                  userId: state.pathParameters['userId']!,
                  initialYear: 2026,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_FixedAuthNotifier.new),
      duesRepositoryProvider.overrideWithValue(dues),
      communityRepositoryProvider.overrideWithValue(
        communities ?? FakeCommunityRepository(detail: testDetail()),
      ),
      communityImagePickerProvider
          .overrideWithValue(picker ?? FakeCommunityImagePicker()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
    ),
  );
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.7;
  addTearDown(tester.view.reset);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('format', () {
    test('rupiah dengan titik ribuan', () {
      expect(formatRupiah(0), 'Rp0');
      expect(formatRupiah(500), 'Rp500');
      expect(formatRupiah(50000), 'Rp50.000');
      expect(formatRupiah(1250000), 'Rp1.250.000');
    });

    test('rentang bulan', () {
      expect(DuesMonths.range([DateTime(2026, 3)]), 'Mar 2026');
      expect(
        DuesMonths.range(
            [DateTime(2026, 3), DateTime(2026, 4), DateTime(2026, 5)]),
        'Mar–Mei 2026',
      );
      expect(
        DuesMonths.range([DateTime(2026, 12), DateTime(2027, 1)]),
        'Des 2026–Jan 2027',
      );
    });

    test('isian rupiah memberi titik ribuan saat diketik', () {
      final formatter = RupiahInputFormatter();
      TextEditingValue type(String text) => formatter.formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(text: text),
          );
      expect(type('50000').text, '50.000');
      expect(type('0050000').text, '50.000');
      expect(type('Rp 1.250.000').text, '1.250.000');
      expect(type('').text, '');
      expect(type('9999999999').text, '999.999.999');
    });
  });

  group('iuran saya', () {
    testWidgets('tunggakan, kalender, uang masuk, dan riwayat', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDues(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Menunggak 3 bulan'), findsOneWidget);
      expect(find.textContaining('Rp50.000 per bulan'), findsOneWidget);
      expect(find.textContaining('setiap tanggal 10'), findsOneWidget);
      expect(
          find.text('2 bulan menunggu verifikasi pengurus.'), findsOneWidget);
      expect(find.byKey(const Key('dues-manager-tools')), findsNothing);
      // Agustus menunggak, Maret lunas.
      expect(
        find.descendant(
          of: find.byKey(const Key('dues-month-2026-8')),
          matching: find.byIcon(Icons.error_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('dues-month-2026-3')),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.text('Alasan ditolak: Nominal transfer kurang Rp50.000'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Riwayat Pembayaran'), findsOneWidget);
    });

    testWidgets('ganti tahun memuat kalender tahun itu', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository();
      await tester
          .pumpWidget(_app(dues, location: AppRoutes.communityDues(_id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dues-year-prev')));
      await tester.pumpAndSettle();

      expect(dues.overviewYears, [null, 2025]);
    });

    testWidgets('Bayar Iuran membuka layar bayar', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDues(_id),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dues-pay')));
      await tester.pumpAndSettle();

      expect(find.byType(DuesPayScreen), findsOneWidget);
    });

    testWidgets('belum diatur: anggota diberi tahu, tanpa tombol bayar',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(overview: notConfigured),
        location: AppRoutes.communityDues(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Iuran belum diatur'), findsOneWidget);
      expect(find.textContaining('Pengurus belum mengatur'), findsOneWidget);
      expect(find.byKey(const Key('dues-pay')), findsNothing);
      expect(find.byKey(const Key('dues-set-up')), findsNothing);
    });

    testWidgets('gagal dimuat: pesan dan coba lagi', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository()
        ..overviewError = const NetworkException('Tidak dapat terhubung.');
      await tester
          .pumpWidget(_app(dues, location: AppRoutes.communityDues(_id)));
      await tester.pumpAndSettle();

      expect(find.text('Tidak dapat terhubung.'), findsOneWidget);
      dues.overviewError = null;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Menunggak 3 bulan'), findsOneWidget);
    });
  });

  group('pengelola', () {
    testWidgets('alat kelola: verifikasi (jumlah), kalender, pengaturan',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(overview: managerOverview()),
        location: AppRoutes.communityDues(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 bukti transfer menunggu'), findsOneWidget);
      expect(find.byKey(const Key('dues-tool-calendar')), findsOneWidget);
      expect(find.byKey(const Key('dues-tool-settings')), findsOneWidget);
      // Pengelola tetap anggota: punya ringkasan dan tombol bayar sendiri.
      expect(find.byKey(const Key('dues-pay')), findsOneWidget);
    });

    testWidgets('belum diatur: hanya pengaturan, ajakan Atur Iuran',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(
          overview: overviewWith(canManage: true, configured: false),
        ),
        location: AppRoutes.communityDues(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('dues-tool-payments')), findsNothing);
      expect(find.byKey(const Key('dues-tool-calendar')), findsNothing);
      await tester.tap(find.byKey(const Key('dues-set-up')));
      await tester.pumpAndSettle();
      expect(find.byType(DuesSettingsScreen), findsOneWidget);
    });
  });

  group('bayar iuran', () {
    testWidgets('rekening, jumlah bulan mengikuti tunggakan, rincian',
        (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDuesPay(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('a.n. Komunitas Pemanah Nusantara'), findsOneWidget);
      // Menunggak 3 bulan → langsung 3 bulan, mulai dari tunggakan terawal.
      expect(find.text('3 bulan'), findsOneWidget);
      for (final label in ['Agu 2026', 'Sep 2026', 'Okt 2026']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Nov 2026'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const Key('dues-total'))).data,
        'Rp150.000',
      );

      await tester.tap(find.byKey(const Key('dues-months-plus')));
      await tester.pumpAndSettle();
      expect(find.text('Nov 2026'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('dues-total'))).data,
        'Rp200.000',
      );
    });

    testWidgets('uang masuk ikut dihitung bila belum dibayar', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(overview: managerOverview()),
        location: AppRoutes.communityDuesPay(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Uang masuk (sekali)'), findsOneWidget);
      // Creator tanpa tunggakan: 1 bulan + uang masuk.
      expect(
        tester.widget<Text>(find.byKey(const Key('dues-total'))).data,
        'Rp150.000',
      );
      expect(find.text('Kirim Bukti Transfer · Rp150.000'), findsOneWidget);
    });

    testWidgets('salin nomor rekening', (tester) async {
      _phone(tester);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDuesPay(_id),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dues-copy-account')));
      await tester.pump();

      expect(copied, '1234567890');
      expect(find.text('Nomor rekening disalin'), findsOneWidget);
    });

    testWidgets('tanpa bukti transfer tidak terkirim', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository();
      await tester
          .pumpWidget(_app(dues, location: AppRoutes.communityDuesPay(_id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dues-send')));
      await tester.pumpAndSettle();

      expect(find.text('Unggah foto bukti transfer terlebih dahulu.'),
          findsOneWidget);
      expect(dues.actions, isEmpty);
    });

    testWidgets('unggah bukti lalu kirim: menunggu verifikasi', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository();
      final communities = FakeCommunityRepository(detail: testDetail());
      await tester.pumpWidget(_app(
        dues,
        location: AppRoutes.communityDuesPay(_id),
        communities: communities,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dues-months-minus')));
      await _tapVisible(tester, find.byKey(const Key('dues-proof-pick')));
      expect(find.byKey(const Key('dues-proof-preview')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('dues-note')), 'Via BCA');
      await tester.tap(find.byKey(const Key('dues-send')));
      await tester.pumpAndSettle();

      expect(communities.uploads, ['dues-proof:foto-1-0.png']);
      expect(dues.paid, (
        monthsCount: 2,
        proofAssetId: 'aset-foto-1-0.png',
        note: 'Via BCA',
      ));
      expect(find.text('Bukti transfer terkirim'), findsOneWidget);
      expect(find.textContaining('Agu–Sep 2026'), findsOneWidget);
      expect(find.byKey(const Key('dues-send')), findsNothing);
    });

    testWidgets('ditolak server: pesannya tampil, bisa kirim ulang',
        (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository()
        ..actionError = const DuesFieldException(
          'months_count',
          'Bulan yang sama sudah diajukan. Muat ulang lalu coba lagi.',
        );
      await tester
          .pumpWidget(_app(dues, location: AppRoutes.communityDuesPay(_id)));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-proof-pick')));
      await tester.tap(find.byKey(const Key('dues-send')));
      await tester.pumpAndSettle();

      expect(find.textContaining('sudah diajukan'), findsOneWidget);
      expect(find.text('Bukti transfer terkirim'), findsNothing);

      await tester.tap(find.byKey(const Key('dues-send')));
      await tester.pumpAndSettle();
      expect(find.text('Bukti transfer terkirim'), findsOneWidget);
    });

    testWidgets('foto bukti ditolak pemilih: pesannya tampil', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDuesPay(_id),
        picker: FakeCommunityImagePicker(
          error: const CommunityImageException('Ukuran foto maksimal 5 MB.'),
        ),
      ));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-proof-pick')));

      expect(find.text('Ukuran foto maksimal 5 MB.'), findsOneWidget);
    });
  });

  group('pengaturan iuran', () {
    testWidgets('terisi dari setelan, simpan mengirim nominal utuh',
        (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(overview: managerOverview());
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesSettings(_id)));
      await tester.pumpAndSettle();

      expect(find.text('50.000'), findsOneWidget);
      expect(find.text('100.000'), findsOneWidget);
      expect(find.text('10 Maret 2026'), findsOneWidget);
      expect(find.textContaining('setiap tanggal 10'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('dues-settings-amount')), '75000');
      await tester.pump();
      expect(find.text('75.000'), findsOneWidget);
      await _tapVisible(tester, find.byKey(const Key('dues-settings-save')));

      final saved = dues.savedSettings!;
      expect(saved.monthlyAmount, 75000);
      expect(saved.entryFee, 100000);
      expect(saved.startDate, DateTime(2026, 3, 10));
      expect(saved.bankName, 'BCA');
      expect(saved.accountNumber, '1234567890');
    });

    testWidgets('isian kosong ditolak sebelum dikirim', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(
        overview: overviewWith(canManage: true, configured: false),
      );
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesSettings(_id)));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-settings-save')));

      expect(find.text('Iuran per bulan wajib diisi.'), findsOneWidget);
      expect(find.text('Nama bank wajib diisi.'), findsOneWidget);
      expect(
          find.text('Nomor rekening hanya angka, 5–30 digit.'), findsOneWidget);
      expect(find.text('Pilih tanggal mulai iuran.'), findsOneWidget);
      expect(dues.actions, isEmpty);

      await tester.enterText(
          find.byKey(const Key('dues-settings-amount')), '500');
      await _tapVisible(tester, find.byKey(const Key('dues-settings-save')));
      expect(find.text('Iuran per bulan minimal Rp1.000.'), findsOneWidget);
      expect(dues.actions, isEmpty);
    });

    testWidgets('galat server tampil di bawah isiannya', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(overview: managerOverview())
        ..actionError = const DuesFieldException(
          'dues_account_number',
          'Nomor rekening hanya angka, 5–30 digit.',
        );
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesSettings(_id)));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-settings-save')));

      expect(
          find.text('Nomor rekening hanya angka, 5–30 digit.'), findsOneWidget);
      expect(find.byType(DuesSettingsScreen), findsOneWidget);
    });

    testWidgets('anggota biasa tidak bisa mengatur', (tester) async {
      _phone(tester);
      await tester.pumpWidget(_app(
        FakeDuesRepository(),
        location: AppRoutes.communityDuesSettings(_id),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hanya creator dan admin'), findsOneWidget);
      expect(find.byKey(const Key('dues-settings-save')), findsNothing);
    });
  });

  group('verifikasi pembayaran', () {
    testWidgets('terima sesudah konfirmasi', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(payments: pendingPayments());
      final id = dues.payments.single.id;
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesPayments(_id)));
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Jun–Jul 2026'), findsOneWidget);
      expect(find.text('Rp100.000'), findsWidgets);

      await tester.tap(find.byKey(Key('dues-approve-$id')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pastikan Rp100.000 dari Budi Santoso'),
          findsOneWidget);
      await tester.tap(find.byKey(const Key('club-confirm')));
      await tester.pumpAndSettle();

      expect(dues.actions, ['approve:$id']);
      expect(find.text('Pembayaran Budi Santoso diterima'), findsOneWidget);
      expect(
          find.text('Tidak ada bukti transfer yang menunggu.'), findsOneWidget);
    });

    testWidgets('tolak wajib alasan minimal 5 karakter', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(payments: pendingPayments());
      final id = dues.payments.single.id;
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesPayments(_id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('dues-reject-$id')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dues-reject-note')), 'kur');
      await tester.tap(find.byKey(const Key('dues-reject-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('minimal 5 karakter'), findsOneWidget);
      expect(dues.actions, isEmpty);

      await tester.enterText(
          find.byKey(const Key('dues-reject-note')), 'Nominal kurang');
      await tester.tap(find.byKey(const Key('dues-reject-confirm')));
      await tester.pumpAndSettle();

      expect(dues.actions, ['reject:$id:Nominal kurang']);
    });

    testWidgets(
        'sudah diputuskan pengelola lain: pesan server, daftar dimuat ulang',
        (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(payments: pendingPayments())
        ..actionError = const ServerException(
            'Pembayaran ini sudah diverifikasi. Muat ulang untuk melihat yang '
            'terbaru.');
      final id = dues.payments.single.id;
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesPayments(_id)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('dues-approve-$id')));
      await tester.pumpAndSettle();
      dues.payments = [];
      await tester.tap(find.byKey(const Key('club-confirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining('sudah diverifikasi'), findsOneWidget);
      expect(
          find.text('Tidak ada bukti transfer yang menunggu.'), findsOneWidget);
    });

    testWidgets('riwayat tanpa tombol terima/tolak', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(payments: memberOverview().payments);
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesPayments(_id)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();

      expect(find.text('Diterima'), findsWidgets);
      expect(find.text('Ditolak'), findsWidgets);
      expect(find.textContaining('Alasan ditolak'), findsOneWidget);
      // Yang masih menunggu tetap bisa diputuskan dari riwayat.
      expect(find.text('Terima'), findsOneWidget);
    });
  });

  group('kalender anggota', () {
    testWidgets('tunggakan tiap anggota; cari; buka anggota', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(
        members: membersPage(),
        member: memberDetail(),
      );
      await tester.pumpWidget(
          _app(dues, location: AppRoutes.communityDuesMembers(_id)));
      await tester.pumpAndSettle();

      expect(find.text('Menunggak 3 bln'), findsOneWidget);
      expect(find.text('Lancar'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('dues-members-search')), 'budi');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(dues.memberSearches.last, 'budi');
      expect(find.text('Rina Ayu'), findsNothing);

      await tester.tap(find.text('Budi Santoso'));
      await tester.pumpAndSettle();
      expect(find.byType(DuesMemberScreen), findsOneWidget);
      expect(find.text('Menunggak 3 bulan'), findsOneWidget);
    });

    testWidgets('tandai bulan menunggak lunas, dan sebaliknya', (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(member: memberDetail());
      final userId = dues.member!.member.userId;
      await tester.pumpWidget(_app(
        dues,
        location: AppRoutes.communityDuesMember(_id, userId),
      ));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-month-2026-8')));
      expect(find.text('Agustus 2026 · Budi Santoso'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dues-month-paid')));
      await tester.pumpAndSettle();
      expect(dues.actions, ['month:$userId:2026-08:paid']);
      expect(find.text('Agustus 2026 ditandai lunas'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const Key('dues-month-2026-3')));
      await tester.tap(find.byKey(const Key('dues-month-unpaid')));
      await tester.pumpAndSettle();
      expect(dues.actions.last, 'month:$userId:2026-03:unpaid');
    });

    testWidgets('bulan yang menunggu verifikasi tidak bisa diubah',
        (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(member: memberDetail());
      await tester.pumpWidget(_app(
        dues,
        location:
            AppRoutes.communityDuesMember(_id, dues.member!.member.userId),
      ));
      await tester.pumpAndSettle();

      await _tapVisible(tester, find.byKey(const Key('dues-month-2026-6')));

      expect(find.textContaining('menunggu verifikasi'), findsWidgets);
      expect(find.byKey(const Key('dues-month-paid')), findsNothing);
      expect(find.byKey(const Key('dues-month-unpaid')), findsNothing);
    });

    testWidgets('uang masuk: batalkan pelunasan sesudah konfirmasi',
        (tester) async {
      _phone(tester);
      final dues = FakeDuesRepository(member: memberDetail());
      final userId = dues.member!.member.userId;
      await tester.pumpWidget(_app(
        dues,
        location: AppRoutes.communityDuesMember(_id, userId),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Uang masuk Rp100.000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dues-entry-fee')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('club-confirm')));
      await tester.pumpAndSettle();

      expect(dues.actions, ['entry-fee:$userId:unpaid']);
    });
  });

  group('tanpa overflow', () {
    for (final (name, location, repo) in [
      ('iuran saya', AppRoutes.communityDues(_id), FakeDuesRepository.new),
      ('bayar', AppRoutes.communityDuesPay(_id), FakeDuesRepository.new),
      (
        'pengaturan',
        AppRoutes.communityDuesSettings(_id),
        () => FakeDuesRepository(overview: managerOverview()),
      ),
      (
        'verifikasi',
        AppRoutes.communityDuesPayments(_id),
        () => FakeDuesRepository(payments: pendingPayments()),
      ),
      (
        'kalender anggota',
        AppRoutes.communityDuesMembers(_id),
        () => FakeDuesRepository(members: membersPage()),
      ),
      (
        'satu anggota',
        AppRoutes.communityDuesMember(_id, '2'),
        () => FakeDuesRepository(member: memberDetail()),
      ),
    ]) {
      testWidgets('$name: layar sempit + teks besar', (tester) async {
        tester.view.physicalSize = const Size(640, 1280); // 320×640 dp
        tester.view.devicePixelRatio = 2;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(_app(
          repo(),
          location: location,
          communities: FakeCommunityRepository(
            detail: testDetail(myRole: CommunityRole.creator),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.drag(find.byType(Scrollable).last, const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
