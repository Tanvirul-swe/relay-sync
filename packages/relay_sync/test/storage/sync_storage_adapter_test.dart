import 'dart:async';

import 'package:relay_sync/relay_sync.dart';
import 'package:test/test.dart';

class _FakeStorageAdapter implements SyncStorageAdapter {
  final StreamController<List<SyncTask>> _tasksController =
      StreamController<List<SyncTask>>.broadcast();
  final StreamController<Map<SyncTaskStatus, int>> _countsController =
      StreamController<Map<SyncTaskStatus, int>>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> saveTask(SyncTask task) async {}

  @override
  Future<void> updateTask(SyncTask task) async {}

  @override
  Future<void> upsertTask(SyncTask task) async {}

  @override
  Future<SyncTask?> getTaskById(String id) async => null;

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async =>
      <SyncTask>[];

  @override
  Future<List<SyncTask>> getRetryableTasks({
    String? userId,
    String? tenantId,
    DateTime? now,
    int? limit,
  }) async =>
      <SyncTask>[];

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
  }) async =>
      <SyncTask>[];

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<void> clearSynced({String? userId, String? tenantId}) async {}

  @override
  Future<void> clearAll({String? userId, String? tenantId}) async {}

  @override
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  }) async =>
      <SyncTaskStatus, int>{};

  @override
  Stream<List<SyncTask>> watchTasks({String? userId, String? tenantId}) {
    return _tasksController.stream;
  }

  @override
  Stream<Map<SyncTaskStatus, int>> watchCountByStatus({
    String? userId,
    String? tenantId,
  }) {
    return _countsController.stream;
  }

  @override
  Future<void> close() async {
    await _tasksController.close();
    await _countsController.close();
  }
}

void main() {
  test('adapter interface can be implemented and streams are broadcast-safe', () async {
    final adapter = _FakeStorageAdapter();

    expect(adapter.watchTasks().isBroadcast, isTrue);
    expect(adapter.watchCountByStatus().isBroadcast, isTrue);

    await adapter.initialize();
    await adapter.close();
  });
}
