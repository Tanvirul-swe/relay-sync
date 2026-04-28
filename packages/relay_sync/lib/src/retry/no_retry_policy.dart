import 'retry_policy.dart';

/// Retry policy that never schedules retries.
class NoRetryPolicy extends RetryPolicy {
  /// Creates a no-retry policy.
  const NoRetryPolicy();

  @override
  bool shouldRetry({required int retryCount, required int maxRetries}) {
    validate(retryCount: retryCount, maxRetries: maxRetries);
    return false;
  }

  @override
  DateTime? nextRetryAt({
    required DateTime now,
    required int retryCount,
    required int maxRetries,
  }) {
    validate(retryCount: retryCount, maxRetries: maxRetries);
    return null;
  }
}
