import 'model_utils.dart';
import 'relay_sync_exception.dart';
import 'sync_enums.dart';
import 'sync_error.dart';
import 'sync_metadata.dart';

const Object _copyWithUnset = Object();

/// Immutable unit of work representing a queued API request.
class SyncTask {
  /// Creates a validated [SyncTask].
  SyncTask({
    required this.id,
    this.userId,
    this.tenantId,
    required this.method,
    required this.endpoint,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    required this.metadata,
    this.status = SyncTaskStatus.pending,
    this.priority = SyncPriority.normal,
    this.retryCount = 0,
    this.maxRetries = 5,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.idempotencyKey,
    this.dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    this.entityType,
    this.entityLocalId,
    this.entityRemoteId,
    this.lastError,
  })  : body = Map<String, Object?>.unmodifiable(body),
        headers = Map<String, String>.unmodifiable(headers),
        dependsOnTaskIds = List<String>.unmodifiable(dependsOnTaskIds) {
    validate();
  }

  /// Unique task id.
  final String id;

  /// Optional user scope id.
  final String? userId;

  /// Optional tenant scope id.
  final String? tenantId;

  /// HTTP method to execute.
  final SyncMethod method;

  /// Endpoint path or URL.
  final String endpoint;

  /// Request payload.
  final Map<String, Object?> body;

  /// Request headers.
  final Map<String, String> headers;

  /// Additional task metadata.
  final SyncMetadata metadata;

  /// Current processing status.
  final SyncTaskStatus status;

  /// Scheduling priority.
  final SyncPriority priority;

  /// Number of completed retry attempts.
  final int retryCount;

  /// Maximum retries allowed.
  final int maxRetries;

  /// Task creation time.
  final DateTime createdAt;

  /// Last update time.
  final DateTime updatedAt;

  /// Last attempt timestamp.
  final DateTime? lastAttemptAt;

  /// Next retry schedule timestamp.
  final DateTime? nextRetryAt;

  /// Optional idempotency key.
  final String? idempotencyKey;

  /// Optional deduplication key.
  final String? dedupeKey;

  /// Dependent task ids required before processing.
  final List<String> dependsOnTaskIds;

  /// Entity type associated with this task.
  final String? entityType;

  /// Local entity identifier.
  final String? entityLocalId;

  /// Remote entity identifier.
  final String? entityRemoteId;

  /// Last recorded task error.
  final SyncError? lastError;

  /// Factory for a GET sync task.
  factory SyncTask.get({
    required String id,
    String? userId,
    String? tenantId,
    required String endpoint,
    Map<String, String> headers = const <String, String>{},
    required SyncMetadata metadata,
    SyncTaskStatus status = SyncTaskStatus.pending,
    SyncPriority priority = SyncPriority.normal,
    int retryCount = 0,
    int maxRetries = 5,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? idempotencyKey,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    String? entityType,
    String? entityLocalId,
    String? entityRemoteId,
    SyncError? lastError,
  }) {
    return SyncTask(
      id: id,
      userId: userId,
      tenantId: tenantId,
      method: SyncMethod.get,
      endpoint: endpoint,
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
    );
  }

  /// Factory for a POST sync task.
  factory SyncTask.post({
    required String id,
    String? userId,
    String? tenantId,
    required String endpoint,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    required SyncMetadata metadata,
    SyncTaskStatus status = SyncTaskStatus.pending,
    SyncPriority priority = SyncPriority.normal,
    int retryCount = 0,
    int maxRetries = 5,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? idempotencyKey,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    String? entityType,
    String? entityLocalId,
    String? entityRemoteId,
    SyncError? lastError,
  }) {
    return SyncTask(
      id: id,
      userId: userId,
      tenantId: tenantId,
      method: SyncMethod.post,
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
    );
  }

  /// Factory for a PUT sync task.
  factory SyncTask.put({
    required String id,
    String? userId,
    String? tenantId,
    required String endpoint,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    required SyncMetadata metadata,
    SyncTaskStatus status = SyncTaskStatus.pending,
    SyncPriority priority = SyncPriority.normal,
    int retryCount = 0,
    int maxRetries = 5,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? idempotencyKey,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    String? entityType,
    String? entityLocalId,
    String? entityRemoteId,
    SyncError? lastError,
  }) {
    return SyncTask(
      id: id,
      userId: userId,
      tenantId: tenantId,
      method: SyncMethod.put,
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
    );
  }

  /// Factory for a PATCH sync task.
  factory SyncTask.patch({
    required String id,
    String? userId,
    String? tenantId,
    required String endpoint,
    Map<String, Object?> body = const <String, Object?>{},
    Map<String, String> headers = const <String, String>{},
    required SyncMetadata metadata,
    SyncTaskStatus status = SyncTaskStatus.pending,
    SyncPriority priority = SyncPriority.normal,
    int retryCount = 0,
    int maxRetries = 5,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? idempotencyKey,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    String? entityType,
    String? entityLocalId,
    String? entityRemoteId,
    SyncError? lastError,
  }) {
    return SyncTask(
      id: id,
      userId: userId,
      tenantId: tenantId,
      method: SyncMethod.patch,
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
    );
  }

  /// Factory for a DELETE sync task.
  factory SyncTask.delete({
    required String id,
    String? userId,
    String? tenantId,
    required String endpoint,
    Map<String, String> headers = const <String, String>{},
    required SyncMetadata metadata,
    SyncTaskStatus status = SyncTaskStatus.pending,
    SyncPriority priority = SyncPriority.normal,
    int retryCount = 0,
    int maxRetries = 5,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? idempotencyKey,
    String? dedupeKey,
    List<String> dependsOnTaskIds = const <String>[],
    String? entityType,
    String? entityLocalId,
    String? entityRemoteId,
    SyncError? lastError,
  }) {
    return SyncTask(
      id: id,
      userId: userId,
      tenantId: tenantId,
      method: SyncMethod.delete,
      endpoint: endpoint,
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
    );
  }

  /// Validates task fields and throws [RelaySyncException] on invalid data.
  void validate() {
    if (id.trim().isEmpty) {
      throw const RelaySyncException(message: 'SyncTask.id must not be empty.');
    }
    if (endpoint.trim().isEmpty) {
      throw const RelaySyncException(message: 'SyncTask.endpoint must not be empty.');
    }
    if (retryCount < 0) {
      throw const RelaySyncException(message: 'SyncTask.retryCount cannot be negative.');
    }
    if (maxRetries < 0) {
      throw const RelaySyncException(message: 'SyncTask.maxRetries cannot be negative.');
    }
    if (retryCount > maxRetries) {
      throw const RelaySyncException(
        message: 'SyncTask.retryCount cannot exceed SyncTask.maxRetries.',
      );
    }
    if (updatedAt.isBefore(createdAt)) {
      throw const RelaySyncException(
        message: 'SyncTask.updatedAt cannot be before SyncTask.createdAt.',
      );
    }
    if (lastAttemptAt != null && lastAttemptAt!.isBefore(createdAt)) {
      throw const RelaySyncException(
        message: 'SyncTask.lastAttemptAt cannot be before SyncTask.createdAt.',
      );
    }
    if (nextRetryAt != null && lastAttemptAt != null && nextRetryAt!.isBefore(lastAttemptAt!)) {
      throw const RelaySyncException(
        message: 'SyncTask.nextRetryAt cannot be before SyncTask.lastAttemptAt.',
      );
    }
  }

  /// Returns a modified copy of this task.
  SyncTask copyWith({
    String? id,
    Object? userId = _copyWithUnset,
    Object? tenantId = _copyWithUnset,
    SyncMethod? method,
    String? endpoint,
    Map<String, Object?>? body,
    Map<String, String>? headers,
    SyncMetadata? metadata,
    SyncTaskStatus? status,
    SyncPriority? priority,
    int? retryCount,
    int? maxRetries,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastAttemptAt = _copyWithUnset,
    Object? nextRetryAt = _copyWithUnset,
    Object? idempotencyKey = _copyWithUnset,
    Object? dedupeKey = _copyWithUnset,
    List<String>? dependsOnTaskIds,
    Object? entityType = _copyWithUnset,
    Object? entityLocalId = _copyWithUnset,
    Object? entityRemoteId = _copyWithUnset,
    Object? lastError = _copyWithUnset,
  }) {
    return SyncTask(
      id: id ?? this.id,
      userId: identical(userId, _copyWithUnset) ? this.userId : userId as String?,
      tenantId: identical(tenantId, _copyWithUnset) ? this.tenantId : tenantId as String?,
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
      lastAttemptAt: identical(lastAttemptAt, _copyWithUnset)
          ? this.lastAttemptAt
          : lastAttemptAt as DateTime?,
      nextRetryAt: identical(nextRetryAt, _copyWithUnset)
          ? this.nextRetryAt
          : nextRetryAt as DateTime?,
      idempotencyKey: identical(idempotencyKey, _copyWithUnset)
          ? this.idempotencyKey
          : idempotencyKey as String?,
      dedupeKey: identical(dedupeKey, _copyWithUnset) ? this.dedupeKey : dedupeKey as String?,
      dependsOnTaskIds: dependsOnTaskIds ?? this.dependsOnTaskIds,
      entityType: identical(entityType, _copyWithUnset) ? this.entityType : entityType as String?,
      entityLocalId: identical(entityLocalId, _copyWithUnset)
          ? this.entityLocalId
          : entityLocalId as String?,
      entityRemoteId: identical(entityRemoteId, _copyWithUnset)
          ? this.entityRemoteId
          : entityRemoteId as String?,
      lastError: identical(lastError, _copyWithUnset) ? this.lastError : lastError as SyncError?,
    );
  }

  /// Converts this task to a JSON map.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'userId': userId,
      'tenantId': tenantId,
      'method': method.toJson(),
      'endpoint': endpoint,
      'body': body,
      'headers': headers,
      'metadata': metadata.toJson(),
      'status': status.toJson(),
      'priority': priority.toJson(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'idempotencyKey': idempotencyKey,
      'dedupeKey': dedupeKey,
      'dependsOnTaskIds': dependsOnTaskIds,
      'entityType': entityType,
      'entityLocalId': entityLocalId,
      'entityRemoteId': entityRemoteId,
      'lastError': lastError?.toJson(),
    };
  }

  /// Creates a task from JSON.
  factory SyncTask.fromJson(Map<String, Object?> json) {
    return SyncTask(
      id: json['id']! as String,
      userId: json['userId'] as String?,
      tenantId: json['tenantId'] as String?,
      method: SyncMethodJson.fromJson(json['method']! as String),
      endpoint: json['endpoint']! as String,
      body: Map<String, Object?>.from(
        (json['body'] as Map<Object?, Object?>?) ?? const <String, Object?>{},
      ),
      headers: Map<String, String>.from(
        (json['headers'] as Map<Object?, Object?>?) ?? const <String, String>{},
      ),
      metadata: SyncMetadata.fromJson(
        Map<String, Object?>.from(json['metadata']! as Map<Object?, Object?>),
      ),
      status: SyncTaskStatusJson.fromJson(json['status']! as String),
      priority: SyncPriorityJson.fromJson(json['priority']! as String),
      retryCount: json['retryCount']! as int,
      maxRetries: json['maxRetries']! as int,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt']! as String),
      nextRetryAt: json['nextRetryAt'] == null
          ? null
          : DateTime.parse(json['nextRetryAt']! as String),
      idempotencyKey: json['idempotencyKey'] as String?,
      dedupeKey: json['dedupeKey'] as String?,
      dependsOnTaskIds: List<String>.from(
        (json['dependsOnTaskIds'] as List<Object?>?) ?? const <String>[],
      ),
      entityType: json['entityType'] as String?,
      entityLocalId: json['entityLocalId'] as String?,
      entityRemoteId: json['entityRemoteId'] as String?,
      lastError: json['lastError'] == null
          ? null
          : SyncError.fromJson(
              Map<String, Object?>.from(json['lastError']! as Map<Object?, Object?>),
            ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SyncTask &&
            other.id == id &&
            other.userId == userId &&
            other.tenantId == tenantId &&
            other.method == method &&
            other.endpoint == endpoint &&
            mapEquals(other.body, body) &&
            mapEquals(other.headers, headers) &&
            other.metadata == metadata &&
            other.status == status &&
            other.priority == priority &&
            other.retryCount == retryCount &&
            other.maxRetries == maxRetries &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt &&
            other.lastAttemptAt == lastAttemptAt &&
            other.nextRetryAt == nextRetryAt &&
            other.idempotencyKey == idempotencyKey &&
            other.dedupeKey == dedupeKey &&
            listEquals(other.dependsOnTaskIds, dependsOnTaskIds) &&
            other.entityType == entityType &&
            other.entityLocalId == entityLocalId &&
            other.entityRemoteId == entityRemoteId &&
            other.lastError == lastError;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        userId,
        tenantId,
        method,
        endpoint,
        mapHash(body),
        mapHash(headers),
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
        listHash(dependsOnTaskIds),
        entityType,
        entityLocalId,
        entityRemoteId,
        lastError,
      ]);
}
