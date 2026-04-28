import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _SuccessClient implements SyncClient {
  @override
  Future<SyncResponse> execute(
    SyncTask task, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    return const SyncResponse(statusCode: 200);
  }
}

RelaySyncController _buildController({
  InMemorySyncStorage? storage,
  RelaySyncConfig? config,
  TaskIdGenerator? taskIdGenerator,
}) {
  final engine = RelaySyncEngine(
    storage: storage ?? InMemorySyncStorage(),
    client: _SuccessClient(),
    networkMonitor: ManualNetworkMonitor(initiallyOnline: true),
    config: config ?? RelaySyncConfig(syncOnStart: false, autoSync: false),
  );

  return RelaySyncController(
    engine: engine,
    taskIdGenerator: taskIdGenerator,
  );
}

void main() {
  group('RelaySyncController helper methods', () {
    test('get helper creates and enqueues GET task', () async {
      final controller = _buildController(taskIdGenerator: () => 'id-get-1');
      await controller.initialize();

      final task = await controller.get('/v1/items', userId: 'u1', tenantId: 't1');

      expect(task.id, 'id-get-1');
      expect(task.method, SyncMethod.get);
      expect(task.metadata.method, SyncMethod.get);
      expect(task.userId, 'u1');
      expect(task.tenantId, 't1');
      expect(await controller.engine.storage.getTaskById(task.id), isNotNull);

      await controller.dispose();
    });

    test('post/put/patch/delete helpers create expected methods', () async {
      var id = 0;
      final controller = _buildController(taskIdGenerator: () => 'id-${++id}');
      await controller.initialize();

      final post = await controller.post('/v1/items', body: const <String, Object?>{'a': 1});
      final put = await controller.put('/v1/items/1', body: const <String, Object?>{'b': 2});
      final patch = await controller.patch('/v1/items/1', body: const <String, Object?>{'c': 3});
      final del = await controller.delete('/v1/items/1');

      expect(post.method, SyncMethod.post);
      expect(put.method, SyncMethod.put);
      expect(patch.method, SyncMethod.patch);
      expect(del.method, SyncMethod.delete);

      await controller.dispose();
    });
  });

  group('RelaySyncController task controls', () {
    test('cancelTask marks task as cancelled', () async {
      final controller = _buildController(taskIdGenerator: () => 't1');
      await controller.initialize();
      final task = await controller.post('/v1/items');

      await controller.cancelTask(task.id);

      final updated = await controller.engine.storage.getTaskById(task.id);
      expect(updated?.status, SyncTaskStatus.cancelled);

      await controller.dispose();
    });

    test('retryTask moves task back to pending', () async {
      final controller = _buildController(taskIdGenerator: () => 't1');
      await controller.initialize();
      final task = await controller.post('/v1/items');
      await controller.engine.storage.upsertTask(
        task.copyWith(status: SyncTaskStatus.failedPermanent, updatedAt: DateTime.now().toUtc()),
      );

      await controller.retryTask(task.id);

      final updated = await controller.engine.storage.getTaskById(task.id);
      expect(updated?.status, SyncTaskStatus.pending);

      await controller.dispose();
    });

    test('retryAllFailed retries failed tasks in configured scope', () async {
      final storage = InMemorySyncStorage();
      final controller = _buildController(
        storage: storage,
        config: RelaySyncConfig(
          autoSync: false,
          syncOnStart: false,
          userId: 'u1',
          tenantId: 't1',
        ),
      );
      await controller.initialize();

      final now = DateTime.parse('2026-04-28T00:00:00Z');
      await storage.upsertTask(
        SyncTask(
          id: 'a',
          userId: 'u1',
          tenantId: 't1',
          method: SyncMethod.post,
          endpoint: '/v1/items',
          metadata: const SyncMetadata(taskId: 'a', method: SyncMethod.post),
          status: SyncTaskStatus.failedPermanent,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await storage.upsertTask(
        SyncTask(
          id: 'b',
          userId: 'u2',
          tenantId: 't1',
          method: SyncMethod.post,
          endpoint: '/v1/items',
          metadata: const SyncMetadata(taskId: 'b', method: SyncMethod.post),
          status: SyncTaskStatus.failedPermanent,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await controller.retryAllFailed();

      expect((await storage.getTaskById('a'))?.status, SyncTaskStatus.pending);
      expect((await storage.getTaskById('b'))?.status, SyncTaskStatus.failedPermanent);

      await controller.dispose();
    });

    test('clearSynced clears only synced tasks in configured scope', () async {
      final storage = InMemorySyncStorage();
      final controller = _buildController(
        storage: storage,
        config: RelaySyncConfig(autoSync: false, syncOnStart: false, userId: 'u1'),
      );
      await controller.initialize();

      final now = DateTime.parse('2026-04-28T00:00:00Z');
      await storage.upsertTask(
        SyncTask(
          id: 'a',
          userId: 'u1',
          method: SyncMethod.post,
          endpoint: '/v1/items',
          metadata: const SyncMetadata(taskId: 'a', method: SyncMethod.post),
          status: SyncTaskStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await storage.upsertTask(
        SyncTask(
          id: 'b',
          userId: 'u2',
          method: SyncMethod.post,
          endpoint: '/v1/items',
          metadata: const SyncMetadata(taskId: 'b', method: SyncMethod.post),
          status: SyncTaskStatus.synced,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await controller.clearSynced();

      expect(await storage.getTaskById('a'), isNull);
      expect(await storage.getTaskById('b'), isNotNull);

      await controller.dispose();
    });
  });

  group('RelaySyncController streams', () {
    test('watchTasks and watchStatusCounts stream scoped updates', () async {
      final controller = _buildController(
        config: RelaySyncConfig(autoSync: false, syncOnStart: false, userId: 'u1'),
        taskIdGenerator: () => 'stream-id',
      );
      await controller.initialize();

      final tasksFuture = controller.watchTasks().firstWhere((tasks) => tasks.isNotEmpty);
      final countsFuture = controller
          .watchStatusCounts()
          .firstWhere((counts) => (counts[SyncTaskStatus.pending] ?? 0) > 0);

      await controller.post('/v1/items', userId: 'u1');

      final tasks = await tasksFuture;
      final counts = await countsFuture;

      expect(tasks.single.id, 'stream-id');
      expect(counts[SyncTaskStatus.pending], 1);

      await controller.dispose();
    });

    test('watchState proxies engine states', () async {
      final controller = _buildController();
      final states = <RelaySyncState>[];
      final sub = controller.watchState().listen(states.add);

      await controller.initialize();
      await controller.pause();
      await controller.resume();
      await controller.dispose();

      expect(states.contains(RelaySyncState.idle), isTrue);
      expect(states.contains(RelaySyncState.paused), isTrue);
      expect(states.contains(RelaySyncState.disposed), isTrue);

      await sub.cancel();
    });
  });
}
