import 'package:app_main/branding/club_brand.dart';
import 'package:app_main/branding/club_logo.dart';
import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('onboarding menjelaskan fitur utama club', () {
    final titles = ClubBrand.onboardingPages.map((p) => p.title).join(' | ');

    expect(titles, contains('Anak Langit Archery'));
    expect(titles, contains('Jadwal Latihan'));
    expect(titles, contains('Absensi'));
    expect(titles, contains('Prestasi'));
    expect(titles, contains('Iuran Bulanan'));
    expect(titles, contains('Operasional Club'));
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

    expect(find.text('Selamat Datang di Anak Langit Archery'), findsOneWidget);
    expect(find.byType(ClubLogo), findsOneWidget);
  });

  testWidgets('logo dapat dirender di berbagai ukuran', (tester) async {
    for (final size in [24.0, 80.0, 168.0]) {
      await tester.pumpWidget(Center(child: ClubLogo(size: size)));
      expect(tester.getSize(find.byType(ClubLogo)), Size.square(size));
    }
  });
}
