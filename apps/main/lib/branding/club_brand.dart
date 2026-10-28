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

  // Aksen emas dari logo di atas tema monokrom.
  static const gold = Color(0xFFBE8815);
  static const goldDeep = Color(0xFF8A5C06);
  static const bronze = Color(0xFF764903);

  static const onboardingPages = [
    OnboardingPage(
      icon: Icons.storefront_rounded,
      title: 'Selamat Datang di CEO',
      description: 'Community E-Commerce Operator — aplikasi resmi anggota '
          'komunitas. Semua kebutuhan anggota kini ada dalam satu genggaman.',
      color: gold,
      illustration: ClubLogo(size: 168),
    ),
    OnboardingPage(
      icon: Icons.badge_rounded,
      title: 'Kartu Anggota Digital',
      description: 'Data keanggotaan Anda tersimpan rapi dan kartu anggota '
          'selalu siap ditunjukkan langsung dari aplikasi.',
      color: gold,
    ),
    OnboardingPage(
      icon: Icons.event_available_rounded,
      title: 'Absensi Kegiatan',
      description: 'Catat kehadiran Anda di setiap kegiatan komunitas dan '
          'lihat riwayatnya kapan saja.',
      color: goldDeep,
    ),
    OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Iuran Bulanan',
      description: 'Pantau tagihan dan riwayat pembayaran iuran bulanan '
          'dengan mudah dan transparan.',
      color: bronze,
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
