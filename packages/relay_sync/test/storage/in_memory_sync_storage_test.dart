import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

SyncTask _task({
  required String id,
  required SyncTaskStatus status,
  required SyncPriority priority,
  required DateTime createdAt,
  String? userId,
  String? tenantId,
  DateTime? nextRetryAt,
}) {
  return SyncTask(
    id: id,
    userId: userId,
    tenantId: tenantId,
    method: SyncMethod.post,
    endpoint: '/v1/items',
    metadata: SyncMetadata(taskId: id, method: SyncMethod.post),
    status: status,
    priority: priority,
    createdAt: createdAt,
    updatedAt: createdAt,
    nextRetryAt: nextRetryAt,
  );
}

void main() {
  group('InMemorySyncStorage', () {
    late InMemorySyncStorage storage;

    setUp(() async {
      storage = InMemorySyncStorage();
      await storage.initialize();
    });

    tearDown(() async {
      await storage.close();
    });

    test('save/get/update/upsert/delete flow', () async {
      final task = _task(
        id: 't1',
        status: SyncTaskStatus.pending,
        priority: SyncPriority.normal,
        createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
      );

      await storage.saveTask(task);
      expect(await storage.getTaskById('t1'), task);

      final updated = task.copyWith(status: SyncTaskStatus.syncing);
      await storage.updateTask(updated);
      expect((await storage.getTaskById('t1'))?.status, SyncTaskStatus.syncing);

      await storage.upsertTask(task.copyWith(status: SyncTaskStatus.synced));
      expect((await storage.getTaskById('t1'))?.status, SyncTaskStatus.synced);

      await storage.deleteTask('t1');
      expect(await storage.getTaskById('t1'), isNull);
    });

    test('supports userId and tenantId filtering', () async {
      await storage.saveTask(
        _task(
          id: 'u1',
          userId: 'a',
          tenantId: 't1',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'u2',
          userId: 'b',
          tenantId: 't2',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:01:00Z'),
        ),
      );

      final byUser = await storage.getPendingTasks(userId: 'a');
      final byTenant = await storage.getPendingTasks(tenantId: 't2');

      expect(byUser.map((e) => e.id), ['u1']);
      expect(byTenant.map((e) => e.id), ['u2']);
    });

    test('sorts pending by priority desc then createdAt asc', () async {
      await storage.saveTask(
        _task(
          id: 'p1',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.high,
          createdAt: DateTime.parse('2026-04-28T00:10:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'p2',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:20:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'p3',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:05:00Z'),
        ),
      );

      final pending = await storage.getPendingTasks();
      expect(pending.map((e) => e.id).toList(), ['p3', 'p2', 'p1']);
    });

    test('sorts retryable by priority desc then createdAt asc and due time', () async {
      final now = DateTime.parse('2026-04-28T01:00:00Z');
      await storage.saveTask(
        _task(
          id: 'r1',
          status: SyncTaskStatus.retryScheduled,
          priority: SyncPriority.high,
          createdAt: DateTime.parse('2026-04-28T00:10:00Z'),
          nextRetryAt: DateTime.parse('2026-04-28T00:59:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'r2',
          status: SyncTaskStatus.failedRetryable,
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:20:00Z'),
          nextRetryAt: DateTime.parse('2026-04-28T02:00:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'r3',
          status: SyncTaskStatus.failedRetryable,
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:05:00Z'),
          nextRetryAt: DateTime.parse('2026-04-28T01:00:00Z'),
        ),
      );

      final retryable = await storage.getRetryableTasks(now: now);
      expect(retryable.map((e) => e.id).toList(), ['r3', 'r1']);
    });

    test('counts by status and clear helpers work', () async {
      await storage.saveTask(
        _task(
          id: 'c1',
          userId: 'u',
          tenantId: 't',
          status: SyncTaskStatus.synced,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
        ),
      );
      await storage.saveTask(
        _task(
          id: 'c2',
          userId: 'u',
          tenantId: 't',
          status: SyncTaskStatus.failedPermanent,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:01:00Z'),
        ),
      );

      final counts = await storage.countByStatus(userId: 'u', tenantId: 't');
      expect(counts[SyncTaskStatus.synced], 1);
      expect(counts[SyncTaskStatus.failedPermanent], 1);

      await storage.clearSynced(userId: 'u', tenantId: 't');
      expect(await storage.getTaskById('c1'), isNull);
      expect(await storage.getTaskById('c2'), isNotNull);

      await storage.clearAll(userId: 'u', tenantId: 't');
      expect(await storage.getTaskById('c2'), isNull);
    });

    test('watchTasks and watchCountByStatus are broadcast and emit updates', () async {
      final tasksStream = storage.watchTasks();
      final countsStream = storage.watchCountByStatus();

      expect(tasksStream.isBroadcast, isTrue);
      expect(countsStream.isBroadcast, isTrue);

      final taskEventsA = <List<SyncTask>>[];
      final taskEventsB = <List<SyncTask>>[];
      final countEvents = <Map<SyncTaskStatus, int>>[];

      final subA = tasksStream.listen(taskEventsA.add);
      final subB = tasksStream.listen(taskEventsB.add);
      final countSub = countsStream.listen(countEvents.add);

      await Future<void>.delayed(Duration.zero);

      await storage.saveTask(
        _task(
          id: 'w1',
          status: SyncTaskStatus.pending,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
        ),
      );
      await storage.upsertTask(
        _task(
          id: 'w1',
          status: SyncTaskStatus.synced,
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(taskEventsA.isNotEmpty, isTrue);
      expect(taskEventsB.isNotEmpty, isTrue);
      expect(countEvents.isNotEmpty, isTrue);
      expect(taskEventsA.last.single.status, SyncTaskStatus.synced);
      expect(countEvents.last[SyncTaskStatus.synced], 1);

      await subA.cancel();
      await subB.cancel();
      await countSub.cancel();
    });

    test('throws before initialize and after close', () async {
      final uninitialized = InMemorySyncStorage();

      expect(
        () => uninitialized.getPendingTasks(),
        throwsA(isA<RelaySyncException>()),
      );

      await uninitialized.initialize();
      await uninitialized.close();

      expect(
        () => uninitialized.getPendingTasks(),
        throwsA(isA<RelaySyncException>()),
      );
    });
  });
}
