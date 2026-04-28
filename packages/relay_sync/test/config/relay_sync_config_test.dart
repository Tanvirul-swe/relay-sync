import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _TestLogger implements RelaySyncLogger {
  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {}
}

class _TestMetrics implements RelaySyncMetrics {
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

void main() {
  group('RelaySyncConfig', () {
    test('uses production defaults', () {
      final config = RelaySyncConfig();

      expect(config.autoSync, isTrue);
      expect(config.maxRetries, 5);
      expect(config.maxConcurrentTasks, 1);
      expect(config.deleteSyncedTasks, isFalse);
      expect(config.syncOnNetworkRestore, isTrue);
      expect(config.enableDeduplication, isTrue);
      expect(config.deduplicationStrategy, DeduplicationStrategy.keepLatest);
      expect(config.enableDependencyOrdering, isTrue);
    });

    test('is immutable and copyWith updates fields', () {
      final logger = _TestLogger();
      final metrics = _TestMetrics();
      final config = RelaySyncConfig(
        defaultHeaders: const <String, String>{'x-app': 'relay'},
      );

      final updated = config.copyWith(
        autoSync: false,
        maxRetries: 10,
        maxConcurrentTasks: 3,
        deleteSyncedTasks: true,
        syncOnStart: false,
        userId: 'u1',
        tenantId: 't1',
        requestTimeout: const Duration(seconds: 10),
        continueOnTaskFailure: false,
        deduplicationStrategy: DeduplicationStrategy.keepFirst,
        logger: logger,
        metrics: metrics,
      );

      expect(updated.autoSync, isFalse);
      expect(updated.maxRetries, 10);
      expect(updated.maxConcurrentTasks, 3);
      expect(updated.deleteSyncedTasks, isTrue);
      expect(updated.syncOnStart, isFalse);
      expect(updated.userId, 'u1');
      expect(updated.tenantId, 't1');
      expect(updated.requestTimeout, const Duration(seconds: 10));
      expect(updated.continueOnTaskFailure, isFalse);
      expect(updated.deduplicationStrategy, DeduplicationStrategy.keepFirst);
      expect(updated.logger, same(logger));
      expect(updated.metrics, same(metrics));

      expect(() => config.defaultHeaders['new'] = 'value', throwsUnsupportedError);
    });

    test('supports equality and hashCode', () {
      final a = RelaySyncConfig();
      final b = RelaySyncConfig();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('validates numeric constraints', () {
      expect(
        () => RelaySyncConfig(maxRetries: -1),
        throwsA(isA<RelaySyncException>()),
      );
      expect(
        () => RelaySyncConfig(maxConcurrentTasks: 0),
        throwsA(isA<RelaySyncException>()),
      );
      expect(
        () => RelaySyncConfig(requestTimeout: Duration.zero),
        throwsA(isA<RelaySyncException>()),
      );
    });
  });
}
