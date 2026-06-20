import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:relay_sync/relay_sync.dart';

import 'relay_sync_drift_database.dart';

/// Drift-backed [SyncStorageAdapter].
class DriftSyncStorage implements SyncStorageAdapter {
  /// Creates a storage adapter using [database].
  DriftSyncStorage({required RelaySyncDriftDatabase database})
      : _database = database;

  final RelaySyncDriftDatabase _database;
  bool _initialized = false;
  bool _closed = false;

  @override
  Future<void> initialize() async {
    _ensureNotClosed();
    if (_initialized) {
      return;
    }
    await _database.customSelect('SELECT 1').get();
    _initialized = true;
  }

  @override
  Future<void> saveTask(SyncTask task) async {
    _ensureUsable();
    try {
      await _database.into(_database.syncTasks).insert(_taskToCompanion(task));
    } catch (error) {
      if (error.toString().toLowerCase().contains('unique')) {
        throw RelaySyncException(
          message: 'Task with id `${task.id}` already exists.',
          cause: error,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> updateTask(SyncTask task) async {
    _ensureUsable();
    final updated = await (_database.update(_database.syncTasks)
          ..where((table) => table.id.equals(task.id)))
        .write(_taskToCompanion(task));
    if (updated == 0) {
      throw RelaySyncException(
        message: 'Task with id `${task.id}` does not exist.',
      );
    }
  }

  @override
  Future<void> upsertTask(SyncTask task) async {
    _ensureUsable();
    await _database
        .into(_database.syncTasks)
        .insertOnConflictUpdate(_taskToCompanion(task));
  }

  @override
  Future<SyncTask?> getTaskById(String id) async {
    _ensureUsable();
    final query = _database.select(_database.syncTasks)
      ..where((table) => table.id.equals(id))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _taskFromRow(row);
  }

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) {
    return _queryTasks(
      filter: (table) => table.status.equals(SyncTaskStatus.pending.name),
      userId: userId,
      tenantId: tenantId,
      limit: limit,
      orderByScheduler: true,
    );
  }

  @override
  Future<List<SyncTask>> getRetryableTasks({
    String? userId,
    String? tenantId,
    DateTime? now,
    int? limit,
  }) {
    final effectiveNow = now ?? DateTime.now().toUtc();
    return _queryTasks(
      filter: (table) {
        final retryableStatus = table.status.isIn(<String>[
          SyncTaskStatus.retryScheduled.name,
          SyncTaskStatus.failedRetryable.name,
        ]);
        final due = table.nextRetryAt.isNull() |
            table.nextRetryAt
                .isSmallerOrEqualValue(effectiveNow.toIso8601String());
        return retryableStatus & due;
      },
      userId: userId,
      tenantId: tenantId,
      limit: limit,
      orderByScheduler: true,
    );
  }

  @override
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) {
    return _queryTasks(
      filter: (table) => table.status.isIn(<String>[
        SyncTaskStatus.failedRetryable.name,
        SyncTaskStatus.failedPermanent.name,
      ]),
      userId: userId,
      tenantId: tenantId,
      limit: limit,
    );
  }

  @override
  Future<List<SyncTask>> getTasksByStatus(
    SyncTaskStatus status, {
    String? userId,
    String? tenantId,
    int? limit,
  }) {
    return _queryTasks(
      filter: (table) => table.status.equals(status.name),
      userId: userId,
      tenantId: tenantId,
      limit: limit,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    _ensureUsable();
    await (_database.delete(_database.syncTasks)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearSynced({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    final delete = _database.delete(_database.syncTasks)
      ..where(
        (table) => _withScope(
          table,
          table.status.equals(SyncTaskStatus.synced.name),
          userId: userId,
          tenantId: tenantId,
        ),
      );
    await delete.go();
  }

  @override
  Future<void> clearAll({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    final delete = _database.delete(_database.syncTasks);
    if (userId != null || tenantId != null) {
      delete.where(
        (table) => _withScope(
          table,
          const Constant<bool>(true),
          userId: userId,
          tenantId: tenantId,
        ),
      );
    }
    await delete.go();
  }

  @override
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  }) async {
    _ensureUsable();
    final tasks = await _queryTasks(userId: userId, tenantId: tenantId);
    return _countTasks(tasks);
  }

  @override
  Stream<List<SyncTask>> watchTasks({
    String? userId,
    String? tenantId,
  }) {
    _ensureUsable();
    final query = _selectTasks(userId: userId, tenantId: tenantId);
    return query
        .watch()
        .map((rows) => rows.map(_taskFromRow).toList(growable: false))
        .asBroadcastStream();
  }

  @override
  Stream<Map<SyncTaskStatus, int>> watchCountByStatus({
    String? userId,
    String? tenantId,
  }) {
    _ensureUsable();
    return watchTasks(userId: userId, tenantId: tenantId)
        .map(_countTasks)
        .asBroadcastStream();
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _database.close();
  }

  Future<List<SyncTask>> _queryTasks({
    Expression<bool> Function($SyncTasksTable table)? filter,
    String? userId,
    String? tenantId,
    int? limit,
    bool orderByScheduler = false,
  }) async {
    _ensureUsable();
    final query = _selectTasks(
      filter: filter,
      userId: userId,
      tenantId: tenantId,
      orderByScheduler: orderByScheduler,
    );
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    return rows.map(_taskFromRow).toList(growable: false);
  }

  SimpleSelectStatement<$SyncTasksTable, SyncTaskRow> _selectTasks({
    Expression<bool> Function($SyncTasksTable table)? filter,
    String? userId,
    String? tenantId,
    bool orderByScheduler = false,
  }) {
    final query = _database.select(_database.syncTasks);
    query.where(
      (table) => _withScope(
        table,
        filter == null ? const Constant<bool>(true) : filter(table),
        userId: userId,
        tenantId: tenantId,
      ),
    );
    if (orderByScheduler) {
      query.orderBy(<OrderingTerm Function($SyncTasksTable)>[
        (table) => OrderingTerm(
              expression: table.priority,
              mode: OrderingMode.desc,
            ),
        (table) => OrderingTerm(expression: table.createdAt),
      ]);
    }
    return query;
  }

  Expression<bool> _withScope(
    $SyncTasksTable table,
    Expression<bool> expression, {
    String? userId,
    String? tenantId,
  }) {
    var scoped = expression;
    if (userId != null) {
      scoped = scoped & table.userId.equals(userId);
    }
    if (tenantId != null) {
      scoped = scoped & table.tenantId.equals(tenantId);
    }
    return scoped;
  }

  Map<SyncTaskStatus, int> _countTasks(List<SyncTask> tasks) {
    final counts = <SyncTaskStatus, int>{};
    for (final task in tasks) {
      counts.update(task.status, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  SyncTasksCompanion _taskToCompanion(SyncTask task) {
    return SyncTasksCompanion.insert(
      id: task.id,
      userId: Value<String?>(task.userId),
      tenantId: Value<String?>(task.tenantId),
      method: task.method.name,
      endpoint: task.endpoint,
      body: jsonEncode(task.body),
      headers: jsonEncode(task.headers),
      metadata: jsonEncode(task.metadata.toJson()),
      status: task.status.name,
      priority: task.priority.index,
      retryCount: task.retryCount,
      maxRetries: task.maxRetries,
      createdAt: task.createdAt.toIso8601String(),
      updatedAt: task.updatedAt.toIso8601String(),
      lastAttemptAt: Value<String?>(task.lastAttemptAt?.toIso8601String()),
      nextRetryAt: Value<String?>(task.nextRetryAt?.toIso8601String()),
      idempotencyKey: Value<String?>(task.idempotencyKey),
      dedupeKey: Value<String?>(task.dedupeKey),
      dependsOnTaskIds: jsonEncode(task.dependsOnTaskIds),
      entityType: Value<String?>(task.entityType),
      entityLocalId: Value<String?>(task.entityLocalId),
      entityRemoteId: Value<String?>(task.entityRemoteId),
      lastError: Value<String?>(
          task.lastError == null ? null : jsonEncode(task.lastError!.toJson())),
    );
  }

  SyncTask _taskFromRow(SyncTaskRow row) {
    return SyncTask(
      id: row.id,
      userId: row.userId,
      tenantId: row.tenantId,
      method: SyncMethodJson.fromJson(row.method),
      endpoint: row.endpoint,
      body: Map<String, Object?>.from(
        jsonDecode(row.body) as Map<Object?, Object?>,
      ),
      headers: Map<String, String>.from(
        jsonDecode(row.headers) as Map<Object?, Object?>,
      ),
      metadata: SyncMetadata.fromJson(
        Map<String, Object?>.from(
          jsonDecode(row.metadata) as Map<Object?, Object?>,
        ),
      ),
      status: SyncTaskStatusJson.fromJson(row.status),
      priority: SyncPriority.values[row.priority],
      retryCount: row.retryCount,
      maxRetries: row.maxRetries,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      lastAttemptAt:
          row.lastAttemptAt == null ? null : DateTime.parse(row.lastAttemptAt!),
      nextRetryAt:
          row.nextRetryAt == null ? null : DateTime.parse(row.nextRetryAt!),
      idempotencyKey: row.idempotencyKey,
      dedupeKey: row.dedupeKey,
      dependsOnTaskIds: List<String>.from(
        jsonDecode(row.dependsOnTaskIds) as List<Object?>,
      ),
      entityType: row.entityType,
      entityLocalId: row.entityLocalId,
      entityRemoteId: row.entityRemoteId,
      lastError: row.lastError == null
          ? null
          : SyncError.fromJson(
              Map<String, Object?>.from(
                jsonDecode(row.lastError!) as Map<Object?, Object?>,
              ),
            ),
    );
  }

  void _ensureUsable() {
    _ensureNotClosed();
    if (!_initialized) {
      throw const RelaySyncException(
        message: 'DriftSyncStorage is not initialized.',
      );
    }
  }

  void _ensureNotClosed() {
    if (_closed) {
      throw const RelaySyncException(message: 'DriftSyncStorage is closed.');
    }
  }
}
