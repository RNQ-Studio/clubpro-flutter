import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/core.dart';
import 'package:features_shared/features_shared.dart';

import 'branding/club_brand.dart';
import 'account_data_cache.dart';
import 'router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key, required this.storage, required this.database});

  final StorageService storage;
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const _AppRouter(),
    );
  }
}

class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(authProvider) is AuthInitial) {
        ref.read(authProvider.notifier).checkCurrentUser();
      }
    });
    ref.listenManual(authProvider, (previous, next) {
      final before = previous is AuthAuthenticated ? previous.user.id : null;
      final after = next is AuthAuthenticated ? next.user.id : null;
      // Clear before a new session's private routes read data. Invalidating an
      // outgoing session while its routes still mount would start fresh private
      // requests during logout/storage cleanup instead.
      if (after != null && before != after) clearAccountData(ref);
      appRouter.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(themeProvider).asData?.value ?? ThemeMode.system;
    final locale = ref.watch(localeProvider).asData?.value;

    return MaterialApp.router(
      title: ClubBrand.title,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
