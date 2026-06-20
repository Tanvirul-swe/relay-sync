import 'dart:async';
import 'dart:collection';

import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _ClientCall {
  const _ClientCall({required this.taskId, required this.headers});

  final String taskId;
  final Map<String, String> headers;
}

class _FakeSyncClient implements SyncClient {
  _FakeSyncClient({
    this.delay = Duration.zero,
    Queue<Future<SyncResponse> Function(SyncTask task)>? handlers,
  }) : _handlers = handlers ?? Queue<Future<SyncResponse> Function(SyncTask task)>();

  final Duration delay;
  final Queue<Future<SyncResponse> Function(SyncTask task)> _handlers;
  final List<_ClientCall> calls = <_ClientCall>[];

  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    calls.add(_ClientCall(taskId: task.id, headers: Map<String, String>.from(headers)));
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (_handlers.isEmpty) {
      return const SyncResponse(statusCode: 200);
    }
    return _handlers.removeFirst()(task);
  }
}

class _FakeStorage implements SyncStorageAdapter {
  final Map<String, SyncTask> _tasks = <String, SyncTask>{};
  bool initialized = false;
  bool closed = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> saveTask(SyncTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> updateTask(SyncTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<void> upsertTask(SyncTask task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<SyncTask?> getTaskById(String id) async => _tasks[id];

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    final tasks = _tasks.values
        .where((task) =>
            task.status == SyncTaskStatus.pending && _matchesScope(task, userId, tenantId))
        .toList(growable: false);
    return _sortAndLimit(tasks, limit);
  }

  @override
  Future<List<SyncTask>> getRetryableTasks({
    String? userId,
    String? tenantId,
    DateTime? now,
    int? limit,
  }) async {
    final effectiveNow = now ?? DateTime.now().toUtc();
    final tasks = _tasks.values
        .where((task) {
          final retryable = task.status == SyncTaskStatus.retryScheduled ||
              task.status == SyncTaskStatus.failedRetryable;
          final due = task.nextRetryAt == null || !task.nextRetryAt!.isAfter(effectiveNow);
          return retryable && due && _matchesScope(task, userId, tenantId);
        })
        .toList(growable: false);
    return _sortAndLimit(tasks, limit);
  }

  @override
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async =>
      <SyncTask>[];

  @override
  Future<List<SyncTask>> getTasksByStatus(
    SyncTaskStatus status, {
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    final tasks = _tasks.values
        .where((task) => task.status == status && _matchesScope(task, userId, tenantId))
        .toList(growable: false);
    return _sortAndLimit(tasks, limit);
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
  }

  @override
  Future<void> clearSynced({String? userId, String? tenantId}) async {
    _tasks.removeWhere((_, task) {
      return task.status == SyncTaskStatus.synced && _matchesScope(task, userId, tenantId);
    });
  }

  @override
  Future<void> clearAll({String? userId, String? tenantId}) async {
    if (userId == null && tenantId == null) {
      _tasks.clear();
      return;
    }
    _tasks.removeWhere((_, task) => _matchesScope(task, userId, tenantId));
  }

  @override
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  }) async =>
      <SyncTaskStatus, int>{};

  @override
  Stream<List<SyncTask>> watchTasks({String? userId, String? tenantId}) =>
      const Stream<List<SyncTask>>.empty();

  @override
  Stream<Map<SyncTaskStatus, int>> watchCountByStatus({
    String? userId,
    String? tenantId,
  }) =>
      const Stream<Map<SyncTaskStatus, int>>.empty();

  @override
  Future<void> close() async {
    closed = true;
  }

  bool _matchesScope(SyncTask task, String? userId, String? tenantId) {
    final userMatches = userId == null || task.userId == userId;
    final tenantMatches = tenantId == null || task.tenantId == tenantId;
    return userMatches && tenantMatches;
  }

  List<SyncTask> _sortAndLimit(List<SyncTask> tasks, int? limit) {
    tasks.sort((a, b) {
      final priorityDiff = b.priority.index.compareTo(a.priority.index);
      if (priorityDiff != 0) {
        return priorityDiff;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    if (limit == null || limit >= tasks.length) {
      return tasks;
    }
    return tasks.take(limit).toList(growable: false);
  }
}

class _DeterministicRetryPolicy implements RetryPolicy {
  @override
  DateTime? nextRetryAt({
    required DateTime now,
    required int retryCount,
    required int maxRetries,
  }) {
    if (retryCount > maxRetries) {
      return null;
    }
    return now.add(const Duration(minutes: 1));
  }

  @override
  bool shouldRetry({required int retryCount, required int maxRetries}) {
    return retryCount <= maxRetries;
  }

  @override
  void validate({required int retryCount, required int maxRetries}) {}
}

SyncTask _task(
  String id, {
  SyncTaskStatus status = SyncTaskStatus.pending,
  SyncPriority priority = SyncPriority.normal,
  DateTime? createdAt,
  DateTime? nextRetryAt,
  String? userId,
  String? tenantId,
  Map<String, String> headers = const <String, String>{},
}) {
  final created = createdAt ?? DateTime.parse('2026-04-28T00:00:00Z');
  return SyncTask(
    id: id,
    userId: userId,
    tenantId: tenantId,
    method: SyncMethod.post,
    endpoint: '/v1/items',
    headers: headers,
    metadata: SyncMetadata(taskId: id, method: SyncMethod.post),
    status: status,
    priority: priority,
    createdAt: created,
    updatedAt: created,
    nextRetryAt: nextRetryAt,
  );
}

void main() {
  group('RelaySyncEngine', () {
    test('initialize initializes storage and syncs on start when online', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final client = _FakeSyncClient();
      final network = ManualNetworkMonitor(initiallyOnline: true);

      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: network,
        config: RelaySyncConfig(syncOnStart: true),
      );

      await engine.initialize();

      expect(storage.initialized, isTrue);
      expect(client.calls.length, 1);

      await engine.dispose();
    });

    test('enqueue saves task', () async {
      final storage = _FakeStorage();
      final client = _FakeSyncClient();
      final network = ManualNetworkMonitor();

      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: network,
        config: RelaySyncConfig(autoSync: false),
      );
      await engine.initialize();

      await engine.enqueue(_task('t1'));

      expect(await storage.getTaskById('t1'), isNotNull);

      await engine.dispose();
    });

    test('pause and resume control sync execution', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final client = _FakeSyncClient();
      final network = ManualNetworkMonitor();

      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: network,
        config: RelaySyncConfig(syncOnStart: false),
      );
      await engine.initialize();

      await engine.pause();
      await engine.syncNow();
      expect(client.calls, isEmpty);

      await engine.resume();
      await engine.syncNow();
      expect(client.calls.length, 1);

      await engine.dispose();
    });

    test('dispose closes dependencies and emits disposed state', () async {
      final storage = _FakeStorage();
      final client = _FakeSyncClient();
      final network = ManualNetworkMonitor();

      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: network,
        config: RelaySyncConfig(syncOnStart: false),
      );
      final states = <RelaySyncState>[];
      final sub = engine.states.listen(states.add);

      await engine.initialize();
      await engine.dispose();

      expect(storage.closed, isTrue);
      expect(states.contains(RelaySyncState.disposed), isTrue);

      await sub.cancel();
    });

    test('prevents duplicate concurrent sync runs', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final client = _FakeSyncClient(delay: const Duration(milliseconds: 50));
      final network = ManualNetworkMonitor();

      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: network,
        config: RelaySyncConfig(syncOnStart: false),
      );
      await engine.initialize();

      await Future.wait(<Future<void>>[engine.syncNow(), engine.syncNow()]);

      expect(client.calls.length, 1);

      await engine.dispose();
    });

    test('success marks task synced', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(syncOnStart: false, autoSync: false),
      );
      await engine.initialize();

      await engine.syncNow();

      final updated = await storage.getTaskById('t1');
      expect(updated?.status, SyncTaskStatus.synced);
      expect(updated?.lastAttemptAt, isNotNull);
      expect(updated?.lastError, isNull);

      await engine.dispose();
    });

    test('success deletes task when deleteSyncedTasks enabled', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          syncOnStart: false,
          autoSync: false,
          deleteSyncedTasks: true,
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      expect(await storage.getTaskById('t1'), isNull);

      await engine.dispose();
    });

    test('retryable failure schedules retry and increments retryCount', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final handlers = Queue<Future<SyncResponse> Function(SyncTask task)>()
        ..add((_) async => const SyncResponse(statusCode: 503));
      final client = _FakeSyncClient(handlers: handlers);
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          syncOnStart: false,
          autoSync: false,
          retryPolicy: _DeterministicRetryPolicy(),
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      final updated = await storage.getTaskById('t1');
      expect(updated?.status, SyncTaskStatus.retryScheduled);
      expect(updated?.retryCount, 1);
      expect(updated?.nextRetryAt, isNotNull);

      await engine.dispose();
    });

    test('permanent failure sets failedPermanent', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final handlers = Queue<Future<SyncResponse> Function(SyncTask task)>()
        ..add((_) async => const SyncResponse(statusCode: 400));
      final client = _FakeSyncClient(handlers: handlers);
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(syncOnStart: false, autoSync: false),
      );
      await engine.initialize();

      await engine.syncNow();

      final updated = await storage.getTaskById('t1');
      expect(updated?.status, SyncTaskStatus.failedPermanent);

      await engine.dispose();
    });

    test('conflict response sets conflict status', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final handlers = Queue<Future<SyncResponse> Function(SyncTask task)>()
        ..add((_) async => const SyncResponse(statusCode: 409));
      final client = _FakeSyncClient(handlers: handlers);
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(syncOnStart: false, autoSync: false),
      );
      await engine.initialize();

      await engine.syncNow();

      final updated = await storage.getTaskById('t1');
      expect(updated?.status, SyncTaskStatus.conflict);

      await engine.dispose();
    });

    test('unauthorized refresh retries once and succeeds', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final handlers = Queue<Future<SyncResponse> Function(SyncTask task)>()
        ..add((_) async => const SyncResponse(statusCode: 401))
        ..add((_) async => const SyncResponse(statusCode: 200));
      final client = _FakeSyncClient(handlers: handlers);
      var refreshCalls = 0;
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(syncOnStart: false, autoSync: false),
        tokenRefreshHandler: () async {
          refreshCalls++;
          return true;
        },
      );
      await engine.initialize();

      await engine.syncNow();

      final updated = await storage.getTaskById('t1');
      expect(refreshCalls, 1);
      expect(client.calls.length, 2);
      expect(updated?.status, SyncTaskStatus.synced);

      await engine.dispose();
    });

    test('task fetch respects scope, sorting, max concurrency, and header merge', () async {
      final storage = _FakeStorage();
      await storage.saveTask(
        _task(
          'scoped-high',
          userId: 'u1',
          tenantId: 't1',
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:00:02Z'),
          headers: const <String, String>{'x-task': 'high', 'x-shared': 'task'},
        ),
      );
      await storage.saveTask(
        _task(
          'scoped-retry',
          userId: 'u1',
          tenantId: 't1',
          status: SyncTaskStatus.retryScheduled,
          nextRetryAt: DateTime.parse('2026-04-27T23:59:00Z'),
          priority: SyncPriority.high,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
          headers: const <String, String>{'x-task': 'retry'},
        ),
      );
      await storage.saveTask(
        _task(
          'other-scope',
          userId: 'u2',
          tenantId: 't1',
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:00:01Z'),
        ),
      );

      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        authHeaderProvider: () async => const <String, String>{
          'authorization': 'Bearer token',
          'x-shared': 'auth',
        },
        config: RelaySyncConfig(
          syncOnStart: false,
          autoSync: false,
          maxConcurrentTasks: 2,
          userId: 'u1',
          tenantId: 't1',
          defaultHeaders: const <String, String>{'x-shared': 'config', 'x-default': '1'},
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      expect(client.calls.map((call) => call.taskId), <String>['scoped-high', 'scoped-retry']);
      expect(client.calls.first.headers['x-default'], '1');
      expect(client.calls.first.headers['x-task'], 'high');
      expect(client.calls.first.headers['authorization'], 'Bearer token');
      expect(client.calls.first.headers['x-shared'], 'auth');
      expect(await storage.getTaskById('other-scope'), isNotNull);
      expect((await storage.getTaskById('other-scope'))?.status, SyncTaskStatus.pending);

      await engine.dispose();
    });



    test('deduplication keepFirst skips new pending duplicate', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('first', headers: const <String, String>{'x': '1'}).copyWith(dedupeKey: 'same'));

      final engine = RelaySyncEngine(
        storage: storage,
        client: _FakeSyncClient(),
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          deduplicationStrategy: DeduplicationStrategy.keepFirst,
        ),
      );
      await engine.initialize();

      await engine.enqueue(_task('second').copyWith(dedupeKey: 'same'));

      expect(await storage.getTaskById('first'), isNotNull);
      expect(await storage.getTaskById('second'), isNull);

      await engine.dispose();
    });

    test('deduplication keepLatest replaces previous pending duplicate', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('first').copyWith(dedupeKey: 'same'));

      final engine = RelaySyncEngine(
        storage: storage,
        client: _FakeSyncClient(),
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          deduplicationStrategy: DeduplicationStrategy.keepLatest,
        ),
      );
      await engine.initialize();

      await engine.enqueue(_task('second').copyWith(dedupeKey: 'same'));

      expect(await storage.getTaskById('first'), isNull);
      expect(await storage.getTaskById('second'), isNotNull);

      await engine.dispose();
    });

    test('deduplication allowDuplicates keeps both pending tasks', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('first').copyWith(dedupeKey: 'same'));

      final engine = RelaySyncEngine(
        storage: storage,
        client: _FakeSyncClient(),
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          deduplicationStrategy: DeduplicationStrategy.allowDuplicates,
        ),
      );
      await engine.initialize();

      await engine.enqueue(_task('second').copyWith(dedupeKey: 'same'));

      expect(await storage.getTaskById('first'), isNotNull);
      expect(await storage.getTaskById('second'), isNotNull);

      await engine.dispose();
    });

    test('dependency ordering blocks dependent task until dependency is synced', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('dep'));
      await storage.saveTask(_task('child').copyWith(dependsOnTaskIds: const <String>['dep']));

      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          maxConcurrentTasks: 2,
          enableDependencyOrdering: true,
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      expect(client.calls.length, 1);
      expect(client.calls.single.taskId, 'dep');
      expect((await storage.getTaskById('dep'))?.status, SyncTaskStatus.synced);
      expect((await storage.getTaskById('child'))?.status, SyncTaskStatus.pending);

      await engine.dispose();
    });

    test('dependency permanent failure marks dependent as failedPermanent', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('dep', status: SyncTaskStatus.failedPermanent));
      await storage.saveTask(_task('child').copyWith(dependsOnTaskIds: const <String>['dep']));

      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          enableDependencyOrdering: true,
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      expect(client.calls, isEmpty);
      final updated = await storage.getTaskById('child');
      expect(updated?.status, SyncTaskStatus.failedPermanent);
      expect(updated?.lastError?.code, 'dependency_failed');

      await engine.dispose();
    });

    test('dependency cancelled marks dependent as failedPermanent', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('dep', status: SyncTaskStatus.cancelled));
      await storage.saveTask(_task('child').copyWith(dependsOnTaskIds: const <String>['dep']));

      final client = _FakeSyncClient();
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          enableDependencyOrdering: true,
        ),
      );
      await engine.initialize();

      await engine.syncNow();

      expect(client.calls, isEmpty);
      final updated = await storage.getTaskById('child');
      expect(updated?.status, SyncTaskStatus.failedPermanent);
      expect(updated?.lastError?.code, 'dependency_failed');

      await engine.dispose();
    });

    test('task state transitions include syncing before final state', () async {
      final storage = _FakeStorage();
      await storage.saveTask(_task('t1'));
      final handlers = Queue<Future<SyncResponse> Function(SyncTask task)>()
        ..add((_) async {
          final syncingTask = await storage.getTaskById('t1');
          expect(syncingTask?.status, SyncTaskStatus.syncing);
          return const SyncResponse(statusCode: 200);
        });
      final client = _FakeSyncClient(handlers: handlers);
      final engine = RelaySyncEngine(
        storage: storage,
        client: client,
        networkMonitor: ManualNetworkMonitor(),
        config: RelaySyncConfig(syncOnStart: false, autoSync: false),
      );
      await engine.initialize();

      await engine.syncNow();

      expect((await storage.getTaskById('t1'))?.status, SyncTaskStatus.synced);

      await engine.dispose();
    });
  });
}
