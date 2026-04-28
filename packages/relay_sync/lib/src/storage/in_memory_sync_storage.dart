import 'dart:async';

import '../models/relay_sync_exception.dart';
import '../models/sync_enums.dart';
import '../models/sync_task.dart';
import 'sync_storage_adapter.dart';

/// In-memory [SyncStorageAdapter] intended for tests and demos only.
///
/// This adapter is process-local and non-persistent. Data is lost when the
/// instance is discarded.
class InMemorySyncStorage implements SyncStorageAdapter {
  final Map<String, SyncTask> _tasksById = <String, SyncTask>{};
  final StreamController<void> _tasksChanged = StreamController<void>.broadcast();
  final StreamController<void> _countsChanged = StreamController<void>.broadcast();

  bool _initialized = false;
  bool _closed = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
    _emitState();
  }

  @override
  Future<void> saveTask(SyncTask task) async {
    _ensureUsable();
    if (_tasksById.containsKey(task.id)) {
      throw RelaySyncException(message: 'Task with id `${task.id}` already exists.');
    }
    _tasksById[task.id] = task;
    _emitState();
  }

  @override
  Future<void> updateTask(SyncTask task) async {
    _ensureUsable();
    if (!_tasksById.containsKey(task.id)) {
      throw RelaySyncException(message: 'Task with id `${task.id}` does not exist.');
    }
    _tasksById[task.id] = task;
    _emitState();
  }

  @override
  Future<void> upsertTask(SyncTask task) async {
    _ensureUsable();
    _tasksById[task.id] = task;
    _emitState();
  }

  @override
  Future<SyncTask?> getTaskById(String id) async {
    _ensureUsable();
    return _tasksById[id];
  }

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final results = _tasksById.values.where((task) {
      return task.status == SyncTaskStatus.pending && _matchesScope(task, userId, tenantId);
    }).toList()
      ..sort(_priorityThenCreatedAtComparator);

    return _applyLimit(results, limit);
  }

  @override
  Future<List<SyncTask>> getRetryableTasks({
    String? userId,
    String? tenantId,
    DateTime? now,
    int? limit,
  }) async {
    _ensureUsable();
    final effectiveNow = now ?? DateTime.now().toUtc();
    final results = _tasksById.values.where((task) {
      final retryableStatus = task.status == SyncTaskStatus.retryScheduled ||
          task.status == SyncTaskStatus.failedRetryable;
      final isDue = task.nextRetryAt == null ||
          task.nextRetryAt!.isBefore(effectiveNow) ||
          task.nextRetryAt!.isAtSameMomentAs(effectiveNow);
      return retryableStatus && isDue && _matchesScope(task, userId, tenantId);
    }).toList()
      ..sort(_priorityThenCreatedAtComparator);

    return _applyLimit(results, limit);
  }

  @override
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final results = _tasksById.values.where((task) {
      final isFailed = task.status == SyncTaskStatus.failedRetryable ||
          task.status == SyncTaskStatus.failedPermanent;
      return isFailed && _matchesScope(task, userId, tenantId);
    }).toList();

    return _applyLimit(results, limit);
  }

  @override
  Future<List<SyncTask>> getTasksByStatus(
    SyncTaskStatus status, {
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final results = _tasksById.values.where((task) {
      return task.status == status && _matchesScope(task, userId, tenantId);
    }).toList();

    return _applyLimit(results, limit);
  }

  @override
  Future<void> deleteTask(String id) async {
    _ensureUsable();
    _tasksById.remove(id);
    _emitState();
  }

  @override
  Future<void> clearSynced({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    final idsToRemove = _tasksById.values
        .where((task) {
          return task.status == SyncTaskStatus.synced && _matchesScope(task, userId, tenantId);
        })
        .map((task) => task.id)
        .toList(growable: false);

    for (final id in idsToRemove) {
      _tasksById.remove(id);
    }
    _emitState();
  }

  @override
  Future<void> clearAll({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    if (userId == null && tenantId == null) {
      _tasksById.clear();
      _emitState();
      return;
    }

    final idsToRemove = _tasksById.values
        .where((task) => _matchesScope(task, userId, tenantId))
        .map((task) => task.id)
        .toList(growable: false);

    for (final id in idsToRemove) {
      _tasksById.remove(id);
    }
    _emitState();
  }

  @override
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    return _computeCounts(userId: userId, tenantId: tenantId);
  }

  @override
  Stream<List<SyncTask>> watchTasks({
    String? userId,
    String? tenantId,
  }) {
    _ensureUsable();
    return Stream<List<SyncTask>>.multi((controller) {
      controller.add(_scopedTasks(userId: userId, tenantId: tenantId));
      final subscription = _tasksChanged.stream.listen((_) {
        controller.add(_scopedTasks(userId: userId, tenantId: tenantId));
      });
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  Stream<Map<SyncTaskStatus, int>> watchCountByStatus({
    String? userId,
    String? tenantId,
  }) {
    _ensureUsable();
    return Stream<Map<SyncTaskStatus, int>>.multi((controller) {
      controller.add(_computeCounts(userId: userId, tenantId: tenantId));
      final subscription = _countsChanged.stream.listen((_) {
        controller.add(_computeCounts(userId: userId, tenantId: tenantId));
      });
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _tasksChanged.close();
    await _countsChanged.close();
  }

  bool _matchesScope(SyncTask task, String? userId, String? tenantId) {
    final userMatches = userId == null || task.userId == userId;
    final tenantMatches = tenantId == null || task.tenantId == tenantId;
    return userMatches && tenantMatches;
  }

  List<SyncTask> _scopedTasks({String? userId, String? tenantId}) {
    return _tasksById.values
        .where((task) => _matchesScope(task, userId, tenantId))
        .toList(growable: false);
  }

  Map<SyncTaskStatus, int> _computeCounts({String? userId, String? tenantId}) {
    final counts = <SyncTaskStatus, int>{};
    for (final task in _tasksById.values) {
      if (!_matchesScope(task, userId, tenantId)) {
        continue;
      }
      counts.update(task.status, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<SyncTask> _applyLimit(List<SyncTask> tasks, int? limit) {
    if (limit == null || limit >= tasks.length) {
      return tasks;
    }
    if (limit <= 0) {
      return <SyncTask>[];
    }
    return tasks.take(limit).toList(growable: false);
  }

  int _priorityThenCreatedAtComparator(SyncTask a, SyncTask b) {
    final priorityDiff = b.priority.index.compareTo(a.priority.index);
    if (priorityDiff != 0) {
      return priorityDiff;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  void _emitState() {
    if (_closed) {
      return;
    }
    _tasksChanged.add(null);
    _countsChanged.add(null);
  }

  void _ensureUsable() {
    if (_closed) {
      throw const RelaySyncException(message: 'InMemorySyncStorage is closed.');
    }
    if (!_initialized) {
      throw const RelaySyncException(message: 'InMemorySyncStorage is not initialized.');
    }
  }
}
