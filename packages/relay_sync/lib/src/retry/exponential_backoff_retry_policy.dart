import 'dart:math';

import '../models/relay_sync_exception.dart';
import 'retry_policy.dart';

/// Retry policy using exponential backoff with optional jitter.
class ExponentialBackoffRetryPolicy extends RetryPolicy {
  /// Creates an exponential backoff retry policy.
  ExponentialBackoffRetryPolicy({
    required this.initialDelay,
    required this.maxDelay,
    this.multiplier = 2.0,
    this.jitter = 0,
    Random? random,
  }) : _random = random ?? Random() {
    if (initialDelay.inMicroseconds <= 0) {
      throw const RelaySyncException(message: 'initialDelay must be greater than zero.');
    }
    if (maxDelay.inMicroseconds <= 0) {
      throw const RelaySyncException(message: 'maxDelay must be greater than zero.');
    }
    if (maxDelay < initialDelay) {
      throw const RelaySyncException(message: 'maxDelay cannot be less than initialDelay.');
    }
    if (multiplier < 1.0) {
      throw const RelaySyncException(message: 'multiplier must be at least 1.0.');
    }
    if (jitter < 0 || jitter > 1) {
      throw const RelaySyncException(message: 'jitter must be between 0 and 1.');
    }
  }

  /// Base delay for the first retry.
  final Duration initialDelay;

  /// Upper bound for computed delays.
  final Duration maxDelay;

  /// Exponential multiplier applied per retry count step.
  final double multiplier;

  /// Randomization percentage in range `0..1`.
  final double jitter;

  final Random _random;

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

    final exponential = initialDelay.inMicroseconds * pow(multiplier, retryCount).toDouble();
    final cappedMicros = min<double>(exponential, maxDelay.inMicroseconds.toDouble());
    final adjustedMicros = _applyJitter(cappedMicros);
    return now.add(Duration(microseconds: adjustedMicros.round()));
  }

  double _applyJitter(double value) {
    if (jitter == 0) {
      return value;
    }
    final randomFactor = (_random.nextDouble() * 2) - 1;
    final jitterDelta = value * jitter * randomFactor;
    return value + jitterDelta;
  }
}
