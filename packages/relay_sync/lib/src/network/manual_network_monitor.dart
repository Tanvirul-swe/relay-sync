import 'dart:async';

import '../models/relay_sync_exception.dart';
import 'network_monitor.dart';

/// Test-friendly [NetworkMonitor] that can be toggled manually.
class ManualNetworkMonitor implements NetworkMonitor {
  /// Creates a monitor with an [initiallyOnline] state.
  ManualNetworkMonitor({bool initiallyOnline = true}) : _isOnline = initiallyOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isOnline;
  bool _disposed = false;

  @override
  Stream<bool> get onStatusChanged {
    _ensureNotDisposed();
    return _controller.stream;
  }

  @override
  Future<bool> get hasReliableConnection async {
    _ensureNotDisposed();
    return _isOnline;
  }

  /// Sets the current network status and notifies listeners when changed.
  Future<void> setOnlineStatus(bool isOnline) async {
    _ensureNotDisposed();
    if (_isOnline == isOnline) {
      return;
    }
    _isOnline = isOnline;
    _controller.add(_isOnline);
  }

  /// Marks network status as online.
  Future<void> setOnline() => setOnlineStatus(true);

  /// Marks network status as offline.
  Future<void> setOffline() => setOnlineStatus(false);

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _controller.close();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const RelaySyncException(message: 'ManualNetworkMonitor has been disposed.');
    }
  }
}
