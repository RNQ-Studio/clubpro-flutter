// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotes_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async notifier managing the Quotes list state with offline-first
/// auto-synchronization.
///
/// The [build] method initializes by triggering a background sync,
/// then returns the local SQLite data as the single source of truth.
///
/// All CRUD methods use **optimistic UI updates**: they modify local
/// storage first, immediately rebuild the state, then trigger
/// background sync to push changes to the server.

@ProviderFor(QuotesNotifier)
final quotesProvider = QuotesNotifierProvider._();

/// Async notifier managing the Quotes list state with offline-first
/// auto-synchronization.
///
/// The [build] method initializes by triggering a background sync,
/// then returns the local SQLite data as the single source of truth.
///
/// All CRUD methods use **optimistic UI updates**: they modify local
/// storage first, immediately rebuild the state, then trigger
/// background sync to push changes to the server.
final class QuotesNotifierProvider
    extends $AsyncNotifierProvider<QuotesNotifier, List<QuoteEntity>> {
  /// Async notifier managing the Quotes list state with offline-first
  /// auto-synchronization.
  ///
  /// The [build] method initializes by triggering a background sync,
  /// then returns the local SQLite data as the single source of truth.
  ///
  /// All CRUD methods use **optimistic UI updates**: they modify local
  /// storage first, immediately rebuild the state, then trigger
  /// background sync to push changes to the server.
  QuotesNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'quotesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$quotesNotifierHash();

  @$internal
  @override
  QuotesNotifier create() => QuotesNotifier();
}

String _$quotesNotifierHash() => r'60864ce5e5c3525d763845a4d573d8f4cff40473';

/// Async notifier managing the Quotes list state with offline-first
/// auto-synchronization.
///
/// The [build] method initializes by triggering a background sync,
/// then returns the local SQLite data as the single source of truth.
///
/// All CRUD methods use **optimistic UI updates**: they modify local
/// storage first, immediately rebuild the state, then trigger
/// background sync to push changes to the server.

abstract class _$QuotesNotifier extends $AsyncNotifier<List<QuoteEntity>> {
  FutureOr<List<QuoteEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<QuoteEntity>>, List<QuoteEntity>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<QuoteEntity>>, List<QuoteEntity>>,
        AsyncValue<List<QuoteEntity>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
