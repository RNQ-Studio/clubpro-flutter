import 'dart:io';

import 'package:app_main/branding/club_brand.dart';
import 'package:app_main/branding/club_logo.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding menjelaskan fitur utama CEO', () {
    final titles = ClubBrand.onboardingPages.map((p) => p.title).join(' | ');

    expect(titles, contains('CEO'));
    expect(titles, contains('Kartu Anggota'));
    expect(titles, contains('Absensi'));
    expect(titles, contains('Iuran Bulanan'));
    expect(titles, contains('Top-up Saldo'));
  });

  test('tidak ada sisa branding lama di identitas app', () {
    final copy = [
      ClubBrand.name,
      ClubBrand.title,
      ClubBrand.tagline,
      ClubBrand.loginSubtitle,
      for (final p in ClubBrand.onboardingPages) ...[p.title, p.description],
    ].join(' ').toLowerCase();

    for (final old in ['anak langit', 'archery', 'panah', 'club']) {
      expect(copy, isNot(contains(old)), reason: old);
    }
    expect(ClubBrand.title, 'CEO · Community E-Commerce Operator');
  });

  testWidgets('halaman pertama onboarding menampilkan logo club',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(pages: ClubBrand.onboardingPages),
        ),
      ),
    );

    expect(find.text('Selamat Datang di CEO'), findsOneWidget);
    expect(find.byType(ClubLogo), findsOneWidget);
  });

  testWidgets('onboarding muat di ponsel kecil dengan teks besar',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1280); // 360×640 dp
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(pages: ClubBrand.onboardingPages),
        ),
      ),
    );
    for (var i = 0; i < ClubBrand.onboardingPages.length; i++) {
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'halaman ${i + 1}');
      if (i < ClubBrand.onboardingPages.length - 1) {
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('logo dapat dirender di berbagai ukuran', (tester) async {
    for (final size in [24.0, 80.0, 168.0]) {
      await tester.pumpWidget(_wrap(ClubLogo(size: size)));
      expect(tester.getSize(find.byType(ClubLogo)), Size.square(size));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('logo memakai aset CEO; ubin bersudut, watermark memudar',
      (tester) async {
    await tester.pumpWidget(_wrap(const ClubLogo(size: 80)));
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as ResizeImage).imageProvider,
        isA<AssetImage>().having((a) => a.assetName, 'asset', ClubLogo.asset));
    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);

    await tester.pumpWidget(_wrap(const ClubLogo(size: 150, fadeEdges: true)));
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });

  test('aset logo terdaftar di pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/branding/'));
    expect(File(ClubLogo.asset).existsSync(), isTrue);
  });
}

Widget _wrap(Widget child) => Directionality(
    textDirection: TextDirection.ltr, child: Center(child: child));
