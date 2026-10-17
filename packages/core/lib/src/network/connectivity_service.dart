import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Service to monitor network connectivity status.
///
/// Exposes a stream of booleans representing whether the device is online
/// (`true`) or offline (`false`).
@riverpod
class ConnectivityService extends _$ConnectivityService {
  late final Connectivity _connectivity;

  @override
  Stream<bool> build() {
    _connectivity = Connectivity();

    // Listen to changes and map them to a simple boolean (online/offline)
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasActiveConnection(results);
    });
  }

  /// Check synchronously if the device has an active connection.
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  }
}
