import '../models/relay_sync_exception.dart';

/// Strategy interface used to compute retry schedules for failed tasks.
abstract class RetryPolicy {
  /// Creates a retry policy.
  const RetryPolicy();

  /// Returns `true` when another retry can be attempted.
  bool shouldRetry({
    required int retryCount,
    required int maxRetries,
  });

  /// Computes the next retry timestamp based on [retryCount].
  ///
  /// Returns `null` when no retry should be scheduled.
  DateTime? nextRetryAt({
    required DateTime now,
    required int retryCount,
    required int maxRetries,
  });

  /// Guards common retry input validation.
  void validate({
    required int retryCount,
    required int maxRetries,
  }) {
    if (retryCount < 0) {
      throw const RelaySyncException(message: 'retryCount cannot be negative.');
    }
    if (maxRetries < 0) {
      throw const RelaySyncException(message: 'maxRetries cannot be negative.');
    }
  }
}
