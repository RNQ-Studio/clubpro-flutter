import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';

import 'club_logo.dart';

/// Identitas app member club Anak Langit Archery.
abstract final class ClubBrand {
  static const name = 'Anak Langit Archery';
  static const shortName = 'Anak Langit';
  static const tagline = 'Aplikasi Anggota Club Panahan';
  static const loginSubtitle = 'Masuk untuk mengakses jadwal latihan, absensi, '
      'prestasi, dan iuran bulanan club.';

  // Warna aksen mengikuti cincin target (biru, emas, merah) di atas tema monokrom.
  static const blue = Color(0xFF1E6FD9);
  static const gold = Color(0xFFC98A00);
  static const red = Color(0xFFD62F33);
  static const green = Color(0xFF178A5B);

  static const onboardingPages = [
    OnboardingPage(
      icon: Icons.sports_score_rounded,
      title: 'Selamat Datang di Anak Langit Archery',
      description: 'Aplikasi resmi anggota club panahan Anak Langit. '
          'Semua kebutuhan anggota club kini ada dalam satu genggaman.',
      color: blue,
      illustration: ClubLogo(size: 168),
    ),
    OnboardingPage(
      icon: Icons.event_available_rounded,
      title: 'Jadwal Latihan & Absensi',
      description: 'Lihat jadwal latihan terbaru dan catat kehadiran Anda '
          'di setiap sesi latihan langsung dari aplikasi.',
      color: blue,
    ),
    OnboardingPage(
      icon: Icons.emoji_events_rounded,
      title: 'Catat Prestasi',
      description: 'Simpan hasil lomba, skor latihan, dan pencapaian Anda '
          'sebagai pemanah, lalu pantau perkembangannya dari waktu ke waktu.',
      color: gold,
    ),
    OnboardingPage(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Iuran Bulanan',
      description: 'Pantau tagihan dan riwayat pembayaran iuran bulanan '
          'club dengan mudah dan transparan.',
      color: red,
    ),
    OnboardingPage(
      icon: Icons.groups_rounded,
      title: 'Operasional Club',
      description: 'Pengumuman, kegiatan, dan semua yang berhubungan dengan '
          'operasional club Anak Langit tersedia di satu aplikasi.',
      color: green,
    ),
  ];
}
