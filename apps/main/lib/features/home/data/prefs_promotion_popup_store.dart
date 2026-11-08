import 'package:core/core.dart';

import '../domain/repositories/promotion_popup_store.dart';

/// Disimpan di SharedPreferences (localStorage di web): bukan data sensitif.
class PrefsPromotionPopupStore implements PromotionPopupStore {
  PrefsPromotionPopupStore();

  final _storage = SharedPreferencesStorage();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _storage.init();

  static String _key(String userId) => 'promotion_popup_shown.$userId';

  @override
  Future<DateTime?> lastShown(String userId) async {
    await _init();
    final value = await _storage.read(_key(userId));
    return value == null ? null : DateTime.tryParse(value);
  }

  @override
  Future<void> markShown(String userId, DateTime at) async {
    await _init();
    await _storage.write(_key(userId), at.toUtc().toIso8601String());
  }
}
