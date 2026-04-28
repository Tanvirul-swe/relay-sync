import '../models/sync_enums.dart';
import '../models/sync_task.dart';

/// Contract for persistence backends used by relay_sync.
///
/// Implementations should:
/// - remain deterministic and avoid hidden global state;
/// - preserve task immutability by storing full task snapshots;
/// - enforce `id` uniqueness for [saveTask];
/// - allow id replacement semantics for [updateTask]/[upsertTask];
/// - apply `userId` and `tenantId` filters consistently across query methods;
/// - return tasks sorted by scheduler relevance (recommended: priority desc,
///   createdAt asc, then retry schedule);
/// - ensure stream methods are safe for multiple listeners by exposing broadcast
///   streams (or documented equivalent behavior).
abstract interface class SyncStorageAdapter {
  /// Prepares adapter resources (connections, boxes, tables, caches).
  Future<void> initialize();

  /// Persists a new [task]. Should fail if a task with the same id already exists.
  Future<void> saveTask(SyncTask task);

  /// Updates an existing [task]. Should fail when the task does not exist.
  Future<void> updateTask(SyncTask task);

  /// Inserts or updates [task] by id.
  Future<void> upsertTask(SyncTask task);

  /// Returns a task by [id], or `null` when not found.
  Future<SyncTask?> getTaskById(String id);

  /// Returns pending tasks, optionally scoped by [userId], [tenantId], and [limit].
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  });

  /// Returns retryable tasks due at [now] (defaults to current clock in impl).
  Future<List<SyncTask>> getRetryableTasks({
    String? userId,
    String? tenantId,
    DateTime? now,
    int? limit,
  });

  /// Returns failed tasks, optionally filtered by user/tenant and constrained by [limit].
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  });

  /// Returns tasks for [status], optionally scoped by user/tenant and [limit].
  Future<List<SyncTask>> getTasksByStatus(
    SyncTaskStatus status, {
    String? userId,
    String? tenantId,
    int? limit,
  });

  /// Deletes a task by [id]. Implementations may treat missing ids as no-op.
  Future<void> deleteTask(String id);

  /// Clears tasks in `synced` status, optionally scoped by user/tenant.
  Future<void> clearSynced({
    String? userId,
    String? tenantId,
  });

  /// Clears all tasks, optionally scoped by user/tenant.
  Future<void> clearAll({
    String? userId,
    String? tenantId,
  });

  /// Returns per-status counts, optionally scoped by user/tenant.
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  });

  /// Watches task list changes, optionally scoped by user/tenant.
  ///
  /// Returned streams should be broadcast-capable for safe multi-listener usage.
  Stream<List<SyncTask>> watchTasks({
    String? userId,
    String? tenantId,
  });

  /// Watches per-status count changes, optionally scoped by user/tenant.
  ///
  /// Returned streams should be broadcast-capable for safe multi-listener usage.
  Stream<Map<SyncTaskStatus, int>> watchCountByStatus({
    String? userId,
    String? tenantId,
  });

  /// Releases adapter resources.
  Future<void> close();
}
