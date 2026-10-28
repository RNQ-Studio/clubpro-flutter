import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

const _user = User(
  id: '1',
  name: 'Muhammad Rizky Pratama Wicaksono Putra',
  email: 'muhammad.rizky.pratama@gmail.com',
);

/// Ponsel kecil (360×640 dp) dengan teks diperbesar 1.3× — tidak boleh overflow.
void main() {
  Future<void> pumpSmall(
      WidgetTester tester, Widget screen, AuthState auth) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(ProviderScope(
      overrides: [authProvider.overrideWith(() => _FixedAuthNotifier(auth))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: screen,
      ),
    ));
    await tester.pump();
  }

  Future<void> scrollThrough(WidgetTester tester) async {
    final scrollable = find.byType(Scrollable).first;
    for (var i = 0; i < 6; i++) {
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  }

  testWidgets('GoogleLoginScreen', (tester) async {
    await pumpSmall(
      tester,
      const GoogleLoginScreen(
        title: 'CEO · Community E-Commerce Operator',
        subtitle: 'Masuk untuk mengakses kartu anggota, absensi, iuran '
            'bulanan, dan saldo komunitas Anda.',
        logo: SizedBox.square(dimension: 112),
      ),
      const AuthError('Login Google belum diaktifkan di server. Hubungi '
          'pengurus komunitas.'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen', (tester) async {
    await pumpSmall(
        tester, const ProfileScreen(), const AuthAuthenticated(_user));
    expect(tester.takeException(), isNull);
    await scrollThrough(tester);
  });

  testWidgets('ProfileSetupScreen', (tester) async {
    await pumpSmall(
        tester, const ProfileSetupScreen(), const AuthAuthenticated(_user));
    expect(tester.takeException(), isNull);
    await scrollThrough(tester);
  });

  testWidgets('EditProfileScreen', (tester) async {
    await pumpSmall(
        tester, const EditProfileScreen(), const AuthAuthenticated(_user));
    expect(tester.takeException(), isNull);
    await scrollThrough(tester);
  });
}
