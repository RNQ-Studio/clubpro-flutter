import 'package:flutter/material.dart';

/// Menu utama operasional club.
class HomeMenu {
  const HomeMenu({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;

  /// Ditampilkan saat fitur belum tersedia.
  final String description;
}

const homeMenus = [
  HomeMenu(
    id: 'schedule',
    label: 'Jadwal Latihan',
    icon: Icons.event_note_rounded,
    color: Color(0xFF1E6FD9),
    description: 'Lihat jadwal latihan, lokasi, dan pelatih setiap sesi.',
  ),
  HomeMenu(
    id: 'attendance',
    label: 'Absensi',
    icon: Icons.how_to_reg_rounded,
    color: Color(0xFF178A5B),
    description: 'Catat kehadiran latihan dan lihat riwayat absensi Anda.',
  ),
  HomeMenu(
    id: 'achievements',
    label: 'Prestasi',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFC98A00),
    description: 'Simpan hasil lomba, skor latihan, dan pencapaian Anda.',
  ),
  HomeMenu(
    id: 'dues',
    label: 'Iuran Bulanan',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFD62F33),
    description: 'Pantau tagihan dan riwayat pembayaran iuran bulanan.',
  ),
  HomeMenu(
    id: 'events',
    label: 'Event & Lomba',
    icon: Icons.military_tech_rounded,
    color: Color(0xFF6D4AFF),
    description: 'Info kejuaraan, pendaftaran lomba, dan kegiatan club.',
  ),
  HomeMenu(
    id: 'announcements',
    label: 'Pengumuman',
    icon: Icons.campaign_rounded,
    color: Color(0xFFE8710A),
    description: 'Pengumuman resmi dari pengurus club.',
  ),
  HomeMenu(
    id: 'members',
    label: 'Anggota',
    icon: Icons.groups_rounded,
    color: Color(0xFF00838F),
    description: 'Daftar anggota dan pelatih club Anak Langit.',
  ),
  HomeMenu(
    id: 'equipment',
    label: 'Peralatan',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFF5D4037),
    description: 'Peminjaman busur, anak panah, dan perlengkapan club.',
  ),
];

class HomeMenuGrid extends StatelessWidget {
  const HomeMenuGrid({
    super.key,
    required this.onTap,
    this.menus = homeMenus,
  });

  final List<HomeMenu> menus;
  final ValueChanged<HomeMenu> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tanpa letterSpacing bawaan M3 agar kata panjang ("Pengumuman") muat satu baris.
    final labelStyle =
        theme.textTheme.labelMedium?.copyWith(height: 1.2, letterSpacing: 0);
    // Tinggi tile mengikuti skala teks perangkat: ikon + jarak + 2 baris label.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(labelStyle?.fontSize ?? 12) *
            1.2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: menus.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 4,
        mainAxisExtent: 56 + 8 + lineHeight * 2 + 6,
      ),
      itemBuilder: (context, i) {
        final menu = menus[i];
        return InkWell(
          key: Key('home-menu-${menu.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => onTap(menu),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(menu.icon, color: menu.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                menu.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lembar "segera hadir" untuk menu yang fiturnya sedang disiapkan.
Future<void> showComingSoonSheet(BuildContext context, HomeMenu menu) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(menu.icon, color: menu.color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                menu.label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Segera hadir',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: menu.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                menu.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
