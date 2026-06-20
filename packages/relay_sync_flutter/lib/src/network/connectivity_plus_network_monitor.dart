import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:relay_sync/relay_sync.dart';

/// Reads connectivity status from `connectivity_plus`.
class ConnectivityPlusNetworkMonitor implements NetworkMonitor {
  /// Creates a monitor backed by [Connectivity].
  ConnectivityPlusNetworkMonitor({
    Connectivity? connectivity,
  }) : this.custom(
          checkConnectivity: (connectivity ?? Connectivity()).checkConnectivity,
          onConnectivityChanged:
              (connectivity ?? Connectivity()).onConnectivityChanged,
        );

  /// Creates a monitor with injected connectivity sources.
  ///
  /// This constructor is primarily useful for tests.
  ConnectivityPlusNetworkMonitor.custom({
    required Future<List<ConnectivityResult>> Function() checkConnectivity,
    required Stream<List<ConnectivityResult>> onConnectivityChanged,
  })  : _checkConnectivity = checkConnectivity,
        _onConnectivityChanged = onConnectivityChanged;

  final Future<List<ConnectivityResult>> Function() _checkConnectivity;
  final Stream<List<ConnectivityResult>> _onConnectivityChanged;

  bool _disposed = false;

  @override
  Stream<bool> get onStatusChanged {
    _ensureNotDisposed();
    return _onConnectivityChanged.map(_hasNetworkType).distinct();
  }

  @override
  Future<bool> get hasReliableConnection async {
    _ensureNotDisposed();
    try {
      return _hasNetworkType(await _checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const RelaySyncException(
        message: 'ConnectivityPlusNetworkMonitor has been disposed.',
      );
    }
  }

  static bool _hasNetworkType(List<ConnectivityResult> results) {
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
