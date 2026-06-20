import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_drift/relay_sync_drift.dart';
import 'package:test/test.dart';

void main() {
  group('DriftSyncStorage', () {
    late RelaySyncDriftDatabase database;
    late DriftSyncStorage storage;

    setUp(() async {
      database = RelaySyncDriftDatabase(NativeDatabase.memory());
      storage = DriftSyncStorage(database: database);
      await storage.initialize();
    });

    tearDown(() async {
      await storage.close();
    });

    test('creates sync_tasks table and indexes', () async {
      final tableInfo =
          await database.customSelect('PRAGMA table_info(sync_tasks)').get();
      expect(
        tableInfo.map((row) => row.data['name']).toSet(),
        containsAll(<String>{
          'id',
          'user_id',
          'tenant_id',
          'method',
          'endpoint',
          'body',
          'headers',
          'metadata',
          'status',
          'priority',
          'retry_count',
          'max_retries',
          'created_at',
          'updated_at',
          'last_attempt_at',
          'next_retry_at',
          'idempotency_key',
          'dedupe_key',
          'depends_on_task_ids',
          'entity_type',
          'entity_local_id',
          'entity_remote_id',
          'last_error',
        }),
      );

      final indexes =
          await database.customSelect('PRAGMA index_list(sync_tasks)').get();
      expect(
        indexes.map((row) => row.data['name']).toSet(),
        containsAll(<String>{
          'idx_sync_tasks_status',
          'idx_sync_tasks_userId',
          'idx_sync_tasks_tenantId',
          'idx_sync_tasks_nextRetryAt',
          'idx_sync_tasks_priority',
          'idx_sync_tasks_createdAt',
          'idx_sync_tasks_dedupeKey',
        }),
      );
    });

    test('saves and reads task snapshots with JSON fields', () async {
      final task = _task('task-1').copyWith(
        headers: const <String, String>{'authorization': 'Bearer token'},
        lastError: const SyncError(
          code: 'retry',
          message: 'Retry later',
          details: <String, Object?>{'statusCode': 503},
        ),
      );

      await storage.saveTask(task);

      expect(await storage.getTaskById(task.id), task);

      final row = (await database.customSelect(
        'SELECT body, headers, metadata, last_error FROM sync_tasks WHERE id = ?',
        variables: <drift.Variable>[drift.Variable.withString(task.id)],
      ).get())
          .single;

      expect(jsonDecode(row.data['body']! as String), task.body);
      expect(jsonDecode(row.data['headers']! as String), task.headers);
      expect(
          jsonDecode(row.data['metadata']! as String), task.metadata.toJson());
      expect(jsonDecode(row.data['last_error']! as String),
          task.lastError!.toJson());
    });

    test(
        'queries pending, retryable, failed, status, scoped, and limited tasks',
        () async {
      final now = DateTime.parse('2026-04-28T12:00:00Z');
      await storage.upsertTask(
        _task('pending-low', priority: SyncPriority.low, createdAt: now),
      );
      await storage.upsertTask(
        _task(
          'pending-high',
          priority: SyncPriority.high,
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      );
      await storage.upsertTask(
        _task(
          'retry-due',
          status: SyncTaskStatus.retryScheduled,
          nextRetryAt: now,
        ),
      );
      await storage.upsertTask(
        _task(
          'retry-later',
          status: SyncTaskStatus.retryScheduled,
          nextRetryAt: now.add(const Duration(minutes: 1)),
        ),
      );
      await storage.upsertTask(
        _task('failed', status: SyncTaskStatus.failedPermanent),
      );
      await storage.upsertTask(_task('other-user', userId: 'user-2'));

      final pending = await storage.getPendingTasks(userId: 'user-1');
      expect(pending.map((task) => task.id), <String>[
        'pending-high',
        'pending-low',
      ]);

      final retryable = await storage.getRetryableTasks(
        userId: 'user-1',
        now: now,
      );
      expect(retryable.map((task) => task.id), <String>['retry-due']);

      final failed = await storage.getFailedTasks(userId: 'user-1');
      expect(failed.map((task) => task.id), <String>['failed']);

      final limited = await storage.getTasksByStatus(
        SyncTaskStatus.pending,
        limit: 1,
      );
      expect(limited, hasLength(1));
    });

    test('updates, upserts, deletes, clears, and counts tasks', () async {
      final task = _task('task-1');
      await storage.saveTask(task);
      await storage.updateTask(task.copyWith(status: SyncTaskStatus.synced));
      expect(
        (await storage.getTaskById(task.id))?.status,
        SyncTaskStatus.synced,
      );

      await storage.upsertTask(_task('task-2'));
      await storage.upsertTask(
        _task('task-3', status: SyncTaskStatus.failedRetryable),
      );

      expect(
        await storage.countByStatus(),
        <SyncTaskStatus, int>{
          SyncTaskStatus.synced: 1,
          SyncTaskStatus.pending: 1,
          SyncTaskStatus.failedRetryable: 1,
        },
      );

      await storage.clearSynced();
      expect(await storage.getTaskById('task-1'), isNull);

      await storage.deleteTask('task-2');
      expect(await storage.getTaskById('task-2'), isNull);

      await storage.clearAll();
      expect(await storage.countByStatus(), isEmpty);
    });

    test('watchTasks and watchCountByStatus react through Drift streams',
        () async {
      final taskEvents = <List<SyncTask>>[];
      final countEvents = <Map<SyncTaskStatus, int>>[];
      final taskSubscription = storage.watchTasks().listen(taskEvents.add);
      final countSubscription =
          storage.watchCountByStatus().listen(countEvents.add);
      addTearDown(taskSubscription.cancel);
      addTearDown(countSubscription.cancel);

      await _waitFor(() => taskEvents.isNotEmpty && countEvents.isNotEmpty);
      await storage.saveTask(_task('task-1'));
      await _waitFor(
        () => taskEvents.any(
          (tasks) => tasks.map((task) => task.id).contains('task-1'),
        ),
      );
      await _waitFor(
        () => countEvents.any(
          (counts) => counts[SyncTaskStatus.pending] == 1,
        ),
      );

      expect(taskEvents.first, isEmpty);
      expect(
        taskEvents
            .where((tasks) => tasks.map((task) => task.id).contains('task-1'))
            .last
            .map((task) => task.id),
        <String>['task-1'],
      );
      expect(
        countEvents.where((counts) => counts[SyncTaskStatus.pending] == 1).last,
        <SyncTaskStatus, int>{SyncTaskStatus.pending: 1},
      );
    });
  });
}

SyncTask _task(
  String id, {
  String userId = 'user-1',
  String tenantId = 'tenant-1',
  SyncTaskStatus status = SyncTaskStatus.pending,
  SyncPriority priority = SyncPriority.normal,
  DateTime? createdAt,
  DateTime? nextRetryAt,
}) {
  final now = createdAt ?? DateTime.parse('2026-04-28T00:00:00Z');
  return SyncTask(
    id: id,
    userId: userId,
    tenantId: tenantId,
    method: SyncMethod.post,
    endpoint: '/items',
    body: const <String, Object?>{'value': 1},
    headers: const <String, String>{'x-task': 'task'},
    metadata: SyncMetadata(
      taskId: id,
      method: SyncMethod.post,
      userId: userId,
      tenantId: tenantId,
      priority: priority,
      tags: const <String, String>{'source': 'test'},
    ),
    status: status,
    priority: priority,
    retryCount: status == SyncTaskStatus.pending ? 0 : 1,
    maxRetries: 5,
    createdAt: now,
    updatedAt: now,
    lastAttemptAt: status == SyncTaskStatus.pending ? null : now,
    nextRetryAt: nextRetryAt,
    idempotencyKey: 'idem-$id',
    dedupeKey: 'dedupe-$id',
    dependsOnTaskIds: const <String>['dependency'],
    entityType: 'item',
    entityLocalId: 'local-$id',
    entityRemoteId: 'remote-$id',
  );
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Timed out waiting for condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
