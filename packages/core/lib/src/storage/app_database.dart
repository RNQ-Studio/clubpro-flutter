import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Cache entries table for offline data persistence.
///
/// Uses a unique [key] to identify cached payloads, with optional
/// TTL (time-to-live) support for automatic expiration.
class CacheEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get jsonPayload => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// TTL in seconds. Null = never expires.
  IntColumn get ttlSeconds => integer().nullable()();
}

/// Quotes table for offline-first quote management.
///
/// Supports full CRUD with sync tracking via [isSynced] and [syncAction].
/// The [localId] is the local primary key; [id] is the server-assigned ID
/// which may be null for quotes created while offline.
///
/// Note: The quote text is stored in [content] (not `text`) to avoid
/// shadowing Drift's built-in `text()` column builder method.
class Quotes extends Table {
  /// Local auto-increment primary key.
  IntColumn get localId => integer().autoIncrement()();

  /// Server-assigned ID. Null when created offline and not yet synced.
  IntColumn get serverId => integer().nullable()();

  /// The quote text content.
  /// Named `content` to avoid shadowing Drift's `text()` method.
  TextColumn get content => text()();

  /// The quote author name.
  TextColumn get author => text()();

  /// Optional source of the quote (book, speech, etc.).
  TextColumn get source => text().nullable()();

  /// Whether the quote is active.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Whether this record has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Pending sync action: 'create', 'update', 'delete', or null.
  TextColumn get syncAction => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

/// Main application database using Drift (SQLite).
///
/// Provides structured offline storage with a generic cache table
/// and feature-specific tables (e.g. [Quotes]).
@DriftDatabase(tables: [CacheEntries, Quotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(quotes);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'app_cache');
  }

  // ─── Cache Operations ─────────────────────────────────────────

  /// Upserts a cache entry (insert or replace if key exists).
  Future<void> writeCache(
    String cacheKey,
    String jsonPayload, {
    int? ttlSeconds,
  }) async {
    await into(cacheEntries).insertOnConflictUpdate(
      CacheEntriesCompanion.insert(
        key: cacheKey,
        jsonPayload: jsonPayload,
        ttlSeconds: Value(ttlSeconds),
      ),
    );
  }

  /// Reads a cache entry by key. Returns `null` if not found or expired.
  Future<String?> readCache(String cacheKey) async {
    final entry = await (select(cacheEntries)
          ..where((t) => t.key.equals(cacheKey)))
        .getSingleOrNull();

    if (entry == null) return null;

    // Check TTL expiration
    if (entry.ttlSeconds != null) {
      final age = DateTime.now().difference(entry.createdAt).inSeconds;
      if (age > entry.ttlSeconds!) {
        await deleteCache(cacheKey);
        return null;
      }
    }

    return entry.jsonPayload;
  }

  /// Deletes a cache entry by key.
  Future<void> deleteCache(String cacheKey) async {
    await (delete(cacheEntries)..where((t) => t.key.equals(cacheKey))).go();
  }

  /// Evicts all expired cache entries. Returns the count of deleted entries.
  Future<int> evictExpired() async {
    final now = DateTime.now();
    final all = await select(cacheEntries).get();
    int deleted = 0;

    for (final entry in all) {
      if (entry.ttlSeconds != null) {
        final age = now.difference(entry.createdAt).inSeconds;
        if (age > entry.ttlSeconds!) {
          await (delete(cacheEntries)..where((t) => t.id.equals(entry.id)))
              .go();
          deleted++;
        }
      }
    }
    return deleted;
  }

  /// Clears all cache entries.
  Future<int> clearAllCache() async {
    return delete(cacheEntries).go();
  }
}
