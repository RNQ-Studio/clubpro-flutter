import 'package:core/core.dart';

import '../../domain/repositories/active_community_store.dart';

/// Disimpan di SharedPreferences (localStorage di web): bukan data sensitif.
class PrefsActiveCommunityStore implements ActiveCommunityStore {
  PrefsActiveCommunityStore();

  final _storage = SharedPreferencesStorage();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _storage.init();

  static String _key(String userId) => 'active_community.$userId';

  @override
  Future<String?> read(String userId) async {
    await _init();
    return _storage.read(_key(userId));
  }

  @override
  Future<void> write(String userId, String communityId) async {
    await _init();
    await _storage.write(_key(userId), communityId);
  }
}
