import 'dart:async';

import '../auth/auth_hooks.dart';
import '../client/sync_client.dart';
import '../config/relay_sync_config.dart';
import '../logging/log_redaction.dart';
import '../logging/relay_sync_logger.dart';
import '../models/relay_sync_exception.dart';
import '../models/sync_enums.dart';
import '../models/sync_error.dart';
import '../models/sync_response.dart';
import '../models/sync_task.dart';
import '../network/network_monitor.dart';
import '../storage/sync_storage_adapter.dart';


/// High-level lifecycle states for [RelaySyncEngine].
enum RelaySyncState {
  /// Engine is initialized and idle.
  idle,

  /// Engine is actively syncing.
  syncing,

  /// Engine is initialized but paused.
  paused,

  /// Engine has been disposed.
  disposed,
}

/// Basic relay_sync engine lifecycle and orchestration.
class RelaySyncEngine {
  /// Creates a new engine instance.
  RelaySyncEngine({
    required this.storage,
    required this.client,
    required this.networkMonitor,
    required this.config,
    this.authHeaderProvider,
    this.tokenRefreshHandler,
  });

  /// Task storage adapter.
  final SyncStorageAdapter storage;

  /// Sync request execution client.
  final SyncClient client;

  /// Network monitor for online/offline events.
  final NetworkMonitor networkMonitor;

  /// Runtime engine configuration.
  final RelaySyncConfig config;

  /// Optional dynamic auth header provider.
  final AuthHeaderProvider? authHeaderProvider;

  /// Optional token refresh callback.
  final TokenRefreshHandler? tokenRefreshHandler;

  final StreamController<RelaySyncState> _stateController =
      StreamController<RelaySyncState>.broadcast();

  StreamSubscription<bool>? _networkSubscription;
  bool _initialized = false;
  bool _disposed = false;
  bool _paused = false;
  bool _isSyncing = false;

  /// Emits lifecycle state changes.
  Stream<RelaySyncState> get states => _stateController.stream;

  /// Initializes engine dependencies and optional startup behaviors.
  Future<void> initialize() async {
    _ensureNotDisposed();
    if (_initialized) {
      return;
    }

    await storage.initialize();

    if (config.syncOnNetworkRestore) {
      _networkSubscription = networkMonitor.onStatusChanged.listen((isOnline) {
        if (isOnline) {
          unawaited(syncNow());
        }
      });
    }

    _initialized = true;
    _emitState(RelaySyncState.idle);

    if (config.syncOnStart && await networkMonitor.hasReliableConnection) {
      await syncNow();
    }
  }

  /// Enqueues [task] for future sync.
  Future<void> enqueue(SyncTask task) async {
    _ensureInitialized();

    if (config.enableDeduplication &&
        config.deduplicationStrategy != DeduplicationStrategy.allowDuplicates &&
        task.dedupeKey != null &&
        task.dedupeKey!.trim().isNotEmpty) {
      final pendingTasks = await storage.getPendingTasks(
        userId: task.userId,
        tenantId: task.tenantId,
      );
      final duplicates = pendingTasks
          .where((existing) => existing.dedupeKey == task.dedupeKey && existing.id != task.id)
          .toList(growable: false);

      if (duplicates.isNotEmpty) {
        if (config.deduplicationStrategy == DeduplicationStrategy.keepFirst) {
          return;
        }

        for (final duplicate in duplicates) {
          await storage.deleteTask(duplicate.id);
        }
      }
    }

    await storage.upsertTask(task);
    if (!_paused && config.autoSync) {
      unawaited(syncNow());
    }
  }

  /// Runs a best-effort sync pass.
  Future<void> syncNow() async {
    _ensureInitialized();
    if (_paused || _isSyncing) {
      return;
    }

    final startedAt = DateTime.now().toUtc();
    _metric('syncStarted');
    _log(RelaySyncLogLevel.info, 'syncStarted');

    _isSyncing = true;
    _emitState(RelaySyncState.syncing);

    try {
      final isOnline = await networkMonitor.hasReliableConnection;
      if (!isOnline) {
        return;
      }

      final tasks = await _loadDueTasks();
      if (tasks.isEmpty) {
        return;
      }

      final concurrency = config.maxConcurrentTasks;
      for (var i = 0; i < tasks.length; i += concurrency) {
        if (_paused || _disposed) {
          break;
        }
        final end = (i + concurrency) > tasks.length ? tasks.length : i + concurrency;
        final chunk = tasks.sublist(i, end);
        await Future.wait(chunk.map(_processTask));
      }
    } finally {
      _isSyncing = false;
      _metric('syncCompleted');
      config.metrics?.timing('syncDuration', DateTime.now().toUtc().difference(startedAt));
      _log(RelaySyncLogLevel.info, 'syncCompleted');

      if (!_disposed) {
        _emitState(_paused ? RelaySyncState.paused : RelaySyncState.idle);
      }
    }
  }

  /// Pauses automatic/manual sync execution.
  Future<void> pause() async {
    _ensureInitialized();
    _paused = true;
    _metric('syncPaused');
    _log(RelaySyncLogLevel.info, 'syncPaused');
    _emitState(RelaySyncState.paused);
  }

  /// Resumes sync execution.
  Future<void> resume() async {
    _ensureInitialized();
    _paused = false;
    _metric('syncResumed');
    _log(RelaySyncLogLevel.info, 'syncResumed');
    _emitState(RelaySyncState.idle);
  }

  /// Disposes engine resources.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _paused = false;

    await _networkSubscription?.cancel();
    await storage.close();
    await networkMonitor.dispose();

    _emitState(RelaySyncState.disposed);
    await _stateController.close();
  }

  Future<List<SyncTask>> _loadDueTasks() async {
    final pending = await storage.getPendingTasks(
      userId: config.userId,
      tenantId: config.tenantId,
    );
    final retryable = await storage.getRetryableTasks(
      userId: config.userId,
      tenantId: config.tenantId,
      now: DateTime.now().toUtc(),
    );

    final mergedById = <String, SyncTask>{
      for (final task in pending) task.id: task,
      for (final task in retryable) task.id: task,
    };

    final candidates = mergedById.values.toList(growable: false)
      ..sort(_priorityThenCreatedAtComparator);

    final readyTasks = <SyncTask>[];
    for (final task in candidates) {
      if (readyTasks.length >= config.maxConcurrentTasks) {
        break;
      }
      if (await _shouldProcessTask(task)) {
        readyTasks.add(task);
      }
    }
    return readyTasks;
  }

  Future<bool> _shouldProcessTask(SyncTask task) async {
    if (!config.enableDependencyOrdering || task.dependsOnTaskIds.isEmpty) {
      return true;
    }

    for (final dependencyId in task.dependsOnTaskIds) {
      final dependencyTask = await storage.getTaskById(dependencyId);
      if (dependencyTask == null) {
        return false;
      }
      if (dependencyTask.status == SyncTaskStatus.synced) {
        continue;
      }

      if (dependencyTask.status == SyncTaskStatus.failedPermanent ||
          dependencyTask.status == SyncTaskStatus.cancelled) {
        await _markFailedDueToDependency(task, dependencyTask);
      }
      return false;
    }

    return true;
  }

  Future<void> _markFailedDueToDependency(SyncTask task, SyncTask dependencyTask) async {
    final updated = task.copyWith(
      status: SyncTaskStatus.failedPermanent,
      updatedAt: DateTime.now().toUtc(),
      nextRetryAt: null,
      lastError: SyncError(
        code: 'dependency_failed',
        message:
            'Dependency `${dependencyTask.id}` is ${dependencyTask.status.name}; task cannot be synced.',
        details: <String, Object?>{
          'dependencyId': dependencyTask.id,
          'dependencyStatus': dependencyTask.status.name,
        },
      ),
    );
    await storage.upsertTask(updated);
    _metric('taskFailedPermanent');
    _log(RelaySyncLogLevel.warning, 'taskFailedPermanent', context: <String, Object?>{
      'taskId': task.id,
      'reason': 'dependency_failed',
    });
  }

  Future<void> _processTask(SyncTask originalTask) async {
    if (_disposed) {
      return;
    }

    final startedAt = DateTime.now().toUtc();
    var task = originalTask.copyWith(
      status: SyncTaskStatus.syncing,
      updatedAt: startedAt,
      lastAttemptAt: startedAt,
      nextRetryAt: null,
    );
    await storage.upsertTask(task);

    _metric('taskSyncStarted');
    _log(
      RelaySyncLogLevel.info,
      'taskSyncStarted',
      context: <String, Object?>{'taskId': task.id, 'endpoint': task.endpoint},
    );

    try {
      var response = await _executeTask(task);

      if (_isUnauthorized(response.statusCode) && tokenRefreshHandler != null) {
        final didRefresh = await tokenRefreshHandler!();
        if (didRefresh) {
          response = await _executeTask(task);
        }
      }

      task = await _applyResponse(task, response);
    } catch (error, stackTrace) {
      task = await _handleTransportError(task, error, stackTrace);
    }

    if (!config.continueOnTaskFailure &&
        (task.status == SyncTaskStatus.failedPermanent ||
            task.status == SyncTaskStatus.failedRetryable ||
            task.status == SyncTaskStatus.conflict)) {
      _paused = true;
      _metric('syncPaused');
      _log(RelaySyncLogLevel.warning, 'syncPaused');
      _emitState(RelaySyncState.paused);
    }
  }

  Future<SyncResponse> _executeTask(SyncTask task) async {
    final dynamicHeaders = authHeaderProvider == null
        ? const <String, String>{}
        : await authHeaderProvider!();

    final headers = <String, String>{
      ...config.defaultHeaders,
      ...task.headers,
      ...dynamicHeaders,
    };

    return client.execute(task, headers: headers);
  }

  Future<SyncTask> _applyResponse(SyncTask task, SyncResponse response) async {
    if (_isSuccess(response.statusCode)) {
      final syncedTask = task.copyWith(
        status: SyncTaskStatus.synced,
        updatedAt: DateTime.now().toUtc(),
        lastError: null,
      );
      if (config.deleteSyncedTasks) {
        await storage.deleteTask(task.id);
      } else {
        await storage.upsertTask(syncedTask);
      }
      _metric('taskSynced');
      _log(RelaySyncLogLevel.info, 'taskSynced', context: <String, Object?>{'taskId': task.id});
      return syncedTask;
    }

    if (_isConflict(response.statusCode)) {
      final conflictTask = task.copyWith(
        status: SyncTaskStatus.conflict,
        updatedAt: DateTime.now().toUtc(),
        nextRetryAt: null,
        lastError: SyncError(
          code: 'conflict',
          message: 'Server returned conflict (${response.statusCode}).',
          details: <String, Object?>{'statusCode': response.statusCode},
        ),
      );
      await storage.upsertTask(conflictTask);
      _metric('taskConflict');
      _log(RelaySyncLogLevel.warning, 'taskConflict', context: <String, Object?>{'taskId': task.id});
      return conflictTask;
    }

    if (_isRetryableStatus(response.statusCode)) {
      return _markRetryableFailure(
        task,
        error: SyncError(
          code: 'http_retryable',
          message: 'Retryable server response (${response.statusCode}).',
          details: <String, Object?>{'statusCode': response.statusCode},
        ),
      );
    }

    final permanentTask = task.copyWith(
      status: SyncTaskStatus.failedPermanent,
      updatedAt: DateTime.now().toUtc(),
      nextRetryAt: null,
      lastError: SyncError(
        code: 'http_permanent',
        message: 'Permanent server response (${response.statusCode}).',
        details: <String, Object?>{'statusCode': response.statusCode},
      ),
    );
    await storage.upsertTask(permanentTask);
    _metric('taskFailedPermanent');
    _log(RelaySyncLogLevel.error, 'taskFailedPermanent', context: <String, Object?>{'taskId': task.id});
    return permanentTask;
  }

  Future<SyncTask> _handleTransportError(
    SyncTask task,
    Object error,
    StackTrace stackTrace,
  ) {
    return _markRetryableFailure(
      task,
      error: SyncError(
        code: 'transport_error',
        message: 'Transport error during sync.',
        details: <String, Object?>{
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        },
      ),
    );
  }

  Future<SyncTask> _markRetryableFailure(
    SyncTask task, {
    required SyncError error,
  }) async {
    final nextRetryCount = task.retryCount + 1;
    final effectiveMaxRetries = task.maxRetries < config.maxRetries
        ? task.maxRetries
        : config.maxRetries;
    final now = DateTime.now().toUtc();

    if (!config.retryPolicy.shouldRetry(
      retryCount: nextRetryCount,
      maxRetries: effectiveMaxRetries,
    )) {
      final failedTask = task.copyWith(
        status: SyncTaskStatus.failedRetryable,
        retryCount: nextRetryCount,
        nextRetryAt: null,
        updatedAt: now,
        lastError: error,
      );
      await storage.upsertTask(failedTask);
      _metric('taskFailedPermanent');
      _log(RelaySyncLogLevel.error, 'taskFailedPermanent', context: <String, Object?>{'taskId': task.id});
      return failedTask;
    }

    final nextRetryAt = config.retryPolicy.nextRetryAt(
      now: now,
      retryCount: nextRetryCount,
      maxRetries: effectiveMaxRetries,
    );

    final scheduledTask = task.copyWith(
      status: nextRetryAt == null
          ? SyncTaskStatus.failedRetryable
          : SyncTaskStatus.retryScheduled,
      retryCount: nextRetryCount,
      nextRetryAt: nextRetryAt,
      updatedAt: now,
      lastError: error,
    );
    await storage.upsertTask(scheduledTask);

    if (scheduledTask.status == SyncTaskStatus.retryScheduled) {
      _metric('taskRetryScheduled');
      _log(
        RelaySyncLogLevel.warning,
        'taskRetryScheduled',
        context: <String, Object?>{'taskId': task.id, 'nextRetryAt': scheduledTask.nextRetryAt},
      );
    } else {
      _metric('taskFailedPermanent');
      _log(RelaySyncLogLevel.error, 'taskFailedPermanent', context: <String, Object?>{'taskId': task.id});
    }

    return scheduledTask;
  }

  int _priorityThenCreatedAtComparator(SyncTask a, SyncTask b) {
    final priorityDiff = b.priority.index.compareTo(a.priority.index);
    if (priorityDiff != 0) {
      return priorityDiff;
    }
    return a.createdAt.compareTo(b.createdAt);
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  bool _isConflict(int statusCode) => statusCode == 409;

  bool _isUnauthorized(int statusCode) => statusCode == 401;

  bool _isRetryableStatus(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;

  void _metric(String name) {
    config.metrics?.increment(name);
  }

  void _log(
    RelaySyncLogLevel level,
    String message, {
    Map<String, Object?> context = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final safeContext = <String, Object?>{};
    context.forEach((key, value) {
      if (key == 'headers' && value is Map<String, String>) {
        safeContext[key] = LogRedaction.redactHeaders(value);
      } else {
        safeContext[key] = value;
      }
    });

    config.logger?.log(
      level,
      message,
      context: safeContext,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _emitState(RelaySyncState state) {
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }

  void _ensureInitialized() {
    _ensureNotDisposed();
    if (!_initialized) {
      throw const RelaySyncException(message: 'RelaySyncEngine is not initialized.');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const RelaySyncException(message: 'RelaySyncEngine is disposed.');
    }
  }
}
