// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relay_sync_drift_database.dart';

// ignore_for_file: type=lint
class $SyncTasksTable extends SyncTasks
    with TableInfo<$SyncTasksTable, SyncTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
      'method', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endpointMeta =
      const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
      'endpoint', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _headersMeta =
      const VerificationMeta('headers');
  @override
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
      'headers', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxRetriesMeta =
      const VerificationMeta('maxRetries');
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
      'max_retries', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<String> lastAttemptAt = GeneratedColumn<String>(
      'last_attempt_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nextRetryAtMeta =
      const VerificationMeta('nextRetryAt');
  @override
  late final GeneratedColumn<String> nextRetryAt = GeneratedColumn<String>(
      'next_retry_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dedupeKeyMeta =
      const VerificationMeta('dedupeKey');
  @override
  late final GeneratedColumn<String> dedupeKey = GeneratedColumn<String>(
      'dedupe_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dependsOnTaskIdsMeta =
      const VerificationMeta('dependsOnTaskIds');
  @override
  late final GeneratedColumn<String> dependsOnTaskIds = GeneratedColumn<String>(
      'depends_on_task_ids', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityLocalIdMeta =
      const VerificationMeta('entityLocalId');
  @override
  late final GeneratedColumn<String> entityLocalId = GeneratedColumn<String>(
      'entity_local_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entityRemoteIdMeta =
      const VerificationMeta('entityRemoteId');
  @override
  late final GeneratedColumn<String> entityRemoteId = GeneratedColumn<String>(
      'entity_remote_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        tenantId,
        method,
        endpoint,
        body,
        headers,
        metadata,
        status,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        updatedAt,
        lastAttemptAt,
        nextRetryAt,
        idempotencyKey,
        dedupeKey,
        dependsOnTaskIds,
        entityType,
        entityLocalId,
        entityRemoteId,
        lastError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<SyncTaskRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    }
    if (data.containsKey('method')) {
      context.handle(_methodMeta,
          method.isAcceptableOrUnknown(data['method']!, _methodMeta));
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta,
          endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('headers')) {
      context.handle(_headersMeta,
          headers.isAcceptableOrUnknown(data['headers']!, _headersMeta));
    } else if (isInserting) {
      context.missing(_headersMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    } else if (isInserting) {
      context.missing(_metadataMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    } else if (isInserting) {
      context.missing(_retryCountMeta);
    }
    if (data.containsKey('max_retries')) {
      context.handle(
          _maxRetriesMeta,
          maxRetries.isAcceptableOrUnknown(
              data['max_retries']!, _maxRetriesMeta));
    } else if (isInserting) {
      context.missing(_maxRetriesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
          _nextRetryAtMeta,
          nextRetryAt.isAcceptableOrUnknown(
              data['next_retry_at']!, _nextRetryAtMeta));
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    }
    if (data.containsKey('dedupe_key')) {
      context.handle(_dedupeKeyMeta,
          dedupeKey.isAcceptableOrUnknown(data['dedupe_key']!, _dedupeKeyMeta));
    }
    if (data.containsKey('depends_on_task_ids')) {
      context.handle(
          _dependsOnTaskIdsMeta,
          dependsOnTaskIds.isAcceptableOrUnknown(
              data['depends_on_task_ids']!, _dependsOnTaskIdsMeta));
    } else if (isInserting) {
      context.missing(_dependsOnTaskIdsMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    }
    if (data.containsKey('entity_local_id')) {
      context.handle(
          _entityLocalIdMeta,
          entityLocalId.isAcceptableOrUnknown(
              data['entity_local_id']!, _entityLocalIdMeta));
    }
    if (data.containsKey('entity_remote_id')) {
      context.handle(
          _entityRemoteIdMeta,
          entityRemoteId.isAcceptableOrUnknown(
              data['entity_remote_id']!, _entityRemoteIdMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncTaskRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id']),
      method: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}method'])!,
      endpoint: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      headers: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}headers'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      maxRetries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_retries'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      lastAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_attempt_at']),
      nextRetryAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}next_retry_at']),
      idempotencyKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}idempotency_key']),
      dedupeKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dedupe_key']),
      dependsOnTaskIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}depends_on_task_ids'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type']),
      entityLocalId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_local_id']),
      entityRemoteId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}entity_remote_id']),
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $SyncTasksTable createAlias(String alias) {
    return $SyncTasksTable(attachedDatabase, alias);
  }
}

class SyncTaskRow extends DataClass implements Insertable<SyncTaskRow> {
  final String id;
  final String? userId;
  final String? tenantId;
  final String method;
  final String endpoint;
  final String body;
  final String headers;
  final String metadata;
  final String status;
  final int priority;
  final int retryCount;
  final int maxRetries;
  final String createdAt;
  final String updatedAt;
  final String? lastAttemptAt;
  final String? nextRetryAt;
  final String? idempotencyKey;
  final String? dedupeKey;
  final String dependsOnTaskIds;
  final String? entityType;
  final String? entityLocalId;
  final String? entityRemoteId;
  final String? lastError;
  const SyncTaskRow(
      {required this.id,
      this.userId,
      this.tenantId,
      required this.method,
      required this.endpoint,
      required this.body,
      required this.headers,
      required this.metadata,
      required this.status,
      required this.priority,
      required this.retryCount,
      required this.maxRetries,
      required this.createdAt,
      required this.updatedAt,
      this.lastAttemptAt,
      this.nextRetryAt,
      this.idempotencyKey,
      this.dedupeKey,
      required this.dependsOnTaskIds,
      this.entityType,
      this.entityLocalId,
      this.entityRemoteId,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || tenantId != null) {
      map['tenant_id'] = Variable<String>(tenantId);
    }
    map['method'] = Variable<String>(method);
    map['endpoint'] = Variable<String>(endpoint);
    map['body'] = Variable<String>(body);
    map['headers'] = Variable<String>(headers);
    map['metadata'] = Variable<String>(metadata);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<String>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<String>(nextRetryAt);
    }
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || dedupeKey != null) {
      map['dedupe_key'] = Variable<String>(dedupeKey);
    }
    map['depends_on_task_ids'] = Variable<String>(dependsOnTaskIds);
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityLocalId != null) {
      map['entity_local_id'] = Variable<String>(entityLocalId);
    }
    if (!nullToAbsent || entityRemoteId != null) {
      map['entity_remote_id'] = Variable<String>(entityRemoteId);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncTasksCompanion toCompanion(bool nullToAbsent) {
    return SyncTasksCompanion(
      id: Value(id),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      tenantId: tenantId == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantId),
      method: Value(method),
      endpoint: Value(endpoint),
      body: Value(body),
      headers: Value(headers),
      metadata: Value(metadata),
      status: Value(status),
      priority: Value(priority),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      dedupeKey: dedupeKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dedupeKey),
      dependsOnTaskIds: Value(dependsOnTaskIds),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityLocalId: entityLocalId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityLocalId),
      entityRemoteId: entityRemoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityRemoteId),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncTaskRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncTaskRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      tenantId: serializer.fromJson<String?>(json['tenantId']),
      method: serializer.fromJson<String>(json['method']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      body: serializer.fromJson<String>(json['body']),
      headers: serializer.fromJson<String>(json['headers']),
      metadata: serializer.fromJson<String>(json['metadata']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      lastAttemptAt: serializer.fromJson<String?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<String?>(json['nextRetryAt']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      dedupeKey: serializer.fromJson<String?>(json['dedupeKey']),
      dependsOnTaskIds: serializer.fromJson<String>(json['dependsOnTaskIds']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityLocalId: serializer.fromJson<String?>(json['entityLocalId']),
      entityRemoteId: serializer.fromJson<String?>(json['entityRemoteId']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String?>(userId),
      'tenantId': serializer.toJson<String?>(tenantId),
      'method': serializer.toJson<String>(method),
      'endpoint': serializer.toJson<String>(endpoint),
      'body': serializer.toJson<String>(body),
      'headers': serializer.toJson<String>(headers),
      'metadata': serializer.toJson<String>(metadata),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'lastAttemptAt': serializer.toJson<String?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<String?>(nextRetryAt),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'dedupeKey': serializer.toJson<String?>(dedupeKey),
      'dependsOnTaskIds': serializer.toJson<String>(dependsOnTaskIds),
      'entityType': serializer.toJson<String?>(entityType),
      'entityLocalId': serializer.toJson<String?>(entityLocalId),
      'entityRemoteId': serializer.toJson<String?>(entityRemoteId),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncTaskRow copyWith(
          {String? id,
          Value<String?> userId = const Value.absent(),
          Value<String?> tenantId = const Value.absent(),
          String? method,
          String? endpoint,
          String? body,
          String? headers,
          String? metadata,
          String? status,
          int? priority,
          int? retryCount,
          int? maxRetries,
          String? createdAt,
          String? updatedAt,
          Value<String?> lastAttemptAt = const Value.absent(),
          Value<String?> nextRetryAt = const Value.absent(),
          Value<String?> idempotencyKey = const Value.absent(),
          Value<String?> dedupeKey = const Value.absent(),
          String? dependsOnTaskIds,
          Value<String?> entityType = const Value.absent(),
          Value<String?> entityLocalId = const Value.absent(),
          Value<String?> entityRemoteId = const Value.absent(),
          Value<String?> lastError = const Value.absent()}) =>
      SyncTaskRow(
        id: id ?? this.id,
        userId: userId.present ? userId.value : this.userId,
        tenantId: tenantId.present ? tenantId.value : this.tenantId,
        method: method ?? this.method,
        endpoint: endpoint ?? this.endpoint,
        body: body ?? this.body,
        headers: headers ?? this.headers,
        metadata: metadata ?? this.metadata,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        retryCount: retryCount ?? this.retryCount,
        maxRetries: maxRetries ?? this.maxRetries,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
        idempotencyKey:
            idempotencyKey.present ? idempotencyKey.value : this.idempotencyKey,
        dedupeKey: dedupeKey.present ? dedupeKey.value : this.dedupeKey,
        dependsOnTaskIds: dependsOnTaskIds ?? this.dependsOnTaskIds,
        entityType: entityType.present ? entityType.value : this.entityType,
        entityLocalId:
            entityLocalId.present ? entityLocalId.value : this.entityLocalId,
        entityRemoteId:
            entityRemoteId.present ? entityRemoteId.value : this.entityRemoteId,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  SyncTaskRow copyWithCompanion(SyncTasksCompanion data) {
    return SyncTaskRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      method: data.method.present ? data.method.value : this.method,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      body: data.body.present ? data.body.value : this.body,
      headers: data.headers.present ? data.headers.value : this.headers,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      maxRetries:
          data.maxRetries.present ? data.maxRetries.value : this.maxRetries,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt:
          data.nextRetryAt.present ? data.nextRetryAt.value : this.nextRetryAt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      dedupeKey: data.dedupeKey.present ? data.dedupeKey.value : this.dedupeKey,
      dependsOnTaskIds: data.dependsOnTaskIds.present
          ? data.dependsOnTaskIds.value
          : this.dependsOnTaskIds,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityLocalId: data.entityLocalId.present
          ? data.entityLocalId.value
          : this.entityLocalId,
      entityRemoteId: data.entityRemoteId.present
          ? data.entityRemoteId.value
          : this.entityRemoteId,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncTaskRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tenantId: $tenantId, ')
          ..write('method: $method, ')
          ..write('endpoint: $endpoint, ')
          ..write('body: $body, ')
          ..write('headers: $headers, ')
          ..write('metadata: $metadata, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('dependsOnTaskIds: $dependsOnTaskIds, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('entityRemoteId: $entityRemoteId, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        userId,
        tenantId,
        method,
        endpoint,
        body,
        headers,
        metadata,
        status,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        updatedAt,
        lastAttemptAt,
        nextRetryAt,
        idempotencyKey,
        dedupeKey,
        dependsOnTaskIds,
        entityType,
        entityLocalId,
        entityRemoteId,
        lastError
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncTaskRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.tenantId == this.tenantId &&
          other.method == this.method &&
          other.endpoint == this.endpoint &&
          other.body == this.body &&
          other.headers == this.headers &&
          other.metadata == this.metadata &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.dedupeKey == this.dedupeKey &&
          other.dependsOnTaskIds == this.dependsOnTaskIds &&
          other.entityType == this.entityType &&
          other.entityLocalId == this.entityLocalId &&
          other.entityRemoteId == this.entityRemoteId &&
          other.lastError == this.lastError);
}

class SyncTasksCompanion extends UpdateCompanion<SyncTaskRow> {
  final Value<String> id;
  final Value<String?> userId;
  final Value<String?> tenantId;
  final Value<String> method;
  final Value<String> endpoint;
  final Value<String> body;
  final Value<String> headers;
  final Value<String> metadata;
  final Value<String> status;
  final Value<int> priority;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> lastAttemptAt;
  final Value<String?> nextRetryAt;
  final Value<String?> idempotencyKey;
  final Value<String?> dedupeKey;
  final Value<String> dependsOnTaskIds;
  final Value<String?> entityType;
  final Value<String?> entityLocalId;
  final Value<String?> entityRemoteId;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncTasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.method = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.body = const Value.absent(),
    this.headers = const Value.absent(),
    this.metadata = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    this.dependsOnTaskIds = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.entityRemoteId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncTasksCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    this.tenantId = const Value.absent(),
    required String method,
    required String endpoint,
    required String body,
    required String headers,
    required String metadata,
    required String status,
    required int priority,
    required int retryCount,
    required int maxRetries,
    required String createdAt,
    required String updatedAt,
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.dedupeKey = const Value.absent(),
    required String dependsOnTaskIds,
    this.entityType = const Value.absent(),
    this.entityLocalId = const Value.absent(),
    this.entityRemoteId = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        method = Value(method),
        endpoint = Value(endpoint),
        body = Value(body),
        headers = Value(headers),
        metadata = Value(metadata),
        status = Value(status),
        priority = Value(priority),
        retryCount = Value(retryCount),
        maxRetries = Value(maxRetries),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        dependsOnTaskIds = Value(dependsOnTaskIds);
  static Insertable<SyncTaskRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? tenantId,
    Expression<String>? method,
    Expression<String>? endpoint,
    Expression<String>? body,
    Expression<String>? headers,
    Expression<String>? metadata,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? lastAttemptAt,
    Expression<String>? nextRetryAt,
    Expression<String>? idempotencyKey,
    Expression<String>? dedupeKey,
    Expression<String>? dependsOnTaskIds,
    Expression<String>? entityType,
    Expression<String>? entityLocalId,
    Expression<String>? entityRemoteId,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (method != null) 'method': method,
      if (endpoint != null) 'endpoint': endpoint,
      if (body != null) 'body': body,
      if (headers != null) 'headers': headers,
      if (metadata != null) 'metadata': metadata,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (dedupeKey != null) 'dedupe_key': dedupeKey,
      if (dependsOnTaskIds != null) 'depends_on_task_ids': dependsOnTaskIds,
      if (entityType != null) 'entity_type': entityType,
      if (entityLocalId != null) 'entity_local_id': entityLocalId,
      if (entityRemoteId != null) 'entity_remote_id': entityRemoteId,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncTasksCompanion copyWith(
      {Value<String>? id,
      Value<String?>? userId,
      Value<String?>? tenantId,
      Value<String>? method,
      Value<String>? endpoint,
      Value<String>? body,
      Value<String>? headers,
      Value<String>? metadata,
      Value<String>? status,
      Value<int>? priority,
      Value<int>? retryCount,
      Value<int>? maxRetries,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? lastAttemptAt,
      Value<String?>? nextRetryAt,
      Value<String?>? idempotencyKey,
      Value<String?>? dedupeKey,
      Value<String>? dependsOnTaskIds,
      Value<String?>? entityType,
      Value<String?>? entityLocalId,
      Value<String?>? entityRemoteId,
      Value<String?>? lastError,
      Value<int>? rowid}) {
    return SyncTasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tenantId: tenantId ?? this.tenantId,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      body: body ?? this.body,
      headers: headers ?? this.headers,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      dependsOnTaskIds: dependsOnTaskIds ?? this.dependsOnTaskIds,
      entityType: entityType ?? this.entityType,
      entityLocalId: entityLocalId ?? this.entityLocalId,
      entityRemoteId: entityRemoteId ?? this.entityRemoteId,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<String>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<String>(nextRetryAt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (dedupeKey.present) {
      map['dedupe_key'] = Variable<String>(dedupeKey.value);
    }
    if (dependsOnTaskIds.present) {
      map['depends_on_task_ids'] = Variable<String>(dependsOnTaskIds.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityLocalId.present) {
      map['entity_local_id'] = Variable<String>(entityLocalId.value);
    }
    if (entityRemoteId.present) {
      map['entity_remote_id'] = Variable<String>(entityRemoteId.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncTasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('tenantId: $tenantId, ')
          ..write('method: $method, ')
          ..write('endpoint: $endpoint, ')
          ..write('body: $body, ')
          ..write('headers: $headers, ')
          ..write('metadata: $metadata, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('dedupeKey: $dedupeKey, ')
          ..write('dependsOnTaskIds: $dependsOnTaskIds, ')
          ..write('entityType: $entityType, ')
          ..write('entityLocalId: $entityLocalId, ')
          ..write('entityRemoteId: $entityRemoteId, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RelaySyncDriftDatabase extends GeneratedDatabase {
  _$RelaySyncDriftDatabase(QueryExecutor e) : super(e);
  $RelaySyncDriftDatabaseManager get managers =>
      $RelaySyncDriftDatabaseManager(this);
  late final $SyncTasksTable syncTasks = $SyncTasksTable(this);
  late final Index idxSyncTasksStatus = Index('idx_sync_tasks_status',
      'CREATE INDEX idx_sync_tasks_status ON sync_tasks (status)');
  late final Index idxSyncTasksUserId = Index('idx_sync_tasks_userId',
      'CREATE INDEX idx_sync_tasks_userId ON sync_tasks (user_id)');
  late final Index idxSyncTasksTenantId = Index('idx_sync_tasks_tenantId',
      'CREATE INDEX idx_sync_tasks_tenantId ON sync_tasks (tenant_id)');
  late final Index idxSyncTasksNextRetryAt = Index('idx_sync_tasks_nextRetryAt',
      'CREATE INDEX idx_sync_tasks_nextRetryAt ON sync_tasks (next_retry_at)');
  late final Index idxSyncTasksPriority = Index('idx_sync_tasks_priority',
      'CREATE INDEX idx_sync_tasks_priority ON sync_tasks (priority)');
  late final Index idxSyncTasksCreatedAt = Index('idx_sync_tasks_createdAt',
      'CREATE INDEX idx_sync_tasks_createdAt ON sync_tasks (created_at)');
  late final Index idxSyncTasksDedupeKey = Index('idx_sync_tasks_dedupeKey',
      'CREATE INDEX idx_sync_tasks_dedupeKey ON sync_tasks (dedupe_key)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        syncTasks,
        idxSyncTasksStatus,
        idxSyncTasksUserId,
        idxSyncTasksTenantId,
        idxSyncTasksNextRetryAt,
        idxSyncTasksPriority,
        idxSyncTasksCreatedAt,
        idxSyncTasksDedupeKey
      ];
}

typedef $$SyncTasksTableCreateCompanionBuilder = SyncTasksCompanion Function({
  required String id,
  Value<String?> userId,
  Value<String?> tenantId,
  required String method,
  required String endpoint,
  required String body,
  required String headers,
  required String metadata,
  required String status,
  required int priority,
  required int retryCount,
  required int maxRetries,
  required String createdAt,
  required String updatedAt,
  Value<String?> lastAttemptAt,
  Value<String?> nextRetryAt,
  Value<String?> idempotencyKey,
  Value<String?> dedupeKey,
  required String dependsOnTaskIds,
  Value<String?> entityType,
  Value<String?> entityLocalId,
  Value<String?> entityRemoteId,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncTasksTableUpdateCompanionBuilder = SyncTasksCompanion Function({
  Value<String> id,
  Value<String?> userId,
  Value<String?> tenantId,
  Value<String> method,
  Value<String> endpoint,
  Value<String> body,
  Value<String> headers,
  Value<String> metadata,
  Value<String> status,
  Value<int> priority,
  Value<int> retryCount,
  Value<int> maxRetries,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> lastAttemptAt,
  Value<String?> nextRetryAt,
  Value<String?> idempotencyKey,
  Value<String?> dedupeKey,
  Value<String> dependsOnTaskIds,
  Value<String?> entityType,
  Value<String?> entityLocalId,
  Value<String?> entityRemoteId,
  Value<String?> lastError,
  Value<int> rowid,
});

class $$SyncTasksTableFilterComposer
    extends Composer<_$RelaySyncDriftDatabase, $SyncTasksTable> {
  $$SyncTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get headers => $composableBuilder(
      column: $table.headers, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dedupeKey => $composableBuilder(
      column: $table.dedupeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependsOnTaskIds => $composableBuilder(
      column: $table.dependsOnTaskIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityRemoteId => $composableBuilder(
      column: $table.entityRemoteId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnFilters(column));
}

class $$SyncTasksTableOrderingComposer
    extends Composer<_$RelaySyncDriftDatabase, $SyncTasksTable> {
  $$SyncTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get method => $composableBuilder(
      column: $table.method, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint => $composableBuilder(
      column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get headers => $composableBuilder(
      column: $table.headers, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dedupeKey => $composableBuilder(
      column: $table.dedupeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependsOnTaskIds => $composableBuilder(
      column: $table.dependsOnTaskIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityRemoteId => $composableBuilder(
      column: $table.entityRemoteId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastError => $composableBuilder(
      column: $table.lastError, builder: (column) => ColumnOrderings(column));
}

class $$SyncTasksTableAnnotationComposer
    extends Composer<_$RelaySyncDriftDatabase, $SyncTasksTable> {
  $$SyncTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get maxRetries => $composableBuilder(
      column: $table.maxRetries, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<String> get nextRetryAt => $composableBuilder(
      column: $table.nextRetryAt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get dedupeKey =>
      $composableBuilder(column: $table.dedupeKey, builder: (column) => column);

  GeneratedColumn<String> get dependsOnTaskIds => $composableBuilder(
      column: $table.dependsOnTaskIds, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityLocalId => $composableBuilder(
      column: $table.entityLocalId, builder: (column) => column);

  GeneratedColumn<String> get entityRemoteId => $composableBuilder(
      column: $table.entityRemoteId, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncTasksTableTableManager extends RootTableManager<
    _$RelaySyncDriftDatabase,
    $SyncTasksTable,
    SyncTaskRow,
    $$SyncTasksTableFilterComposer,
    $$SyncTasksTableOrderingComposer,
    $$SyncTasksTableAnnotationComposer,
    $$SyncTasksTableCreateCompanionBuilder,
    $$SyncTasksTableUpdateCompanionBuilder,
    (
      SyncTaskRow,
      BaseReferences<_$RelaySyncDriftDatabase, $SyncTasksTable, SyncTaskRow>
    ),
    SyncTaskRow,
    PrefetchHooks Function()> {
  $$SyncTasksTableTableManager(
      _$RelaySyncDriftDatabase db, $SyncTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> tenantId = const Value.absent(),
            Value<String> method = const Value.absent(),
            Value<String> endpoint = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String> headers = const Value.absent(),
            Value<String> metadata = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> lastAttemptAt = const Value.absent(),
            Value<String?> nextRetryAt = const Value.absent(),
            Value<String?> idempotencyKey = const Value.absent(),
            Value<String?> dedupeKey = const Value.absent(),
            Value<String> dependsOnTaskIds = const Value.absent(),
            Value<String?> entityType = const Value.absent(),
            Value<String?> entityLocalId = const Value.absent(),
            Value<String?> entityRemoteId = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncTasksCompanion(
            id: id,
            userId: userId,
            tenantId: tenantId,
            method: method,
            endpoint: endpoint,
            body: body,
            headers: headers,
            metadata: metadata,
            status: status,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            idempotencyKey: idempotencyKey,
            dedupeKey: dedupeKey,
            dependsOnTaskIds: dependsOnTaskIds,
            entityType: entityType,
            entityLocalId: entityLocalId,
            entityRemoteId: entityRemoteId,
            lastError: lastError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> userId = const Value.absent(),
            Value<String?> tenantId = const Value.absent(),
            required String method,
            required String endpoint,
            required String body,
            required String headers,
            required String metadata,
            required String status,
            required int priority,
            required int retryCount,
            required int maxRetries,
            required String createdAt,
            required String updatedAt,
            Value<String?> lastAttemptAt = const Value.absent(),
            Value<String?> nextRetryAt = const Value.absent(),
            Value<String?> idempotencyKey = const Value.absent(),
            Value<String?> dedupeKey = const Value.absent(),
            required String dependsOnTaskIds,
            Value<String?> entityType = const Value.absent(),
            Value<String?> entityLocalId = const Value.absent(),
            Value<String?> entityRemoteId = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncTasksCompanion.insert(
            id: id,
            userId: userId,
            tenantId: tenantId,
            method: method,
            endpoint: endpoint,
            body: body,
            headers: headers,
            metadata: metadata,
            status: status,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastAttemptAt: lastAttemptAt,
            nextRetryAt: nextRetryAt,
            idempotencyKey: idempotencyKey,
            dedupeKey: dedupeKey,
            dependsOnTaskIds: dependsOnTaskIds,
            entityType: entityType,
            entityLocalId: entityLocalId,
            entityRemoteId: entityRemoteId,
            lastError: lastError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncTasksTableProcessedTableManager = ProcessedTableManager<
    _$RelaySyncDriftDatabase,
    $SyncTasksTable,
    SyncTaskRow,
    $$SyncTasksTableFilterComposer,
    $$SyncTasksTableOrderingComposer,
    $$SyncTasksTableAnnotationComposer,
    $$SyncTasksTableCreateCompanionBuilder,
    $$SyncTasksTableUpdateCompanionBuilder,
    (
      SyncTaskRow,
      BaseReferences<_$RelaySyncDriftDatabase, $SyncTasksTable, SyncTaskRow>
    ),
    SyncTaskRow,
    PrefetchHooks Function()>;

class $RelaySyncDriftDatabaseManager {
  final _$RelaySyncDriftDatabase _db;
  $RelaySyncDriftDatabaseManager(this._db);
  $$SyncTasksTableTableManager get syncTasks =>
      $$SyncTasksTableTableManager(_db, _db.syncTasks);
}
