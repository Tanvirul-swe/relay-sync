/// Metrics contract that can be wired into the engine.
abstract interface class RelaySyncMetrics {
  /// Increments a counter metric.
  void increment(
    String name, {
    int value = 1,
    Map<String, String> tags = const <String, String>{},
  });

  /// Records a duration metric.
  void timing(
    String name,
    Duration duration, {
    Map<String, String> tags = const <String, String>{},
  });
}

/// Metrics implementation that ignores all events.
class NoopRelaySyncMetrics implements RelaySyncMetrics {
  /// Creates a no-op metrics sink.
  const NoopRelaySyncMetrics();

  @override
  void increment(
    String name, {
    int value = 1,
    Map<String, String> tags = const <String, String>{},
  }) {}

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, String> tags = const <String, String>{},
  }) {}
}
