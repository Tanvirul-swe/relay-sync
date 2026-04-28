import 'dart:collection';

import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _CapturingLogger implements RelaySyncLogger {
  final List<String> events = <String>[];
  final List<Map<String, Object?>> contexts = <Map<String, Object?>>[];

  @override
  void log(
    RelaySyncLogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    events.add(message);
    contexts.add(context);
  }
}

class _CapturingMetrics implements RelaySyncMetrics {
  final List<String> increments = <String>[];

  @override
  void increment(
    String name, {
    int value = 1,
    Map<String, String> tags = const <String, String>{},
  }) {
    increments.add(name);
  }

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, String> tags = const <String, String>{},
  }) {}
}

class _QueueClient implements SyncClient {
  _QueueClient(this._statusCodes);

  final Queue<int> _statusCodes;

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    return SyncResponse(statusCode: _statusCodes.removeFirst());
  }
}

void main() {
  group('logging redaction', () {
    test('redacts sensitive auth-like headers', () {
      final redacted = LogRedaction.redactHeaders(const <String, String>{
        'Authorization': 'Bearer secret',
        'x-api-key': 'super-secret',
        'X-Trace-Id': 'abc',
      });

      expect(redacted['Authorization'], '<redacted>');
      expect(redacted['x-api-key'], '<redacted>');
      expect(redacted['X-Trace-Id'], 'abc');
    });
  });

  group('logging/metrics events', () {
    test('controller enqueue and successful sync emit events', () async {
      final logger = _CapturingLogger();
      final metrics = _CapturingMetrics();

      final engine = RelaySyncEngine(
        storage: InMemorySyncStorage(),
        client: _QueueClient(Queue<int>.from(<int>[200])),
        networkMonitor: ManualNetworkMonitor(initiallyOnline: true),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          logger: logger,
          metrics: metrics,
        ),
      );
      final controller = RelaySyncController(
        engine: engine,
        taskIdGenerator: () => 'task-1',
      );

      await controller.initialize();
      await controller.post(
        '/v1/items',
        headers: const <String, String>{'Authorization': 'Bearer secret'},
      );
      await controller.syncNow();
      await controller.pause();
      await controller.resume();
      await controller.dispose();

      expect(logger.events, contains('taskEnqueued'));
      expect(logger.events, contains('syncStarted'));
      expect(logger.events, contains('taskSyncStarted'));
      expect(logger.events, contains('taskSynced'));
      expect(logger.events, contains('syncCompleted'));
      expect(logger.events, contains('syncPaused'));
      expect(logger.events, contains('syncResumed'));

      expect(metrics.increments, contains('taskEnqueued'));
      expect(metrics.increments, contains('syncStarted'));
      expect(metrics.increments, contains('taskSyncStarted'));
      expect(metrics.increments, contains('taskSynced'));
      expect(metrics.increments, contains('syncCompleted'));

      final enqueueContext = logger.contexts.firstWhere((c) => c['taskId'] == 'task-1');
      expect((enqueueContext['headers'] as Map<String, String>)['Authorization'], '<redacted>');
    });

    test('retry, permanent failure, and conflict emit specific events', () async {
      final logger = _CapturingLogger();
      final metrics = _CapturingMetrics();

      final storage = InMemorySyncStorage();
      final engine = RelaySyncEngine(
        storage: storage,
        client: _QueueClient(Queue<int>.from(<int>[503, 400, 409])),
        networkMonitor: ManualNetworkMonitor(initiallyOnline: true),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          logger: logger,
          metrics: metrics,
          retryPolicy: FixedRetryPolicy(delay: const Duration(seconds: 1)),
        ),
      );
      final controller = RelaySyncController(engine: engine);
      await controller.initialize();

      final now = DateTime.parse('2026-04-28T00:00:00Z');
      await storage.upsertTask(
        SyncTask(
          id: 'r',
          method: SyncMethod.post,
          endpoint: '/r',
          metadata: const SyncMetadata(taskId: 'r', method: SyncMethod.post),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await controller.syncNow();

      await storage.upsertTask(
        SyncTask(
          id: 'p',
          method: SyncMethod.post,
          endpoint: '/p',
          metadata: const SyncMetadata(taskId: 'p', method: SyncMethod.post),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await controller.syncNow();

      await storage.upsertTask(
        SyncTask(
          id: 'c',
          method: SyncMethod.post,
          endpoint: '/c',
          metadata: const SyncMetadata(taskId: 'c', method: SyncMethod.post),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await controller.syncNow();
      await controller.dispose();

      expect(logger.events, contains('taskRetryScheduled'));
      expect(logger.events, contains('taskFailedPermanent'));
      expect(logger.events, contains('taskConflict'));

      expect(metrics.increments, contains('taskRetryScheduled'));
      expect(metrics.increments, contains('taskFailedPermanent'));
      expect(metrics.increments, contains('taskConflict'));
    });
  });
}
