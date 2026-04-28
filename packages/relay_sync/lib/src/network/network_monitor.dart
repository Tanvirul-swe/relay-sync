/// Abstraction for observing connection reliability in relay_sync.
///
/// Implementations should report `true` only when network conditions are
/// reliable enough for request execution.
abstract interface class NetworkMonitor {
  /// Emits connectivity reliability changes.
  Stream<bool> get onStatusChanged;

  /// Returns the latest known network reliability state.
  Future<bool> get hasReliableConnection;

  /// Releases monitor resources.
  Future<void> dispose();
}
