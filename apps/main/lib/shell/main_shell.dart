import 'package:features_shared/features_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Halaman utama setelah login: navigasi bawah Beranda & Profil.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileIncomplete =
        authState is AuthAuthenticated && !authState.user.completion.isComplete;

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Mengetuk tab aktif kembali ke halaman awal tab itu.
        onDestinationSelected: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge(
              key: const Key('profile-tab-badge'),
              isLabelVisible: profileIncomplete,
              smallSize: 8,
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: profileIncomplete,
              smallSize: 8,
              child: const Icon(Icons.person_rounded),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
