import 'dart:io';

import 'package:hive/hive.dart';
import 'package:relay_sync/relay_sync.dart';
import 'package:relay_sync_hive/relay_sync_hive.dart';
import 'package:test/test.dart';

SyncTask _task(
  String id, {
  String? userId,
  String? tenantId,
  SyncTaskStatus status = SyncTaskStatus.pending,
  SyncPriority priority = SyncPriority.normal,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.parse('2026-04-28T00:00:00Z');
  return SyncTask(
    id: id,
    userId: userId,
    tenantId: tenantId,
    method: SyncMethod.post,
    endpoint: '/v1/items',
    metadata: SyncMetadata(taskId: id, method: SyncMethod.post),
    status: status,
    priority: priority,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('relay_sync_hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('HiveSyncStorage', () {
    test('supports custom box name and basic CRUD', () async {
      const boxName = 'custom_tasks_box';
      final storage = HiveSyncStorage(boxName: boxName);
      await storage.initialize();

      final task = _task('t1');
      await storage.saveTask(task);

      final loaded = await storage.getTaskById('t1');
      expect(loaded, isNotNull);
      expect(loaded?.id, 't1');

      await storage.deleteTask('t1');
      expect(await storage.getTaskById('t1'), isNull);

      await storage.close();
      await Hive.deleteBoxFromDisk(boxName);
    });

    test('filters by userId and tenantId', () async {
      const boxName = 'scoped_tasks_box';
      final storage = HiveSyncStorage(boxName: boxName);
      await storage.initialize();

      await storage.upsertTask(_task('u1t1', userId: 'u1', tenantId: 't1'));
      await storage.upsertTask(_task('u1t2', userId: 'u1', tenantId: 't2'));
      await storage.upsertTask(_task('u2t1', userId: 'u2', tenantId: 't1'));

      final scoped = await storage.getPendingTasks(userId: 'u1', tenantId: 't1');
      expect(scoped.map((task) => task.id), <String>['u1t1']);

      await storage.close();
      await Hive.deleteBoxFromDisk(boxName);
    });

    test('watchTasks and watchCountByStatus emit updates', () async {
      const boxName = 'watch_tasks_box';
      final storage = HiveSyncStorage(boxName: boxName);
      await storage.initialize();

      final tasksFuture = storage.watchTasks().firstWhere((tasks) => tasks.isNotEmpty);
      final countsFuture = storage
          .watchCountByStatus()
          .firstWhere((counts) => (counts[SyncTaskStatus.pending] ?? 0) > 0);

      await storage.upsertTask(_task('t1'));

      final tasks = await tasksFuture;
      final counts = await countsFuture;

      expect(tasks.single.id, 't1');
      expect(counts[SyncTaskStatus.pending], 1);

      await storage.close();
      await Hive.deleteBoxFromDisk(boxName);
    });

    test('sorts pending tasks by priority desc then createdAt asc', () async {
      const boxName = 'sort_tasks_box';
      final storage = HiveSyncStorage(boxName: boxName);
      await storage.initialize();

      await storage.upsertTask(
        _task(
          'normal-old',
          priority: SyncPriority.normal,
          createdAt: DateTime.parse('2026-04-28T00:00:00Z'),
        ),
      );
      await storage.upsertTask(
        _task(
          'critical-new',
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-28T00:00:10Z'),
        ),
      );
      await storage.upsertTask(
        _task(
          'critical-old',
          priority: SyncPriority.critical,
          createdAt: DateTime.parse('2026-04-27T23:59:00Z'),
        ),
      );

      final tasks = await storage.getPendingTasks();
      expect(tasks.map((task) => task.id), <String>['critical-old', 'critical-new', 'normal-old']);

      await storage.close();
      await Hive.deleteBoxFromDisk(boxName);
    });
  });
}
