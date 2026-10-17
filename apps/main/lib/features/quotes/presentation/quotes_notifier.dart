import 'dart:developer';

import 'package:core/core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/quote_entity.dart';
import 'providers/quotes_providers.dart';

part 'quotes_notifier.g.dart';

/// Async notifier managing the Quotes list state with offline-first
/// auto-synchronization.
///
/// The [build] method initializes by triggering a background sync,
/// then returns the local SQLite data as the single source of truth.
///
/// All CRUD methods use **optimistic UI updates**: they modify local
/// storage first, immediately rebuild the state, then trigger
/// background sync to push changes to the server.
@riverpod
class QuotesNotifier extends _$QuotesNotifier {
  @override
  Future<List<QuoteEntity>> build() async {
    // Listen to network status changes and trigger background sync when coming online
    ref.listen(connectivityServiceProvider, (previous, next) {
      final isOnline = next.value ?? false;
      final wasOnline = previous?.value ?? false;

      // Trigger sync ONLY when transitioning from offline to online
      if (isOnline && !wasOnline) {
        log('Connectivity changed from Offline to Online. Flushing sync queue...',
            name: 'QuotesNotifier');
        syncInBackground();
      }
    });

    // Trigger background sync (don't block UI loading)
    syncInBackground();

    // Return local data as the initial state
    return _loadLocalQuotes();
  }

  // ─── CRUD Actions (Optimistic UI) ───────────────────────────

  /// Creates a new quote with optimistic UI update.
  ///
  /// 1. Saves to local SQLite immediately with `syncAction = 'create'`
  /// 2. Rebuilds state instantly so the user sees the new quote
  /// 3. Triggers background sync to POST to the server
  Future<void> addQuote({
    required String text,
    required String author,
    String? source,
    bool isActive = true,
  }) async {
    final repository = ref.read(quotesRepositoryProvider);

    try {
      await repository.createQuote(
        text: text,
        author: author,
        source: source,
        isActive: isActive,
      );

      // Optimistic: reload from local DB and rebuild state instantly
      state = AsyncData(await _loadLocalQuotes());

      // Background sync
      syncInBackground();
    } catch (e, st) {
      log(
        'QuotesNotifier.addQuote: failed',
        error: e,
        stackTrace: st,
        name: 'QuotesNotifier',
      );
      // Re-throw so the UI can show an error snackbar
      rethrow;
    }
  }

  /// Updates an existing quote with optimistic UI update.
  ///
  /// Only the provided fields are updated; others remain unchanged.
  Future<void> editQuote({
    required int localId,
    String? text,
    String? author,
    String? source,
    bool? isActive,
  }) async {
    final repository = ref.read(quotesRepositoryProvider);

    try {
      await repository.updateQuote(
        localId: localId,
        text: text,
        author: author,
        source: source,
        isActive: isActive,
      );

      // Optimistic: reload and rebuild
      state = AsyncData(await _loadLocalQuotes());

      // Background sync
      syncInBackground();
    } catch (e, st) {
      log(
        'QuotesNotifier.editQuote: failed for localId=$localId',
        error: e,
        stackTrace: st,
        name: 'QuotesNotifier',
      );
      rethrow;
    }
  }

  /// Deletes a quote with optimistic UI update.
  ///
  /// If the quote was never synced, it's removed immediately.
  /// If it was synced, it's soft-deleted and removed from the server
  /// during the next sync cycle.
  Future<void> removeQuote(int localId) async {
    final repository = ref.read(quotesRepositoryProvider);

    try {
      await repository.deleteQuote(localId);

      // Optimistic: remove from visible list immediately
      state = AsyncData(await _loadLocalQuotes());

      // Background sync
      syncInBackground();
    } catch (e, st) {
      log(
        'QuotesNotifier.removeQuote: failed for localId=$localId',
        error: e,
        stackTrace: st,
        name: 'QuotesNotifier',
      );
      rethrow;
    }
  }

  /// Manually refreshes the quotes list.
  ///
  /// Shows a loading state, syncs with the server, then reloads
  /// local data. Useful for pull-to-refresh.
  Future<void> refreshQuotes() async {
    state = const AsyncLoading();

    try {
      // Sync first to push/pull latest data
      await _syncData();

      // Reload local data
      state = AsyncData(await _loadLocalQuotes());
    } catch (e, st) {
      log(
        'QuotesNotifier.refreshQuotes: failed',
        error: e,
        stackTrace: st,
        name: 'QuotesNotifier',
      );
      state = AsyncError(e, st);
    }
  }

  // ─── Internal Helpers ─────────────────────────────────────────

  /// Loads all visible quotes from the local SQLite database.
  Future<List<QuoteEntity>> _loadLocalQuotes() async {
    final repository = ref.read(quotesRepositoryProvider);
    return repository.getQuotes();
  }

  /// Runs the full sync cycle in the background without blocking UI.
  ///
  /// After sync completes, silently updates the state with fresh data.
  /// Errors are logged but never thrown to the UI.
  void syncInBackground() {
    Future(() async {
      try {
        // Riverpod 3 otomatis membawa data sebelumnya saat state = AsyncLoading().
        state = AsyncLoading<List<QuoteEntity>>();

        await _syncData();
        // Silently refresh state after successful sync
        final freshData = await _loadLocalQuotes();
        state = AsyncData(freshData);
      } catch (e) {
        // Swallow — background sync should never crash the UI
        print('QuotesNotifier.syncInBackground: failed silently, error: $e');
        // Fallback to local database data
        final local = await _loadLocalQuotes();
        state = AsyncData(local);
      }
    });
  }

  /// Executes the sync cycle: pushes unsynced local changes to the
  /// server, then pulls the latest data from the server.
  Future<void> _syncData() async {
    final repository = ref.read(quotesRepositoryProvider);
    await repository.syncQuotes();
  }
}
