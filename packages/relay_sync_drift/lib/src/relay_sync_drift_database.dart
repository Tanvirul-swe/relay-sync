import 'package:drift/drift.dart';

part 'relay_sync_drift_database.g.dart';

@DataClassName('SyncTaskRow')
@TableIndex(name: 'idx_sync_tasks_status', columns: {#status})
@TableIndex(name: 'idx_sync_tasks_userId', columns: {#userId})
@TableIndex(name: 'idx_sync_tasks_tenantId', columns: {#tenantId})
@TableIndex(name: 'idx_sync_tasks_nextRetryAt', columns: {#nextRetryAt})
@TableIndex(name: 'idx_sync_tasks_priority', columns: {#priority})
@TableIndex(name: 'idx_sync_tasks_createdAt', columns: {#createdAt})
@TableIndex(name: 'idx_sync_tasks_dedupeKey', columns: {#dedupeKey})
class SyncTasks extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get tenantId => text().nullable()();
  TextColumn get method => text()();
  TextColumn get endpoint => text()();
  TextColumn get body => text()();
  TextColumn get headers => text()();
  TextColumn get metadata => text()();
  TextColumn get status => text()();
  IntColumn get priority => integer()();
  IntColumn get retryCount => integer()();
  IntColumn get maxRetries => integer()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get lastAttemptAt => text().nullable()();
  TextColumn get nextRetryAt => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  TextColumn get dedupeKey => text().nullable()();
  TextColumn get dependsOnTaskIds => text()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityLocalId => text().nullable()();
  TextColumn get entityRemoteId => text().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[SyncTasks])
class RelaySyncDriftDatabase extends _$RelaySyncDriftDatabase {
  RelaySyncDriftDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
