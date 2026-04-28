import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

void main() {
  const baseTime = '2026-04-28T00:00:00.000Z';

  SyncMetadata metadata() {
    return SyncMetadata(taskId: 'task-meta-1', method: SyncMethod.post);
  }

  SyncTask taskWithMethod(SyncMethod method) {
    return SyncTask(
      id: 'task-1',
      method: method,
      endpoint: '/v1/items',
      metadata: metadata(),
      createdAt: DateTime.parse(baseTime),
      updatedAt: DateTime.parse(baseTime),
    );
  }

  group('enum serialization', () {
    test('SyncMethod toJson/fromJson roundtrip', () {
      for (final value in SyncMethod.values) {
        expect(SyncMethodJson.fromJson(value.toJson()), value);
      }
    });

    test('SyncTaskStatus toJson/fromJson roundtrip', () {
      for (final value in SyncTaskStatus.values) {
        expect(SyncTaskStatusJson.fromJson(value.toJson()), value);
      }
    });

    test('SyncPriority toJson/fromJson roundtrip', () {
      for (final value in SyncPriority.values) {
        expect(SyncPriorityJson.fromJson(value.toJson()), value);
      }
    });
  });

  group('SyncError', () {
    test('serialization and equality', () {
      final error = SyncError(
        code: 'timeout',
        message: 'Request timed out',
        details: const <String, Object?>{'retryAfterMs': 1500},
      );

      final parsed = SyncError.fromJson(error.toJson());

      expect(parsed, error);
      expect(parsed.hashCode, error.hashCode);
    });

    test('copyWith updates selected fields', () {
      const original = SyncError(code: 'e1', message: 'old');

      final updated = original.copyWith(message: 'new');

      expect(updated.code, 'e1');
      expect(updated.message, 'new');
    });
  });

  group('SyncResponse', () {
    test('serialization and equality', () {
      final response = SyncResponse(
        statusCode: 200,
        body: const <String, Object?>{'ok': true},
        headers: const <String, String>{'x-trace': 'abc'},
      );

      final parsed = SyncResponse.fromJson(response.toJson());

      expect(parsed, response);
      expect(parsed.hashCode, response.hashCode);
    });

    test('copyWith updates selected fields', () {
      const original = SyncResponse(statusCode: 202);

      final updated = original.copyWith(statusCode: 500);

      expect(updated.statusCode, 500);
      expect(updated.body, isEmpty);
    });
  });

  group('SyncMetadata', () {
    test('serialization and equality', () {
      final value = SyncMetadata(
        taskId: 'task-1',
        method: SyncMethod.post,
        userId: 'user-1',
        tenantId: 'tenant-1',
        priority: SyncPriority.high,
        attempt: 1,
        maxAttempts: 5,
        dependsOnTaskIds: const <String>['task-0'],
        tags: const <String, String>{'source': 'unit-test'},
      );

      final parsed = SyncMetadata.fromJson(value.toJson());

      expect(parsed, value);
      expect(parsed.hashCode, value.hashCode);
    });

    test('copyWith updates selected fields', () {
      final original = SyncMetadata(taskId: 'task-1', method: SyncMethod.get);

      final updated = original.copyWith(priority: SyncPriority.critical, attempt: 2);

      expect(updated.taskId, 'task-1');
      expect(updated.method, SyncMethod.get);
      expect(updated.priority, SyncPriority.critical);
      expect(updated.attempt, 2);
    });
  });

  group('SyncTask factories', () {
    test('SyncTask.get sets method and defaults', () {
      final task = SyncTask.get(
        id: 'task-get',
        endpoint: '/v1/items',
        metadata: SyncMetadata(taskId: 'task-get', method: SyncMethod.get),
        createdAt: DateTime.parse(baseTime),
        updatedAt: DateTime.parse(baseTime),
      );

      expect(task.method, SyncMethod.get);
      expect(task.status, SyncTaskStatus.pending);
      expect(task.priority, SyncPriority.normal);
      expect(task.maxRetries, 5);
    });

    test('post/put/patch/delete factories set methods', () {
      final createdAt = DateTime.parse(baseTime);
      final updatedAt = DateTime.parse(baseTime);

      final post = SyncTask.post(
        id: 'task-post',
        endpoint: '/v1/items',
        metadata: SyncMetadata(taskId: 'task-post', method: SyncMethod.post),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final put = SyncTask.put(
        id: 'task-put',
        endpoint: '/v1/items/1',
        metadata: SyncMetadata(taskId: 'task-put', method: SyncMethod.put),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final patch = SyncTask.patch(
        id: 'task-patch',
        endpoint: '/v1/items/1',
        metadata: SyncMetadata(taskId: 'task-patch', method: SyncMethod.patch),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final del = SyncTask.delete(
        id: 'task-delete',
        endpoint: '/v1/items/1',
        metadata: SyncMetadata(taskId: 'task-delete', method: SyncMethod.delete),
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(post.method, SyncMethod.post);
      expect(put.method, SyncMethod.put);
      expect(patch.method, SyncMethod.patch);
      expect(del.method, SyncMethod.delete);
    });
  });

  group('SyncTask serialization and copyWith', () {
    test('toJson/fromJson roundtrip and equality', () {
      final value = SyncTask.post(
        id: 'task-1',
        userId: 'user-1',
        tenantId: 'tenant-1',
        endpoint: '/v1/items',
        body: const <String, Object?>{'name': 'test'},
        headers: const <String, String>{'authorization': 'Bearer token'},
        metadata: SyncMetadata(
          taskId: 'task-1',
          method: SyncMethod.post,
          tags: const <String, String>{'origin': 'test'},
        ),
        status: SyncTaskStatus.retryScheduled,
        priority: SyncPriority.high,
        retryCount: 1,
        maxRetries: 5,
        createdAt: DateTime.parse(baseTime),
        updatedAt: DateTime.parse(baseTime),
        lastAttemptAt: DateTime.parse('2026-04-28T00:10:00.000Z'),
        nextRetryAt: DateTime.parse('2026-04-28T00:20:00.000Z'),
        idempotencyKey: 'idem-1',
        dedupeKey: 'dedupe-1',
        dependsOnTaskIds: const <String>['task-0'],
        entityType: 'item',
        entityLocalId: 'local-1',
        entityRemoteId: 'remote-1',
        lastError: const SyncError(code: 'network', message: 'No internet'),
      );

      final parsed = SyncTask.fromJson(value.toJson());

      expect(parsed, value);
      expect(parsed.hashCode, value.hashCode);
    });

    test('copyWith updates selected fields', () {
      final original = taskWithMethod(SyncMethod.post);

      final updated = original.copyWith(
        status: SyncTaskStatus.syncing,
        retryCount: 1,
        dedupeKey: 'd-1',
      );

      expect(updated.status, SyncTaskStatus.syncing);
      expect(updated.retryCount, 1);
      expect(updated.dedupeKey, 'd-1');
      expect(updated.id, original.id);
    });
  });

  group('SyncTask validation', () {
    test('throws for empty id', () {
      expect(
        () => SyncTask(
          id: ' ',
          method: SyncMethod.get,
          endpoint: '/v1/items',
          metadata: metadata(),
          createdAt: DateTime.parse(baseTime),
          updatedAt: DateTime.parse(baseTime),
        ),
        throwsA(isA<RelaySyncException>()),
      );
    });

    test('throws for empty endpoint', () {
      expect(
        () => SyncTask(
          id: 'task-1',
          method: SyncMethod.get,
          endpoint: ' ',
          metadata: metadata(),
          createdAt: DateTime.parse(baseTime),
          updatedAt: DateTime.parse(baseTime),
        ),
        throwsA(isA<RelaySyncException>()),
      );
    });

    test('throws when retryCount exceeds maxRetries', () {
      expect(
        () => SyncTask(
          id: 'task-1',
          method: SyncMethod.get,
          endpoint: '/v1/items',
          metadata: metadata(),
          retryCount: 4,
          maxRetries: 3,
          createdAt: DateTime.parse(baseTime),
          updatedAt: DateTime.parse(baseTime),
        ),
        throwsA(isA<RelaySyncException>()),
      );
    });

    test('throws when updatedAt before createdAt', () {
      expect(
        () => SyncTask(
          id: 'task-1',
          method: SyncMethod.get,
          endpoint: '/v1/items',
          metadata: metadata(),
          createdAt: DateTime.parse('2026-04-28T01:00:00.000Z'),
          updatedAt: DateTime.parse('2026-04-28T00:00:00.000Z'),
        ),
        throwsA(isA<RelaySyncException>()),
      );
    });
  });

  group('RelaySyncException', () {
    test('supports equality', () {
      const ex1 = RelaySyncException(message: 'boom');
      const ex2 = RelaySyncException(message: 'boom');

      expect(ex1, ex2);
      expect(ex1.hashCode, ex2.hashCode);
    });
  });
}
