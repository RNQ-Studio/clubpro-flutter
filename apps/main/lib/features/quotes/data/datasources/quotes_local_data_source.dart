import 'package:core/core.dart';
import 'package:drift/drift.dart';

import '../models/quote_model.dart';

/// Local data source for offline Quotes storage using Drift (SQLite).
///
/// Manages CRUD operations on the local [Quotes] table and provides
/// sync-status tracking for the offline-first architecture.
class QuotesLocalDataSource {
  const QuotesLocalDataSource(this._db);

  final AppDatabase _db;

  /// Retrieves all quotes that are NOT marked for deletion.
  ///
  /// Items with `syncAction = 'delete'` are excluded from the result
  /// since they are pending server-side removal.
  Future<List<QuoteModel>> getAllQuotes() async {
    final query = _db.select(_db.quotes)
      ..where(
        (t) =>
            t.syncAction.isNull() |
            t.syncAction.equals('create') |
            t.syncAction.equals('update'),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
      ]);

    final rows = await query.get();
    return rows.map(QuoteModel.fromDatabase).toList();
  }

  /// Inserts a new quote into the local database.
  ///
  /// Sets `isSynced = false` and `syncAction = 'create'` so the
  /// sync engine knows to POST this item to the server.
  ///
  /// Returns the newly assigned `localId`.
  Future<int> insertQuote(QuotesCompanion companion) async {
    final withSyncFlags = companion.copyWith(
      isSynced: const Value(false),
      syncAction: const Value('create'),
    );
    return _db.into(_db.quotes).insert(withSyncFlags);
  }

  /// Updates an existing quote identified by [localId].
  ///
  /// If the quote has already been synced to the server (has a server ID),
  /// sets `isSynced = false` and `syncAction = 'update'` to trigger
  /// a PUT on next sync. If it was never synced, keeps `syncAction = 'create'`.
  Future<void> updateQuote(int localId, QuotesCompanion companion) async {
    // First, check the current state to determine the correct syncAction.
    final existing = await (_db.select(_db.quotes)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();

    if (existing == null) return;

    // If the item was already synced (has server ID and syncAction is null),
    // mark it for update. If it's still pending create, keep 'create'.
    final syncAction = existing.syncAction == 'create' ? 'create' : 'update';

    final updated = companion.copyWith(
      isSynced: const Value(false),
      syncAction: Value(syncAction),
    );

    await (_db.update(_db.quotes)..where((t) => t.localId.equals(localId)))
        .write(updated);
  }

  /// Marks a quote for deletion or removes it immediately.
  ///
  /// - If the quote was **never synced** to the server (`id == null`),
  ///   it is deleted permanently from SQLite.
  /// - If it **has been synced**, it is soft-deleted by setting
  ///   `isSynced = false` and `syncAction = 'delete'`.
  Future<void> markAsDeleted(int localId) async {
    final existing = await (_db.select(_db.quotes)
          ..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();

    if (existing == null) return;

    if (existing.serverId == null) {
      // Never synced — delete immediately
      await (_db.delete(_db.quotes)..where((t) => t.localId.equals(localId)))
          .go();
    } else {
      // Has been synced — soft-delete for server sync
      await (_db.update(_db.quotes)..where((t) => t.localId.equals(localId)))
          .write(
        const QuotesCompanion(
          isSynced: Value(false),
          syncAction: Value('delete'),
        ),
      );
    }
  }

  /// Returns all quotes that have not been synced (`isSynced == false`).
  Future<List<QuoteModel>> getUnsyncedQuotes() async {
    final query = _db.select(_db.quotes)
      ..where((t) => t.isSynced.equals(false));
    final rows = await query.get();
    return rows.map(QuoteModel.fromDatabase).toList();
  }

  /// Marks a quote as synced after successful server communication.
  ///
  /// Sets `isSynced = true`, clears `syncAction`, and optionally
  /// updates the server-assigned [serverId].
  Future<void> markAsSynced(int localId, {int? serverId}) async {
    final companion = QuotesCompanion(
      isSynced: const Value(true),
      syncAction: const Value(null),
      serverId: serverId != null ? Value(serverId) : const Value.absent(),
    );

    await (_db.update(_db.quotes)..where((t) => t.localId.equals(localId)))
        .write(companion);
  }

  /// Permanently deletes a quote from the local database.
  ///
  /// Called after a `DELETE` sync action succeeds on the server.
  Future<void> deletePermanently(int localId) async {
    await (_db.delete(_db.quotes)..where((t) => t.localId.equals(localId)))
        .go();
  }

  /// Replaces all synced data with fresh server data.
  ///
  /// **Important**: Only deletes rows where `isSynced == true`.
  /// Unsynced local changes (`isSynced == false`) are preserved
  /// to avoid data loss during the refresh.
  Future<void> replaceAllWithServerData(
    List<QuotesCompanion> serverData,
  ) async {
    await _db.transaction(() async {
      // Delete only previously-synced rows
      await (_db.delete(_db.quotes)..where((t) => t.isSynced.equals(true)))
          .go();

      // Insert fresh server data
      for (final companion in serverData) {
        await _db.into(_db.quotes).insert(companion);
      }
    });
  }
}
