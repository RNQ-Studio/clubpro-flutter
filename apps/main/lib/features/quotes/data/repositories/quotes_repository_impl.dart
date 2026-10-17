import 'dart:developer';

import 'package:core/core.dart';
import 'package:drift/drift.dart';

import '../../domain/entities/quote_entity.dart';
import '../../domain/repositories/quotes_repository.dart';
import '../datasources/quotes_local_data_source.dart';
import '../datasources/quotes_remote_data_source.dart';

/// Offline-first implementation of [QuotesRepository].
///
/// Strategy:
/// - **Read**: Try remote first → save to local → return local data.
///   Falls back to local-only if the network is unavailable.
/// - **Write**: Always write to local first (optimistic), then sync
///   to the server in the background.
/// - **Sync**: Process all unsynced items (create/update/delete) one
///   by one. Errors on individual items are logged but do not halt
///   the overall sync process.
class QuotesRepositoryImpl implements QuotesRepository {
  const QuotesRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final QuotesRemoteDataSource _remoteDataSource;
  final QuotesLocalDataSource _localDataSource;

  @override
  Future<List<QuoteEntity>> getQuotes() async {
    // Always return data from local database immediately (single source of truth)
    // Background synchronization will fetch and update this in the background.
    return _localDataSource.getAllQuotes();
  }

  @override
  Future<QuoteEntity> createQuote({
    required String text,
    required String author,
    String? source,
    bool isActive = true,
  }) async {
    final companion = QuotesCompanion(
      content: Value(text),
      author: Value(author),
      source: Value(source),
      isActive: Value(isActive),
      isSynced: const Value(false),
      syncAction: const Value('create'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    final localId = await _localDataSource.insertQuote(companion);

    // Optimistically trigger background sync
    syncQuotes().catchError((e) {
      log('Background sync error in createQuote: $e');
    });

    return QuoteEntity(
      localId: localId,
      text: text,
      author: author,
      source: source,
      isActive: isActive,
      isSynced: false,
      syncAction: 'create',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<QuoteEntity> updateQuote({
    required int localId,
    String? text,
    String? author,
    String? source,
    bool? isActive,
  }) async {
    final companion = QuotesCompanion(
      content: text != null ? Value(text) : const Value.absent(),
      author: author != null ? Value(author) : const Value.absent(),
      source: source != null ? Value(source) : const Value.absent(),
      isActive: isActive != null ? Value(isActive) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );

    await _localDataSource.updateQuote(localId, companion);

    // Optimistically trigger background sync
    syncQuotes().catchError((e) {
      log('Background sync error in updateQuote: $e');
    });

    // Return updated data from local DB
    final allQuotes = await _localDataSource.getAllQuotes();
    return allQuotes.firstWhere((q) => q.localId == localId);
  }

  @override
  Future<void> deleteQuote(int localId) async {
    await _localDataSource.markAsDeleted(localId);

    // Optimistically trigger background sync
    syncQuotes().catchError((e) {
      log('Background sync error in deleteQuote: $e');
    });
  }

  @override
  Future<void> syncQuotes() async {
    print('QuotesRepository.syncQuotes: Starting sync cycle...');
    // Check server availability first
    final isOnline = await _remoteDataSource.checkHealth();
    if (!isOnline) {
      print(
          'QuotesRepository.syncQuotes: server unreachable (health check returned false), skipping sync');
      return;
    }

    print(
        'QuotesRepository.syncQuotes: Server is online, getting unsynced quotes...');
    // Get all unsynced items
    final unsyncedQuotes = await _localDataSource.getUnsyncedQuotes();
    print(
        'QuotesRepository.syncQuotes: found ${unsyncedQuotes.length} unsynced quotes');

    for (final quote in unsyncedQuotes) {
      try {
        switch (quote.syncAction) {
          case 'create':
            print(
                'QuotesRepository.syncQuotes: creating quote localId=${quote.localId} on server...');
            final created = await _remoteDataSource.create(
              text: quote.text,
              author: quote.author,
              source: quote.source,
              isActive: quote.isActive,
            );
            await _localDataSource.markAsSynced(
              quote.localId,
              serverId: created.id,
            );
            print(
                'QuotesRepository.syncQuotes: quote localId=${quote.localId} synced with serverId=${created.id}');

          case 'update':
            if (quote.id == null) {
              print(
                  'QuotesRepository.syncQuotes: cannot update quote localId=${quote.localId} — no server ID');
              continue;
            }
            print(
                'QuotesRepository.syncQuotes: updating quote serverId=${quote.id} on server...');
            await _remoteDataSource.update(
              id: quote.id!,
              text: quote.text,
              author: quote.author,
              source: quote.source,
              isActive: quote.isActive,
            );
            await _localDataSource.markAsSynced(quote.localId);
            print(
                'QuotesRepository.syncQuotes: quote localId=${quote.localId} updated on server');

          case 'delete':
            if (quote.id == null) {
              // No server ID — just delete locally
              await _localDataSource.deletePermanently(quote.localId);
              continue;
            }
            print(
                'QuotesRepository.syncQuotes: deleting quote serverId=${quote.id} on server...');
            await _remoteDataSource.delete(quote.id!);
            await _localDataSource.deletePermanently(quote.localId);
            print(
                'QuotesRepository.syncQuotes: quote localId=${quote.localId} deleted on server');

          default:
            print(
                'QuotesRepository.syncQuotes: unknown syncAction "${quote.syncAction}" for localId=${quote.localId}');
        }
      } catch (e) {
        // Log but don't rethrow — continue syncing remaining items
        print(
            'QuotesRepository.syncQuotes: failed to sync localId=${quote.localId} (action=${quote.syncAction}), error: $e');
      }
    }

    // After syncing all pending items, refresh local data from server
    try {
      print(
          'QuotesRepository.syncQuotes: fetching latest quotes from server...');
      final remoteQuotes = await _remoteDataSource.fetchAll();
      print(
          'QuotesRepository.syncQuotes: fetched ${remoteQuotes.length} quotes from server. Updating local DB...');
      final companions =
          remoteQuotes.map((q) => q.toDatabaseCompanion()).toList();
      await _localDataSource.replaceAllWithServerData(companions);
      print(
          'QuotesRepository.syncQuotes: local DB successfully updated with server quotes.');
    } catch (e) {
      print(
          'QuotesRepository.syncQuotes: failed to refresh from server after sync, error: $e');
    }
  }
}
