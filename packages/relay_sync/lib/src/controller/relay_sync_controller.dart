import '../engine/relay_sync_engine.dart';
import '../logging/log_redaction.dart';
import '../logging/relay_sync_logger.dart';
import '../models/relay_sync_exception.dart';
import '../models/sync_enums.dart';
import '../models/sync_metadata.dart';
import '../models/sync_task.dart';

/// Generates task identifiers for helper enqueue APIs.
typedef TaskIdGenerator = String Function();

/// Developer-facing API for enqueueing and orchestrating sync work.
///
/// This controller wraps [RelaySyncEngine] and exposes ergonomic helper methods
/// for common HTTP verbs while keeping task persistence and syncing centralized
/// in the engine.
class RelaySyncController {
  /// Creates a controller for [engine].
  ///
  /// Provide [taskIdGenerator] to customize task IDs created by helper methods.
  RelaySyncController({
    required this.engine,
    TaskIdGenerator? taskIdGenerator,
  }) : _taskIdGenerator = taskIdGenerator;

  /// Wrapped sync engine.
  final RelaySyncEngine engine;

  final TaskIdGenerator? _taskIdGenerator;
  int _idCounter = 0;

  /// Initializes the wrapped engine.
  Future<void> initialize() => engine.initialize();

  /// Enqueues a fully constructed [task].
  Future<void> enqueue(SyncTask task) async {
    await engine.enqueue(task);
    engine.config.metrics?.increment('taskEnqueued');
    engine.config.logger?.log(
      RelaySyncLogLevel.info,
      'taskEnqueued',
      context: <String, Object?>{
        'taskId': task.id,
        'method': task.method.name,
        'endpoint': task.endpoint,
        'headers': LogRedaction.redactHeaders(task.headers),
      },
    );
  }

  /// Creates and enqueues a GET task.
  Future<SyncTask> get(
    String endpoint, {
    String? id,
    String? userId,
    String? tenantId,
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) {
    return _enqueueWithMethod(
      method: SyncMethod.get,
      endpoint: endpoint,
      id: id,
      userId: userId,
      tenantId: tenantId,
      headers: headers,
      priority: priority,
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
      tags: tags,
    );
  }

  /// Creates and enqueues a POST task.
  Future<SyncTask> post(
    String endpoint, {
    String? id,
    String? userId,
    String? tenantId,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) {
    return _enqueueWithMethod(
      method: SyncMethod.post,
      endpoint: endpoint,
      id: id,
      userId: userId,
      tenantId: tenantId,
      body: body,
      headers: headers,
      priority: priority,
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
      tags: tags,
    );
  }

  /// Creates and enqueues a PUT task.
  Future<SyncTask> put(
    String endpoint, {
    String? id,
    String? userId,
    String? tenantId,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) {
    return _enqueueWithMethod(
      method: SyncMethod.put,
      endpoint: endpoint,
      id: id,
      userId: userId,
      tenantId: tenantId,
      body: body,
      headers: headers,
      priority: priority,
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
      tags: tags,
    );
  }

  /// Creates and enqueues a PATCH task.
  Future<SyncTask> patch(
    String endpoint, {
    String? id,
    String? userId,
    String? tenantId,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) {
    return _enqueueWithMethod(
      method: SyncMethod.patch,
      endpoint: endpoint,
      id: id,
      userId: userId,
      tenantId: tenantId,
      body: body,
      headers: headers,
      priority: priority,
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
      tags: tags,
    );
  }

  /// Creates and enqueues a DELETE task.
  Future<SyncTask> delete(
    String endpoint, {
    String? id,
    String? userId,
    String? tenantId,
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) {
    return _enqueueWithMethod(
      method: SyncMethod.delete,
      endpoint: endpoint,
      id: id,
      userId: userId,
      tenantId: tenantId,
      headers: headers,
      priority: priority,
      maxRetries: maxRetries,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
      tags: tags,
    );
  }

  /// Triggers an immediate sync pass.
  Future<void> syncNow() => engine.syncNow();

  /// Pauses sync processing.
  Future<void> pause() => engine.pause();

  /// Resumes sync processing.
  Future<void> resume() => engine.resume();

  /// Marks a queued task as cancelled.
  Future<void> cancelTask(String taskId) async {
    final task = await engine.storage.getTaskById(taskId);
    if (task == null) {
      throw RelaySyncException(message: 'Task `$taskId` was not found.');
    }

    await engine.storage.upsertTask(
      task.copyWith(
        status: SyncTaskStatus.cancelled,
        updatedAt: DateTime.now().toUtc(),
        nextRetryAt: null,
      ),
    );
  }

  /// Moves a task back to pending state for another attempt.
  Future<void> retryTask(String taskId) async {
    final task = await engine.storage.getTaskById(taskId);
    if (task == null) {
      throw RelaySyncException(message: 'Task `$taskId` was not found.');
    }

    await engine.storage.upsertTask(
      task.copyWith(
        status: SyncTaskStatus.pending,
        updatedAt: DateTime.now().toUtc(),
        nextRetryAt: null,
      ),
    );
  }

  /// Retries all failed tasks in the configured scope.
  Future<void> retryAllFailed() async {
    final failedTasks = await engine.storage.getFailedTasks(
      userId: engine.config.userId,
      tenantId: engine.config.tenantId,
    );

    final now = DateTime.now().toUtc();
    for (final task in failedTasks) {
      await engine.storage.upsertTask(
        task.copyWith(
          status: SyncTaskStatus.pending,
          updatedAt: now,
          nextRetryAt: null,
        ),
      );
    }
  }

  /// Clears all synced tasks in the configured scope.
  Future<void> clearSynced() {
    return engine.storage.clearSynced(
      userId: engine.config.userId,
      tenantId: engine.config.tenantId,
    );
  }

  /// Watches tasks in the configured scope.
  Stream<List<SyncTask>> watchTasks() {
    return engine.storage.watchTasks(
      userId: engine.config.userId,
      tenantId: engine.config.tenantId,
    );
  }

  /// Watches per-status task counts in the configured scope.
  Stream<Map<SyncTaskStatus, int>> watchStatusCounts() {
    return engine.storage.watchCountByStatus(
      userId: engine.config.userId,
      tenantId: engine.config.tenantId,
    );
  }

  /// Watches engine lifecycle state changes.
  Stream<RelaySyncState> watchState() => engine.states;

  /// Disposes the wrapped engine.
  Future<void> dispose() => engine.dispose();

  Future<SyncTask> _enqueueWithMethod({
    required SyncMethod method,
    required String endpoint,
    String? id,
    String? userId,
    String? tenantId,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    SyncPriority priority = SyncPriority.normal,
    int? maxRetries,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    Map<String, String> tags = const <String, String>{},
  }) async {
    final taskId = id ?? _createTaskId();
    final now = DateTime.now().toUtc();

    final task = SyncTask(
      id: taskId,
      userId: userId,
      tenantId: tenantId,
      method: method,
      endpoint: endpoint,
      body: body,
      headers: headers,
      metadata: SyncMetadata(
        taskId: taskId,
        method: method,
        userId: userId,
        tenantId: tenantId,
        priority: priority,
        maxAttempts: maxRetries ?? engine.config.maxRetries,
        dependsOnTaskIds: dependsOnTaskIds,
        tags: tags,
      ),
      priority: priority,
      maxRetries: maxRetries ?? engine.config.maxRetries,
      createdAt: now,
      updatedAt: now,
      dedupeKey: dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds,
    );

    await enqueue(task);
    return task;
  }

  String _createTaskId() {
    if (_taskIdGenerator != null) {
      return _taskIdGenerator!();
    }
    _idCounter += 1;
    return 'task-${DateTime.now().toUtc().microsecondsSinceEpoch}-$_idCounter';
  }
}
