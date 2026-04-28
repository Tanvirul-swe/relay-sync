import 'dart:math';

import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _FixedRandom implements Random {
  _FixedRandom(this._value);

  final double _value;

  @override
  bool nextBool() => _value >= 0.5;

  @override
  double nextDouble() => _value;

  @override
  int nextInt(int max) => (_value * max).floor();
}

void main() {
  group('NoRetryPolicy', () {
    test('never retries and returns null retry time', () {
      const policy = NoRetryPolicy();
      final now = DateTime.parse('2026-04-28T00:00:00Z');

      expect(policy.shouldRetry(retryCount: 0, maxRetries: 5), isFalse);
      expect(policy.nextRetryAt(now: now, retryCount: 0, maxRetries: 5), isNull);
    });
  });

  group('FixedRetryPolicy', () {
    test('returns fixed delay retry time while under max retries', () {
      final policy = FixedRetryPolicy(delay: const Duration(seconds: 10));
      final now = DateTime.parse('2026-04-28T00:00:00Z');

      expect(policy.shouldRetry(retryCount: 1, maxRetries: 3), isTrue);
      expect(
        policy.nextRetryAt(now: now, retryCount: 1, maxRetries: 3),
        DateTime.parse('2026-04-28T00:00:10Z'),
      );
    });

    test('returns null when retry limit reached', () {
      final policy = FixedRetryPolicy(delay: const Duration(seconds: 5));
      final now = DateTime.parse('2026-04-28T00:00:00Z');

      expect(policy.shouldRetry(retryCount: 3, maxRetries: 3), isFalse);
      expect(policy.nextRetryAt(now: now, retryCount: 3, maxRetries: 3), isNull);
    });
  });

  group('ExponentialBackoffRetryPolicy', () {
    test('calculates exponential retry times based on retryCount', () {
      final policy = ExponentialBackoffRetryPolicy(
        initialDelay: const Duration(seconds: 2),
        maxDelay: const Duration(minutes: 5),
        multiplier: 2,
      );
      final now = DateTime.parse('2026-04-28T00:00:00Z');

      expect(
        policy.nextRetryAt(now: now, retryCount: 0, maxRetries: 5),
        DateTime.parse('2026-04-28T00:00:02Z'),
      );
      expect(
        policy.nextRetryAt(now: now, retryCount: 1, maxRetries: 5),
        DateTime.parse('2026-04-28T00:00:04Z'),
      );
      expect(
        policy.nextRetryAt(now: now, retryCount: 2, maxRetries: 5),
        DateTime.parse('2026-04-28T00:00:08Z'),
      );
    });

    test('applies max delay cap', () {
      final policy = ExponentialBackoffRetryPolicy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 25),
        multiplier: 2,
      );
      final now = DateTime.parse('2026-04-28T00:00:00Z');

      expect(
        policy.nextRetryAt(now: now, retryCount: 3, maxRetries: 5),
        DateTime.parse('2026-04-28T00:00:25Z'),
      );
    });

    test('keeps jitter within expected range', () {
      final now = DateTime.parse('2026-04-28T00:00:00Z');
      final baseMicros = const Duration(seconds: 10).inMicroseconds;

      final minPolicy = ExponentialBackoffRetryPolicy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 20),
        multiplier: 1,
        jitter: 0.2,
        random: _FixedRandom(0),
      );
      final maxPolicy = ExponentialBackoffRetryPolicy(
        initialDelay: const Duration(seconds: 10),
        maxDelay: const Duration(seconds: 20),
        multiplier: 1,
        jitter: 0.2,
        random: _FixedRandom(1),
      );

      final minTime = minPolicy.nextRetryAt(now: now, retryCount: 0, maxRetries: 5)!;
      final maxTime = maxPolicy.nextRetryAt(now: now, retryCount: 0, maxRetries: 5)!;

      final minDelta = minTime.difference(now).inMicroseconds;
      final maxDelta = maxTime.difference(now).inMicroseconds;

      expect(minDelta, greaterThanOrEqualTo((baseMicros * 0.8).round()));
      expect(minDelta, lessThanOrEqualTo((baseMicros * 1.2).round()));
      expect(maxDelta, greaterThanOrEqualTo((baseMicros * 0.8).round()));
      expect(maxDelta, lessThanOrEqualTo((baseMicros * 1.2).round()));
    });
  });
}
