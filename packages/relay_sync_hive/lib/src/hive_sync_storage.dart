import 'dart:async';

import 'package:hive/hive.dart';
import 'package:relay_sync/relay_sync.dart';

/// Hive-backed [SyncStorageAdapter] for persistent relay_sync task storage.
///
/// This implementation stores tasks as JSON maps for compatibility and
/// maintainability across schema updates.
class HiveSyncStorage implements SyncStorageAdapter {
  /// Creates a Hive storage adapter.
  HiveSyncStorage({this.boxName = 'relay_sync_tasks'});

  /// Name of the Hive box used to persist tasks.
  final String boxName;

  Box<dynamic>? _box;
  bool _initialized = false;
  bool _closed = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _box = await Hive.openBox<dynamic>(boxName);
    _initialized = true;
  }

  @override
  Future<void> saveTask(SyncTask task) async {
    _ensureUsable();
    if (_box!.containsKey(task.id)) {
      throw RelaySyncException(message: 'Task with id `${task.id}` already exists.');
    }
    await _box!.put(task.id, task.toJson());
  }

  @override
  Future<void> updateTask(SyncTask task) async {
    _ensureUsable();
    if (!_box!.containsKey(task.id)) {
      throw RelaySyncException(message: 'Task with id `${task.id}` does not exist.');
    }
    await _box!.put(task.id, task.toJson());
  }

  @override
  Future<void> upsertTask(SyncTask task) async {
    _ensureUsable();
    await _box!.put(task.id, task.toJson());
  }

  @override
  Future<SyncTask?> getTaskById(String id) async {
    _ensureUsable();
    final value = _box!.get(id);
    return _decodeTask(value);
  }

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final tasks = _allTasks().where((task) {
      return task.status == SyncTaskStatus.pending && _matchesScope(task, userId, tenantId);
    }).toList(growable: false)
      ..sort(_priorityThenCreatedAtComparator);
    return _applyLimit(tasks, limit);
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
    final tasks = _allTasks().where((task) {
      final retryableStatus = task.status == SyncTaskStatus.retryScheduled ||
          task.status == SyncTaskStatus.failedRetryable;
      final due = task.nextRetryAt == null || !task.nextRetryAt!.isAfter(effectiveNow);
      return retryableStatus && due && _matchesScope(task, userId, tenantId);
    }).toList(growable: false)
      ..sort(_priorityThenCreatedAtComparator);
    return _applyLimit(tasks, limit);
  }

  @override
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final tasks = _allTasks().where((task) {
      final isFailed = task.status == SyncTaskStatus.failedRetryable ||
          task.status == SyncTaskStatus.failedPermanent;
      return isFailed && _matchesScope(task, userId, tenantId);
    }).toList(growable: false);
    return _applyLimit(tasks, limit);
  }

  @override
  Future<List<SyncTask>> getTasksByStatus(
    SyncTaskStatus status, {
    String? userId,
    String? tenantId,
    int? limit,
  }) async {
    _ensureUsable();
    final tasks = _allTasks().where((task) {
      return task.status == status && _matchesScope(task, userId, tenantId);
    }).toList(growable: false);
    return _applyLimit(tasks, limit);
  }

  @override
  Future<void> deleteTask(String id) async {
    _ensureUsable();
    await _box!.delete(id);
  }

  @override
  Future<void> clearSynced({String? userId, String? tenantId}) async {
    _ensureUsable();
    final ids = _allTasks()
        .where((task) => task.status == SyncTaskStatus.synced && _matchesScope(task, userId, tenantId))
        .map((task) => task.id)
        .toList(growable: false);

    await _box!.deleteAll(ids);
  }

  @override
  Future<void> clearAll({String? userId, String? tenantId}) async {
    _ensureUsable();
    if (userId == null && tenantId == null) {
      await _box!.clear();
      return;
    }

    final ids = _allTasks()
        .where((task) => _matchesScope(task, userId, tenantId))
        .map((task) => task.id)
        .toList(growable: false);
    await _box!.deleteAll(ids);
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
  Stream<List<SyncTask>> watchTasks({String? userId, String? tenantId}) {
    _ensureUsable();
    return Stream<List<SyncTask>>.multi((controller) {
      controller.add(_scopedTasks(userId: userId, tenantId: tenantId));
      final sub = _box!.watch().listen((_) {
        controller.add(_scopedTasks(userId: userId, tenantId: tenantId));
      });
      controller.onCancel = sub.cancel;
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
      final sub = _box!.watch().listen((_) {
        controller.add(_computeCounts(userId: userId, tenantId: tenantId));
      });
      controller.onCancel = sub.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }

    _closed = true;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }

  List<SyncTask> _allTasks() {
    return _box!.values.map(_decodeTask).whereType<SyncTask>().toList(growable: false);
  }

  List<SyncTask> _scopedTasks({String? userId, String? tenantId}) {
    return _allTasks().where((task) => _matchesScope(task, userId, tenantId)).toList(growable: false);
  }

  Map<SyncTaskStatus, int> _computeCounts({String? userId, String? tenantId}) {
    final counts = <SyncTaskStatus, int>{};
    for (final task in _allTasks()) {
      if (!_matchesScope(task, userId, tenantId)) {
        continue;
      }
      counts.update(task.status, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  SyncTask? _decodeTask(Object? rawValue) {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is SyncTask) {
      return rawValue;
    }
    if (rawValue is Map<Object?, Object?>) {
      return SyncTask.fromJson(Map<String, Object?>.from(rawValue));
    }
    if (rawValue is Map<String, Object?>) {
      return SyncTask.fromJson(rawValue);
    }
    throw RelaySyncException(message: 'Unsupported task payload type in Hive box `$boxName`.');
  }

  bool _matchesScope(SyncTask task, String? userId, String? tenantId) {
    final userMatches = userId == null || task.userId == userId;
    final tenantMatches = tenantId == null || task.tenantId == tenantId;
    return userMatches && tenantMatches;
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

  void _ensureUsable() {
    if (_closed) {
      throw const RelaySyncException(message: 'HiveSyncStorage is closed.');
    }
    if (!_initialized || _box == null) {
      throw const RelaySyncException(message: 'HiveSyncStorage is not initialized.');
    }
  }
}
