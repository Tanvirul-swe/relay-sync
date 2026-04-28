import 'network_monitor.dart';

/// Network monitor implementation that is always online.
///
/// Useful for demos or environments where network health checks are not needed.
class AlwaysOnlineNetworkMonitor implements NetworkMonitor {
  /// Creates an always-online monitor.
  const AlwaysOnlineNetworkMonitor();

  @override
  Stream<bool> get onStatusChanged => const Stream<bool>.empty();

  @override
  Future<bool> get hasReliableConnection async => true;

  @override
  Future<void> dispose() async {}
}
