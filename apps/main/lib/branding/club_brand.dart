import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';

import 'club_logo.dart';

/// Identitas app anggota CEO (Community E-Commerce Operator).
abstract final class ClubBrand {
  static const name = 'CEO';
  static const shortName = 'CEO';
  static const tagline = 'Community E-Commerce Operator';

  /// Judul tab browser / pengalih tugas.
  static const title = '$name · $tagline';
  static const loginSubtitle = 'Masuk untuk mengakses kartu anggota, absensi, '
      'iuran bulanan, dan saldo komunitas Anda.';

  // Warna aksen di atas tema monokrom.
  static const blue = Color(0xFF1E6FD9);
  static const gold = Color(0xFFC98A00);
  static const red = Color(0xFFD62F33);
  static const green = Color(0xFF178A5B);

  static const onboardingPages = [
    OnboardingPage(
      icon: Icons.storefront_rounded,
      title: 'Selamat Datang di CEO',
      description: 'Community E-Commerce Operator — aplikasi resmi anggota '
          'komunitas. Semua kebutuhan anggota kini ada dalam satu genggaman.',
      color: blue,
      illustration: ClubLogo(size: 168),
    ),
    OnboardingPage(
      icon: Icons.badge_rounded,
      title: 'Kartu Anggota Digital',
      description: 'Data keanggotaan Anda tersimpan rapi dan kartu anggota '
          'selalu siap ditunjukkan langsung dari aplikasi.',
      color: blue,
    ),
    OnboardingPage(
      icon: Icons.event_available_rounded,
      title: 'Absensi Kegiatan',
      description: 'Catat kehadiran Anda di setiap kegiatan komunitas dan '
          'lihat riwayatnya kapan saja.',
      color: green,
    ),
    OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Iuran Bulanan',
      description: 'Pantau tagihan dan riwayat pembayaran iuran bulanan '
          'dengan mudah dan transparan.',
      color: red,
    ),
    OnboardingPage(
      icon: Icons.add_card_rounded,
      title: 'Top-up Saldo via Transfer',
      description: 'Isi saldo lewat transfer bank lalu unggah bukti '
          'transfernya; pengurus memverifikasi nominal yang masuk.',
      color: gold,
    ),
  ];
}
