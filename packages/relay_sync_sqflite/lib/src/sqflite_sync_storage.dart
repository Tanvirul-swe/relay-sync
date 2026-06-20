import 'dart:async';
import 'dart:convert';

import 'package:relay_sync/relay_sync.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'default_database_factory_stub.dart'
    if (dart.library.ui) 'default_database_factory_sqflite.dart';

/// Migration callback for [SqfliteSyncStorage].
typedef SqfliteSyncMigration = FutureOr<void> Function(
  Database database,
  int oldVersion,
  int newVersion,
);

/// Sqflite-backed [SyncStorageAdapter].
class SqfliteSyncStorage implements SyncStorageAdapter {
  /// Creates a storage adapter that opens [databasePath].
  SqfliteSyncStorage({
    required String databasePath,
    DatabaseFactory? databaseFactory,
    int version = 1,
    List<SqfliteSyncMigration> migrations = const <SqfliteSyncMigration>[],
  })  : _databasePath = databasePath,
        _databaseFactory = databaseFactory,
        _version = version,
        _migrations = migrations;

  static const String tableName = 'sync_tasks';

  final String _databasePath;
  final DatabaseFactory? _databaseFactory;
  final int _version;
  final List<SqfliteSyncMigration> _migrations;

  final StreamController<void> _tasksChanged =
      StreamController<void>.broadcast();
  final StreamController<void> _countsChanged =
      StreamController<void>.broadcast();

  Database? _database;
  bool _closed = false;

  @override
  Future<void> initialize() async {
    if (_database != null) {
      return;
    }
    if (_closed) {
      throw const RelaySyncException(message: 'SqfliteSyncStorage is closed.');
    }

    final factory = _databaseFactory ?? defaultDatabaseFactory();
    _database = await factory.openDatabase(
      _databasePath,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (database, version) async {
          await _createSchema(database);
          for (final migration in _migrations) {
            await migration(database, 0, version);
          }
        },
        onUpgrade: (database, oldVersion, newVersion) async {
          await _createSchema(database);
          for (final migration in _migrations) {
            await migration(database, oldVersion, newVersion);
          }
        },
      ),
    );
    _emitState();
  }

  @override
  Future<void> saveTask(SyncTask task) async {
    final database = _ensureUsable();
    try {
      await database.insert(tableName, _taskToRow(task));
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw RelaySyncException(
          message: 'Task with id `${task.id}` already exists.',
          cause: error,
        );
      }
      rethrow;
    }
    _emitState();
  }

  @override
  Future<void> updateTask(SyncTask task) async {
    final database = _ensureUsable();
    final updated = await database.update(
      tableName,
      _taskToRow(task),
      where: 'id = ?',
      whereArgs: <Object?>[task.id],
    );
    if (updated == 0) {
      throw RelaySyncException(
        message: 'Task with id `${task.id}` does not exist.',
      );
    }
    _emitState();
  }

  @override
  Future<void> upsertTask(SyncTask task) async {
    final database = _ensureUsable();
    await database.insert(
      tableName,
      _taskToRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _emitState();
  }

  @override
  Future<SyncTask?> getTaskById(String id) async {
    final database = _ensureUsable();
    final rows = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _taskFromRow(rows.single);
  }

  @override
  Future<List<SyncTask>> getPendingTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) {
    return _queryTasks(
      whereParts: <String>['status = ?'],
      whereArgs: <Object?>[SyncTaskStatus.pending.name],
      userId: userId,
      tenantId: tenantId,
      limit: limit,
      orderBy: 'priority DESC, createdAt ASC',
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
      whereParts: <String>[
        'status IN (?, ?)',
        '(nextRetryAt IS NULL OR nextRetryAt <= ?)',
      ],
      whereArgs: <Object?>[
        SyncTaskStatus.retryScheduled.name,
        SyncTaskStatus.failedRetryable.name,
        effectiveNow.toIso8601String(),
      ],
      userId: userId,
      tenantId: tenantId,
      limit: limit,
      orderBy: 'priority DESC, createdAt ASC',
    );
  }

  @override
  Future<List<SyncTask>> getFailedTasks({
    String? userId,
    String? tenantId,
    int? limit,
  }) {
    return _queryTasks(
      whereParts: <String>['status IN (?, ?)'],
      whereArgs: <Object?>[
        SyncTaskStatus.failedRetryable.name,
        SyncTaskStatus.failedPermanent.name,
      ],
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
      whereParts: <String>['status = ?'],
      whereArgs: <Object?>[status.name],
      userId: userId,
      tenantId: tenantId,
      limit: limit,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final database = _ensureUsable();
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    _emitState();
  }

  @override
  Future<void> clearSynced({
    String? userId,
    String? tenantId,
  }) async {
    final database = _ensureUsable();
    final filter = _buildWhere(
      whereParts: <String>['status = ?'],
      whereArgs: <Object?>[SyncTaskStatus.synced.name],
      userId: userId,
      tenantId: tenantId,
    );
    await database.delete(
      tableName,
      where: filter.where,
      whereArgs: filter.args,
    );
    _emitState();
  }

  @override
  Future<void> clearAll({
    String? userId,
    String? tenantId,
  }) async {
    final database = _ensureUsable();
    final filter = _buildWhere(userId: userId, tenantId: tenantId);
    await database.delete(
      tableName,
      where: filter.where,
      whereArgs: filter.args,
    );
    _emitState();
  }

  @override
  Future<Map<SyncTaskStatus, int>> countByStatus({
    String? userId,
    String? tenantId,
  }) async {
    final database = _ensureUsable();
    final filter = _buildWhere(userId: userId, tenantId: tenantId);
    final rows = await database.query(
      tableName,
      columns: <String>['status', 'COUNT(*) AS count'],
      where: filter.where,
      whereArgs: filter.args,
      groupBy: 'status',
    );

    final counts = <SyncTaskStatus, int>{};
    for (final row in rows) {
      counts[SyncTaskStatusJson.fromJson(row['status']! as String)] =
          row['count']! as int;
    }
    return counts;
  }

  @override
  Stream<List<SyncTask>> watchTasks({
    String? userId,
    String? tenantId,
  }) {
    _ensureUsable();
    return Stream<List<SyncTask>>.multi((controller) {
      Future<void> emit() async {
        try {
          final tasks = await _queryTasks(userId: userId, tenantId: tenantId);
          if (!controller.isClosed && !_closed) {
            controller.add(tasks);
          }
        } catch (error, stackTrace) {
          if (!controller.isClosed && !_closed) {
            controller.addError(error, stackTrace);
          }
        }
      }

      unawaited(emit());
      final subscription = _tasksChanged.stream.listen((_) {
        unawaited(emit());
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
      Future<void> emit() async {
        try {
          final counts =
              await countByStatus(userId: userId, tenantId: tenantId);
          if (!controller.isClosed && !_closed) {
            controller.add(counts);
          }
        } catch (error, stackTrace) {
          if (!controller.isClosed && !_closed) {
            controller.addError(error, stackTrace);
          }
        }
      }

      unawaited(emit());
      final subscription = _countsChanged.stream.listen((_) {
        unawaited(emit());
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
    final database = _database;
    _database = null;
    if (database != null) {
      await database.close();
    }
    await _tasksChanged.close();
    await _countsChanged.close();
  }

  Future<List<SyncTask>> _queryTasks({
    List<String> whereParts = const <String>[],
    List<Object?> whereArgs = const <Object?>[],
    String? userId,
    String? tenantId,
    int? limit,
    String? orderBy,
  }) async {
    final database = _ensureUsable();
    final filter = _buildWhere(
      whereParts: whereParts,
      whereArgs: whereArgs,
      userId: userId,
      tenantId: tenantId,
    );
    final rows = await database.query(
      tableName,
      where: filter.where,
      whereArgs: filter.args,
      orderBy: orderBy,
      limit: limit,
    );
    return rows.map(_taskFromRow).toList(growable: false);
  }

  _WhereClause _buildWhere({
    List<String> whereParts = const <String>[],
    List<Object?> whereArgs = const <Object?>[],
    String? userId,
    String? tenantId,
  }) {
    final parts = <String>[...whereParts];
    final args = <Object?>[...whereArgs];

    if (userId != null) {
      parts.add('userId = ?');
      args.add(userId);
    }
    if (tenantId != null) {
      parts.add('tenantId = ?');
      args.add(tenantId);
    }

    return _WhereClause(
      where: parts.isEmpty ? null : parts.join(' AND '),
      args: args.isEmpty ? null : args,
    );
  }

  Database _ensureUsable() {
    if (_closed) {
      throw const RelaySyncException(message: 'SqfliteSyncStorage is closed.');
    }
    final database = _database;
    if (database == null) {
      throw const RelaySyncException(
        message: 'SqfliteSyncStorage is not initialized.',
      );
    }
    return database;
  }

  Future<void> _createSchema(Database database) async {
    await database.execute('''
CREATE TABLE IF NOT EXISTS $tableName (
  id TEXT PRIMARY KEY NOT NULL,
  userId TEXT,
  tenantId TEXT,
  method TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  body TEXT NOT NULL,
  headers TEXT NOT NULL,
  metadata TEXT NOT NULL,
  status TEXT NOT NULL,
  priority INTEGER NOT NULL,
  retryCount INTEGER NOT NULL,
  maxRetries INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  lastAttemptAt TEXT,
  nextRetryAt TEXT,
  idempotencyKey TEXT,
  dedupeKey TEXT,
  dependsOnTaskIds TEXT NOT NULL,
  entityType TEXT,
  entityLocalId TEXT,
  entityRemoteId TEXT,
  lastError TEXT
)
''');

    await _createIndex(database, 'status');
    await _createIndex(database, 'userId');
    await _createIndex(database, 'tenantId');
    await _createIndex(database, 'nextRetryAt');
    await _createIndex(database, 'priority');
    await _createIndex(database, 'createdAt');
    await _createIndex(database, 'dedupeKey');
  }

  Future<void> _createIndex(Database database, String column) {
    return database.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_tasks_$column ON $tableName ($column)',
    );
  }

  Map<String, Object?> _taskToRow(SyncTask task) {
    return <String, Object?>{
      'id': task.id,
      'userId': task.userId,
      'tenantId': task.tenantId,
      'method': task.method.name,
      'endpoint': task.endpoint,
      'body': jsonEncode(task.body),
      'headers': jsonEncode(task.headers),
      'metadata': jsonEncode(task.metadata.toJson()),
      'status': task.status.name,
      'priority': task.priority.index,
      'retryCount': task.retryCount,
      'maxRetries': task.maxRetries,
      'createdAt': task.createdAt.toIso8601String(),
      'updatedAt': task.updatedAt.toIso8601String(),
      'lastAttemptAt': task.lastAttemptAt?.toIso8601String(),
      'nextRetryAt': task.nextRetryAt?.toIso8601String(),
      'idempotencyKey': task.idempotencyKey,
      'dedupeKey': task.dedupeKey,
      'dependsOnTaskIds': jsonEncode(task.dependsOnTaskIds),
      'entityType': task.entityType,
      'entityLocalId': task.entityLocalId,
      'entityRemoteId': task.entityRemoteId,
      'lastError':
          task.lastError == null ? null : jsonEncode(task.lastError!.toJson()),
    };
  }

  SyncTask _taskFromRow(Map<String, Object?> row) {
    return SyncTask(
      id: row['id']! as String,
      userId: row['userId'] as String?,
      tenantId: row['tenantId'] as String?,
      method: SyncMethodJson.fromJson(row['method']! as String),
      endpoint: row['endpoint']! as String,
      body: Map<String, Object?>.from(
        jsonDecode(row['body']! as String) as Map<Object?, Object?>,
      ),
      headers: Map<String, String>.from(
        jsonDecode(row['headers']! as String) as Map<Object?, Object?>,
      ),
      metadata: SyncMetadata.fromJson(
        Map<String, Object?>.from(
          jsonDecode(row['metadata']! as String) as Map<Object?, Object?>,
        ),
      ),
      status: SyncTaskStatusJson.fromJson(row['status']! as String),
      priority: SyncPriority.values[row['priority']! as int],
      retryCount: row['retryCount']! as int,
      maxRetries: row['maxRetries']! as int,
      createdAt: DateTime.parse(row['createdAt']! as String),
      updatedAt: DateTime.parse(row['updatedAt']! as String),
      lastAttemptAt: row['lastAttemptAt'] == null
          ? null
          : DateTime.parse(row['lastAttemptAt']! as String),
      nextRetryAt: row['nextRetryAt'] == null
          ? null
          : DateTime.parse(row['nextRetryAt']! as String),
      idempotencyKey: row['idempotencyKey'] as String?,
      dedupeKey: row['dedupeKey'] as String?,
      dependsOnTaskIds: List<String>.from(
        jsonDecode(row['dependsOnTaskIds']! as String) as List<Object?>,
      ),
      entityType: row['entityType'] as String?,
      entityLocalId: row['entityLocalId'] as String?,
      entityRemoteId: row['entityRemoteId'] as String?,
      lastError: row['lastError'] == null
          ? null
          : SyncError.fromJson(
              Map<String, Object?>.from(
                jsonDecode(row['lastError']! as String)
                    as Map<Object?, Object?>,
              ),
            ),
    );
  }

  void _emitState() {
    if (_closed) {
      return;
    }
    _tasksChanged.add(null);
    _countsChanged.add(null);
  }
}

class _WhereClause {
  const _WhereClause({required this.where, required this.args});

  final String? where;
  final List<Object?>? args;
}
