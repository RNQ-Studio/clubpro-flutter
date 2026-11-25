import 'dart:async';
import 'package:core/core.dart';
import 'package:app_main/features/directory/domain/directory_repository.dart';
import 'package:app_main/features/community/domain/entities/community.dart';
import 'package:app_main/features/directory/presentation/directory_providers.dart';
import 'package:app_main/features/directory/presentation/directory_screen.dart';
import 'package:app_main/features/directory/presentation/guardian_screen.dart';
import 'package:app_main/features/directory/presentation/member_identity_screen.dart';
import 'package:app_main/router/app_router.dart'
    show clubAuthRedirect, safeLoginReturn;
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const member = User(
    id: '1',
    name: 'Wali Uji',
    email: 'wali@anaklangit.manahpro.web.id',
    pinEnabled: true);

class FixedAuth extends AuthNotifier {
  FixedAuth(this.value);
  final AuthState value;
  @override
  AuthState build() => value;
  @override
  Future<void> checkCurrentUser() async {}
  @override
  Future<void> sessionExpired() async {
    state = const AuthUnauthenticated();
  }
}

class FakePin implements PinRepository {
  bool emailAvailable = true, failOptions = false;
  Completer<bool>? optionsPending;
  @override
  Future<bool> emailRecoveryAvailable() async {
    if (optionsPending != null) return optionsPending!.future;
    if (failOptions) throw Exception('Layanan belum tersedia.');
    return emailAvailable;
  }

  int logins = 0, saves = 0, recovers = 0, resets = 0;
  bool fail = false, empty = false;
  String? lastVerification, lastCurrentPin, lastCurrentPassword;
  Completer<void>? pending;
  @override
  Future<User> login(String id, String pin) async {
    logins++;
    await pending?.future;
    if (fail) throw Exception('Pengenal akun atau PIN tidak sesuai.');
    return member;
  }

  @override
  Future<void> save(String pin,
      {String? currentPin,
      String? currentPassword,
      String? verificationMethod,
      bool useRecentGoogleAuth = false}) async {
    saves++;
    lastVerification = verificationMethod;
    lastCurrentPin = currentPin;
    lastCurrentPassword = currentPassword;
  }

  @override
  Future<void> recover(String id) async {
    recovers++;
  }

  @override
  Future<void> reset(String id, String code, String pin) async {
    resets++;
  }
}

class FakeDirectory implements DirectoryRepository {
  bool inApp = false, mixedInvites = false, accountInvite = false;
  int consentClaims = 0, emailVerificationRequests = 0;
  bool fail = false, empty = false;
  Completer<void>? pending;
  String query = '';
  int created = 0,
      edited = 0,
      invited = 0,
      claimed = 0,
      updated = 0,
      revoked = 0;
  Map<String, Object?>? fields;
  @override
  Future<DirectoryPage> search(
      {required bool members,
      String search = '',
      String? communityId,
      String? role,
      String status = 'active',
      int page = 1}) async {
    await pending?.future;
    query = search;
    if (fail) throw Exception('Akses ditolak');
    return DirectoryPage(
        empty
            ? []
            : [
                DirectoryItem('1', members ? 'Rina' : 'Komunitas Uji',
                    members ? 'Anggota · Komunitas Uji' : 'Bandung',
                    communityId: members ? '1' : null)
              ],
        1,
        1);
  }

  @override
  Future<DirectoryItem> community(String id) async =>
      const DirectoryItem('1', 'Komunitas Uji', 'Bandung',
          description: 'Latihan bersama');
  @override
  Future<Map<String, dynamic>> createMember(
      String c, Map<String, Object?> f) async {
    created++;
    fields = f;
    return {'id': 42};
  }

  @override
  Future<Map<String, dynamic>> memberDetail(String c, String m) async =>
      {'name': 'Anak Uji', 'guardian_grants': []};
  @override
  Future<void> editMember(String c, String m, Map<String, Object?> f) async {
    edited++;
    fields = f;
  }

  @override
  Future<void> invite(String c, String m, String email,
      {required bool account}) async {
    invited++;
  }

  @override
  Future<List<Map<String, dynamic>>> invitations() async => [
        if (!inApp || mixedInvites)
          {
            'id': 9,
            'member_name': 'Anak Uji',
            'kind': 'guardian',
            'delivery_method': 'email',
            'invited_by_name': 'Pendiri Uji',
            'community_name': 'Komunitas Uji'
          },
        if (inApp)
          {
            'id': 10,
            'member_name': 'Anak Uji',
            'kind': accountInvite ? 'account' : 'guardian',
            'delivery_method': 'in_app',
            'invited_by_name': 'Pendiri Uji',
            'community_name': 'Komunitas Uji'
          },
      ];
  @override
  Future<void> sendEmailVerification() async {
    emailVerificationRequests++;
  }

  @override
  Future<void> claim(String id, String token, {bool accept = false}) async {
    claimed++;
    if (accept) {
      consentClaims++;
      expect(token, '');
      return;
    }
    if (token != 'token-test') throw Exception('Token tidak valid');
  }

  @override
  Future<List<Map<String, dynamic>>> dependents() async => [
        {'id': 4, 'name': 'Anak Uji'}
      ];
  @override
  Future<Map<String, dynamic>> dependent(String id) async => {
        'name': 'Anak Uji',
        'birth_date': null,
        'gender': null,
        'grant_id': 8,
        'memberships': [
          {
            'id': 42,
            'community_name': 'Komunitas Uji',
            'status': 'active',
            'member_number': 'KU-000042'
          }
        ]
      };
  @override
  Future<void> updateDependent(String id, Map<String, Object?> f) async {
    updated++;
    fields = f;
  }

  @override
  Future<void> revoke(String id) async {
    revoked++;
  }

  @override
  Future<Map<String, dynamic>> card(String i, String m) async =>
      {'name': 'Anak Uji', 'member_number': 'KU-000042', 'status': 'active'};
  @override
  Future<List<Map<String, dynamic>>> internalMembers(String c,
          {String search = '',
          String? role,
          String status = 'active',
          int page = 1}) async =>
      [];
  @override
  Future<void> updateCommunity(String c, Map<String, Object?> f) async {}
}

Widget app(Widget child,
        {FakeDirectory? repo,
        FakePin? pin,
        AuthState auth = const AuthAuthenticated(member),
        GoRouter? router}) =>
    ProviderScope(
        overrides: [
          authProvider.overrideWith(() => FixedAuth(auth)),
          if (repo != null) directoryRepositoryProvider.overrideWithValue(repo),
          if (pin != null) pinRepositoryProvider.overrideWithValue(pin)
        ],
        child: router == null
            ? MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                home: child)
            : MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                routerConfig: router));
void size(WidgetTester t, double width) {
  t.view.physicalSize = Size(width, 950);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  test('return route rejects external or login loops', () {
    expect(safeLoginReturn('//evil.invalid'), null);
    expect(safeLoginReturn('/login?from=/'), null);
    expect(safeLoginReturn('/communities/1'), '/communities/1');
  });
  testWidgets(
      'visitor searches members, opens community and identity action returns via login',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    final router = GoRouter(
        initialLocation: '/explore',
        redirect: clubAuthRedirect,
        routes: [
          GoRoute(
              path: '/explore', builder: (_, __) => const DirectoryScreen()),
          GoRoute(
              path: '/explore/communities/:id',
              builder: (_, __) => const PublicCommunityScreen(id: '1')),
          GoRoute(
              path: '/login',
              builder: (_, s) =>
                  Text('LOGIN:${s.uri.queryParameters['from']}')),
          GoRoute(
              path: '/communities/:id',
              builder: (_, __) => const Text('PRIVATE'))
        ]);
    await t.pumpWidget(app(const SizedBox(),
        repo: repo, auth: const AuthUnauthenticated(), router: router));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'uji');
    await t.pumpAndSettle();
    expect(repo.query, 'uji');
    await t.tap(find.text('Komunitas Uji'));
    await t.pumpAndSettle();
    await t.tap(find.text('Masuk untuk bergabung'));
    await t.pumpAndSettle();
    expect(find.text('LOGIN:/communities/1'), findsOneWidget);
  });
  testWidgets(
      'PIN rejects invalid, shows uniform error, prevents double submit',
      (t) async {
    size(t, 500);
    final pin = FakePin()..fail = true;
    await t.pumpWidget(
        app(const PinScreen(), pin: pin, auth: const AuthUnauthenticated()));
    await t.tap(find.text('Masuk').last);
    await t.pump();
    expect(pin.logins, 0);
    await t.enterText(
        find.byType(TextFormField).at(0), 'wali@anaklangit.manahpro.web.id');
    await t.enterText(find.byType(TextFormField).at(1), '123456');
    pin.pending = Completer<void>();
    await t.tap(find.text('Masuk').last);
    await t.pump();
    await t.tap(find.byType(FilledButton));
    expect(pin.logins, 1);
    pin.pending!.complete();
    await t.pumpAndSettle();
    expect(find.textContaining('Pengenal akun atau PIN'), findsOneWidget);
  });
  testWidgets('PIN enrollment/change verifies current PIN', (t) async {
    size(t, 500);
    final pin = FakePin();
    await t.pumpWidget(app(const PinScreen(mode: PinMode.manage), pin: pin));
    await t.enterText(find.byType(TextFormField).at(0), '123456');
    await t.enterText(find.byType(TextFormField).at(1), '654321');
    await t.enterText(find.byType(TextFormField).at(2), '654321');
    await t.tap(find.text('Simpan PIN'));
    await t.pumpAndSettle();
    expect(pin.saves, 1);
    expect(pin.lastVerification, 'pin');
    expect(pin.lastCurrentPin, '123456');
    expect(find.text('PIN berhasil disimpan.'), findsOneWidget);
  });
  testWidgets('recovery sends generic code and reveals reset form', (t) async {
    final pin = FakePin();
    await t.pumpWidget(app(const PinScreen(mode: PinMode.recovery),
        pin: pin, auth: const AuthUnauthenticated()));
    await t.pumpAndSettle();
    await t.enterText(
        find.byType(TextFormField).first, 'wali@anaklangit.manahpro.web.id');
    await t.tap(find.text('Kirim kode'));
    await t.pumpAndSettle();
    expect(pin.recovers, 1);
    expect(find.text('Kode dari email'), findsOneWidget);
    expect(find.textContaining('Jika akun memenuhi syarat'), findsOneWidget);
  });
  testWidgets(
      'manual create then invite preserves stable membership and validates DOB',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    await t.pumpWidget(
        app(const MemberIdentityScreen(communityId: '1'), repo: repo));
    await t.enterText(find.byType(TextFormField).at(0), 'Anak Uji');
    await t.enterText(find.byType(TextFormField).at(1), '2099-01-01');
    await t.tap(find.text('Simpan Anggota'));
    await t.pumpAndSettle();
    expect(repo.created, 0);
    await t.enterText(find.byType(TextFormField).at(1), '2016-05-20');
    await t.tap(find.text('Simpan Anggota'));
    await t.pumpAndSettle();
    expect(repo.created, 1);
    expect(repo.fields!['idempotency_key'], isNotEmpty);
    await t.ensureVisible(find.text('Undang Wali'));
    await t.enterText(
        find.byType(TextField).last, 'wali@anaklangit.manahpro.web.id');
    await t.tap(find.text('Undang Wali'));
    await t.pumpAndSettle();
    expect(repo.invited, 1);
    expect(find.textContaining('Undangan dibuat.'), findsOneWidget);
  });
  testWidgets(
      'guardian claim requires token and dependent edit/revoke real actions',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    await t.pumpWidget(app(const GuardianScreen(), repo: repo));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('guardian-invitation-9')));
    await t.enterText(find.byType(TextField).last, 'token-test');
    await t.tap(find.text('Klaim Undangan'));
    await t.pumpAndSettle();
    expect(repo.claimed, 1);
    await t.pumpWidget(app(const DependentScreen(id: '4'), repo: repo));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, 'Anak Diperbarui');
    await t.enterText(find.byType(TextField).at(1), '2099-01-01');
    await t.tap(find.text('Simpan Data'));
    await t.pumpAndSettle();
    expect(repo.updated, 0);
    expect(find.textContaining('Gunakan tanggal YYYY-MM-DD yang valid'),
        findsOneWidget);
    await t.enterText(find.byType(TextField).at(1), '2026-02-30');
    await t.tap(find.text('Simpan Data'));
    await t.pumpAndSettle();
    expect(repo.updated, 0);
    await t.enterText(find.byType(TextField).at(1), '2016-05-20');
    await t.tap(find.text('Simpan Data'));
    await t.pumpAndSettle();
    expect(repo.updated, 1);
    expect(repo.fields!['name'], 'Anak Diperbarui');
    expect(repo.fields!['birth_date'], '2016-05-20');
    await t.ensureVisible(find.text('Lepaskan Hubungan Wali'));
    await t.tap(find.text('Lepaskan Hubungan Wali'));
    await t.pumpAndSettle();
    await t.tap(find.text('Batal'));
    await t.pumpAndSettle();
    expect(repo.revoked, 0);
  });
  testWidgets(
      'PIN login success stores authenticated state and calls destination',
      (t) async {
    final pin = FakePin();
    var arrived = false;
    await t.pumpWidget(app(PinScreen(onLoggedIn: () => arrived = true),
        pin: pin, auth: const AuthUnauthenticated()));
    await t.enterText(
        find.byType(TextFormField).at(0), 'wali@anaklangit.manahpro.web.id');
    await t.enterText(find.byType(TextFormField).at(1), '123456');
    await t.tap(find.text('Masuk').last);
    await t.pumpAndSettle();
    expect(pin.logins, 1);
    expect(arrived, true);
  });
  testWidgets('directory loading then empty state', (t) async {
    final repo = FakeDirectory()
      ..empty = true
      ..pending = Completer<void>();
    await t.pumpWidget(app(const DirectoryScreen(), repo: repo));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.pending!.complete();
    await t.pumpAndSettle();
    expect(find.text('Belum ada hasil. Coba pencarian lain.'), findsOneWidget);
  });
  testWidgets(
      'linked account owner manages guardian invitations without profile overwrite',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    await t.pumpWidget(app(
        const MemberIdentityScreen(
            communityId: '1',
            member: CommunityMember(
                id: '42',
                userId: '1',
                name: 'Saya',
                role: CommunityRole.member)),
        repo: repo));
    await t.pumpAndSettle();
    expect(find.text('Simpan Anggota'), findsNothing);
    await t.ensureVisible(find.text('Undang Wali'));
    await t.enterText(
        find.byType(TextField).last, 'wali@anaklangit.manahpro.web.id');
    await t.tap(find.text('Undang Wali'));
    await t.pumpAndSettle();
    expect(repo.invited, 1);
    expect(repo.edited, 0);
  });
  testWidgets('PIN reset keeps requested destination across recovery',
      (t) async {
    size(t, 500);
    final pin = FakePin();
    final router = GoRouter(
        initialLocation: '/login/recovery?from=%2Fcommunities%2F7',
        routes: [
          GoRoute(
              path: '/login/recovery',
              builder: (_, __) => const PinScreen(mode: PinMode.recovery)),
          GoRoute(
              path: '/login/pin',
              builder: (_, s) => Text('PIN:${s.uri.queryParameters['from']}'))
        ]);
    await t.pumpWidget(app(const SizedBox(),
        pin: pin, auth: const AuthUnauthenticated(), router: router));
    await t.pumpAndSettle();
    await t.enterText(
        find.byType(TextFormField).first, 'wali@anaklangit.manahpro.web.id');
    await t.tap(find.text('Kirim kode'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).at(1), '654321');
    await t.enterText(find.byType(TextFormField).at(2), '123456');
    await t.enterText(find.byType(TextFormField).at(3), '123456');
    await t.tap(find.text('Perbarui PIN'));
    await t.pumpAndSettle();
    expect(pin.resets, 1);
    expect(find.text('PIN:/communities/7'), findsOneWidget);
  });
  testWidgets('guardian can revoke own grant after direct deep-link reload',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    final router =
        GoRouter(initialLocation: '/guardians/dependents/4', routes: [
      GoRoute(
          path: '/guardians', builder: (_, __) => const Text('DAFTAR WALI')),
      GoRoute(
          path: '/guardians/dependents/:id',
          builder: (_, s) => DependentScreen(id: s.pathParameters['id']!))
    ]);
    await t.pumpWidget(app(const SizedBox(), repo: repo, router: router));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Lepaskan Hubungan Wali'));
    await t.tap(find.text('Lepaskan Hubungan Wali'));
    await t.pumpAndSettle();
    await t.tap(find.text('Lepaskan'));
    await t.pumpAndSettle();
    expect(repo.revoked, 1);
    expect(find.text('DAFTAR WALI'), findsOneWidget);
    expect(t.takeException(), null);
  });

  testWidgets('existing PIN can be recovered with account password', (t) async {
    size(t, 500);
    final pin = FakePin();
    await t.pumpWidget(app(const PinScreen(mode: PinMode.manage), pin: pin));
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Password akun').last);
    await t.pumpAndSettle();
    await t.enterText(
        find.byType(TextFormField).at(0), 'account-password-test');
    await t.enterText(find.byType(TextFormField).at(1), '654321');
    await t.enterText(find.byType(TextFormField).at(2), '654321');
    await t.ensureVisible(find.text('Simpan PIN'));
    await t.tap(find.text('Simpan PIN'));
    await t.pumpAndSettle();
    expect(pin.saves, 1);
    expect(pin.lastVerification, 'password');
    expect(pin.lastCurrentPassword, 'account-password-test');
    expect(pin.lastCurrentPin, null);
  });
  testWidgets('fresh Google proof sets PIN without asking old PIN or password',
      (t) async {
    size(t, 500);
    final pin = FakePin();
    await t.pumpWidget(app(const PinScreen(mode: PinMode.manage),
        pin: pin,
        auth: const AuthAuthenticated(User(
            id: '1',
            name: 'Google Uji',
            email: 'google@anaklangit.manahpro.web.id',
            pinEnabled: true,
            pinGoogleReauthenticated: true))));
    expect(find.text('Google baru diverifikasi'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await t.enterText(find.byType(TextFormField).at(0), '654321');
    await t.enterText(find.byType(TextFormField).at(1), '654321');
    await t.tap(find.text('Simpan PIN'));
    await t.pumpAndSettle();
    expect(pin.saves, 1);
    expect(pin.lastVerification, 'google');
    expect(pin.lastCurrentPin, null);
    expect(pin.lastCurrentPassword, null);
  });
  testWidgets('authenticated PIN recovery explicitly reopens account login',
      (t) async {
    size(t, 500);
    final router = GoRouter(
        initialLocation: '/login/recovery',
        redirect: clubAuthRedirect,
        routes: [
          GoRoute(
              path: '/login/recovery',
              builder: (_, __) => const PinScreen(mode: PinMode.recovery)),
          GoRoute(
              path: '/login',
              builder: (_, s) => Text(
                  'ACCOUNT LOGIN:${s.uri.queryParameters['from']}:${s.uri.queryParameters['reauth']}')),
          GoRoute(
              path: '/account/pin',
              builder: (_, __) => const Text('MANAGE PIN'))
        ]);
    await t.pumpWidget(app(const SizedBox(), router: router));
    await t.pumpAndSettle();
    await t.tap(find.text('Pulihkan melalui akun'));
    await t.pumpAndSettle();
    expect(find.text('ACCOUNT LOGIN:/account/pin:1'), findsOneWidget);
  });
  for (final account in [false, true]) {
    testWidgets(
        'in-app ${account ? 'account' : 'guardian'} invitation requires explicit consent',
        (t) async {
      size(t, 500);
      final repo = FakeDirectory()
        ..inApp = true
        ..accountInvite = account;
      await t.pumpWidget(app(const GuardianScreen(), repo: repo));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Setujui'));
      await t.pumpAndSettle();
      expect(
          find.textContaining('Pendiri Uji di Komunitas Uji'), findsOneWidget);
      if (account) {
        expect(find.textContaining('Hubungan wali lama'), findsOneWidget);
      }
      await t.tap(find.text('Batal'));
      await t.pumpAndSettle();
      expect(repo.claimed, 0);
      await t.tap(find.text('Setujui'));
      await t.pumpAndSettle();
      await t.tap(find.text('Setujui undangan'));
      await t.pumpAndSettle();
      expect(repo.claimed, 1);
      expect(repo.consentClaims, 1);
      expect(
          find.textContaining(account
              ? 'Akun terhubung.'
              : 'Hubungan wali terverifikasi berhasil'),
          findsOneWidget);
      expect(t.takeException(), null);
    });
  }

  testWidgets(
      'unavailable or failed email options keep account recovery available',
      (t) async {
    size(t, 500);
    final pin = FakePin()..optionsPending = Completer<bool>();
    await t.pumpWidget(app(const PinScreen(mode: PinMode.recovery), pin: pin));
    await t.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(t.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNotNull);
    pin.optionsPending!.completeError(Exception('Layanan belum tersedia.'));
    await t.pumpAndSettle();
    expect(find.text('Coba Muat Pilihan Lagi'), findsOneWidget);
    expect(find.text('Pulihkan melalui akun'), findsOneWidget);
    expect(find.text('Kirim kode'), findsNothing);
    pin.optionsPending = null;
    pin.emailAvailable = false;
    await t.tap(find.text('Coba Muat Pilihan Lagi'));
    await t.pumpAndSettle();
    expect(
        find.textContaining('Pemulihan email belum tersedia.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Kirim kode'), findsNothing);
    expect(pin.recovers, 0);
    expect(t.takeException(), null);
  });

  testWidgets(
      'guardian verification reopens Google login without pretending email delivery',
      (t) async {
    size(t, 500);
    final repo = FakeDirectory();
    final router = GoRouter(
        initialLocation: '/guardians',
        redirect: clubAuthRedirect,
        routes: [
          GoRoute(
              path: '/guardians', builder: (_, __) => const GuardianScreen()),
          GoRoute(
              path: '/login',
              builder: (_, s) => Text(
                  'REAUTH:${s.uri.queryParameters['from']}:${s.uri.queryParameters['reauth']}'))
        ]);
    await t.pumpWidget(app(const SizedBox(), repo: repo, router: router));
    await t.pumpAndSettle();
    expect(find.text('Kirim Tautan Verifikasi Email'), findsNothing);
    expect(
        find.textContaining('tautan verifikasi telah dikirim'), findsNothing);
    await t.tap(find.text('Masuk ulang dengan Google'));
    await t.pumpAndSettle();
    expect(find.text('REAUTH:/guardians:1'), findsOneWidget);
    expect(repo.emailVerificationRequests, 0);
    expect(t.takeException(), null);
  });
  for (final width in [500.0, 1280.0]) {
    testWidgets('directory loading/error/empty accessible at $width',
        (t) async {
      size(t, width);
      final repo = FakeDirectory()
        ..empty = true
        ..pending = Completer<void>();
      await t.pumpWidget(app(const DirectoryScreen(), repo: repo));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(t.takeException(), null);
      repo.pending!.complete();
      await t.pumpAndSettle();
      expect(
          find.text('Belum ada hasil. Coba pencarian lain.'), findsOneWidget);
      expect(find.text('Komunitas Uji'), findsNothing);
      expect(t.takeException(), null);
      repo.empty = false;
      repo.pending = Completer<void>();
      await t.enterText(find.byType(TextField), 'uji');
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.pending!.complete();
      await t.pumpAndSettle();
      expect(find.text('Komunitas Uji'), findsOneWidget);
      expect(repo.query, 'uji');
      expect(t.takeException(), null);
      repo.fail = true;
      repo.pending = Completer<void>();
      await t.enterText(find.byType(TextField), 'gagal');
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.pending!.complete();
      await t.pumpAndSettle();
      expect(find.textContaining('Akses ditolak'), findsOneWidget);
      expect(t.takeException(), null);
      repo.fail = false;
      repo.pending = Completer<void>();
      await t.tap(find.text('Coba Lagi'));
      await t.pump();
      // Riverpod keeps the previous error during a same-query refresh.
      expect(find.textContaining('Akses ditolak'), findsOneWidget);
      repo.pending!.complete();
      await t.pumpAndSettle();
      expect(find.text('Komunitas Uji'), findsOneWidget);
      expect(t.takeException(), null);
    });
  }
}
