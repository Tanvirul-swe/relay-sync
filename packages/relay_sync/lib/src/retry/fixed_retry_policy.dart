import '../models/relay_sync_exception.dart';
import 'retry_policy.dart';

/// Retry policy with a fixed delay between attempts.
class FixedRetryPolicy extends RetryPolicy {
  /// Creates a fixed retry policy.
  FixedRetryPolicy({required this.delay}) {
    if (delay.inMicroseconds <= 0) {
      throw const RelaySyncException(message: 'delay must be greater than zero.');
    }
  }

  /// Fixed retry delay.
  final Duration delay;

  @override
  bool shouldRetry({required int retryCount, required int maxRetries}) {
    validate(retryCount: retryCount, maxRetries: maxRetries);
    return retryCount < maxRetries;
  }

  @override
  DateTime? nextRetryAt({
    required DateTime now,
    required int retryCount,
    required int maxRetries,
  }) {
    if (!shouldRetry(retryCount: retryCount, maxRetries: maxRetries)) {
      return null;
    }
    return now.add(delay);
  }
}
